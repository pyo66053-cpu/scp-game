class_name NpcAI
extends CharacterBody3D

# kind: 0=SCP-173, 1=SCP-096, 2=Хаос, 3=D-Класс, 4=Учёный, 5=МОГ, 6=SCP-049, 7=Зомби, 8=SCP-939
var kind := 0; var hp := 100.0; var max_hp := 100.0; var card_lvl := 0; var alive := true
var weapon := ""; var medkits := 0; var nav := NavAgent.new()
var rage := 0.0; var cd := 0.0; var anim_t := 0.0
var npc_blink := false; var blink_t := 5.0; var blink_d := 0.0
var lbl: Label3D; var wh: MeshInstance3D; var gun: MeshInstance3D; var leg_l: MeshInstance3D; var leg_r: MeshInstance3D

func setup(k: int) -> void:
	kind = k; blink_t = randf_range(3.5, 6.5)
	max_hp = 2500.0 if k <= 1 else (1800.0 if k == 6 else (2200.0 if k == 8 else (350.0 if k == 7 else (150.0 if (k == 2 or k == 5) else 100.0))))
	hp = max_hp; card_lvl = 8 if (k == 2 or k == 5) else (1 if k == 4 else 0)
	if k == 2 or k == 5: weapon = "Rifle"
	for ch in get_children(): ch.queue_free()
	var cs := CollisionShape3D.new(); cs.shape = CapsuleShape3D.new(); add_child(cs)
	build_sl_model(k)

	wh = MeshInstance3D.new(); var wm := CapsuleMesh.new(); wm.radius = 0.45; wm.height = 1.9; wh.mesh = wm
	var wmat := StandardMaterial3D.new(); wmat.albedo_color = Color(1, 0.1, 0.1, 0.35) if (k <= 2 or k >= 6) else Color(0.1, 0.85, 1.0, 0.35)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; wmat.no_depth_test = true; wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wh.material_override = wmat; wh.visible = false; add_child(wh)
	lbl = Label3D.new(); lbl.position = Vector3(0, 1.52, 0); lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; add_child(lbl)

func build_sl_model(k: int) -> void:
	if k == 0:
		var b := Color(0.7, 0.62, 0.54)
		leg_l = cap(Vector3(-0.14, -0.45, 0), 0.11, 0.9, b); leg_r = cap(Vector3(0.14, -0.45, 0), 0.11, 0.9, b)
		cap(Vector3(0, 0.25, 0), 0.26, 0.85, b); cap(Vector3(0, 0.85, 0), 0.22, 0.52, b)
		cap(Vector3(0, 0.82, -0.19), 0.08, 0.16, Color(0.85, 0.1, 0.1))
		cap(Vector3(-0.28, 0.35, -0.22), 0.07, 0.55, b, Vector3(1.57, 0, 0))
		cap(Vector3(0.28, 0.35, -0.22), 0.07, 0.55, b, Vector3(1.57, 0, 0))
	elif k == 1:
		var s := Color(0.94, 0.9, 0.9)
		leg_l = cap(Vector3(-0.13, -0.48, 0), 0.07, 1.02, s); leg_r = cap(Vector3(0.13, -0.48, 0), 0.07, 1.02, s)
		cap(Vector3(0, 0.28, 0), 0.16, 0.82, s); cap(Vector3(0, 0.88, 0), 0.13, 0.36, s)
		cap(Vector3(-0.22, 0.02, 0), 0.055, 1.15, s); cap(Vector3(0.22, 0.02, 0), 0.055, 1.15, s)
	elif k == 6:
		var blk := Color(0.08, 0.08, 0.1)
		leg_l = cap(Vector3(-0.13, -0.5, 0), 0.09, 0.85, blk); leg_r = cap(Vector3(0.13, -0.5, 0), 0.09, 0.85, blk)
		cap(Vector3(0, 0.18, 0), 0.26, 1.15, blk); cap(Vector3(0, 0.78, 0), 0.2, 0.42, blk)
		cap(Vector3(0, 0.78, -0.12), 0.13, 0.26, Color(0.95, 0.95, 0.95))
		cap(Vector3(0, 0.74, -0.26), 0.04, 0.28, Color(0.92, 0.92, 0.92), Vector3(1.4, 0, 0))
		cap(Vector3(-0.28, 0.2, -0.12), 0.08, 0.68, blk, Vector3(0.4, 0, 0))
		cap(Vector3(0.28, 0.2, -0.12), 0.08, 0.68, blk, Vector3(0.4, 0, 0))
	elif k == 8:
		var red := Color(0.68, 0.12, 0.1)
		leg_l = cap(Vector3(-0.22, -0.5, -0.25), 0.08, 0.7, red); leg_r = cap(Vector3(0.22, -0.5, -0.25), 0.08, 0.7, red)
		cap(Vector3(-0.22, -0.5, 0.35), 0.08, 0.7, red); cap(Vector3(0.22, -0.5, 0.35), 0.08, 0.7, red)
		cap(Vector3(0, -0.15, 0.05), 0.26, 1.15, red, Vector3(1.57, 0, 0))
		cap(Vector3(0, -0.05, -0.62), 0.2, 0.52, red.darkened(0.15), Vector3(1.4, 0, 0))
		box_p(Vector3(0, -0.08, -0.72), Vector3(0.24, 0.08, 0.28), Color(0.95, 0.92, 0.85))
	else:
		var suit := Color(0.35, 0.45, 0.32) if k == 7 else (Color(0.16, 0.36, 0.18) if k == 2 else (Color(0.12, 0.26, 0.62) if k == 5 else (Color(0.92, 0.42, 0.08) if k == 3 else Color(0.95, 0.96, 0.99))))
		var pants := Color(0.14, 0.24, 0.15) if k == 2 else (Color(0.1, 0.16, 0.35) if k == 5 else (Color(0.84, 0.36, 0.06) if k == 3 else Color(0.2, 0.22, 0.26)))
		var skin := Color(0.42, 0.52, 0.38) if k == 7 else (Color(0.16, 0.18, 0.16) if (k == 2 or k == 5) else Color(0.88, 0.72, 0.6))
		leg_l = cap(Vector3(-0.13, -0.48, 0), 0.095, 0.88, pants); leg_r = cap(Vector3(0.13, -0.48, 0), 0.095, 0.88, pants)
		cap(Vector3(0, 0.18, 0), 0.22, 0.76, suit); cap(Vector3(0, 0.58, 0), 0.07, 0.2, skin)
		cap(Vector3(0, 0.76, 0), 0.14, 0.32, skin)
		if k == 2 or k == 5:
			cap(Vector3(0, 0.82, 0), 0.155, 0.22, suit.darkened(0.3))
			cap(Vector3(0, 0.22, 0), 0.24, 0.52, Color(0.12, 0.13, 0.15))
		cap(Vector3(-0.27, 0.2, -0.08), 0.075, 0.66, suit, Vector3(0.35 if k != 7 else 1.2, 0, 0))
		cap(Vector3(0.27, 0.2, -0.08), 0.075, 0.66, suit, Vector3(0.35 if k != 7 else 1.2, 0, 0))
		gun = box_p(Vector3(0.24, 0.18, -0.36), Vector3(0.08, 0.14, 0.68), Color(0.12, 0.13, 0.15)); gun.visible = (k == 2 or k == 5)
func cap(pos: Vector3, r: float, h: float, col: Color, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new(); var cm := CapsuleMesh.new(); cm.radius = r; cm.height = h; m.mesh = cm; m.position = pos; m.rotation = rot
	var mt := StandardMaterial3D.new(); mt.albedo_color = col; mt.roughness = 0.65; m.material_override = mt; add_child(m); return m

func box_p(pos: Vector3, sz: Vector3, col: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sz; m.mesh = bm; m.position = pos
	var mt := StandardMaterial3D.new(); mt.albedo_color = col; m.material_override = mt; add_child(m); return m

func has_los(from_p: Vector3, to_p: Vector3, ign: Array) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from_p, to_p); q.exclude = ign
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func hit(dmg: float) -> void:
	if not alive: return
	hp -= dmg; if kind == 1 and rage <= 0.0: rage = 12.0
	if hp < max_hp * 0.6 and medkits > 0: medkits -= 1; hp = minf(max_hp, hp + 55.0)
	if hp <= 0.0:
		alive = false; visible = false; process_mode = Node.PROCESS_MODE_DISABLED
		if get_parent().has_method("on_mob_died"): get_parent().call("on_mob_died", global_position, kind, card_lvl, weapon, medkits)
		global_position = Vector3(0, -50, 0)

func is_watched(player: CharacterBody3D, cam: Camera3D, blink: bool, mobs: Array, p_role: int) -> bool:
	var my_eye := global_position + Vector3(0, 0.7, 0)
	if p_role >= 2 and p_role <= 5 and not blink and cam.global_position.distance_to(my_eye) < 22.0:
		var dir_to_me := (my_eye - cam.global_position).normalized()
		if (-cam.global_transform.basis.z).dot(dir_to_me) > 0.55 and has_los(cam.global_position, my_eye, [self, player]): return true
	for m: Node3D in mobs:
		if m != self and m.alive and m.kind >= 2 and m.kind <= 5 and not m.npc_blink:
			var m_eye := m.global_position + Vector3(0, 0.7, 0)
			if m_eye.distance_to(my_eye) < 18.0 and (-m.global_transform.basis.z).dot((my_eye - m_eye).normalized()) > 0.62:
				if has_los(m_eye, my_eye, [self, m]): return true
	return false

func is_enemy(ok: int) -> bool:
	if kind <= 1 or kind >= 6: return ok >= 3 and ok <= 5
	if kind == 2: return ok <= 1 or ok >= 4
	if kind == 5: return ok <= 3 or ok >= 6
	return ok <= 1 or ok >= 6
func step(delta: float, player: CharacterBody3D, cam: Camera3D, blink: bool, mobs: Array, p_role: int, _nodes: Array, loot: Array, corpses: Array) -> int:
	if not alive: return 0
	if not is_on_floor(): velocity.y -= 9.8 * delta
	if gun != null: gun.visible = (weapon != "")

	# Собственный таймер моргания для каждого бота-человека (даёт шанс SCP-173!)
	if kind >= 2 and kind <= 5:
		if npc_blink:
			blink_d -= delta
			if blink_d <= 0.0: npc_blink = false; blink_t = randf_range(4.5, 7.0)
		else:
			blink_t -= delta
			if blink_t <= 0.0: npc_blink = true; blink_d = 0.45

	var names := ["SCP-173", "SCP-096", "Хаос", "D-Класс", "Учёный", "МОГ", "SCP-049", "Зомби", "SCP-939"]
	var ally := (kind == p_role) or ((p_role <= 1 or p_role >= 6) and (kind <= 1 or kind >= 6)) or (p_role == 4 and kind == 5) or (p_role == 5 and kind == 4) or (p_role == 3 and kind == 2) or (p_role == 2 and kind == 3)
	var tag := " [МОРГАЕТ]" if npc_blink else (" [СОЮЗНИК]" if ally else (" [Ур.%d]" % card_lvl if (kind >= 2 and kind <= 5) else ""))
	lbl.text = names[kind] + (" [" + weapon + "]" if weapon != "" else "") + tag
	if cd > 0.0: cd -= delta

	if kind == 0 and is_watched(player, cam, blink, mobs, p_role):
		velocity.x = 0.0; velocity.z = 0.0; move_and_slide(); return 0

	if kind == 6:
		for c in corpses:
			if c["active"] and global_position.distance_to(c["pos"]) < 14.0:
				var dc: Vector3 = c["pos"] - global_position; dc.y = 0.0
				if dc.length() < 1.8:
					c["active"] = false; c["node"].queue_free()
					if get_parent().has_method("spawn_zombie"): get_parent().call("spawn_zombie", global_position + Vector3(1.0, 0, 0))
					return 4
				move_dir(nav.avoid_walls(self, dc.normalized()), 5.6, delta); return 0

	if kind >= 2 and kind <= 5 and weapon != "":
		var foe: Node3D = null; var ed := 24.0
		if is_enemy(p_role) and player.global_position.distance_to(global_position) < ed and has_los(global_position + Vector3(0, 0.7, 0), player.global_position + Vector3(0, 0.7, 0), [self, player]):
			foe = player; ed = player.global_position.distance_to(global_position)
		for m: Node3D in mobs:
			if m != self and m.alive and is_enemy(m.kind) and m.global_position.distance_to(global_position) < ed and has_los(global_position + Vector3(0, 0.7, 0), m.global_position + Vector3(0, 0.7, 0), [self, m]):
				foe = m; ed = m.global_position.distance_to(global_position)
		if foe != null:
			var f := Vector3(foe.global_position.x - global_position.x, 0, foe.global_position.z - global_position.z)
			if f.length() < 6.5: move_dir(nav.avoid_walls(self, -f.normalized()), 5.5, delta)
			else: rotation.y = atan2(-f.x, -f.z)
			if cd <= 0.0:
				cd = 0.25 if weapon == "MicroHID" else 0.22
				var d := 160.0 if weapon == "MicroHID" else 32.0
				if get_parent().has_method("spawn_tracer"):
					get_parent().call("spawn_tracer", global_position + Vector3(0, 0.35, 0), foe.global_position + Vector3(0, 0.4, 0), Color.CYAN if weapon == "MicroHID" else Color.GOLD)
				if foe == player: return 2
				elif foe.has_method("hit"): foe.call("hit", d)
			return 0

	if kind <= 1 or kind >= 6:
		var t: Node3D = null; var bd := 24.0
		if is_enemy(p_role) and player.global_position.distance_to(global_position) < bd and (kind == 8 or has_los(global_position + Vector3(0, 0.7, 0), player.global_position + Vector3(0, 0.7, 0), [self, player])):
			t = player; bd = player.global_position.distance_to(global_position)
		for m: Node3D in mobs:
			if m != self and m.alive and is_enemy(m.kind) and m.global_position.distance_to(global_position) < bd and (kind == 8 or has_los(global_position + Vector3(0, 0.7, 0), m.global_position + Vector3(0, 0.7, 0), [self, m])):
				t = m; bd = m.global_position.distance_to(global_position)
		if t != null:
			var flat := Vector3(t.global_position.x - global_position.x, 0, t.global_position.z - global_position.z)
			if kind == 0 or kind >= 6:
				var sp_scp := 9.2 if kind == 0 else (5.6 if kind == 6 else (8.4 if kind == 8 else 6.4))
				var step_target := nav.bfs_step(global_position, t.global_position) if (kind == 8 and not has_los(global_position + Vector3(0, 0.7, 0), t.global_position + Vector3(0, 0.7, 0), [self, t])) else t.global_position
				var dir_s := Vector3(step_target.x - global_position.x, 0, step_target.z - global_position.z)
				if dir_s.length() > 0.2: move_dir(nav.avoid_walls(self, dir_s.normalized()), sp_scp, delta)
				if flat.length() < 1.55:
					if t == player: return 1 if (kind == 0 or kind == 6) else 5
					elif t.has_method("hit"): t.call("hit", 9999.0 if (kind == 0 or kind == 6) else (65.0 if kind == 8 else 35.0))
				return 0
			elif kind == 1:
				if is_watched(player, cam, blink, mobs, p_role) and rage <= 0.0: rage = 12.0; return 3
				if rage > 0.0:
					rage -= delta
					if rage < 9.5:
						move_dir(nav.avoid_walls(self, flat.normalized()), 9.6, delta)
						if flat.length() < 1.45:
							if t == player: return 1
							elif t.has_method("hit"): t.call("hit", 9999.0)
				return 0

	if kind >= 2 and kind <= 5:
		for m: Node3D in mobs:
			if m.alive and m.kind == 0 and m.global_position.distance_to(global_position) < 16.0 and has_los(global_position + Vector3(0, 0.7, 0), m.global_position + Vector3(0, 0.7, 0), [self, m]):
				var aw: Vector3 = nav.avoid_walls(self, (global_position - m.global_position).normalized()); aw.y = 0.0
				velocity.x = aw.x * 5.0; velocity.z = aw.z * 5.0; rotation.y = atan2(aw.x, aw.z); move_and_slide(); return 0
			if m.alive and m.kind == 1 and m.global_position.distance_to(global_position) < 16.0:
				var away096: Vector3 = global_position - m.global_position; away096.y = 0.0
				move_dir(nav.avoid_walls(self, away096.normalized()), 7.2, delta); return 0
		if p_role == 0 and player.global_position.distance_to(global_position) < 16.0 and has_los(global_position + Vector3(0, 0.7, 0), player.global_position + Vector3(0, 0.7, 0), [self, player]):
			var ap: Vector3 = nav.avoid_walls(self, (global_position - player.global_position).normalized()); ap.y = 0.0
			velocity.x = ap.x * 5.0; velocity.z = ap.z * 5.0; rotation.y = atan2(ap.x, ap.z); move_and_slide(); return 0
		if p_role == 1 and player.global_position.distance_to(global_position) < 16.0:
			var ap96: Vector3 = global_position - player.global_position; ap96.y = 0.0
			move_dir(nav.avoid_walls(self, ap96.normalized()), 7.2, delta); return 0

		for it in loot:
			if is_instance_valid(it):
				var id := String(it.get_meta("id"))
				var useful := (id.begins_with("C") and int(id.substr(1)) > card_lvl) or (id == "Medkit" and medkits < 2) or ((id == "Pistol" or id == "Rifle" or id == "Shotgun" or id == "MicroHID") and weapon == "")
				var d_it := global_position.distance_to(it.global_position)
				if useful and d_it < 16.0 and has_los(global_position + Vector3(0, 0.5, 0), it.global_position + Vector3(0, 0.3, 0), [self, it]):
					if d_it < 1.9:
						if id.begins_with("C"): card_lvl = int(id.substr(1))
						elif id == "Medkit": medkits += 1
						else: weapon = id
						it.queue_free(); return 0
					move_dir(nav.avoid_walls(self, (it.global_position - global_position).normalized()), 5.4, delta); return 0

	var smart_d := nav.get_smart_dir(self, delta, kind, card_lvl, mobs)
	if smart_d.length() > 0.1: move_dir(smart_d, 5.2, delta)
	return 0

func move_dir(d: Vector3, spd: float, delta: float) -> void:
	velocity.x = d.x * spd; velocity.z = d.z * spd; rotation.y = atan2(-d.x, -d.z); move_and_slide()
	if leg_l != null and leg_r != null:
		anim_t += delta * spd * 2.2; leg_l.rotation.x = sin(anim_t) * 0.55; leg_r.rotation.x = -sin(anim_t) * 0.55
	for i in get_slide_collision_count():
		var obj := get_slide_collision(i).get_collider()
		if obj is Node:
			if get_parent().has_method("bot_open_door"):
				var lvl := 11 if (kind == 0 or kind >= 6 or (kind == 1 and rage > 0.0)) else card_lvl
				get_parent().call("bot_open_door", obj.name, lvl)
			if kind >= 2 and kind <= 5 and obj.name == "LIFT_HCZ": global_position = Vector3(216, 1.2, 4)
			elif kind >= 2 and kind <= 5 and obj.name == "LIFT_LCZ": global_position = Vector3(24, 1.2, 4)
			elif kind >= 2 and kind <= 5 and obj.name == "LIFT_SURF": global_position = Vector3(348, 1.2, 4)
			elif kind >= 2 and kind <= 5 and obj.name == "LIFT_EZ": global_position = Vector3(144, 1.2, 4)
			elif (kind == 3 or kind == 4) and obj.name == "ESCAPE":
				setup(5 if kind == 4 else 2); global_position = Vector3(324, 1.2, 12)
