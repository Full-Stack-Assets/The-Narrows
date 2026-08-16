extends Node
class_name WantedSystem

signal pursuit_state_changed(label: String, last_known_position: Vector3)




const POLICE_SCRIPT: = preload("res://scripts/police.gd")
const ENFORCER_SCRIPT: = preload("res://scripts/faction_enforcer.gd")
const PoliceStateRuntime = preload("res://scripts/ai/police_state.gd")

var player: Node3D = null
var world: Node3D = null

var _cops: Array = []
var _enforcers: Array = []
var _spawn_timer: float = 0.0
var _enforcer_spawn_timer: float = 0.0
var _decay_timer: float = 0.0
var _busted_cooldown: float = 0.0
var _pursuit_label: String = ""
var _last_known_position: Vector3 = Vector3.ZERO
var _escaped_announced: bool = false

const MAX_COPS: = 5
const MAX_ENFORCERS: = 3
const SPAWN_DIST: = 42.0
const DECAY_TIME: = 13.0


func setup(p_player: Node3D, p_world: Node3D) -> void :
    player = p_player
    world = p_world


func get_cops() -> Array:
    return _cops


func get_enforcers() -> Array:
    return _enforcers


func get_search_area() -> Dictionary:
    if _pursuit_label != "SEARCHING":
        return {}
    return {"position": _last_known_position, "radius": 18.0}


func clear_pursuit() -> void :
    _set_pursuit_label("", Vector3.ZERO)
    _clear_cops()
    _clear_enforcers()
    _busted_cooldown = 2.0


func add_heat(stars: int) -> void :
    # Cheat: suppress all police heat while testing.
    if GameManager and GameManager.cheat_no_police:
        return
    if _busted_cooldown > 0.0:
        return
    GameManager.set_wanted(GameManager.wanted_level + stars)
    _decay_timer = DECAY_TIME * 1.5
    if GameManager.wanted_level == 1 and stars > 0:
        GameManager.show_message("You've drawn police attention!")


func add_faction_heat(stars: int) -> void :
    if GameManager == null:
        return
    if _busted_cooldown > 0.0:
        return
    var was: int = GameManager.faction_level
    GameManager.set_faction(GameManager.faction_level + stars)
    _decay_timer = DECAY_TIME * 1.5
    if was == 0 and GameManager.faction_level >= 1:
        GameManager.show_message("The streets noticed that.")


func on_cop_killed() -> void :
    add_heat(1)


func on_player_caught() -> void :
    if _busted_cooldown > 0.0:
        return
    _busted()


func _process(delta: float) -> void :
    _busted_cooldown = max(0.0, _busted_cooldown - delta)

    for i in range(_cops.size() - 1, -1, -1):
        if not is_instance_valid(_cops[i]):
            _cops.remove_at(i)

    var level: int = GameManager.wanted_level
    var faction: int = GameManager.faction_level
    if level <= 0 and faction <= 0:
        if _pursuit_label != "ESCAPED":
            _set_pursuit_label("", Vector3.ZERO)
        if not _cops.is_empty():
            _clear_cops()
        return

    if level <= 0 and not _cops.is_empty():
        _clear_cops()

    _update_pursuit_status()
    if not _has_active_sight():
        _decay_timer -= delta
    if _decay_timer <= 0.0:
        _decay_timer = DECAY_TIME
        level = GameManager.wanted_level
        faction = GameManager.faction_level
        if level > 0:
            GameManager.set_wanted(level - 1)
            if GameManager.wanted_level == 0 and GameManager.faction_level == 0:
                GameManager.show_message("You lost the heat.")
            elif GameManager.wanted_level == 0:
                GameManager.show_message("You lost the cops.")
        if faction > 0:
            GameManager.set_faction(faction - 1)
            if GameManager.faction_level == 0 and GameManager.wanted_level > 0:
                GameManager.show_message("The crews backed off.")

    _update_enforcers(delta)
    if GameManager.wanted_level <= 0:
        return

    var quality: int = GameManager.graphics_quality if GameManager else 1
    var want_cops: int = mini(PoliceStateRuntime.backup_cap(level, quality), MAX_COPS)
    _spawn_timer -= delta
    if _cops.size() < want_cops and _spawn_timer <= 0.0:
        _spawn_timer = 1.6
        _spawn_cop()

func _update_enforcers(delta: float) -> void :
    for i in range(_enforcers.size() - 1, -1, -1):
        if not is_instance_valid(_enforcers[i]):
            _enforcers.remove_at(i)

    var faction: int = GameManager.faction_level
    if faction <= 0:
        if not _enforcers.is_empty():
            _clear_enforcers()
        return

    var want: int = mini(faction + 1, MAX_ENFORCERS)
    _enforcer_spawn_timer -= delta
    if _enforcers.size() < want and _enforcer_spawn_timer <= 0.0 and player != null:
        _enforcer_spawn_timer = 2.4
        _spawn_enforcer()


func _spawn_enforcer() -> void :
    if world == null or player == null:
        return
    var ang: float = randf() * TAU
    var offset: = Vector3(cos(ang), 0, sin(ang)) * (SPAWN_DIST * 0.85)
    var pos: Vector3 = player.global_position + offset
    pos.y = 0.4
    var goon: = CharacterBody3D.new()
    goon.set_script(ENFORCER_SCRIPT)
    goon.setup(player, self)
    world.add_child(goon)
    goon.global_position = pos
    _enforcers.append(goon)


func _spawn_cop() -> void :
    if world == null or player == null:
        return
    var pos := Vector3.INF
    for _attempt in range(18):
        var ang: float = randf() * TAU
        var distance := randf_range(SPAWN_DIST, SPAWN_DIST + 14.0)
        var offset: = Vector3(cos(ang), 0, sin(ang)) * distance
        var candidate: Vector3 = player.global_position + offset
        candidate.y = 0.4
        if not _is_position_visible(candidate):
            pos = candidate
            break
    if not pos.is_finite():
        return
    var cop: = CharacterBody3D.new()
    cop.set_script(POLICE_SCRIPT)
    cop.setup(player, self)
    world.add_child(cop)
    cop.global_position = pos
    _cops.append(cop)


func _is_position_visible(position: Vector3) -> bool:
    var camera := get_viewport().get_camera_3d()
    return camera != null and camera.is_position_in_frustum(position + Vector3.UP)


func _has_active_sight() -> bool:
    for cop in _cops:
        if is_instance_valid(cop) and cop.has_method("is_actively_seeing_player") and cop.is_actively_seeing_player():
            return true
    return false


func on_police_state_changed(_cop: Node, _state: int, last_known: Vector3) -> void:
    if last_known != Vector3.ZERO:
        _last_known_position = last_known
    _update_pursuit_status()


func _update_pursuit_status() -> void:
    var pursuing := false
    var searching := false
    var disengaging := false
    for cop in _cops:
        if not is_instance_valid(cop) or not cop.has_method("pursuit_state"):
            continue
        var state: int = cop.pursuit_state()
        if cop.has_method("last_known_position") and cop.last_known_position() != Vector3.ZERO:
            _last_known_position = cop.last_known_position()
        pursuing = pursuing or state == PoliceStateRuntime.State.PURSUING
        searching = searching or state == PoliceStateRuntime.State.SEARCHING
        disengaging = disengaging or state == PoliceStateRuntime.State.DISENGAGING
    if pursuing:
        _escaped_announced = false
        _set_pursuit_label("SPOTTED", _last_known_position)
    elif searching or (not _cops.is_empty() and not disengaging):
        _set_pursuit_label("SEARCHING", _last_known_position)
    elif disengaging and not _escaped_announced:
        _escaped_announced = true
        _set_pursuit_label("ESCAPED", _last_known_position)
        GameManager.set_wanted(0)


func _set_pursuit_label(label: String, last_known: Vector3) -> void:
    if label == _pursuit_label and last_known == _last_known_position:
        return
    _pursuit_label = label
    if last_known != Vector3.ZERO:
        _last_known_position = last_known
    pursuit_state_changed.emit(_pursuit_label, _last_known_position)


func _busted() -> void :
    if ConsequenceManager and ConsequenceManager.is_active():
        return
    _busted_cooldown = 4.0
    _clear_cops()
    if ConsequenceManager and ConsequenceManager.has_method("start"):
        ConsequenceManager.start("busted")
        return
    # Fallback if autoload missing.
    GameManager.set_wanted(0)
    GameManager.set_faction(0)
    if player and is_instance_valid(player) and player.has_method("on_busted"):
        player.on_busted()


func _clear_enforcers() -> void :
    for e in _enforcers:
        if is_instance_valid(e):
            e.queue_free()
    _enforcers.clear()


func _clear_cops() -> void :
    for c in _cops:
        if is_instance_valid(c):
            c.queue_free()
    _cops.clear()
