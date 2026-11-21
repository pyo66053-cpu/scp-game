extends Node3D

const WG = preload("res://world_grid.gd")
const AI = preload("res://npc_ai.gd")
const MM = preload("res://main_menu.gd")

var player: CharacterBody3D; var head: Node3D; var cam: Camera3D; var ray: RayCast3D
var hand: MeshInstance3D; var beam: MeshInstance3D; var muzzle: OmniLight3D
var doors := {}; var mobs := []; var loot := []; var corpses := []; var inv := []; var eq := -1
var my_role := 3; var hp := 100; var max_hp := 100; var armor := 0
var limbs := {"head": 100.0, "torso": 100.0, "arms": 100.0, "legs": 100.0}
var map_open := false; var inv_open := false; var ui := {}
var mode914 := "Fine"; var in914 := {}; var move_vec := Vector2.ZERO; var touch_sprint := false
var boost := 0.0; var chg := 0.0; var r_cd := 0.0; var banner_t := 4.5; var wave_t := 45.0
var shake := 0.0; var bob_t := 0.0; var flash_a := 0.0
var watched_173 := false; var spotted_096 := false; var windup_096 := 0.0
var firing := false; var dead := false; var win := false; var blink := false; var b_t := 7.0; var b_d := 0.0

var cards_db := [
	{"id": "C0", "t": "Уборщик", "l": 0, "c": Color.WHITE}, {"id": "C1", "t": "Учёный", "l": 1, "c": Color.YELLOW},
	{"id": "C3", "t": "Менеджер Зон", "l": 3, "c": Color.CYAN}, {"id": "C4", "t": "Охранник", "l": 4, "c": Color.GRAY},
	{"id": "C6", "t": "Инженер", "l": 6, "c": Color.BROWN}, {"id": "C8", "t": "Командир МОГ", "l": 8, "c": Color.BLUE},
	{"id": "C11", "t": "Совет O5", "l": 11, "c": Color.BLACK}
]

func _ready() -> void:
	randomize(); WG.init_audio(self); WG.build(self, doors)
	var roles := [3, 4] if MM.refuse_scp else [0, 1, 3, 4, 6, 8]
	my_role = int(roles[randi() % roles.size()])

	player = CharacterBody3D.new()
	if my_role == 0: player.position = Vector3(80, 1.2, 12); max_hp = 2500
	elif my_role == 1: player.position = Vector3(204, 1.2, 24); max_hp = 2000
	elif my_role == 6: player.position = Vector3(247, 1.2, 12); max_hp = 1800
	elif my_role == 8: player.position = Vector3(192, 1.2, 36); max_hp = 2200
	elif my_role == 3: player.position = Vector3(-7, 1.2, 24); max_hp = 100
	else: player.position = Vector3(36, 1.2, 12); max_hp = 100
	hp = max_hp; add_child(player)
	var cs := CollisionShape3D.new(); cs.shape = CapsuleShape3D.new(); player.add_child(cs)
	head = Node3D.new(); head.position = Vector3(0, 0.6, 0); player.add_child(head)
	cam = Camera3D.new(); head.add_child(cam); cam.make_current()
	var sp := SpotLight3D.new(); sp.spot_range = 26.0; head.add_child(sp)
	ray = RayCast3D.new(); ray.target_position = Vector3(0, 0, -24); ray.add_exception(player); head.add_child(ray)
	hand = MeshInstance3D.new(); hand.position = Vector3(0.32, -0.25, -0.55); hand.visible = false; head.add_child(hand)
	muzzle = OmniLight3D.new(); muzzle.position = Vector3(0.32, -0.2, -0.9); muzzle.light_color = Color(1.0, 0.85, 0.3); muzzle.omni_range = 8.0; muzzle.visible = false; head.add_child(muzzle)
	beam = MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.15, 0.15, 14); beam.mesh = bm; beam.position = Vector3(0.32, -0.22, -7.5)
	beam.material_override = WG.mat(Color.CYAN, true); beam.visible = false; head.add_child(beam)

	if my_role == 4:
		inv.append({"id": "C1", "t": "Учёный [Ур.1]", "c": Color.YELLOW})
		inv.append({"id": "Medkit", "t": "Аптечка (+50)", "c": Color.RED})
		equip(0)

	spawn_loot_and_mobs()
	build_ui()

func spawn_loot_and_mobs() -> void:
	add_card("C0", Vector3(-6, 0.82, 25)); add_card("C1", Vector3(36, 0.82, -1.2)); add_card("C3", Vector3(48, 0.82, 49.2))
	add_card("C4", Vector3(204, 0.82, -1.2)); add_card("C8", Vector3(144, 0.82, 13.4)); add_card("C11", Vector3(247, 0.5, 26))
	item("Pistol", "Пистолет COM-15", Vector3(12, 0.85, -1.2), Vector3(0.16, 0.18, 0.4), Color.DIM_GRAY)
	item("Shotgun", "Дробовик M870", Vector3(-8, 0.5, 34), Vector3(0.2, 0.22, 1.05), Color.SADDLE_BROWN)
	item("Rifle", "Автомат E-11", Vector3(-8, 0.5, 38), Vector3(0.2, 0.25, 0.95), Color.DARK_SLATE_GRAY)
	item("MicroHID", "Микро-ХИД", Vector3(247, 0.6, 24), Vector3(0.45, 0.45, 1.3), Color.AQUA)
	item("MicroHID", "Микро-ХИД", Vector3(168, 0.88, 13.4), Vector3(0.45, 0.45, 1.3), Color.AQUA)
	item("ArmorLight", "Лёгкая броня (+40)", Vector3(-6, 0.5, 36), Vector3(0.5, 0.35, 0.4), Color.SLATE_GRAY)
	item("ArmorHeavy", "Броня МОГ (+80)", Vector3(245, 0.5, 22), Vector3(0.55, 0.4, 0.45), Color.ROYAL_BLUE)
	item("Medkit", "Аптечка (+50)", Vector3(24, 0.5, 12), Vector3(0.5, 0.3, 0.5), Color.RED)
	item("SCP500", "SCP-500 (Панацея)", Vector3(80, 0.5, 15), Vector3(0.28, 0.35, 0.28), Color.CRIMSON)
	item("SCP1344", "SCP-1344 (Очки ВХ)", Vector3(80, 0.88, 36), Vector3(0.42, 0.18, 0.28), Color.MAGENTA)
	item("SCP1344", "SCP-1344 (Очки ВХ)", Vector3(36.4, 0.88, -1.2), Vector3(0.42, 0.18, 0.28), Color.MAGENTA)

	if my_role != 0: spawn_bot(Vector3(80, 1.2, 12), 0)
	if my_role != 1: spawn_bot(Vector3(204, 1.2, 24), 1)
	if my_role != 6: spawn_bot(Vector3(247, 1.2, 12), 6)
	if my_role != 8: spawn_bot(Vector3(192, 1.2, 36), 8)
	spawn_bot(Vector3(156, 1.2, 12), 2); spawn_bot(Vector3(-8, 1.2, 25), 3); spawn_bot(Vector3(12, 1.2, 24), 3); spawn_bot(Vector3(36, 1.2, 14), 4); spawn_bot(Vector3(48, 1.2, 24), 4)
func spawn_bot(p: Vector3, k: int) -> void:
	var b := AI.new(); b.position = p; add_child(b); b.setup(k); mobs.append(b)

func spawn_zombie(p: Vector3) -> void:
	spawn_bot(p, 7); WG.play("cure")

func spawn_tracer(p1: Vector3, p2: Vector3, col: Color) -> void:
	var d := p1.distance_to(p2)
	if d < 0.2: return
	var tr := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.04, 0.04, d); tr.mesh = bm
	tr.material_override = WG.mat(col, true); add_child(tr); tr.global_position = (p1 + p2) * 0.5; tr.look_at(p2)
	get_tree().create_timer(0.08).timeout.connect(func(): if is_instance_valid(tr): tr.queue_free())

func on_mob_died(pos: Vector3, k: int, clvl: int, weap: String, meds: int) -> void:
	if k < 2 or k > 5: return
	var col := Color(0.16, 0.38, 0.18) if k == 2 else (Color(0.12, 0.25, 0.65) if k == 5 else (Color(0.92, 0.44, 0.1) if k == 3 else Color(0.95, 0.96, 0.99)))
	var body := WG.box(self, Vector3(pos.x, 0.18, pos.z), Vector3(0.55, 0.28, 1.65), WG.mat(col, false))
	corpses.append({"node": body, "pos": body.global_position, "active": true})
	if clvl > 0: add_card("C" + str(clvl), Vector3(pos.x + 0.5, 0.4, pos.z))
	if weap != "": item(weap, weap, Vector3(pos.x - 0.5, 0.4, pos.z), Vector3(0.25, 0.25, 0.8), Color.DARK_SLATE_GRAY)
	if meds > 0: item("Medkit", "Аптечка (+50)", Vector3(pos.x, 0.4, pos.z + 0.5), Vector3(0.5, 0.3, 0.5), Color.RED)

func add_card(id: String, p: Vector3) -> void:
	for c in cards_db:
		if c["id"] == id: item(id, c["t"] + " [Ур." + str(c["l"]) + "]", p, Vector3(0.4, 0.05, 0.6), c["c"])

func item(id: String, t: String, p: Vector3, s: Vector3, col: Color) -> void:
	var b := WG.box(self, p, s, WG.make_tex_mat(col, 0.06, 2 if id == "Rifle" or id == "MicroHID" else 1))
	b.set_meta("id", id); b.set_meta("t", t); b.set_meta("c", col); loot.append(b)
	if id.begins_with("C"):
		add_detail(b, Vector3(0, 0.03, -0.18), Vector3(0.36, 0.02, 0.1), WG.mat(Color.BLACK, false))
		add_detail(b, Vector3(-0.1, 0.03, 0.08), Vector3(0.1, 0.02, 0.1), WG.mat(Color.GOLD, true))
	elif id == "SCP500":
		add_detail(b, Vector3(0, 0.2, 0), Vector3(0.3, 0.08, 0.3), WG.mat(Color.WHITE, false))
		add_detail(b, Vector3(0, 0, 0.15), Vector3(0.18, 0.18, 0.02), WG.mat(Color.WHITE, true))
	elif id == "Shotgun" or id == "Rifle":
		add_detail(b, Vector3(0, 0.06, -0.45), Vector3(0.06, 0.06, 0.55), WG.mat(Color(0.1, 0.1, 0.12), false))
		add_detail(b, Vector3(0, -0.08, 0.15), Vector3(0.08, 0.18, 0.2), WG.mat(Color(0.15, 0.15, 0.18), false))
	elif id == "MicroHID":
		add_detail(b, Vector3(0, 0.18, -0.2), Vector3(0.5, 0.15, 0.6), WG.mat(Color.CYAN, true))
	elif id == "SCP1344":
		add_detail(b, Vector3(-0.12, 0, -0.15), Vector3(0.14, 0.12, 0.05), WG.mat(Color.CYAN, true))
		add_detail(b, Vector3(0.12, 0, -0.15), Vector3(0.14, 0.12, 0.05), WG.mat(Color.CYAN, true))
	elif id == "Medkit":
		add_detail(b, Vector3(0, 0.16, 0), Vector3(0.28, 0.02, 0.08), WG.mat(Color.WHITE, true))
		add_detail(b, Vector3(0, 0.16, 0), Vector3(0.08, 0.02, 0.28), WG.mat(Color.WHITE, true))

func add_detail(parent: Node3D, off: Vector3, sz: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sz; mi.mesh = bm; mi.position = off; mi.material_override = m; parent.add_child(mi)

func show_banner(txt: String, col: Color) -> void:
	ui["ban"].text = txt; ui["ban"].modulate = col; ui["ban"].visible = true; banner_t = 4.5

func rage_096() -> void:
	if my_role == 1 and spotted_096 and boost <= 0.0 and windup_096 <= 0.0:
		windup_096 = 2.0; WG.play("shy"); shake = 0.35

func dmg_body(amt: int) -> void:
	if armor > 0:
		var abs_d := mini(armor, int(amt * 0.65)); armor -= abs_d; amt -= abs_d
	hp = maxi(0, hp - amt)
	var parts := ["head", "torso", "arms", "legs"]
	var p := String(parts[randi() % 4])
	limbs[p] = clampf(limbs[p] - float(amt) * 1.3, 0.0, 100.0)
func build_ui() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	var fl := ColorRect.new(); fl.color = Color(1, 0, 0, 0); fl.set_anchors_preset(Control.PRESET_FULL_RECT); fl.mouse_filter = Control.MOUSE_FILTER_IGNORE; cl.add_child(fl)
	var bl := ColorRect.new(); bl.color = Color.BLACK; bl.set_anchors_preset(Control.PRESET_FULL_RECT); bl.visible = false; bl.mouse_filter = Control.MOUSE_FILTER_IGNORE; cl.add_child(bl)
	var dot := ColorRect.new(); dot.size = Vector2(6, 6); dot.set_anchors_preset(Control.PRESET_CENTER); dot.position = Vector2(-3, -3); dot.mouse_filter = Control.MOUSE_FILTER_IGNORE; cl.add_child(dot)
	var hint := Label.new(); hint.set_anchors_preset(Control.PRESET_CENTER); hint.position = Vector2(-180, 18); hint.size = Vector2(360, 30); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cl.add_child(hint)
	var inf := Label.new(); inf.position = Vector2(20, 20); inf.add_theme_font_size_override("font_size", 19); cl.add_child(inf)

	var hp_bg := ColorRect.new(); hp_bg.color = Color(0.1, 0.1, 0.12, 0.85); hp_bg.size = Vector2(240, 26); hp_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); hp_bg.position = Vector2(20, -42); cl.add_child(hp_bg)
	var hp_bar := ColorRect.new(); hp_bar.color = Color(0.85, 0.18, 0.18) if (my_role <= 1 or my_role >= 6) else Color(0.2, 0.8, 0.35); hp_bar.size = Vector2(236, 22); hp_bar.position = Vector2(2, 2); hp_bg.add_child(hp_bar)
	var hp_txt := Label.new(); hp_txt.position = Vector2(10, 1); hp_bg.add_child(hp_txt)

	var ar_bg := ColorRect.new(); ar_bg.color = Color(0.1, 0.1, 0.15, 0.85); ar_bg.size = Vector2(240, 16); ar_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); ar_bg.position = Vector2(20, -62); cl.add_child(ar_bg)
	var ar_bar := ColorRect.new(); ar_bar.color = Color(0.25, 0.65, 1.0); ar_bar.size = Vector2(0, 12); ar_bar.position = Vector2(2, 2); ar_bg.add_child(ar_bar)

	var rn := {0: "SCP-173", 1: "SCP-096", 3: "D-Класс", 4: "Учёный", 6: "SCP-049 (Чумной Доктор)", 8: "SCP-939 (Слепой хищник)"}
	var ban := Label.new(); ban.text = "ВЫ НАЧАЛИ ИГРУ ЗА:\n" + String(rn[my_role]); ban.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ban.add_theme_font_size_override("font_size", 24); ban.set_anchors_preset(Control.PRESET_CENTER); ban.position = Vector2(-280, -150); cl.add_child(ban)

	var iv := Control.new(); iv.set_anchors_preset(Control.PRESET_CENTER); iv.visible = false; cl.add_child(iv)
	var ibg := ColorRect.new(); ibg.color = Color(0.05, 0.07, 0.1, 0.94); ibg.size = Vector2(620, 400); ibg.position = Vector2(-310, -200); iv.add_child(ibg)
	var slots := []
	for i in range(8):
		var b := Button.new(); b.size = Vector2(240, 38); b.position = Vector2(-290, -180 + i * 44)
		var idx := i; b.pressed.connect(func(): equip(idx); toggle_inv()); iv.add_child(b); slots.append(b)
	var b_head := ColorRect.new(); b_head.size = Vector2(44, 44); b_head.position = Vector2(138, -165); iv.add_child(b_head)
	var b_torso := ColorRect.new(); b_torso.size = Vector2(72, 105); b_torso.position = Vector2(124, -115); iv.add_child(b_torso)
	var b_arms := ColorRect.new(); b_arms.size = Vector2(126, 85); b_arms.position = Vector2(97, -110); b_arms.z_index = -1; iv.add_child(b_arms)
	var b_legs := ColorRect.new(); b_legs.size = Vector2(68, 115); b_legs.position = Vector2(126, -5); iv.add_child(b_legs)
	var b_txt := Label.new(); b_txt.position = Vector2(65, 125); iv.add_child(b_txt)

	var mp := Control.new(); mp.set_anchors_preset(Control.PRESET_CENTER); mp.visible = false; cl.add_child(mp)
	var mbg := ColorRect.new(); mbg.color = Color(0.03, 0.08, 0.12, 0.92); mbg.size = Vector2(540, 340); mbg.position = Vector2(-270, -170); mp.add_child(mbg)
	for nd in WG.nodes:
		var r := ColorRect.new(); r.size = Vector2(10, 10); r.color = Color(0.3, 0.55, 0.65); r.position = to_map(nd["pos"]) - Vector2(5, 5); mp.add_child(r)
	var pd := ColorRect.new(); pd.color = Color.YELLOW; pd.size = Vector2(8, 8); mp.add_child(pd)

	var rst := Button.new(); rst.text = "ЗАНОВО (R)"; rst.size = Vector2(180, 70); rst.set_anchors_preset(Control.PRESET_CENTER); rst.visible = false; rst.pressed.connect(func(): get_tree().reload_current_scene()); cl.add_child(rst)
	m_btn(cl, "W", Vector2(80, -200), Vector2(0, -1)); m_btn(cl, "S", Vector2(80, -85), Vector2(0, 1)); m_btn(cl, "A", Vector2(20, -142), Vector2(-1, 0)); m_btn(cl, "D", Vector2(140, -142), Vector2(1, 0))
	var sb := Button.new(); sb.text = "БЕГ"; sb.size = Vector2(58, 54); sb.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); sb.position = Vector2(205, -142); sb.button_down.connect(func(): touch_sprint = true); sb.button_up.connect(func(): touch_sprint = false); cl.add_child(sb)

	btn(cl, "USE (E)", Vector2(-125, -75), use_ray); btn(cl, "BLINK", Vector2(-125, -140), func(): blink = true; b_d = 0.3; bl.visible = true; b_t = 7.0)
	btn(cl, "INV (TAB)", Vector2(-125, -205), toggle_inv); btn(cl, "MAP (M)", Vector2(-125, -270), toggle_map)
	if my_role == 1: btn(cl, "ЯРОСТЬ (R)", Vector2(-260, -140), rage_096)
	var fb := Button.new(); fb.text = "АТАКА / ОГОНЬ"; fb.size = Vector2(125, 56); fb.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); fb.position = Vector2(-260, -75); fb.button_down.connect(func(): set_fire(true)); fb.button_up.connect(func(): set_fire(false)); cl.add_child(fb)
	ui = {"fl": fl, "bl": bl, "dot": dot, "hint": hint, "inf": inf, "iv": iv, "slots": slots, "mp": mp, "pd": pd, "rst": rst, "hp_bar": hp_bar, "hp_txt": hp_txt, "ar_bar": ar_bar, "ban": ban, "b_head": b_head, "b_torso": b_torso, "b_arms": b_arms, "b_legs": b_legs, "b_txt": b_txt}

func m_btn(p: Node, t: String, pos: Vector2, d: Vector2) -> void:
	var b := Button.new(); b.text = t; b.size = Vector2(54, 54); b.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); b.position = pos; b.button_down.connect(func(): move_vec += d); b.button_up.connect(func(): move_vec -= d); p.add_child(b)

func btn(p: Node, t: String, pos: Vector2, cb: Callable) -> void:
	var b := Button.new(); b.text = t; b.size = Vector2(105, 56); b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); b.position = pos; b.pressed.connect(cb); p.add_child(b)
func limb_col(v: float) -> Color:
	return Color(0.2, 0.85, 0.35) if v > 70.0 else (Color(0.95, 0.75, 0.15) if v > 35.0 else Color(0.9, 0.15, 0.15))

func toggle_inv() -> void:
	if dead or win or my_role <= 1 or my_role >= 6: return
	inv_open = !inv_open; ui["iv"].visible = inv_open
	if inv_open: map_open = false; ui["mp"].visible = false
	for i in range(8):
		ui["slots"][i].text = (("> " if i == eq else "") + String(inv[i]["t"])) if i < inv.size() else "[Пусто]"
	ui["b_head"].color = limb_col(limbs["head"]); ui["b_torso"].color = limb_col(limbs["torso"])
	ui["b_arms"].color = limb_col(limbs["arms"]); ui["b_legs"].color = limb_col(limbs["legs"])
	ui["b_txt"].text = "Броня: %d | Ноги: %d%%" % [armor, int(limbs["legs"])]
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if (inv_open or map_open) else Input.MOUSE_MODE_CAPTURED

func toggle_map() -> void:
	if dead or win: return
	map_open = !map_open; ui["mp"].visible = map_open
	if map_open: inv_open = false; ui["iv"].visible = false
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if (inv_open or map_open) else Input.MOUSE_MODE_CAPTURED

func to_map(wp: Vector3) -> Vector2:
	if wp.x < 100.0: return Vector2(50.0 + (wp.x / 12.0) * 22.0, -120.0 + (wp.z / 12.0) * 22.0)
	elif wp.x < 270.0: return Vector2(-200.0 + ((wp.x - 132.0) / 12.0) * 22.0, 45.0 + (wp.z / 12.0) * 22.0)
	return Vector2(-210.0 + ((wp.x - 300.0) / 12.0) * 22.0, -105.0 + (wp.z / 12.0) * 22.0)

func set_fire(v: bool) -> void:
	firing = v
	if not v: chg = 0.0; beam.visible = false; return
	if (my_role == 0 and not watched_173) or (my_role == 1 and boost > 0.0) or my_role >= 6:
		if ray.is_colliding() and ray.get_collider() in mobs and ray.get_collision_point().distance_to(head.global_position) < 3.6:
			ray.get_collider().hit(9999.0 if my_role != 8 else 120.0); WG.play("shot"); shake = 0.25
	elif my_role >= 2 and my_role <= 5 and eq >= 0:
		var id := String(inv[eq]["id"])
		if id == "Medkit":
			hp = min(max_hp, hp + 50)
			for k in limbs.keys(): limbs[k] = minf(100.0, limbs[k] + 50.0)
			inv.remove_at(eq); equip(inv.size() - 1); WG.play("pick")
		elif id == "SCP500":
			hp = max_hp
			for k in limbs.keys(): limbs[k] = 100.0
			boost = 12.0; inv.remove_at(eq); equip(inv.size() - 1); WG.play("cure")
		elif id == "ArmorLight": armor = mini(100, armor + 40); inv.remove_at(eq); equip(inv.size() - 1); WG.play("pick")
		elif id == "ArmorHeavy": armor = mini(100, armor + 80); inv.remove_at(eq); equip(inv.size() - 1); WG.play("pick")
		elif id == "SCP1344":
			inv.remove_at(eq); equip(inv.size() - 1); WG.play("pick")
			for m: Node3D in mobs: m.wh.visible = true

func equip(i: int) -> void:
	if i < 0 or i >= inv.size(): eq = -1; hand.visible = false
	else:
		eq = i; hand.visible = true; var hm := BoxMesh.new(); hm.size = Vector3(0.2, 0.2, 0.7)
		hand.mesh = hm; hand.material_override = WG.mat(inv[eq]["c"], false)

func _input(e: InputEvent) -> void:
	var menu := inv_open or map_open
	if e is InputEventMouseButton and not menu and not dead and not win and e.button_index == MOUSE_BUTTON_LEFT:
		if not DisplayServer.is_touchscreen_available() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and e.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else: set_fire(e.pressed)
	if e.is_action_pressed("ui_cancel"): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not menu:
		player.rotate_y(-e.relative.x * 0.003); head.rotate_x(-e.relative.y * 0.003); head.rotation.x = clampf(head.rotation.x, -1.4, 1.4)
	if e is InputEventScreenDrag and not menu and e.position.x > get_viewport().get_visible_rect().size.x * 0.35:
		player.rotate_y(-e.relative.x * 0.005); head.rotate_x(-e.relative.y * 0.005); head.rotation.x = clampf(head.rotation.x, -1.4, 1.4)
	if e is InputEventKey and e.pressed:
		if e.keycode == KEY_E: use_ray()
		elif e.keycode == KEY_TAB: toggle_inv()
		elif e.keycode == KEY_Q and inv.size() > 0: equip((eq + 1) % inv.size())
		elif e.keycode == KEY_M: toggle_map()
		elif e.keycode == KEY_R:
			if dead or win: get_tree().reload_current_scene()
			else: rage_096()
func _physics_process(delta: float) -> void:
	if dead or win: return
	MM.sync_player(self, player.global_position, player.rotation.y, my_role)
	if banner_t > 0.0: banner_t -= delta; if banner_t <= 0.0: ui["ban"].visible = false
	ui["hp_bar"].size.x = 236.0 * (float(hp) / float(max_hp)); ui["hp_txt"].text = "HP: %d / %d" % [hp, max_hp]
	ui["ar_bar"].size.x = 236.0 * (float(armor) / 100.0)
	if map_open: ui["pd"].position = to_map(player.global_position) - Vector2(4, 4)
	if boost > 0.0: boost -= delta; if boost <= 0.0 and my_role == 1: spotted_096 = false
	if windup_096 > 0.0: windup_096 -= delta; if windup_096 <= 0.0: boost = 10.0
	if r_cd > 0.0: r_cd -= delta
	if flash_a > 0.0: flash_a = maxf(0.0, flash_a - delta * 1.8)
	ui["fl"].color = Color(0.9, 0.05, 0.05, 0.35 if (my_role == 1 and boost > 0.0) else flash_a)

	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 2.5)
		cam.h_offset = randf_range(-0.08, 0.08) * shake; cam.v_offset = randf_range(-0.08, 0.08) * shake
	else: cam.h_offset = 0.0; cam.v_offset = 0.0

	wave_t -= delta
	if wave_t <= 0.0:
		wave_t = 45.0; var is_mtf := (randi() % 2 == 0); var spawn_k := 5 if is_mtf else 2
		spawn_bot(Vector3(312, 1.2, 12), spawn_k); spawn_bot(Vector3(324, 1.2, 12), spawn_k)
		show_banner("ПРИБЫЛО ПОДКРЕПЛЕНИЕ:\n" + ("ОТРЯД МОГ (Эпсилон-11)" if is_mtf else "ПОВСТАНЦЫ ХАОСА"), Color.DODGER_BLUE if is_mtf else Color.LIME_GREEN)

	ui["hint"].text = ""; ui["dot"].color = Color.WHITE
	if ray.is_colliding() and ray.get_collision_point().distance_to(head.global_position) < 4.5:
		var c := ray.get_collider() as Node
		if c != null:
			if c.has_meta("t"): ui["hint"].text = "[E] Взять: " + String(c.get_meta("t")); ui["dot"].color = Color.YELLOW
			elif c.has_meta("door_btn"):
				var dn := String(c.get_meta("door_btn"))
				ui["hint"].text = "[E] Кнопка: %s (Ур.%d)" % ["ЗАКРЫТЬ" if doors[dn]["open"] else "ОТКРЫТЬ", doors[dn]["req"]]; ui["dot"].color = Color.LIME_GREEN
			elif c.name.begins_with("LIFT"): ui["hint"].text = "[E] Лифт"; ui["dot"].color = Color.SPRING_GREEN
			elif c.name == "ESCAPE": ui["hint"].text = "[E] ВЫЙТИ / СБЕЖАТЬ"; ui["dot"].color = Color.LIME

	watched_173 = false
	for m: Node3D in mobs:
		if my_role == 8: m.wh.visible = m.alive and m.velocity.length() > 0.3
		if my_role <= 1 and m.alive and m.kind >= 2 and m.kind <= 5 and not m.npc_blink:
			var me: Vector3 = m.global_position + Vector3(0, 0.7, 0); var pe: Vector3 = head.global_position
			if me.distance_to(pe) < 18.0 and (-m.global_transform.basis.z).dot((pe - me).normalized()) > 0.62 and m.has_los(me, pe, [m, player]):
				if my_role == 0: watched_173 = true
				elif my_role == 1: spotted_096 = true; m.wh.visible = true

	var held := String(inv[eq]["id"]) if eq >= 0 else ""
	muzzle.visible = false
	if firing and held == "MicroHID":
		if chg < 1.2: chg += delta; shake = 0.1
		else:
			beam.visible = true; muzzle.visible = true; shake = 0.2
			if ray.is_colliding() and ray.get_collider() in mobs: ray.get_collider().hit(1500.0 * delta)
	elif firing and (held == "Pistol" or held == "Rifle" or held == "Shotgun") and r_cd <= 0.0:
		r_cd = 0.7 if held == "Shotgun" else (0.25 if held == "Pistol" else 0.14)
		WG.play("shot"); muzzle.visible = true; shake = 0.35 if held == "Shotgun" else 0.18
		var hit_p: Vector3 = ray.get_collision_point() if ray.is_colliding() else (head.global_position - head.global_transform.basis.z * 24.0)
		spawn_tracer(hand.global_position, hit_p, Color.ORANGE_RED if held == "Shotgun" else Color.GOLD)
		if ray.is_colliding() and ray.get_collider() in mobs:
			ray.get_collider().hit(140.0 if held == "Shotgun" else (30.0 if held == "Pistol" else 45.0))
	else: beam.visible = false

	if my_role <= 1 or my_role >= 6: blink = false; ui["bl"].visible = false
	elif blink: b_d -= delta; if b_d <= 0.0: blink = false; ui["bl"].visible = false
	else: b_t -= delta; if b_t <= 0.0: blink = true; b_d = 0.3; ui["bl"].visible = true; b_t = 7.0

	var r_labels := {0: "SCP-173", 1: "SCP-096", 2: "ХАОС", 3: "D-КЛАСС", 4: "УЧЁНЫЙ", 5: "МОГ", 6: "SCP-049", 8: "SCP-939"}
	var st_txt := "ЗАМЕР (СМОТРЯТ)" if (my_role == 0 and watched_173) else ("МОРГАНИЕ: %.1fс" % b_t if (my_role >= 2 and my_role <= 5) else "Готов")
	ui["inf"].text = "[%s] Высадка: %dс | %s | %s" % [r_labels[my_role], int(wave_t), st_txt, inv[eq]["t"] if eq >= 0 else "Руки"]

	if not player.is_on_floor(): player.velocity.y -= 9.8 * delta
	var kb := Vector2(int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)), int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W)))
	var dir := (player.transform.basis * Vector3((kb + move_vec).limit_length(1.0).x, 0, (kb + move_vec).limit_length(1.0).y)).normalized()
	var leg_f := clampf(limbs["legs"] / 100.0, 0.45, 1.0)
	var spd := ((0.0 if watched_173 else 9.8) if my_role == 0 else ((11.5 if boost > 0.0 else (0.0 if windup_096 > 0.0 else 5.2)) if my_role == 1 else (8.4 if my_role == 8 else (9.2 if (Input.is_key_pressed(KEY_SHIFT) or touch_sprint) else 6.2)))) * leg_f
	player.velocity.x = dir.x * spd; player.velocity.z = dir.z * spd; player.move_and_slide()

	if dir.length() > 0.1 and spd > 0.1:
		bob_t += delta * spd * 1.8
		hand.position = Vector3(0.32 + cos(bob_t * 0.5) * 0.02, -0.25 + abs(sin(bob_t)) * 0.025, -0.55)

	for m: Node3D in mobs:
		var res: int = m.step(delta, player, cam, blink, mobs, my_role, WG.nodes, loot, corpses)
		if res == 1: hp = 0
		elif res == 2: dmg_body(12); WG.play("shot"); flash_a = 0.45; shake = 0.25
		elif res == 3: WG.play("shy"); shake = 0.3
		elif res == 4: WG.play("cure")
		elif res == 5: dmg_body(25); WG.play("shot"); flash_a = 0.45; shake = 0.25
		if hp <= 0:
			dead = true; ui["inf"].text = "ВЫ ПОГИБЛИ!"; ui["rst"].visible = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			on_mob_died(player.global_position, my_role, 1, held, 0)

func use_ray() -> void:
	if not ray.is_colliding() or inv_open or map_open or (my_role == 0 and watched_173) or ray.get_collision_point().distance_to(head.global_position) > 4.5: return
	var obj := ray.get_collider() as Node
	if obj == null: return
	if my_role == 6:
		for c in corpses:
			if c["active"] and c["node"] == obj:
				c["active"] = false; c["node"].queue_free(); spawn_zombie(player.global_position + Vector3(1.2, 0, 0)); return
	if obj.name == "LIFT_HCZ": tp(Vector3(216, 1.2, 4)); return
	elif obj.name == "LIFT_LCZ": tp(Vector3(24, 1.2, 4)); return
	elif obj.name == "LIFT_SURF": tp(Vector3(348, 1.2, 4)); return
	elif obj.name == "LIFT_EZ": tp(Vector3(144, 1.2, 4)); return
	if obj.has_meta("door_btn"):
		var dn := String(obj.get_meta("door_btn")); var lvl := 11 if (my_role <= 1 or my_role >= 6) else -1
		if lvl < 0 and eq >= 0 and String(inv[eq]["id"]).begins_with("C"):
			for c in cards_db:
				if c["id"] == inv[eq]["id"]: lvl = c["l"]
		toggle_door(dn, lvl); return
	if obj.name == "ESCAPE":
		if my_role <= 1 or my_role >= 6:
			win = true; ui["inf"].text = "ПОБЕДА SCP! ВЫ ВЫБРАЛИСЬ НА ПОВЕРХНОСТЬ!"; ui["rst"].visible = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; return
		elif my_role == 3 or my_role == 4:
			var was_sci := (my_role == 4); my_role = 5 if was_sci else 2; max_hp = 150; hp = 150; armor = 80; inv.clear()
			inv.append({"id": "C8", "t": "Командир МОГ [Ур.8]", "c": Color.BLUE}); inv.append({"id": "Rifle", "t": "Автомат E-11", "c": Color.DARK_SLATE_GRAY}); inv.append({"id": "Medkit", "t": "Аптечка (+50)", "c": Color.RED})
			equip(1); player.global_position = Vector3(324, 1.2, 12); WG.play("pick")
			show_banner("ВЫ СБЕЖАЛИ!\nНОВАЯ РОЛЬ: " + ("КОМАНДИР МОГ" if was_sci else "ПОВСТАНЕЦ ХАОСА"), Color.DODGER_BLUE if was_sci else Color.LIME_GREEN); return
	if my_role <= 1 or my_role >= 6: return
	if obj.has_meta("id") and inv.size() < 8:
		inv.append({"id": obj.get_meta("id"), "t": obj.get_meta("t"), "c": obj.get_meta("c")}); loot.erase(obj); obj.queue_free(); equip(inv.size() - 1); WG.play("pick")
	elif obj.name == "914_KNOB": mode914 = "Very Fine" if mode914 == "Fine" else "Fine"; WG.play("door")
	elif obj.name == "914_IN" and eq >= 0 and String(inv[eq]["id"]).begins_with("C"): in914 = inv[eq]; inv.remove_at(eq); equip(inv.size() - 1); WG.play("pick")
	elif obj.name == "914_GO" and not in914.is_empty():
		var idx: int = mini(cards_db.size() - 1, int(String(in914["id"]).substr(1)) + (2 if mode914 == "Very Fine" else 1))
		in914.clear(); add_card(cards_db[idx]["id"], Vector3(-9.2, 0.5, 10.5)); WG.play("door")

func toggle_door(nm: String, lvl: int) -> void:
	if doors.has(nm):
		var d = doors[nm]
		if lvl >= d["req"]: d["open"] = !d["open"]; d["node"].position = d["open_pos"] if d["open"] else d["closed_pos"]; WG.play("door")
		elif lvl >= 0: WG.play("deny")

func bot_open_door(nm: String, lvl: int) -> void:
	if doors.has(nm) and not doors[nm]["open"] and lvl >= doors[nm]["req"]:
		doors[nm]["open"] = true; doors[nm]["node"].position = doors[nm]["open_pos"]; WG.play("door")

func tp(p: Vector3) -> void:
	player.global_position = p; WG.play("door")
	for m: Node3D in mobs:
		if m.alive and (m.kind == my_role or ((my_role <= 1 or my_role >= 6) and (m.kind <= 1 or m.kind >= 6))) and m.global_position.distance_to(player.global_position) < 120.0: m.global_position = p + Vector3(1.5, 0, 0)

@rpc("any_peer", "unreliable")
func recv_pos(id: int, pos: Vector3, rot: float, _role: int) -> void:
	if MM.net_players.has(id) and is_instance_valid(MM.net_players[id]):
		MM.net_players[id].global_position = pos; MM.net_players[id].rotation.y = rot
