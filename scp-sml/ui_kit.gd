class_name UIKit
extends Node

static func create_ui(root: Node3D, nodes: Array[Dictionary]) -> Dictionary:
	var ui := CanvasLayer.new(); root.add_child(ui)
	var blink := ColorRect.new(); blink.color = Color.BLACK; blink.set_anchors_preset(Control.PRESET_FULL_RECT)
	blink.visible = false; blink.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(blink)

	var dot := ColorRect.new(); dot.size = Vector2(6, 6); dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(dot)

	var info := Label.new(); info.position = Vector2(20, 20); info.add_theme_font_size_override("font_size", 20); ui.add_child(info)

	# Круговой инвентарь
	var inv := Control.new(); inv.set_anchors_preset(Control.PRESET_CENTER); inv.visible = false; ui.add_child(inv)
	var bg := ColorRect.new(); bg.color = Color(0.05, 0.07, 0.1, 0.85); bg.size = Vector2(440, 440); bg.position = Vector2(-220, -220); inv.add_child(bg)

	var slots: Array[Button] = []
	for i in range(8):
		var a: float = (TAU / 8.0) * i - PI * 0.5
		var b := Button.new(); b.size = Vector2(125, 46); b.position = Vector2(cos(a) * 145.0 - 62.0, sin(a) * 145.0 - 23.0)
		b.text = "[Пусто]"; var idx := i
		b.pressed.connect(func(): root.call("pick_slot", idx)); inv.add_child(b); slots.append(b)

	# Планшет комплекса (точная копия схемы со скриншота)
	var map_panel := Control.new(); map_panel.set_anchors_preset(Control.PRESET_CENTER); map_panel.visible = false; ui.add_child(map_panel)
	var mbg := ColorRect.new(); mbg.color = Color(0.03, 0.08, 0.11, 0.94); mbg.size = Vector2(620, 400); mbg.position = Vector2(-310, -200); map_panel.add_child(mbg)
	add_txt(map_panel, "SURFACE ZONE", Vector2(-260, -175)); add_txt(map_panel, "LIGHT CONTAINMENT ZONE", Vector2(40, -175))
	add_txt(map_panel, "ENTRANCE ZONE", Vector2(-240, 15)); add_txt(map_panel, "HEAVY CONTAINMENT ZONE", Vector2(50, 15))

	for nd in nodes:
		var mp := world_to_map(nd["pos"])
		draw_rect_at(map_panel, mp, Vector2(10, 10), Color(0.32, 0.5, 0.62))
		if nd["n"]: draw_rect_at(map_panel, mp + Vector2(0, -10), Vector2(6, 12), Color(0.28, 0.45, 0.55))
		if nd["s"]: draw_rect_at(map_panel, mp + Vector2(0, 10), Vector2(6, 12), Color(0.28, 0.45, 0.55))
		if nd["w"]: draw_rect_at(map_panel, mp + Vector2(-10, 0), Vector2(12, 6), Color(0.28, 0.45, 0.55))
		if nd["e"]: draw_rect_at(map_panel, mp + Vector2(10, 0), Vector2(12, 6), Color(0.28, 0.45, 0.55))

	var p_dot := ColorRect.new(); p_dot.size = Vector2(8, 8); p_dot.color = Color(1.0, 0.9, 0.1); map_panel.add_child(p_dot)

	m_btn(ui, root, "W", Vector2(95, -210), Vector2(0, -1)); m_btn(ui, root, "S", Vector2(95, -95), Vector2(0, 1))
	m_btn(ui, root, "A", Vector2(25, -152), Vector2(-1, 0)); m_btn(ui, root, "D", Vector2(165, -152), Vector2(1, 0))
	a_btn(ui, "USE (E)", Vector2(-140, -95), func(): root.call("use_ray"))
	a_btn(ui, "BLINK", Vector2(-140, -168), func(): root.call("do_blink"))
	a_btn(ui, "INV (TAB)", Vector2(-140, -241), func(): root.call("toggle_inv"))
	a_btn(ui, "MAP (M)", Vector2(-140, -314), func(): root.call("toggle_map"))

	var fb := Button.new(); fb.text = "ОГОНЬ / ЮЗ"; fb.size = Vector2(130, 62); fb.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fb.position = Vector2(-280, -95); fb.button_down.connect(func(): root.call("set_fire", true)); fb.button_up.connect(func(): root.call("set_fire", false)); ui.add_child(fb)

	var rst := Button.new(); rst.text = "ЗАНОВО (R)"; rst.size = Vector2(200, 80); rst.set_anchors_preset(Control.PRESET_CENTER)
	rst.visible = false; rst.pressed.connect(func(): root.call("restart")); ui.add_child(rst)

	return {"blink": blink, "info": info, "inv": inv, "slots": slots, "rst": rst, "map": map_panel, "p_dot": p_dot}

static func draw_rect_at(p: Node, center: Vector2, sz: Vector2, col: Color) -> void:
	var r := ColorRect.new(); r.size = sz; r.color = col; r.position = center - sz * 0.5; p.add_child(r)

static func world_to_map(wp: Vector3) -> Vector2:
	if wp.x < 100.0:
		return Vector2(65.0 + (wp.x / 14.0) * 26.0, -135.0 + (wp.z / 14.0) * 26.0)
	elif wp.x < 300.0:
		return Vector2(-210.0 + ((wp.x - 150.0) / 14.0) * 26.0, 55.0 + (wp.z / 14.0) * 26.0)
	else:
		return Vector2(-220.0 + ((wp.x - 350.0) / 14.0) * 26.0, -120.0 + (wp.z / 14.0) * 26.0)

static func add_txt(parent: Node, t: String, pos: Vector2) -> void:
	var l := Label.new(); l.text = t; l.position = pos; l.modulate = Color(0.6, 0.85, 0.95); parent.add_child(l)

static func a_btn(ui: Node, t: String, p: Vector2, cb: Callable) -> void:
	var b := Button.new(); b.text = t; b.size = Vector2(120, 62); b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); b.position = p; b.pressed.connect(cb); ui.add_child(b)

static func m_btn(ui: Node, root: Node3D, t: String, p: Vector2, d: Vector2) -> void:
	var b := Button.new(); b.text = t; b.size = Vector2(62, 62); b.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); b.position = p
	b.button_down.connect(func(): root.move_vec += d); b.button_up.connect(func(): root.move_vec -= d); ui.add_child(b)
