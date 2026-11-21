class_name SCP173
extends CharacterBody3D

var player: CharacterBody3D
var cam: Camera3D
var ray: RayCast3D
var hp_label: Label3D
var hp := 4000.0
var is_destroyed := false

func init_scp(p: CharacterBody3D, c: Camera3D) -> void:
	player = p
	cam = c
	
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 2.1
	col.shape = cap
	add_child(col)
	
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.45
	mesh.height = 2.1
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.58, 0.52)
	body.material_override = mat
	add_child(body)
	
	var eyes := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.18, 0.2)
	eyes.mesh = box
	eyes.position = Vector3(0, 0.65, -0.4)
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(0.9, 0.1, 0.1)
	emat.emission_enabled = true
	emat.emission = Color(0.8, 0.0, 0.0)
	eyes.material_override = emat
	add_child(eyes)

	hp_label = Label3D.new()
	hp_label.text = "SCP-173: 4000 HP"
	hp_label.position = Vector3(0, 1.45, 0)
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.modulate = Color(1.0, 0.3, 0.3)
	add_child(hp_label)
	
	ray = RayCast3D.new()
	ray.position = Vector3(0, 0.5, 0)
	ray.add_exception(self)
	add_child(ray)

func take_damage(amount: float) -> bool:
	if is_destroyed: return true
	hp = max(0.0, hp - amount)
	hp_label.text = "SCP-173: %d HP" % int(hp)
	if hp <= 0.0:
		is_destroyed = true
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		global_position = Vector3(0, -50, 0)
		return true
	return false

func step_scp(delta: float, is_blinking: bool) -> bool:
	if is_destroyed or player == null or cam == null or ray == null: return false
	if not is_on_floor(): velocity.y -= 9.8 * delta

	var to_p := player.global_position - global_position
	var flat_dir := Vector3(to_p.x, 0.0, to_p.z)
	var dist := flat_dir.length()
	if dist > 16.0:
		velocity.x = 0.0; velocity.z = 0.0; move_and_slide(); return false
	
	ray.target_position = to_local(player.global_position + Vector3(0, 0.5, 0))
	ray.force_raycast_update()
	var can_see := ray.is_colliding() and ray.get_collider() == player
	var looking := false
	if can_see and not is_blinking:
		var look_dir := -cam.global_transform.basis.z
		if look_dir.dot((global_position - cam.global_position).normalized()) > 0.45:
			looking = true

	if can_see and not looking and dist > 0.01:
		var dir := flat_dir.normalized()
		velocity.x = dir.x * 7.2
		velocity.z = dir.z * 7.2
		rotation.y = atan2(-dir.x, -dir.z)
		move_and_slide()
		return dist < 1.3
	velocity.x = 0.0; velocity.z = 0.0; move_and_slide()
	return false
