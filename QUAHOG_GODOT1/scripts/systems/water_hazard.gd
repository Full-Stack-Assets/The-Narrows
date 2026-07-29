extends Node

# Walk/drive into open water → sink briefly, then recover to the last dry spot.

const SINK_TIME: float = 1.1
const SINK_DRAG: float = 3.0

var player: Node3D = null
var _in_water: float = 0.0
var _safe: Vector3 = Vector3.ZERO
var _has_safe: bool = false


func setup(p_player: Node3D, fallback: Vector3) -> void :
    player = p_player
    _safe = fallback
    _has_safe = true


func _physics_process(delta: float) -> void :
    if player == null or not is_instance_valid(player):
        return
    if GameManager and GameManager.cheat_godmode:
        _in_water = 0.0
        return
    if (
        bool(player.get("_boating"))
        and player.get("current_boat") != null
        and is_instance_valid(player.get("current_boat"))
    ):
        _in_water = 0.0
        return

    var pos: Vector3 = player.global_position
    var driving: bool = false
    if "current_car" in player and player.current_car != null and is_instance_valid(player.current_car):
        if "_driving" in player and player._driving:
            driving = true
            if "vehicle_model" in player.current_car and player.current_car.vehicle_model:
                pos = player.current_car.vehicle_model.global_position

    var wet: bool = WaterZones.is_blocked(pos.x, pos.z) and pos.y < 4.0
    if not wet:
        _in_water = 0.0
        if pos.y > 0.4 and pos.y < 6.0:
            _safe = pos + Vector3(0, 0.6, 0)
            _has_safe = true
        return

    _in_water += delta
    if driving and player.current_car.has_method("set_drive_input"):
        player.current_car.set_drive_input(0.0, -0.35)
    elif player is CharacterBody3D:
        var body: = player as CharacterBody3D
        var gp: Vector3 = body.global_position
        gp.y -= SINK_DRAG * delta
        body.global_position = gp
        body.velocity = Vector3(body.velocity.x * 0.4, -SINK_DRAG, body.velocity.z * 0.4)

    if _in_water < SINK_TIME:
        return

    _in_water = 0.0
    var land: Vector3 = _safe if _has_safe else pos
    if player.has_method("recover_from_water"):
        player.recover_from_water(land, driving)
    else:
        player.global_position = land
    if player.has_method("take_damage"):
        player.take_damage(8)
    GameManager.show_message("Into the drink! Use a bridge.")
