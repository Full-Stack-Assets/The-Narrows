extends Node3D




@export var interact_prompt: String = "Get a job"
@export var mission_entity_id: String = ""

var job_manager: Node = null

var mesh_root: Node3D
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _marker: MeshInstance3D

var _lines: Array[String] = [
    "Sully: You're the one lookin' for work? Good. This town eats the patient alive.", 
    "Sully: City hall, the mills, the guys down the wharf - everybody's got a hand out.", 
    "Sully: Sit tight. I'll have a job worth your while real soon. Keep your nose clean.", 
]
var _line_index: int = 0


func _ready() -> void :
    mesh_root = Node3D.new()
    mesh_root.name = "CharacterMesh"
    add_child(mesh_root)

    var scene: = load("res://assets/characters/mission_giver/mission_giver.glb") as PackedScene
    if scene:
        var model: = scene.instantiate()
        mesh_root.add_child(model)
        ModelUtils.setup_character_for_movement(model, 1.8)
        var meshes: Array = model.find_children("*", "MeshInstance3D", true)
        if meshes.size() > 0:
            var first: = meshes[0] as MeshInstance3D
            if first and not ModelUtils.has_vertex_normals(first):
                ModelUtils.generate_normals_for_all(model)
        anim_player = AnimationPlayer.new()
        anim_player.name = "AnimationPlayer"
        model.add_child(anim_player)
        var lib: = load("res://assets/characters/mission_giver/mission_giver_animations.tres") as AnimationLibrary
        if lib:
            anim_player.add_animation_library("", lib)
            ModelUtils.set_animation_loops(anim_player)
            _setup_anim_tree()
        var clamp: = GroundClampNode.new()
        clamp.target_node = self
        clamp.character_mesh = mesh_root
        add_child(clamp)


    var area: = Area3D.new()
    area.collision_layer = 32
    area.collision_mask = 0
    var acol: = CollisionShape3D.new()
    var ashape: = SphereShape3D.new()
    ashape.radius = 2.2
    acol.shape = ashape
    acol.position.y = 1.0
    area.add_child(acol)
    add_child(area)

    _build_marker()


func _setup_anim_tree() -> void :
    var sm: = AnimationNodeStateMachine.new()
    var idle_node: = AnimationNodeAnimation.new()
    idle_node.animation = "ual1_Idle"
    sm.add_node("idle", idle_node)
    var talk_clip: = "ual1_Idle_Talking"
    var talk_node: = AnimationNodeAnimation.new()

    talk_node.animation = talk_clip if anim_player.has_animation(talk_clip) else "ual1_Idle"
    sm.add_node("talk", talk_node)
    for pair in [["idle", "talk"], ["talk", "idle"]]:
        var t: = AnimationNodeStateMachineTransition.new()
        t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
        t.xfade_time = 0.25
        sm.add_transition(pair[0], pair[1], t)
    anim_tree = AnimationTree.new()
    anim_tree.anim_player = anim_player.get_path()
    anim_tree.tree_root = sm
    add_child(anim_tree)
    anim_tree.active = true
    _playback = anim_tree["parameters/playback"]
    _playback.travel("idle")


func _build_marker() -> void :
    _marker = MeshInstance3D.new()
    var prism: = PrismMesh.new()
    prism.size = Vector3(0.45, 0.6, 0.45)
    _marker.mesh = prism
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.95, 0.7, 0.25)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.72, 0.25)
    mat.emission_energy_multiplier = 2.2
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    _marker.material_override = mat
    _marker.rotation_degrees.z = 180.0
    _marker.position = Vector3(0, 2.7, 0)
    add_child(_marker)

    var tw: = _marker.create_tween().set_loops()
    tw.tween_property(_marker, "position:y", 3.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tw.tween_property(_marker, "position:y", 2.7, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void :
    if _marker:
        _marker.rotation.y += delta * 1.6


func interact(_player: Node) -> void :
    if _playback:
        _playback.travel("talk")

    if job_manager and job_manager.has_method("offer_job"):
        if not job_manager.has_active_job():
            job_manager.offer_job()
            return
    if GameManager:
        GameManager.show_message(_lines[_line_index])
    _line_index = (_line_index + 1) % _lines.size()
