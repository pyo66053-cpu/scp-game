extends Node

const TexScript = preload("res://tex_maker.gd")
const DataScript = preload("res://sl_data.gd")

static var m_wall: StandardMaterial3D
static var m_floor: StandardMaterial3D

static func build_all(root: Node3D, doors: Dictionary) -> void:
	m_wall = TexScript.wall_mat()
	m_floor = TexScript.floor_mat()

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.32, 0.34, 0.38)
	e.fog_enabled = true; e.fog_density = 0.012
	env.environment = e; root.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.1
	root.add_child(sun)

	# =====================================================================
	# 1. ЛЁГКАЯ ЗОНА LCZ (X = 0, Z: 6..46)
	# =====================================================================
	box(root, Vector3(0, -0.5, 26), Vector3(40, 1, 44), m_floor)
	box(root, Vector3(0, 3.6, 26), Vector3(40, 1, 44), m_floor)

	# Камера D-класса (z: 38..46, x: -3.5..3.5)
	box(root, Vector3(0, 1.6, 46), Vector3(7.6, 3.4, 0.6), m_wall)
	box(root, Vector3(-3.5, 1.6, 42), Vector3(0.6, 3.4, 8), m_wall)
	box(root, Vector3(3.5, 1.6, 42), Vector3(0.6, 3.4, 8), m_wall)
	door_wall(root, doors, Vector3(0, 1.6, 38), 7.0, false, "D_Start", 0, Color(0.5, 0.6, 0.7))

	# Главный коридор LCZ (x: -5.5..5.5, z: 12..38)
	box(root, Vector3(-5.5, 1.6, 35), Vector3(0.6, 3.4, 6), m_wall)
	box(root, Vector3(5.5, 1.6, 35), Vector3(0.6, 3.4, 6), m_wall)
	box(root, Vector3(-5.5, 1.6, 17), Vector3(0.6, 3.4, 10), m_wall)
	box(root, Vector3(5.5, 1.6, 17), Vector3(0.6, 3.4, 10), m_wall)

	# Комната SCP-914 (Запад: x -16.5..-5.5, z 22..32)
	make_west_room(root, -5.5, 27, 11.0, 10.0)
	door_wall(root, doors, Vector3(-5.5, 1.6, 27), 10.0, true, "D_914", 1, Color(0.95, 0.85, 0.2))
	var machine := box(root, Vector3(-14, 1.5, 27), Vector3(2.2, 2.8, 5.0), TexScript.door_mat(Color(0.35, 0.4, 0.45)))
	machine.name = "SCP914_Machine"
	var knob := box(root, Vector3(-12.7, 1.3, 27), Vector3(0.3, 0.5, 0.8), TexScript.door_mat(Color(0.9, 0.5, 0.1)))
	knob.name = "SCP914_Knob"

	# Камера SCP-173 (Восток: x 5.5..16.5, z 22..32)
	make_east_room(root, 5.5, 27, 11.0, 10.0)
	door_wall(root, doors, Vector3(5.5, 1.6, 27), 10.0, true, "D_173", 1, Color(0.85, 0.15, 0.15))

	# Лифт из LCZ в HCZ (z: 6..12)
	door_wall(root, doors, Vector3(0, 1.6, 12), 11.0, false, "D_Lift_LCZ", 3, Color(0.15, 0.85, 0.85))
	box(root, Vector3(-5.5, 1.6, 9), Vector3(0.6, 3.4, 6), m_wall)
	box(root, Vector3(5.5, 1.6, 9), Vector3(0.6, 3.4, 6), m_wall)
	box(root, Vector3(0, 1.6, 6), Vector3(11.6, 3.4, 0.6), m_wall)
	var lift1 := box(root, Vector3(0, 1.6, 6.5), Vector3(4.0, 2.9, 0.4), TexScript.door_mat(Color(0.2, 0.7, 0.9)))
	lift1.name = "Lift_To_HCZ"
	# =====================================================================
	# 2. ТЯЖЁЛАЯ ЗОНА HCZ + ОФИСЫ EZ (X = 60, Z: -26..45)
	# =====================================================================
	box(root, Vector3(60, -0.5, 10), Vector3(40, 1, 74), m_floor)
	box(root, Vector3(60, 3.6, 10), Vector3(40, 1, 74), m_floor)

	# Коридор HCZ (z: 14..45, x: 54.5..65.5)
	box(root, Vector3(60, 1.6, 45), Vector3(11.6, 3.4, 0.6), m_wall)
	box(root, Vector3(54.5, 1.6, 29.5), Vector3(0.6, 3.4, 31), m_wall)
	box(root, Vector3(65.5, 1.6, 38.5), Vector3(0.6, 3.4, 13), m_wall)
	box(root, Vector3(65.5, 1.6, 18), Vector3(0.6, 3.4, 8), m_wall)

	# Оружейная с Микро-ХИДом (HCZ Восток: x 65.5..76.5, z 22..32)
	make_east_room(root, 65.5, 27, 11.0, 10.0)
	door_wall(root, doors, Vector3(65.5, 1.6, 27), 10.0, true, "D_Armory", 7, Color(0.15, 0.45, 0.95))

	# КПП из HCZ в Офисы EZ (z = 14)
	door_wall(root, doors, Vector3(60, 1.6, 14), 11.0, false, "D_CP_EZ", 4, Color(0.55, 0.6, 0.65))

	# Коридор Офисов EZ (z: -18..14, x: 54.5..65.5)
	box(root, Vector3(54.5, 1.6, -2), Vector3(0.6, 3.4, 32), m_wall)
	box(root, Vector3(65.5, 1.6, -2), Vector3(0.6, 3.4, 32), m_wall)
	box(root, Vector3(57.5, 0.45, 4), Vector3(1.6, 0.9, 2.4), m_wall)
	box(root, Vector3(62.5, 0.45, -6), Vector3(1.6, 0.9, 2.4), m_wall)

	# Лифт на Поверхность (z: -25..-18)
	door_wall(root, doors, Vector3(60, 1.6, -18), 11.0, false, "D_Lift_Surf", 8, Color(0.1, 0.22, 0.75))
	box(root, Vector3(54.5, 1.6, -21.5), Vector3(0.6, 3.4, 7), m_wall)
	box(root, Vector3(65.5, 1.6, -21.5), Vector3(0.6, 3.4, 7), m_wall)
	box(root, Vector3(60, 1.6, -25), Vector3(11.6, 3.4, 0.6), m_wall)
	var lift2 := box(root, Vector3(60, 1.6, -24.5), Vector3(4.0, 2.9, 0.4), TexScript.door_mat(Color(0.2, 0.85, 0.4)))
	lift2.name = "Lift_To_Surface"

	# =====================================================================
	# 3. ПОВЕРХНОСТЬ / УЛИЦА (X = 130, Z: -32..32)
	# =====================================================================
	var road_mat := StandardMaterial3D.new(); road_mat.albedo_color = Color(0.16, 0.17, 0.19)
	box(root, Vector3(130, -0.5, 0), Vector3(22, 1, 64), road_mat)
	box(root, Vector3(119, 2.2, 0), Vector3(1, 5.0, 64), m_wall)
	box(root, Vector3(141, 2.2, 0), Vector3(1, 5.0, 64), m_wall)
	box(root, Vector3(130, 2.2, 32), Vector3(22, 5.0, 1), m_wall)
	box(root, Vector3(130, 2.2, -32), Vector3(22, 5.0, 1), m_wall)
	var esc := box(root, Vector3(130, 1.6, -31.2), Vector3(6.0, 3.2, 0.6), TexScript.door_mat(Color(0.1, 0.95, 0.3)))
	esc.name = "ExitLift"

	# Лампы и таблички
	for p in [Vector3(0,3,41), Vector3(0,3,27), Vector3(-11,3,27), Vector3(11,3,27), Vector3(60,3,38), Vector3(60,3,25), Vector3(71,3,27), Vector3(60,3,2), Vector3(60,3,-12)]:
		var l := OmniLight3D.new(); l.position = p; l.omni_range = 16.0; l.light_energy = 1.5
		if p.x == 60 and p.z > 14: l.light_color = Color(1.0, 0.55, 0.5)
		root.add_child(l)

	lbl(root, "SCP-914 [УР. 1]", Vector3(-5.1, 3.0, 27), PI * 0.5)
	lbl(root, "КАМЕРА SCP-173 [УР. 1]", Vector3(5.1, 3.0, 27), -PI * 0.5)
	lbl(root, "ЛИФТ В ТЯЖЁЛУЮ ЗОНУ [УР. 3]", Vector3(0, 3.0, 12.4), 0.0)
	lbl(root, "ОРУЖЕЙНАЯ: МИКРО-ХИД [УР. 7]", Vector3(65.1, 3.0, 27), -PI * 0.5)
	lbl(root, "КПП: ОФИСЫ [УР. 4]", Vector3(60, 3.0, 14.4), 0.0)
	lbl(root, "ЛИФТ НА УЛИЦУ [УР. 8]", Vector3(60, 3.0, -17.6), 0.0)
	lbl(root, "ЭВАКУАЦИЯ (ПОБЕДА)", Vector3(130, 3.2, -30.5), 0.0)

	# Предметы
	spawn_card(root, "Card0", Vector3(1.8, 0.9, 41))
	spawn_card(root, "Card1", Vector3(-1.8, 0.9, 41))
	item(root, "Adrenaline", "Адреналин (Бег 15с)", Vector3(-2.5, 0.9, 20), Vector3(0.25, 0.45, 0.25), Color(0.1, 0.95, 0.4))
	item(root, "Medkit", "Аптечка (+50 HP)", Vector3(2.5, 0.9, 20), Vector3(0.55, 0.3, 0.55), Color(0.9, 0.15, 0.15))
	item(root, "MicroHID", "Микро-ХИД", Vector3(72, 1.0, 27), Vector3(0.45, 0.45, 1.3), Color(0.15, 0.8, 1.0))

static func make_west_room(root: Node3D, wall_x: float, cz: float, w: float, d: float) -> void:
	var cx: float = wall_x - w * 0.5
	box(root, Vector3(wall_x - w, 1.6, cz), Vector3(0.6, 3.4, d + 0.6), m_wall)
	box(root, Vector3(cx, 1.6, cz - d * 0.5), Vector3(w, 3.4, 0.6), m_wall)
	box(root, Vector3(cx, 1.6, cz + d * 0.5), Vector3(w, 3.4, 0.6), m_wall)

static func make_east_room(root: Node3D, wall_x: float, cz: float, w: float, d: float) -> void:
	var cx: float = wall_x + w * 0.5
	box(root, Vector3(wall_x + w, 1.6, cz), Vector3(0.6, 3.4, d + 0.6), m_wall)
	box(root, Vector3(cx, 1.6, cz - d * 0.5), Vector3(w, 3.4, 0.6), m_wall)
	box(root, Vector3(cx, 1.6, cz + d * 0.5), Vector3(w, 3.4, 0.6), m_wall)

static func spawn_card(root: Node3D, c_id: String, pos: Vector3) -> void:
	for c in DataScript.CARDS:
		if c["id"] == c_id:
			item(root, c["id"], c["title"] + " [Ур." + str(c["lvl"]) + "]", pos, Vector3(0.4, 0.05, 0.6), c["col"])

static func lbl(root: Node3D, txt: String, pos: Vector3, rot_y: float) -> void:
	var l := Label3D.new(); l.text = txt; l.position = pos; l.rotation.y = rot_y; l.pixel_size = 0.008; l.modulate = Color(1.0, 0.92, 0.65); root.add_child(l)

static func door_wall(root: Node3D, doors: Dictionary, center: Vector3, length: float, along_z: bool, d_name: String, req: int, col: Color) -> void:
	var side: float = (length - 2.4) * 0.5
	if along_z:
		box(root, center + Vector3(0, 0, -(1.2 + side * 0.5)), Vector3(0.6, 3.4, side), m_wall)
		box(root, center + Vector3(0, 0, (1.2 + side * 0.5)), Vector3(0.6, 3.4, side), m_wall)
	else:
		box(root, center + Vector3(-(1.2 + side * 0.5), 0, 0), Vector3(side, 3.4, 0.6), m_wall)
		box(root, center + Vector3((1.2 + side * 0.5), 0, 0), Vector3(side, 3.4, 0.6), m_wall)
	var d := StaticBody3D.new(); d.name = d_name; d.position = center; root.add_child(d)
	var m := MeshInstance3D.new(); var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 3.3, 2.4) if along_z else Vector3(2.4, 3.3, 0.3)
	m.mesh = bm; m.material_override = TexScript.door_mat(col); d.add_child(m)
	var c := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = bm.size; c.shape = bs; d.add_child(c)
	doors[d_name] = {"mesh": m, "col": c, "open": false, "req": req}

static func item(root: Node3D, id: String, title: String, pos: Vector3, size: Vector3, col: Color) -> void:
	var mat := StandardMaterial3D.new(); mat.albedo_color = col; mat.emission_enabled = true; mat.emission = col * 0.35
	var b := box(root, pos, size, mat); b.set_meta("id", id); b.set_meta("title", title); b.set_meta("col", col)

static func box(root: Node3D, pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var b := StaticBody3D.new(); b.position = pos; root.add_child(b)
	var m := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; m.mesh = bm; m.material_override = mat; b.add_child(m)
	var c := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = size; c.shape = bs; b.add_child(c)
	return b
