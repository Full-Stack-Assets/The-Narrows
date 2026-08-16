extends CharacterBody3D
class_name EncounterEnemy

signal defeated(actor: Node)

var encounter_id: String = ""
var role: String = "melee"
var target: Node3D = null
var health: int = 2
var _attack_cooldown: float = 0.0
var _defeated: bool = false


func configure(p_encounter_id: String, p_role: String, p_target: Node3D) -> void:
	encounter_id = p_encounter_id
	role = p_role
	target = p_target
	health = 3 if role == "ranged" else 2


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.36
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.height = 1.8
	mesh.radius = 0.36
	body.mesh = mesh
	body.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.42, 0.12, 0.1) if role == "melee" else Color(0.16, 0.2, 0.3)
	body.material_override = material
	add_child(body)


func _physics_process(delta: float) -> void:
	if _defeated or target == null or not is_instance_valid(target):
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var desired_range := 12.0 if role == "ranged" else 1.8
	if distance > desired_range and distance > 0.01:
		var speed := 3.4 if role == "ranged" else 4.6
		velocity.x = offset.normalized().x * speed
		velocity.z = offset.normalized().z * speed
		move_and_slide()
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cooldown <= 0.0 and target.has_method("take_damage"):
			target.take_damage(7 if role == "ranged" else 10)
			_attack_cooldown = 1.4 if role == "ranged" else 0.9


func take_damage(amount: int) -> void:
	if _defeated:
		return
	health -= maxi(amount, 0)
	if health <= 0:
		_defeat()


func defeat_for_test() -> void:
	_defeat()


func _defeat() -> void:
	if _defeated:
		return
	_defeated = true
	collision_layer = 0
	defeated.emit(self)
	queue_free()
