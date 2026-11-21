class_name Entities
extends CharacterBody3D

var player: CharacterBody3D; var cam: Camera3D; var ray: RayCast3D
var hp_lbl: Label3D; var wh_box: MeshInstance3D
var hp := 100.0; var kind := 0; var cd := 0.0; var rage := 0.0
var following := false; var wander_dir := Vector3.ZERO; var wander_t := 0.0

func setup_entity(p: CharacterBody3D, c: Camera3D, k: int) -> void:
	player = p; cam = c; kind = k
	hp = 2200.0 if k == 0 else (1800.0 if k == 1 else (120.0 if k == 2 else 100.0))
	var col := CollisionShape3D.new(); var cap := CapsuleShape3D.new()
	cap.height = 2.25 if k == 1 else 1.95; col.shape = cap; add_child(col)

	build_classic_model(k)

	wh_box = MeshInstance3D.new(); var wm := BoxMesh.new(); wm.size = Vector3(0.85, 1.95, 0.85); wh_box.mesh = wm
	var wmat := StandardMaterial3D.new(); wmat.albedo_color = Color(1, 0.1, 0.1, 0.35) if k <= 2 else Color(0.1, 0.8, 1.0, 0.35)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; wmat.no_depth_test = true; wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wh_box.material_override = wmat; wh_box.visible = false; add_child(wh_box)

	hp_lbl = Label3D.new(); hp_lbl.position = Vector3(0, 1.45, 0); hp_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_lbl.modulate = Color(1, 0.35, 0.35) if k <= 2 else Color(0.4, 1.0, 0.5); update_lbl(); add_child(hp_lbl)
	ray = RayCast3D.new(); ray.position = Vector3(0, 0.5, 0); ray.add_exception(self); add_child(ray)

func build_classic_model(k: int) -> void:
	var rig := Node3D.new(); add_child(rig)
	if k == 0: # SCP-173 (скульптура из старого CB/SL)
		var b := Color(0.68, 0.6, 0.53)
		part(rig, Vector3(0, -0.45, 0), Vector3(0.42, 0.9, 0.32), b)
		part(rig, Vector3(0, 0.25, 0), Vector3(0.55, 0.65, 0.38), b)
		part(rig, Vector3(0, 0.78, 0), Vector3(0.42, 0.44, 0.42), b)
		part(rig, Vector3(0, 0.78, -0.22), Vector3(0.28, 0.26, 0.04), Color(0.75, 0.12, 0.1))
		part(rig, Vector3(-0.36, 0.32, -0.22), Vector3(0.14, 0.14, 0.52), b)
		part(rig, Vector3(0.36, 0.32, -0.22), Vector3(0.14, 0.14, 0.52), b)
	elif k == 1: # SCP-096 Скромник (высокий, худой, с длинными руками до колен)
		var s := Color(0.92, 0.88, 0.88)
		part(rig, Vector3(-0.14, -0.5, 0), Vector3(0.14, 1.0, 0.14), s)
		part(rig, Vector3(0.14, -0.5, 0), Vector3(0.14, 1.0, 0.14), s)
		part(rig, Vector3(0, 0.28, 0), Vector3(0.36, 0.78, 0.2), s)
		part(rig, Vector3(0, 0.88, 0), Vector3(0.26, 0.34, 0.28), s)
		part(rig, Vector3(-0.27, 0.02, 0), Vector3(0.11, 1.15, 0.11), s)
		part(rig, Vector3(0.27, 0.02, 0), Vector3(0.11, 1.15, 0.11), s)
	else: # Люди: 2 = Хаос (зелёная броня + шлем), 3 = D-класс (оранжевый), 4 = Учёный (белый халат)
		var suit := Color(0.16, 0.35, 0.18) if k == 2 else (Color(0.92, 0.44, 0.1) if k == 3 else Color(0.94, 0.95, 0.98))
		var pants := Color(0.12, 0.22, 0.14) if k == 2 else (Color(0.85, 0.38, 0.08) if k == 3 else Color(0.22, 0.24, 0.28))
		var skin := Color(0.15, 0.18, 0.15) if k == 2 else Color(0.88, 0.72, 0.6)
		part(rig, Vector3(-0.15, -0.52, 0), Vector3(0.18, 0.85, 0.18), pants)
		part(rig, Vector3(0.15, -0.52, 0), Vector3(0.18, 0.85, 0.18), pants)
		part(rig, Vector3(0, 0.18, 0), Vector3(0.46, 0.68, 0.26), suit)
		part(rig, Vector3(0, 0.72, 0), Vector3(0.32, 0.32, 0.32), skin)
		part(rig, Vector3(-0.32, 0.16, 0), Vector3(0.15, 0.65, 0.15), suit)
		part(rig, Vector3(0.32, 0.16, 0), Vector3(0.15, 0.65, 0.15), suit)
		if k == 2: # Шлем и автомат у Хаоса
			part(rig, Vector3(0, 0.82, 0), Vector3(0.36, 0.18, 0.36), Color(0.1, 0.15, 0.1))
			part(rig, Vector3(0.25, 0.15, -0.35), Vector3(0.1, 0.14, 0.65), Color(0.12, 0.12, 0.14))

func part(p: Node3D, pos: Vector3, sz: Vector3, col: Color) -> void:
	var m := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sz; m.mesh = bm; m.position = pos
	var mat := StandardMaterial3D.new(); mat.albedo_color = col; m.material_override = mat; p.add_child(m)

func update_lbl() -> void:
	var names := ["SCP-173", "SCP-096", "Хаос", "D-Класс [E]", "Учёный [E]"]
	if kind >= 3 and following: hp_lbl.text = ("D-Класс [С ВАМИ]" if kind == 3 else "Учёный [С ВАМИ]")
	elif kind == 1 and rage > 0.0: hp_lbl.text = "SCP-096 [ЯРОСТЬ]: %d" % int(hp)
	else: hp_lbl.text = "%s: %d" % [names[kind], int(hp)]

func interact_ally() -> void:
	if kind >= 3 and hp > 0: following = not following; update_lbl()

func set_wallhack(active: bool) -> void:
	if wh_box != null: wh_box.visible = active and hp > 0.0; hp_lbl.no_depth_test = active

func hit(dmg: float) -> void:
	if hp <= 0 or kind >= 3: return
	hp = max(0.0, hp - dmg); update_lbl()
	if kind == 1 and rage <= 0.0: rage = 12.0
	if hp <= 0: visible = false; process_mode = Node.PROCESS_MODE_DISABLED; global_position = Vector3(0, -50, 0)

func patrol(delta: float, spd: float) -> void:
	wander_t -= delta
	if wander_t <= 0.0 or is_on_wall():
		wander_t = randf_range(1.5, 3.5); var dirs := [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]; wander_dir = dirs[randi() % 4]
	velocity.x = wander_dir.x * spd; velocity.z = wander_dir.z * spd; rotation.y = atan2(-wander_dir.x, -wander_dir.z); move_and_slide()
	for i in get_slide_collision_count():
		var obj := get_slide_collision(i).get_collider()
		if obj is Node and get_parent().has_method("npc_open_door"): get_parent().call("npc_open_door", obj.name, 0)

func tick_ai(delta: float, blinking: bool) -> int:
	if hp <= 0 or player == null: return 0
	if not is_on_floor(): velocity.y -= 9.8 * delta
	var flat := Vector3(player.global_position.x - global_position.x, 0, player.global_position.z - global_position.z)
	var dist := flat.length()

	if kind >= 3:
		if following and dist > 2.4:
			var d := flat.normalized(); velocity.x = d.x * 6.4; velocity.z = d.z * 6.4; rotation.y = atan2(-d.x, -d.z); move_and_slide()
			for i in get_slide_collision_count():
				var obj := get_slide_collision(i).get_collider()
				if obj is Node and get_parent().has_method("npc_open_door"): get_parent().call("npc_open_door", obj.name, 2 if kind == 4 else 0)
		elif not following: patrol(delta, 2.0)
		else: velocity.x = 0; velocity.z = 0; move_and_slide()
		return 0

	ray.target_position = to_local(player.global_position + Vector3(0, 0.5, 0)); ray.force_raycast_update()
	var see := dist < 24.0 and ray.is_colliding() and ray.get_collider() == player
	var looks := see and not blinking and (-cam.global_transform.basis.z).dot((global_position - cam.global_position).normalized()) > 0.55

	if kind == 0:
		if see and not looks and dist > 0.1:
			var d := flat.normalized(); velocity.x = d.x * 6.8; velocity.z = d.z * 6.8; rotation.y = atan2(-d.x, -d.z); move_and_slide()
			return 1 if dist < 1.3 else 0
		elif not see: patrol(delta, 3.0); return 0
	elif kind == 1:
		if looks and rage <= 0.0: rage = 12.0; update_lbl(); return 3
		if rage > 0.0:
			rage -= delta; update_lbl()
			if rage < 9.5 and dist > 0.1:
				var d := flat.normalized(); velocity.x = d.x * 9.0; velocity.z = d.z * 9.0; rotation.y = atan2(-d.x, -d.z); move_and_slide()
				return 1 if dist < 1.4 else 0
		else: patrol(delta, 2.4); return 0
	else:
		if see and dist > 5.0: var d := flat.normalized(); velocity.x = d.x * 3.8; velocity.z = d.z * 3.8; rotation.y = atan2(-d.x, -d.z); move_and_slide()
		elif not see: patrol(delta, 2.6)
		if see:
			cd -= delta
			if cd <= 0.0: cd = 1.3; return 2
	velocity.x = 0; velocity.z = 0; move_and_slide(); return 0
