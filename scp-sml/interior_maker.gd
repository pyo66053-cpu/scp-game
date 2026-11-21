class_name InteriorMaker
extends Node

static func build_furniture(root: Node3D) -> void:
	# 1. Камера D-класса: койка, тумба, лавка
	prop(root, Vector3(-2.0, 0.35, 37), Vector3(1.2, 0.7, 2.6), Color(0.24, 0.27, 0.32))
	prop(root, Vector3(2.0, 0.45, 34), Vector3(1.2, 0.9, 1.0), Color(0.36, 0.3, 0.24))
	prop(root, Vector3(-2.0, 0.25, 33), Vector3(0.6, 0.5, 1.4), Color(0.28, 0.28, 0.3))

	# 2. Склад (LCZ Запад): стеллажи и ящики
	for z in:
		prop(root, Vector3(-16, 0.8, z), Vector3(1.2, 1.6, 1.2), Color(0.4, 0.3, 0.18))
	prop(root, Vector3(-12, 0.45, 23), Vector3(1.6, 0.9, 1.2), Color(0.35, 0.28, 0.2))

	# 3. Медпункт (LCZ Восток): 2 кушетки и столик
	prop(root, Vector3(15, 0.4, 21), Vector3(2.2, 0.8, 1.0), Color(0.85, 0.88, 0.92))
	prop(root, Vector3(15, 0.4, 25), Vector3(2.2, 0.8, 1.0), Color(0.85, 0.88, 0.92))
	prop(root, Vector3(12, 0.45, 23), Vector3(1.2, 0.9, 1.2), Color(0.2, 0.55, 0.38))

	# 4. Тяжёлая зона (HCZ): серверные стойки вдоль коридора
	for z in [8, 2, -4]:
		prop(root, Vector3(-2.3, 1.1, z), Vector3(0.7, 2.2, 1.4), Color(0.12, 0.14, 0.18))
		prop(root, Vector3(2.3, 1.1, z), Vector3(0.7, 2.2, 1.4), Color(0.12, 0.14, 0.18))

	# Офис Учёных (HCZ Запад)
	prop(root, Vector3(-14, 0.45, -2), Vector3(2.0, 0.9, 1.2), Color(0.3, 0.33, 0.38))
	var mon := prop(root, Vector3(-14, 1.15, -2.3), Vector3(0.8, 0.5, 0.1), Color(0.1, 0.75, 0.95))
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.1, 0.75, 0.95)
	mm.emission_enabled = true
	mm.emission = Color(0.1, 0.65, 0.9)
	mon.get_child(0).material_override = mm

	# Оружейная (HCZ Восток): стойки оружия
	prop(root, Vector3(14, 0.45, -2), Vector3(2.2, 0.9, 1.4), Color(0.18, 0.2, 0.25))
	prop(root, Vector3(16.5, 1.0, 1), Vector3(0.6, 2.0, 2.2), Color(0.15, 0.17, 0.2))

	# 5. Входная зона (EZ): офисные столы перед выходом
	prop(root, Vector3(-1.8, 0.45, -20), Vector3(1.4, 0.9, 2.0), Color(0.34, 0.32, 0.3))
	prop(root, Vector3(1.8, 0.45, -25), Vector3(1.4, 0.9, 2.0), Color(0.34, 0.32, 0.3))

	# Таблички над всеми дверьми
	sign_lbl(root, "КАМЕРА D-КЛАССА", Vector3(0, 3.0, 30.5), 0.0)
	sign_lbl(root, "СКЛАД [УР. 1]", Vector3(-6.2, 3.0, 23), PI * 0.5)
	sign_lbl(root, "МЕДПУНКТ", Vector3(6.2, 3.0, 23), -PI * 0.5)
	sign_lbl(root, "КПП: ТЯЖЁЛАЯ ЗОНА [УР. 1]", Vector3(0, 3.0, 14.5), 0.0)
	sign_lbl(root, "КАМЕРА SCP-173 [ОПАСНО]", Vector3(-6.2, 3.0, 7), PI * 0.5)
	sign_lbl(root, "ОФИС УЧЁНЫХ [УР. 1]", Vector3(-6.2, 3.0, -2), PI * 0.5)
	sign_lbl(root, "ОРУЖЕЙНАЯ [УР. 2]", Vector3(6.2, 3.0, -2), -PI * 0.5)
	sign_lbl(root, "КПП: ВХОДНАЯ ЗОНА [УР. 2]", Vector3(0, 3.0, -12.5), 0.0)
	sign_lbl(root, "ЛИФТ ЭВАКУАЦИИ (GATE A)", Vector3(0, 3.0, -31.2), 0.0)

static func sign_lbl(root: Node3D, txt: String, pos: Vector3, rot_y: float) -> void:
	var l := Label3D.new()
	l.text = txt
	l.position = pos
	l.rotation.y = rot_y
	l.pixel_size = 0.0075
	l.modulate = Color(1.0, 0.92, 0.65)
	root.add_child(l)

static func prop(root: Node3D, pos: Vector3, size: Vector3, col: Color) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.position = pos
	root.add_child(b)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	m.material_override = mat
	b.add_child(m)
	var c := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	c.shape = bs
	b.add_child(c)
	return b
