class_name WorldGrid
extends Node

const STEP := 12.0; const W := 4.4
static var nodes := []; static var graph := {}; static var open_doors := []; static var snd := {}; static var mats := {}

static func init_audio(root: Node) -> void:
	snd["door"] = make_snd(root, 260.0, 640.0, 0.2)
	snd["deny"] = make_snd(root, 140.0, 90.0, 0.2)
	snd["pick"] = make_snd(root, 520.0, 900.0, 0.12)
	snd["shot"] = make_snd(root, 180.0, 60.0, 0.08)
	snd["shy"] = make_snd(root, 340.0, 880.0, 0.6)
	snd["cure"] = make_snd(root, 220.0, 520.0, 0.45)

static func play(id: String) -> void:
	if snd.has(id) and not snd[id].playing: snd[id].play()

static func make_snd(root: Node, f1: float, f2: float, dur: float) -> AudioStreamPlayer:
	var rate := 22050; var cnt := int(rate * dur); var data := PackedByteArray(); data.resize(cnt * 2); var ph := 0.0
	for i in range(cnt):
		var t := float(i) / float(cnt); ph += TAU * lerpf(f1, f2, t) / float(rate)
		data.encode_s16(i * 2, int(clampf(sin(ph) * (1.0 - t) * 20000.0, -32767.0, 32767.0)))
	var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = rate; w.data = data
	var p := AudioStreamPlayer.new(); p.stream = w; p.volume_db = -8.0; root.add_child(p); return p

static func init_textures() -> void:
	mats["lcz_wall"] = make_tex_mat(Color(0.68, 0.69, 0.66), 0.07, 1)
	mats["hcz_wall"] = make_tex_mat(Color(0.24, 0.26, 0.29), 0.09, 2)
	mats["ez_wall"] = make_tex_mat(Color(0.76, 0.75, 0.72), 0.05, 1)
	mats["floor"] = make_tex_mat(Color(0.22, 0.23, 0.25), 0.08, 3)
	mats["hazard"] = make_tex_mat(Color(0.85, 0.65, 0.1), 0.04, 4)
	mats["hcz_trim"] = make_tex_mat(Color(0.72, 0.16, 0.14), 0.05, 2)
	mats["metal"] = make_tex_mat(Color(0.32, 0.35, 0.38), 0.06, 2)

static func make_tex_mat(base: Color, noise_amt: float, pattern: int) -> StandardMaterial3D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in range(64):
		for x in range(64):
			var n := randf_range(-noise_amt, noise_amt)
			var c := Color(base.r + n, base.g + n, base.b + n)
			if pattern == 1 and (x == 0 or y == 0 or y == 32): c = c.darkened(0.22)
			elif pattern == 2 and ((x % 16 == 0 and y % 16 == 0) or y == 0): c = c.darkened(0.3)
			elif pattern == 3 and (x % 32 == 0 or y % 32 == 0): c = c.darkened(0.18)
			elif pattern == 4 and ((x + y) % 16 < 8): c = Color(0.12, 0.12, 0.12)
			img.set_pixel(x, y, c.clamp())
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new(); m.albedo_texture = tex; m.uv1_triplanar = true; m.uv1_scale = Vector3(0.4, 0.4, 0.4); m.roughness = 0.78
	return m
static func build(root: Node, doors: Dictionary) -> void:
	nodes.clear(); graph.clear(); open_doors.clear(); init_textures()
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.05, 0.06, 0.08)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.38, 0.4, 0.45)
	e.fog_enabled = true; e.fog_light_color = Color(0.08, 0.09, 0.11); e.fog_density = 0.012
	env.environment = e; root.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, 30, 0); sun.light_energy = 0.7; root.add_child(sun)

	for dp in [
		Vector3(-2.2, 1.6, 24), Vector3(-2.2, 1.6, 12), Vector3(-2.2, 1.6, 36),
		Vector3(74.2, 1.6, 12), Vector3(74.2, 1.6, 36), Vector3(24, 1.6, -2.2),
		Vector3(242.2, 1.6, 24), Vector3(242.2, 1.6, 12), Vector3(144, 1.6, -2.2),
		Vector3(216, 1.6, -2.2), Vector3(348, 1.6, 14.2)
	]:
		open_doors.append(dp)

	grid(root, Vector3(0, 0, 0), ["0111110", "1111111", "1101101", "1111111", "1101101", "0011100"], mats["lcz_wall"], mats["floor"], mats["hazard"], 0)
	room(root, doors, Vector3(-2.2, 0, 24), -1.0, "D0", 0, Color.LIGHT_GRAY, mats["lcz_wall"], mats["floor"], "КАМЕРЫ CLASS-D")
	room(root, doors, Vector3(-2.2, 0, 12), -1.0, "D_914", 1, Color.YELLOW, mats["lcz_wall"], mats["floor"], "SCP-914 [Ур.1]")
	room(root, doors, Vector3(-2.2, 0, 36), -1.0, "D_ARM1", 2, Color.CORNFLOWER_BLUE, mats["lcz_wall"], mats["floor"], "ОРУЖЕЙНАЯ LCZ [Ур.2]")
	room(root, doors, Vector3(74.2, 0, 12), 1.0, "D_173", 1, Color.RED, mats["lcz_wall"], mats["floor"], "КАМЕРА SCP-173 [Ур.1]")
	room(root, doors, Vector3(74.2, 0, 36), 1.0, "D_1344", 1, Color.PURPLE, mats["lcz_wall"], mats["floor"], "ХРАНИЛИЩЕ SCP-1344 [Ур.1]")
	lift(root, doors, Vector3(24, 0, -2.2), -1.0, "D_L1", 3, Color.CYAN, "LIFT_HCZ", "ЛИФТ В HCZ [Ур.3]", mats["lcz_wall"], mats["floor"])

	box(root, Vector3(-10.5, 1.6, 12), Vector3(1.5, 3, 6), mats["metal"])
	box(root, Vector3(-9.2, 0.2, 13.5), Vector3(1.2, 0.3, 1.8), mat(Color.ORANGE, false)).name = "914_IN"
	box(root, Vector3(-9.2, 0.2, 10.5), Vector3(1.2, 0.3, 1.8), mat(Color.LIME_GREEN, false)).name = "914_OUT"
	box(root, Vector3(-9.5, 1.4, 12.5), Vector3(0.3, 0.4, 0.6), mat(Color.GOLD, false)).name = "914_KNOB"
	box(root, Vector3(-9.5, 1.4, 11.5), Vector3(0.3, 0.4, 0.6), mat(Color.GREEN, false)).name = "914_GO"

	prop_bed(root, Vector3(-9.5, 0, 21.0)); prop_bed(root, Vector3(-9.5, 0, 27.0))
	prop_locker(root, Vector3(-10.5, 0, 34.0)); prop_locker(root, Vector3(-10.5, 0, 38.0))
	prop_table(root, Vector3(36, 0, -1.2)); prop_table(root, Vector3(48, 0, 49.2)); prop_table(root, Vector3(12, 0, -1.2))
	prop_table(root, Vector3(80, 0, 36)); prop_crate(root, Vector3(58, 0, 1.4)); prop_crate(root, Vector3(14, 0, 46.5))

	grid(root, Vector3(132, 0, 0), ["0111001110", "1111111111", "1110011111", "1111111111", "0110001100"], mats["hcz_wall"], mats["floor"], mats["hcz_trim"], 1)
	door(root, doors, Vector3(180, 1.6, 12), true, "D_EZ", 4, Color.LIGHT_GRAY, mats["metal"]); lbl(root, "КПП ОФИСНАЯ ЗОНА [Ур.4]", Vector3(180.5, 3, 12), PI * 0.5)
	room(root, doors, Vector3(242.2, 0, 24), 1.0, "D_ARM2", 6, Color.DODGER_BLUE, mats["hcz_wall"], mats["floor"], "ОРУЖЕЙНАЯ МИКРО-ХИД [Ур.6]")
	room(root, doors, Vector3(242.2, 0, 12), 1.0, "D_049", 3, Color.DARK_GREEN, mats["hcz_wall"], mats["floor"], "КАМЕРА SCP-049 [Ур.3]")
	lift(root, doors, Vector3(216, 0, -2.2), -1.0, "D_L1B", 0, Color.CYAN, "LIFT_LCZ", "ЛИФТ НАЗАД В LCZ", mats["hcz_wall"], mats["floor"])
	lift(root, doors, Vector3(144, 0, -2.2), -1.0, "D_L2", 8, Color.BLUE, "LIFT_SURF", "GATE A: ВЫХОД НА УЛИЦУ [Ур.8]", mats["ez_wall"], mats["floor"])

	prop_table(root, Vector3(144, 0, 13.4)); prop_table(root, Vector3(168, 0, 13.4)); prop_table(root, Vector3(204, 0, -1.2))
	prop_server(root, Vector3(156, 0, 1.4)); prop_server(root, Vector3(168, 0, 1.4))
	prop_locker(root, Vector3(250.5, 0, 22.0)); prop_locker(root, Vector3(250.5, 0, 26.0))
	prop_crate(root, Vector3(228, 0, 34.5)); prop_crate(root, Vector3(192, 0, 13.4))

	grid(root, Vector3(300, 0, 0), ["00011", "11111", "01110"], mats["ez_wall"], mats["floor"], mats["hazard"], 2)
	lift(root, doors, Vector3(348, 0, 14.2), 1.0, "D_L2B", 0, Color.BLUE, "LIFT_EZ", "ЛИФТ В ОФИСЫ", mats["ez_wall"], mats["floor"])
	box(root, Vector3(297.8, 1.6, 12), Vector3(0.6, 3.2, 4.4), mat(Color.LIME, true)).name = "ESCAPE"
	lbl(root, "ESCAPE (ВЫХОД / ПОБЕДА)", Vector3(298.5, 3, 12), PI * 0.5)
	prop_crate(root, Vector3(312, 0, 10.2)); prop_crate(root, Vector3(336, 0, 22.2))
	box(root, Vector3(180, -1.0, 30), Vector3(500, 1, 180), mats["floor"])
static func prop_table(root: Node, p: Vector3) -> void:
	box(root, p + Vector3(0, 0.75, 0), Vector3(1.6, 0.1, 0.8), mats["metal"])
	box(root, p + Vector3(-0.7, 0.37, 0), Vector3(0.1, 0.75, 0.7), mats["metal"])
	box(root, p + Vector3(0.7, 0.37, 0), Vector3(0.1, 0.75, 0.7), mats["metal"])

static func prop_bed(root: Node, p: Vector3) -> void:
	box(root, p + Vector3(0, 0.35, 0), Vector3(1.9, 0.12, 0.9), mats["metal"])
	box(root, p + Vector3(0, 0.46, 0), Vector3(1.75, 0.12, 0.8), mat(Color(0.85, 0.52, 0.25), false))

static func prop_locker(root: Node, p: Vector3) -> void:
	box(root, p + Vector3(0, 1.1, 0), Vector3(0.7, 2.2, 0.9), mats["metal"])
	box(root, p + Vector3(0.36, 1.1, 0), Vector3(0.04, 1.9, 0.75), mat(Color(0.22, 0.28, 0.36), false))

static func prop_server(root: Node, p: Vector3) -> void:
	box(root, p + Vector3(0, 1.15, 0), Vector3(0.9, 2.3, 0.8), mat(Color(0.1, 0.11, 0.14), false))
	box(root, p + Vector3(0, 1.5, 0.42), Vector3(0.6, 0.08, 0.04), mat(Color(0.1, 0.9, 0.3), true))
	box(root, p + Vector3(0, 1.1, 0.42), Vector3(0.6, 0.08, 0.04), mat(Color(0.2, 0.6, 1.0), true))

static func prop_crate(root: Node, p: Vector3) -> void:
	box(root, p + Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 0.9), mat(Color(0.32, 0.26, 0.18), false))

static func grid(root: Node, orig: Vector3, rows: Array, mw: Material, mf: Material, tr: Material, zid: int) -> void:
	var h: int = rows.size(); var cols: int = String(rows.front()).length(); var hw := W * 0.5; var arm := (STEP - W) * 0.5
	for r in range(h):
		var s := String(rows[r])
		for c in range(cols):
			if s[c] == "0": continue
			var p := orig + Vector3(c * STEP, 0, r * STEP)
			var n := r > 0 and String(rows[r - 1])[c] == "1"; var so := r < h - 1 and String(rows[r + 1])[c] == "1"
			var we := c > 0 and s[c - 1] == "1"; var ea := c < cols - 1 and s[c + 1] == "1"
			var nb := []
			if n: nb.append(p + Vector3(0, 0, -STEP))
			if so: nb.append(p + Vector3(0, 0, STEP))
			if we: nb.append(p + Vector3(-STEP, 0, 0))
			if ea: nb.append(p + Vector3(STEP, 0, 0))
			nodes.append({"pos": p, "zone": zid, "nb": nb}); graph[p] = nb

			box(root, p + Vector3(0, -0.5, 0), Vector3(W + 0.4, 1, W + 0.4), mf)
			if zid < 2:
				box(root, p + Vector3(0, 3.6, 0), Vector3(W + 0.4, 1, W + 0.4), mf)
				if (r + c) % 2 == 0:
					box(root, p + Vector3(0, 3.08, 0), Vector3(1.4, 0.08, 0.5), mat(Color(0.95, 0.96, 1.0), true))
					var l := OmniLight3D.new(); l.position = p + Vector3(0, 2.9, 0); l.omni_range = 15.0; l.light_energy = 1.4; root.add_child(l)
			if n: seg(root, p + Vector3(0, 0, -hw - arm * 0.5), Vector3(W, 1, arm), mw, mf, tr, zid < 2, true)
			elif not is_open(p + Vector3(0, 1.6, -hw)): wall(root, p + Vector3(0, 1.6, -hw), Vector3(W + 0.6, 3.4, 0.6), mw, tr)
			if so: seg(root, p + Vector3(0, 0, hw + arm * 0.5), Vector3(W, 1, arm), mw, mf, tr, zid < 2, true)
			elif not is_open(p + Vector3(0, 1.6, hw)): wall(root, p + Vector3(0, 1.6, hw), Vector3(W + 0.6, 3.4, 0.6), mw, tr)
			if we: seg(root, p + Vector3(-hw - arm * 0.5, 0, 0), Vector3(arm, 1, W), mw, mf, tr, zid < 2, false)
			elif not is_open(p + Vector3(-hw, 1.6, 0)): wall(root, p + Vector3(-hw, 1.6, 0), Vector3(0.6, 3.4, W + 0.6), mw, tr)
			if ea: seg(root, p + Vector3(hw + arm * 0.5, 0, 0), Vector3(arm, 1, W), mw, mf, tr, zid < 2, false)
			elif not is_open(p + Vector3(hw, 1.6, 0)): wall(root, p + Vector3(hw, 1.6, 0), Vector3(0.6, 3.4, W + 0.6), mw, tr)
static func seg(root: Node, p: Vector3, s: Vector3, mw: Material, mf: Material, tr: Material, roof: bool, zdir: bool) -> void:
	box(root, p + Vector3(0, -0.5, 0), s + Vector3(0.4, 0, 0.4), mf)
	if roof: box(root, p + Vector3(0, 3.6, 0), s + Vector3(0.4, 0, 0.4), mf)
	if zdir: wall(root, p + Vector3(-W * 0.5, 1.6, 0), Vector3(0.6, 3.4, s.z + 0.2), mw, tr); wall(root, p + Vector3(W * 0.5, 1.6, 0), Vector3(0.6, 3.4, s.z + 0.2), mw, tr)
	else: wall(root, p + Vector3(0, 1.6, -W * 0.5), Vector3(s.x + 0.2, 3.4, 0.6), mw, tr); wall(root, p + Vector3(0, 1.6, W * 0.5), Vector3(s.x + 0.2, 3.4, 0.6), mw, tr)

static func wall(root: Node, p: Vector3, s: Vector3, mw: Material, tr: Material) -> void:
	box(root, p, s, mw); box(root, Vector3(p.x, 0.85, p.z), Vector3(s.x + 0.06, 0.16, s.z + 0.06), tr)

static func is_open(pos: Vector3) -> bool:
	for ep in open_doors:
		if ep.distance_to(pos) < 0.5: return true
	return false

static func lift(root: Node, doors: Dictionary, dp: Vector3, dz: float, dnm: String, req: int, col: Color, lnm: String, txt: String, mw: Material, mf: Material) -> void:
	door(root, doors, dp + Vector3(0, 1.6, 0), false, dnm, req, col, mw); lbl(root, txt, dp + Vector3(0, 3.0, -dz * 0.5), 0.0 if dz < 0 else PI)
	box(root, dp + Vector3(0, -0.5, dz * 2.5), Vector3(W, 1, 5.0), mf); box(root, dp + Vector3(0, 3.6, dz * 2.5), Vector3(W, 1, 5.0), mf)
	box(root, dp + Vector3(-W * 0.5, 1.6, dz * 2.5), Vector3(0.6, 3.4, 5.0), mw); box(root, dp + Vector3(W * 0.5, 1.6, dz * 2.5), Vector3(0.6, 3.4, 5.0), mw)
	box(root, dp + Vector3(0, 1.6, dz * 5.0), Vector3(W + 0.6, 3.4, 0.6), mw); box(root, dp + Vector3(0, 1.6, dz * 4.5), Vector3(3.4, 2.9, 0.4), mat(Color(0.2, 0.75, 0.9), true)).name = lnm

static func room(root: Node, doors: Dictionary, dp: Vector3, dx: float, nm: String, req: int, col: Color, mw: Material, mf: Material, txt: String) -> void:
	var c := dp + Vector3(dx * 5.0, 0, 0)
	box(root, c + Vector3(0, -0.5, 0), Vector3(10.6, 1, 9.6), mf); box(root, c + Vector3(0, 3.6, 0), Vector3(10.6, 1, 9.6), mf)
	box(root, c + Vector3(dx * 5.0, 1.6, 0), Vector3(0.6, 3.4, 9.8), mw); box(root, c + Vector3(0, 1.6, -4.5), Vector3(10.6, 3.4, 0.6), mw); box(root, c + Vector3(0, 1.6, 4.5), Vector3(10.6, 3.4, 0.6), mw)
	box(root, dp + Vector3(0, 1.6, -3.1), Vector3(0.6, 3.4, 3.4), mw); box(root, dp + Vector3(0, 1.6, 3.1), Vector3(0.6, 3.4, 3.4), mw)
	door(root, doors, dp + Vector3(0, 1.6, 0), true, nm, req, col, mw); lbl(root, txt, dp + Vector3(-dx * 0.5, 3.0, 0), PI * 0.5 if dx < 0 else -PI * 0.5)

static func door(root: Node, doors: Dictionary, c: Vector3, zax: bool, nm: String, req: int, col: Color, mw: Material) -> void:
	if zax: box(root, c + Vector3(0, 0, -1.7), Vector3(0.6, 3.4, 1.2), mw); box(root, c + Vector3(0, 0, 1.7), Vector3(0.6, 3.4, 1.2), mw)
	else: box(root, c + Vector3(-1.7, 0, 0), Vector3(1.2, 3.4, 0.6), mw); box(root, c + Vector3(1.7, 0, 0), Vector3(1.2, 3.4, 0.6), mw)
	var d := StaticBody3D.new(); d.name = nm; d.position = c; root.add_child(d)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.24, 3.3, 2.2) if zax else Vector3(2.2, 3.3, 0.24)
	mi.mesh = bm; mi.material_override = mat(col.darkened(0.25), false); d.add_child(mi)
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = bm.size; cs.shape = bs; d.add_child(cs)
	for side in [-0.38, 0.38]:
		var p_off := Vector3(side, -0.25, 1.48) if zax else Vector3(1.48, -0.25, side)
		var b_off := Vector3(side * 1.18, -0.25, 1.48) if zax else Vector3(1.48, -0.25, side * 1.18)
		var p_sz := Vector3(0.16, 0.65, 0.45) if zax else Vector3(0.45, 0.65, 0.16)
		var b_sz := Vector3(0.1, 0.35, 0.28) if zax else Vector3(0.28, 0.35, 0.1)
		box(root, c + p_off, p_sz, mat(Color(0.08, 0.09, 0.11), false)).set_meta("door_btn", nm)
		box(root, c + b_off, b_sz, mat(col, true)).set_meta("door_btn", nm)
	var slide := Vector3(0, 0, -2.05) if zax else Vector3(-2.05, 0, 0)
	doors[nm] = {"node": d, "closed_pos": c, "open_pos": c + slide, "open": false, "req": req}

static func lbl(root: Node, t: String, p: Vector3, r: float) -> void:
	var l := Label3D.new(); l.text = t; l.position = p; l.rotation.y = r; l.pixel_size = 0.008; l.modulate = Color(1, 0.9, 0.6); root.add_child(l)

static func mat(col: Color, em: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = col; if em: m.emission_enabled = true; m.emission = col
	return m

static func box(root: Node, p: Vector3, s: Vector3, m: Material) -> StaticBody3D:
	var b := StaticBody3D.new(); b.position = p; root.add_child(b); var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = s; mi.mesh = bm; mi.material_override = m; b.add_child(mi)
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = s; cs.shape = bs; b.add_child(cs); return b
