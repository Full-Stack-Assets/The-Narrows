extends Node

const SaveSchemaScript := preload("res://scripts/save/save_schema.gd")
const SaveServiceScript := preload("res://scripts/save/save_service.gd")




signal cash_changed(new_cash: int)
signal notify(message: String)
signal wanted_changed(level: int)
signal faction_changed(level: int)
signal scrimshaw_changed(found: int)
signal businesses_changed(count: int)
signal open_shop_requested(shop_kind: String)
signal open_diner_requested()
signal graphics_quality_changed(level: int)

const QUALITY_NAMES: PackedStringArray = ["Low", "Medium", "High"]
const STARTING_CASH: = 40
const SCRIMSHAW_TOTAL: int = 8
const BUSINESS_TOTAL: int = 7

var cash: int = STARTING_CASH
var missions_completed: int = 0
var wanted_level: int = 0
var faction_level: int = 0
var campaign_format: int = 2  # bumps when mission list changes (save migration)
var opener_complete: bool = false
var campaign_mi: int = 0
var campaign_step: int = 0
var campaign_done: bool = false
var player_spawn_override: = Vector3.ZERO
var has_spawn_override: bool = false
var scrimshaw_mask: int = 0
var owned_business_mask: int = 0
var mission_snapshot: Dictionary = {}
var claimed_rewards: Array = []
var activity_state: Dictionary = {}
var business_state: Dictionary = {}
var vehicle_state: Dictionary = {"identity": "", "condition": 1.0}
var saved_health: float = 100.0
var saved_armor: float = 0.0
var accessibility_settings: Dictionary = {
    "subtitles": true,
    "subtitle_size": 1.0,
    "high_contrast": false,
    "reduced_motion": false,
}
var input_settings: Dictionary = {}
var _save_service: SaveService

# Cheats (toggled from the main-menu CHEATS panel; persisted with the save).
# no_police suppresses all wanted-heat for testing. Defaults OFF so the crime loop bites.
var cheat_no_police: bool = false
var cheat_godmode: bool = false
# Forced time of day: -1 = normal day/night clock; otherwise a fixed day_phase
# (0=dusk, 0.25=night, 0.5=dawn, 0.75=midday).
var cheat_time_phase: float = -1.0
var cheat_infinite_ammo: bool = false
var cheat_all_weapons: bool = false
var cheat_oneshot: bool = false
var cheat_rapidfire: bool = false
var cheat_super_speed: bool = false
var cheat_super_jump: bool = false
var cheat_infinite_cash: bool = false
var cheat_car_turbo: bool = false
var cheat_force_rain: int = -1     # -1 auto · 0 forced dry · 1 forced rain
var cheat_traffic_mult: float = 1.0
var cheat_time_scale: float = 1.0  # global slow-mo / fast-forward
var cheat_teleport_anywhere: bool = false
var cheat_show_debug: bool = false   # on-screen FPS/mem/telemetry overlay
# Chase-cam side: false = behind the car, true = flipped to the other side (CAM button).
var cam_flip: bool = false
# Graphics quality: 0=Low (mobile), 1=Medium, 2=High. Affects streaming radius,
# car pool, traffic, rain, and building LOD.
var graphics_quality: int = 1


func stream_radius() -> int:
    return [1, 2, 3][graphics_quality]


func car_pool_size() -> int:
    return [100, 150, 200][graphics_quality]


func traffic_car_count() -> int:
    return [8, 12, 16][graphics_quality]


func pedestrian_count() -> int:
    return [10, 18, 30][graphics_quality]


func stream_tile_budget() -> int:
    return [2, 5, 12][graphics_quality]


func building_lod() -> int:
    return graphics_quality


func rain_particle_count() -> int:
    return [0, 180, 280][graphics_quality]


func car_restream_batch() -> int:
    return [8, 12, 20][graphics_quality]


func set_graphics_quality(level: int) -> void :
    level = clampi(level, 0, 2)
    if level == graphics_quality:
        return
    graphics_quality = level
    graphics_quality_changed.emit(graphics_quality)
    _save_graphics_cfg()


func _load_graphics_cfg() -> void :
    var cfg: = ConfigFile.new()
    if cfg.load("user://settings.cfg") == OK:
        graphics_quality = clampi(int(cfg.get_value("graphics", "quality", 1)), 0, 2)


func _save_graphics_cfg() -> void :
    var cfg: = ConfigFile.new()
    cfg.load("user://settings.cfg")
    cfg.set_value("graphics", "quality", graphics_quality)
    cfg.save("user://settings.cfg")


func toggle_cam_flip() -> void :
    cam_flip = not cam_flip
    save_game()


# All cheat flags, keyed for compact save/load (avoids a giant literal twice).
func _cheat_dict() -> Dictionary:
    return {
        "no_police": cheat_no_police, "godmode": cheat_godmode,
        "time_phase": cheat_time_phase, "inf_ammo": cheat_infinite_ammo,
        "all_weapons": cheat_all_weapons, "oneshot": cheat_oneshot,
        "rapidfire": cheat_rapidfire, "super_speed": cheat_super_speed,
        "super_jump": cheat_super_jump, "inf_cash": cheat_infinite_cash,
        "car_turbo": cheat_car_turbo, "force_rain": cheat_force_rain,
        "traffic_mult": cheat_traffic_mult, "time_scale": cheat_time_scale,
        "tp_anywhere": cheat_teleport_anywhere, "cam_flip": cam_flip,
        "show_debug": cheat_show_debug,
    }


func _load_cheats(d: Dictionary) -> void :
    cheat_no_police = bool(d.get("no_police", false))
    cheat_godmode = bool(d.get("godmode", false))
    cheat_time_phase = float(d.get("time_phase", -1.0))
    cheat_infinite_ammo = bool(d.get("inf_ammo", false))
    cheat_all_weapons = bool(d.get("all_weapons", false))
    cheat_oneshot = bool(d.get("oneshot", false))
    cheat_rapidfire = bool(d.get("rapidfire", false))
    cheat_super_speed = bool(d.get("super_speed", false))
    cheat_super_jump = bool(d.get("super_jump", false))
    cheat_infinite_cash = bool(d.get("inf_cash", false))
    cheat_car_turbo = bool(d.get("car_turbo", false))
    cheat_force_rain = int(d.get("force_rain", -1))
    cheat_traffic_mult = float(d.get("traffic_mult", 1.0))
    cheat_time_scale = float(d.get("time_scale", 1.0))
    cheat_teleport_anywhere = bool(d.get("tp_anywhere", false))
    cam_flip = bool(d.get("cam_flip", false))
    cheat_show_debug = bool(d.get("show_debug", false))

# Last known player position/heading, persisted so the menu can offer Continue.
var saved_pos: = Vector3.ZERO
var saved_yaw: float = 0.0
var has_saved_pos: bool = false

# World clock + weather, written by game_world so the HUD can display them.
# day_phase 0 = dusk; the loop runs dusk→night→dawn→day→dusk.
var day_phase: float = 0.0
var raining: bool = false
# Scripted Act III hurricane — forces heavy rain, wind, and coastal flood visuals.
var gloria_storm_active: bool = false

func time_string() -> String:
    var hours: float = fmod(day_phase * 24.0 + 18.0, 24.0)
    var h: int = int(hours)
    var m: int = int((hours - h) * 60.0)
    return "%02d:%02d" % [h, m]


func set_wanted(level: int) -> void :
    level = clampi(level, 0, 5)
    if level == wanted_level:
        return
    wanted_level = level
    wanted_changed.emit(wanted_level)


func set_faction(level: int) -> void :
    level = clampi(level, 0, 5)
    if level == faction_level:
        return
    faction_level = level
    faction_changed.emit(faction_level)


func scrimshaw_found() -> int:
    var n: int = 0
    for i in SCRIMSHAW_TOTAL:
        if scrimshaw_mask & (1 << i):
            n += 1
    return n


func is_scrimshaw_collected(index: int) -> bool:
    return index >= 0 and index < SCRIMSHAW_TOTAL and (scrimshaw_mask & (1 << index)) != 0


func collect_scrimshaw(index: int) -> bool:
    if index < 0 or index >= SCRIMSHAW_TOTAL:
        return false
    if is_scrimshaw_collected(index):
        return false
    scrimshaw_mask |= 1 << index
    scrimshaw_changed.emit(scrimshaw_found())
    return true


func businesses_owned() -> int:
    var n: int = 0
    for i in BUSINESS_TOTAL:
        if owned_business_mask & (1 << i):
            n += 1
    return n


func is_business_owned(index: int) -> bool:
    return index >= 0 and index < BUSINESS_TOTAL and (owned_business_mask & (1 << index)) != 0


func own_business(index: int) -> bool:
    if index < 0 or index >= BUSINESS_TOTAL:
        return false
    if is_business_owned(index):
        return false
    owned_business_mask |= 1 << index
    businesses_changed.emit(businesses_owned())
    save_game()
    return true

func _ready() -> void :
    _save_service = SaveServiceScript.new()
    _load_graphics_cfg()
    load_game()

func add_cash(amount: int) -> void :
    cash += amount
    cash = max(cash, 0)
    cash_changed.emit(cash)
    save_game()


func add_cash_silent(amount: int) -> void :
    if amount == 0:
        return
    cash += amount
    cash = max(cash, 0)
    cash_changed.emit(cash)

func spend_cash(amount: int) -> bool:
    if cheat_infinite_cash:
        return true
    if cash < amount:
        notify.emit("Not enough cash.")
        return false
    cash -= amount
    cash_changed.emit(cash)
    save_game()
    return true

func can_afford(amount: int) -> bool:
    return cash >= amount

func record_mission_complete() -> void :
    missions_completed += 1
    save_game()

func show_message(message: String) -> void :
    notify.emit(message)

# Called by the player on a light interval so Continue resumes where you left off.
func save_player_state(pos: Vector3, yaw: float, health: float, armor: float, vehicle: Dictionary = {}) -> void:
    saved_pos = pos
    saved_yaw = yaw
    saved_health = health
    saved_armor = armor
    if not vehicle.is_empty():
        vehicle_state = vehicle.duplicate(true)
    has_saved_pos = true
    save_game()


func save_position(pos: Vector3, yaw: float) -> void :
    save_player_state(pos, yaw, saved_health, saved_armor)


func has_save() -> bool:
    return _save_service != null and _save_service.has_valid_save()


func has_backup_save() -> bool:
    return _save_service != null and _save_service.has_recoverable_backup()


func recover_backup_save() -> Error:
    if _save_service == null:
        return ERR_UNCONFIGURED
    var result := _save_service.recover_backup()
    if result == OK:
        load_game()
    return result

func save_game() -> void :
    if _save_service == null:
        return
    if BusinessManager and BusinessManager.has_method("snapshot"):
        business_state = BusinessManager.snapshot()
    var result := _save_service.write(_build_save_snapshot())
    if result != OK:
        push_error("Save failed with error %d" % result)

func load_game() -> void :
    if _save_service == null:
        return
    var data := _save_service.read()
    if data.is_empty():
        return
    var player: Dictionary = data["player"]
    var economy: Dictionary = data["economy"]
    var heat: Dictionary = data["heat"]
    var mission: Dictionary = data["mission"]
    var businesses: Dictionary = data["businesses"]
    var world: Dictionary = data["world"]
    var settings: Dictionary = data["settings"]
    var campaign: Dictionary = data["legacy_campaign"]
    cash = int(economy["cash"])
    missions_completed = int(campaign["missions_completed"])
    wanted_level = int(heat["police"])
    faction_level = int(heat["faction"])
    campaign_format = int(campaign["format"])
    opener_complete = bool(campaign["opener_complete"])
    campaign_mi = int(campaign["mission_index"])
    campaign_step = int(campaign["mission_step"])
    campaign_done = bool(campaign["done"])
    mission_snapshot = mission["snapshot"].duplicate(true)
    claimed_rewards = mission["claimed_rewards"].duplicate(true)
    var cd: Variant = data.get("cheats", {})
    if cd is Dictionary:
        _load_cheats(cd)
    has_saved_pos = bool(player["has_position"])
    if has_saved_pos:
        var position: Array = player["position"]
        saved_pos = Vector3(float(position[0]), float(position[1]), float(position[2]))
        saved_yaw = float(player["yaw"])
    saved_health = float(player["health"])
    saved_armor = float(player["armor"])
    scrimshaw_mask = int(data["collectibles"]["scrimshaw_mask"])
    owned_business_mask = int(businesses["owned_mask"])
    business_state = businesses.duplicate(true)
    activity_state = data["activities"].duplicate(true)
    vehicle_state = data["vehicle"].duplicate(true)
    day_phase = float(world["day_phase"])
    raining = bool(world["raining"])
    gloria_storm_active = bool(world["gloria_storm"])
    graphics_quality = clampi(int(settings["graphics"]["quality"]), 0, 2)
    _apply_audio_settings(settings["audio"])
    input_settings = settings["input"].duplicate(true)
    accessibility_settings = settings["accessibility"].duplicate(true)
    scrimshaw_changed.emit(scrimshaw_found())
    businesses_changed.emit(businesses_owned())
    cash_changed.emit(cash)

func reset_save() -> void :
    if _save_service == null:
        return
    var result := _save_service.clear_progress_preserve_settings()
    if result != OK:
        push_error("New Game reset failed with error %d" % result)
        return
    _apply_blank_progress()
    load_game()


func _build_save_snapshot() -> Dictionary:
    var data := SaveSchemaScript.blank()
    data["saved_at"] = Time.get_datetime_string_from_system(true, true)
    data["source_build_sha"] = BuildInfo.COMMIT_SHA if BuildInfo else "local"
    data["player"] = {
        "has_position": has_saved_pos,
        "position": [saved_pos.x, saved_pos.y, saved_pos.z],
        "yaw": saved_yaw,
        "health": saved_health,
        "armor": saved_armor,
    }
    data["economy"] = {"cash": cash, "reputation": missions_completed}
    data["heat"] = {"police": wanted_level, "faction": faction_level}
    data["mission"] = {
        "snapshot": mission_snapshot.duplicate(true),
        "claimed_rewards": claimed_rewards.duplicate(true),
    }
    var businesses: Dictionary = business_state.duplicate(true)
    businesses["owned_mask"] = owned_business_mask
    data["businesses"] = SaveSchemaScript.with_defaults({"businesses": businesses})["businesses"]
    data["collectibles"] = {"scrimshaw_mask": scrimshaw_mask}
    data["activities"] = activity_state.duplicate(true)
    data["vehicle"] = vehicle_state.duplicate(true)
    data["world"] = {
        "day_phase": day_phase,
        "raining": raining,
        "gloria_storm": gloria_storm_active,
    }
    data["settings"] = {
        "graphics": {"quality": graphics_quality},
        "audio": _audio_settings(),
        "input": input_settings.duplicate(true),
        "accessibility": accessibility_settings.duplicate(true),
    }
    data["legacy_campaign"] = {
        "format": campaign_format,
        "opener_complete": opener_complete,
        "mission_index": campaign_mi,
        "mission_step": campaign_step,
        "done": campaign_done,
        "missions_completed": missions_completed,
    }
    data["cheats"] = _cheat_dict()
    return data


func _audio_settings() -> Dictionary:
    var values := {"master_db": 0.0, "music_db": 0.0, "sfx_db": 0.0}
    for pair in [["Master", "master_db"], ["Music", "music_db"], ["SFX", "sfx_db"]]:
        var bus_index := AudioServer.get_bus_index(pair[0])
        if bus_index >= 0:
            values[pair[1]] = AudioServer.get_bus_volume_db(bus_index)
    return values


func _apply_audio_settings(values: Dictionary) -> void:
    for pair in [["Master", "master_db"], ["Music", "music_db"], ["SFX", "sfx_db"]]:
        var bus_index := AudioServer.get_bus_index(pair[0])
        if bus_index >= 0:
            AudioServer.set_bus_volume_db(bus_index, float(values.get(pair[1], 0.0)))


func _apply_blank_progress() -> void:
    cash = STARTING_CASH
    missions_completed = 0
    wanted_level = 0
    faction_level = 0
    campaign_format = 2
    opener_complete = false
    campaign_mi = 0
    campaign_step = 0
    campaign_done = false
    mission_snapshot = {}
    claimed_rewards = []
    has_saved_pos = false
    saved_pos = Vector3.ZERO
    saved_yaw = 0.0
    saved_health = 100.0
    saved_armor = 0.0
    scrimshaw_mask = 0
    owned_business_mask = 0
    business_state = {}
    activity_state = {}
    vehicle_state = {"identity": "", "condition": 1.0}
    scrimshaw_changed.emit(0)
    businesses_changed.emit(0)
    cash_changed.emit(cash)
