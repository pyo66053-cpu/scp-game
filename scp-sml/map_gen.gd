class_name MapGen
extends Node

const Data = preload("res://sl_data.gd")
const STEP := 14.0
const W := 4.6

static var map_nodes: Array[Dictionary] = []
static var open_edges: Array[Vector3] = []

static func build(root: Node3D, doors: Dictionary) -> void:
	map_nodes.clear(); open_edges.clear()
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_SKY; var sky := Sky.new(); sky.sky_material = ProceduralSkyMaterial.new(); e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.36, 0.38, 0.44)
	env.environment = e; root.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, 30, 0); root.add_child(sun)

	var mw := StandardMaterial3D.new(); mw.albedo_color = Color(0.33, 0.35, 0.39)
	var mf := StandardMaterial3D.new(); mf.albedo_color = Color(0.16, 0.18, 0.21)

	for dp in [Vector3(-2.3, 1.6, 28), Vector3(-2.3, 1.6, 14), Vector3(-2.3, 1.6, 42), Vector3(72.3, 1.6, 14), Vector3(72.3, 1.6, 42), Vector3(28, 1.6, -2.3), Vector3(264.3, 1.6, 28), Vector3(164, 1.6, -2.3)]:
		open_edges.append(dp)

	# 1. LCZ
	var lcz: Array[String] = ["011110", "111111", "110110", "111111", "001100"]
	build_corridors(root, Vector3(0, 0, 0), lcz, mw, mf, 0)
	add_room(root, doors, Vector3(-2.3, 0, 28), -1.0, "D0", 0, Color(0.5, 0.6, 0.7), mw, mf, "CLASS-D")
	add_room(root, doors, Vector3(-2.3, 0, 14), -1.0, "D_914", 1, Color(0.95, 0.85, 0.2), mw, mf, "SCP-914 [УР.1]")
	add_room(root, doors, Vector3(-2.3, 0, 42), -1.0, "D_ARM1", 2, Color(0.3, 0.65, 0.95), mw, mf, "ARMORY [УР.2]")
	add_room(root, doors, Vector3(72.3, 0, 14), 1.0, "D_173", 1, Color(0.85, 0.15, 0.15), mw, mf, "SCP-173 [УР.1]")
	add_room(root, doors, Vector3(72.3, 0, 42), 1.0, "D_1344", 1, Color(0.75, 0.2, 0.95), mw, mf, "SCP-1344 [УР.1]")
	make_lift(root, doors, Vector3(28, 0, -2.3), "D_L1", 3, Color(0.15, 0.85, 0.85), "LIFT_HCZ", "ELEV HCZ [УР.3]", mw, mf)

	# Машина SCP-914
	box(root, Vector3(-11.2, 1.6, 14), Vector3(1.6, 3.2, 6.4), mw)
	var b_in := box(root, Vector3(-9.8, 0.2, 15.8), Vector3(1.2, 0.3, 1.8), mat_c(Color(0.9, 0.55, 0.1))); b_in.name = "914_IN"
	var b_out := box(root, Vector3(-9.8, 0.2, 12.2), Vector3(1.2, 0.3, 1.8), mat_c(Color(0.15, 0.85, 0.35))); b_out.name = "914_OUT"
	var b_k := box(root, Vector3(-10.1, 1.4, 14.5), Vector3(0.3, 0.4, 0.6), mat_c(Color(0.95, 0.7, 0.1))); b_k.name = "914_KNOB"
	var b_s := box(root, Vector3(-10.1, 1.4, 13.5), Vector3(0.3, 0.4, 0.6), mat_c(Color(0.2, 0.9, 0.2))); b_s.name = "914_GO"

	# 2. EZ + HCZ
	var ez_hcz: Array[String] = ["011000110", "111111111", "111001111", "011000110"]
	build_corridors(root, Vector3(150, 0, 0), ez_hcz, mw, mf, 1)
	door(root, doors, Vector3(206, 1.6, 14), true, "D_EZ", 4, Color(0.55, 0.6, 0.65), mw)
	lbl(root, "CHECKPOINT [УР.4]", Vector3(206.5, 3, 14), PI * 0.5)
	add_room(root, doors, Vector3(264.3, 0, 28), 1.0, "D_ARM2", 6, Color(0.15, 0.45, 0.95), mw, mf, "MICRO H.I.D. [УР.6]")
	make_lift(root, doors, Vector3(164, 0, -2.3), "D_L2", 8, Color(0.1, 0.22, 0.75), "LIFT_SURF", "GATE A: УЛИЦА [УР.8]", mw, mf)

	# 3. SURFACE
	var surf: Array[String] = ["0001", "1111"]
	build_corridors(root, Vector3(350, 0, 0), surf, mw, mf, 2)
	var esc := box(root, Vector3(347.8, 1.6, 14), Vector3(0.6, 3.2, 4.4), mat_c(Color(0.1, 0.95, 0.3))); esc.name = "ESCAPE"
	lbl(root, "ESCAPE (ПОБЕДА)", Vector3(348.5, 3, 14), PI * 0.5)

	add_decor(root)
	# Множество ключ-карт разных уровней по всему комплексу
	spawn_card(root, "Card0", Vector3(-10.5, 0.85, 25.0)) # Уборщик на столе D-блока
	spawn_card(root, "Card1", Vector3(-10.5, 0.85, 26.0)) # Учёный на столе D-блока
	spawn_card(root, "Card2", Vector3(42.0, 0.5, 0.0))    # Науч. руководитель в тупике LCZ
	spawn_card(root, "Card3", Vector3(56.0, 0.5, 56.0))   # Менеджер зон на юге LCZ
	spawn_card(root, "Card4", Vector3(234.0, 0.5, 0.0))   # Карта Охранника в HCZ
	spawn_card(root, "Card7", Vector3(248.0, 0.5, 42.0))  # Лейтенант МОГ в HCZ
	spawn_card(root, "Card8", Vector3(164.0, 0.95, 15.6)) # Командир МОГ на столе в Офисах
	spawn_card(root, "Card11", Vector3(271.0, 0.5, 31.0)) # Карта Совета O5 в Оружейной HCZ

	# Оружие и медикаменты
	item(root, "Pistol", "Пистолет COM-15", Vector3(14.0, 0.5, 0.0), Vector3(0.15, 0.18, 0.4), Color(0.25, 0.28, 0.32))
	item(root, "Rifle", "Автомат E-11", Vector3(-8, 0.5, 42), Vector3(0.2, 0.25, 0.9), Color(0.2, 0.22, 0.25))
	item(root, "Adrenaline", "Адреналин", Vector3(-6, 0.5, 41), Vector3(0.25, 0.45, 0.25), Color(0.1, 0.95, 0.4))
	item(root, "SCP1344", "SCP-1344 (Очки ВХ)", Vector3(78, 0.5, 42), Vector3(0.45, 0.2, 0.35), Color(0.85, 0.2, 1.0))
	item(root, "Medkit", "Аптечка", Vector3(28, 0.5, 28), Vector3(0.5, 0.3, 0.5), Color(0.9, 0.15, 0.15))
	item(root, "Logicer", "Пулемёт Logicer", Vector3(270, 0.6, 27), Vector3(0.25, 0.3, 1.1), Color(0.18, 0.35, 0.2))
	item(root, "MicroHID", "Микро-ХИД", Vector3(270, 0.6, 29), Vector3(0.45, 0.45, 1.3), Color(0.15, 0.8, 1.0))
static func add_decor(root: Node3D) -> void:
	box(root, Vector3(-10.5, 0.35, 30.5), Vector3(2.2, 0.7, 1.1), mat_c(Color(0.24, 0.28, 0.34)))
	box(root, Vector3(-10.5, 0.4, 25.5), Vector3(1.4, 0.8, 1.6), mat_c(Color(0.35, 0.3, 0.25)))
	box(root, Vector3(-11.0, 1.1, 42), Vector3(0.8, 2.2, 4.0), mat_c(Color(0.18, 0.2, 0.24)))
	box(root, Vector3(273.0, 1.1, 28), Vector3(0.8, 2.2, 4.5), mat_c(Color(0.16, 0.18, 0.22)))
	for x in:
		box(root, Vector3(x, 1.2, 12.2), Vector3(1.4, 2.4, 0.7), mat_c(Color(0.1, 0.12, 0.16)))
	for x in:
		box(root, Vector3(x, 0.45, 15.6), Vector3(1.8, 0.9, 1.0), mat_c(Color(0.32, 0.34, 0.38)))
		var scr := box(root, Vector3(x, 1.15, 15.8), Vector3(0.7, 0.45, 0.1), mat_c(Color(0.1, 0.75, 0.95)))
		scr.get_child(0).material_override.emission_enabled = true
		scr.get_child(0).material_override.emission = Color(0.1, 0.65, 0.9)

static func make_lift(root: Node3D, doors: Dictionary, dp: Vector3, d_nm: String, req: int, col: Color, l_nm: String, txt: String, mw: Material, mf: Material) -> void:
	door(root, doors, dp + Vector3(0, 1.6, 0), false, d_nm, req, col, mw)
	lbl(root, txt, dp + Vector3(0, 3.0, 0.5), 0.0)
	box(root, dp + Vector3(0, -0.5, -2.5), Vector3(W, 1, 5.0), mf); box(root, dp + Vector3(0, 3.6, -2.5), Vector3(W, 1, 5.0), mf)
	box(root, dp + Vector3(-W * 0.5, 1.6, -2.5), Vector3(0.6, 3.4, 5.0), mw); box(root, dp + Vector3(W * 0.5, 1.6, -2.5), Vector3(0.6, 3.4, 5.0), mw)
	box(root, dp + Vector3(0, 1.6, -5.0), Vector3(W + 0.6, 3.4, 0.6), mw)
	var l := box(root, dp + Vector3(0, 1.6, -4.5), Vector3(3.6, 2.9, 0.4), mat_c(Color(0.2, 0.75, 0.9))); l.name = l_nm

static func is_open_edge(pos: Vector3) -> bool:
	for ep in open_edges:
		if ep.distance_to(pos) < 0.5: return true
	return false

static func build_corridors(root: Node3D, orig: Vector3, rows: Array[String], mw: Material, mf: Material, z_id: int) -> void:
	var h: int = rows.size(); var cols: int = rows.length()
	var hw: float = W * 0.5; var arm: float = (STEP - W) * 0.5
	var trim := mat_c(Color(0.85, 0.65, 0.1) if z_id == 0 else Color(0.8, 0.2, 0.15))
	for r in range(h):
		var s: String = rows[r]
		for c in range(cols):
			if s[c] == "0": continue
			var p := orig + Vector3(c * STEP, 0, r * STEP)
			var n: bool = r > 0 and rows[r - 1][c] == "1"
			var so: bool = r < h - 1 and rows[r + 1][c] == "1"
			var we: bool = c > 0 and s[c - 1] == "1"
			var ea: bool = c < cols - 1 and s[c + 1] == "1"
			map_nodes.append({"pos": p, "zone": z_id, "n": n, "s": so, "w": we, "e": ea})

			box(root, p + Vector3(0, -0.5, 0), Vector3(W + 0.4, 1, W + 0.4), mf)
			if z_id < 2:
				box(root, p + Vector3(0, 3.6, 0), Vector3(W + 0.4, 1, W + 0.4), mf)
				if (r + c) % 2 == 0:
					var l := OmniLight3D.new(); l.position = p + Vector3(0, 3.0, 0); l.omni_range = 16.0; l.light_energy = 1.4; root.add_child(l)

			if n: seg_z(root, p + Vector3(0, 0, -hw - arm * 0.5), arm, mw, mf, trim, z_id < 2)
			elif not is_open_edge(p + Vector3(0, 1.6, -hw)): wall_strip(root, p + Vector3(0, 1.6, -hw), Vector3(W + 0.6, 3.4, 0.6), mw, trim)
			if so: seg_z(root, p + Vector3(0, 0, hw + arm * 0.5), arm, mw, mf, trim, z_id < 2)
			elif not is_open_edge(p + Vector3(0, 1.6, hw)): wall_strip(root, p + Vector3(0, 1.6, hw), Vector3(W + 0.6, 3.4, 0.6), mw, trim)
			if we: seg_x(root, p + Vector3(-hw - arm * 0.5, 0, 0), arm, mw, mf, trim, z_id < 2)
			elif not is_open_edge(p + Vector3(-hw, 1.6, 0)): wall_strip(root, p + Vector3(-hw, 1.6, 0), Vector3(0.6, 3.4, W + 0.6), mw, trim)
			if ea: seg_x(root, p + Vector3(hw + arm * 0.5, 0, 0), arm, mw, mf, trim, z_id < 2)
			elif not is_open_edge(p + Vector3(hw, 1.6, 0)): wall_strip(root, p + Vector3(hw, 1.6, 0), Vector3(0.6, 3.4, W + 0.6), mw, trim)

static func seg_z(root: Node3D, p: Vector3, len: float, mw: Material, mf: Material, tr: Material, roof: bool) -> void:
	box(root, p + Vector3(0, -0.5, 0), Vector3(W + 0.4, 1, len + 0.2), mf)
	if roof: box(root, p + Vector3(0, 3.6, 0), Vector3(W + 0.4, 1, len + 0.2), mf)
	wall_strip(root, p + Vector3(-W * 0.5, 1.6, 0), Vector3(0.6, 3.4, len + 0.2), mw, tr)
	wall_strip(root, p + Vector3(W * 0.5, 1.6, 0), Vector3(0.6, 3.4, len + 0.2), mw, tr)

static func seg_x(root: Node3D, p: Vector3, len: float, mw: Material, mf: Material, tr: Material, roof: bool) -> void:
	box(root, p + Vector3(0, -0.5, 0), Vector3(len + 0.2, 1, W + 0.4), mf)
	if roof: box(root, p + Vector3(0, 3.6, 0), Vector3(len + 0.2, 1, W + 0.4), mf)
	wall_strip(root, p + Vector3(0, 1.6, -W * 0.5), Vector3(len + 0.2, 3.4, 0.6), mw, tr)
	wall_strip(root, p + Vector3(0, 1.6, W * 0.5), Vector3(len + 0.2, 3.4, 0.6), mw, tr)

static func wall_strip(root: Node3D, p: Vector3, s: Vector3, mw: Material, tr: Material) -> void:
	box(root, p, s, mw); box(root, Vector3(p.x, 0.85, p.z), Vector3(s.x + 0.06, 0.16, s.z + 0.06), tr)

static func add_room(root: Node3D, doors: Dictionary, dp: Vector3, dir_x: float, nm: String, req: int, col: Color, mw: Material, mf: Material, title: String) -> void:
	var c := dp + Vector3(dir_x * 5.0, 0, 0)
	box(root, c + Vector3(0, -0.5, 0), Vector3(10.6, 1, 9.6), mf); box(root, c + Vector3(0, 3.6, 0), Vector3(10.6, 1, 9.6), mf)
	box(root, c + Vector3(dir_x * 5.0, 1.6, 0), Vector3(0.6, 3.4, 9.8), mw)
	box(root, c + Vector3(0, 1.6, -4.5), Vector3(10.6, 3.4, 0.6), mw); box(root, c + Vector3(0, 1.6, 4.5), Vector3(10.6, 3.4, 0.6), mw)
	box(root, dp + Vector3(0, 1.6, -3.1), Vector3(0.6, 3.4, 3.4), mw)
	box(root, dp + Vector3(0, 1.6, 3.1), Vector3(0.6, 3.4, 3.4), mw)
	door(root, doors, dp + Vector3(0, 1.6, 0), true, nm, req, col, mw)
	lbl(root, title, dp + Vector3(-dir_x * 0.5, 3.0, 0), PI * 0.5 if dir_x < 0 else -PI * 0.5)

static func door(root: Node3D, doors: Dictionary, c: Vector3, z_axis: bool, nm: String, req: int, col: Color, mw: Material) -> void:
	if z_axis: box(root, c + Vector3(0, 0, -1.75), Vector3(0.6, 3.4, 1.2), mw); box(root, c + Vector3(0, 0, 1.75), Vector3(0.6, 3.4, 1.2), mw)
	else: box(root, c + Vector3(-1.75, 0, 0), Vector3(1.2, 3.4, 0.6), mw); box(root, c + Vector3(1.75, 0, 0), Vector3(1.2, 3.4, 0.6), mw)
	var d := StaticBody3D.new(); d.name = nm; d.position = c; root.add_child(d)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.3, 3.3, 2.4) if z_axis else Vector3(2.4, 3.3, 0.3)
	mi.mesh = bm; mi.material_override = mat_c(col); d.add_child(mi)
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = bm.size; cs.shape = bs; d.add_child(cs)
	doors[nm] = {"mesh": mi, "col": cs, "open": false, "req": req}

static func spawn_card(root: Node3D, id: String, pos: Vector3) -> void:
	for c in Data.CARDS:
		if c["id"] == id: item(root, id, c["title"] + " [Ур." + str(c["lvl"]) + "]", pos, Vector3(0.4, 0.05, 0.6), c["col"])

static func lbl(root: Node3D, t: String, p: Vector3, r: float) -> void:
	var l := Label3D.new(); l.text = t; l.position = p; l.rotation.y = r; l.pixel_size = 0.008; l.modulate = Color(1, 0.9, 0.6); root.add_child(l)

static func item(root: Node3D, id: String, title: String, pos: Vector3, sz: Vector3, col: Color) -> void:
	var b := box(root, pos, sz, mat_c(col)); b.set_meta("id", id); b.set_meta("title", title); b.set_meta("col", col)

static func mat_c(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = col; return m

static func box(root: Node3D, p: Vector3, s: Vector3, m: Material) -> StaticBody3D:
	var b := StaticBody3D.new(); b.position = p; root.add_child(b)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = s; mi.mesh = bm; mi.material_override = m; b.add_child(mi)
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = s; cs.shape = bs; b.add_child(cs)
	return b
