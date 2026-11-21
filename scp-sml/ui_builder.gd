class_name UIBuilder
extends Node

static func build_all(root: Node3D) -> Dictionary:
	var ui := CanvasLayer.new()
	root.add_child(ui)

	var blink_rect := ColorRect.new()
	blink_rect.color = Color.BLACK
	blink_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	blink_rect.visible = false
	blink_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(blink_rect)

	var dot := ColorRect.new()
	dot.size = Vector2(6, 6)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dot)

	var info_label := Label.new()
	info_label.position = Vector2(20, 20)
	info_label.add_theme_font_size_override("font_size", 20)
	ui.add_child(info_label)

	var inv_panel := Control.new()
	inv_panel.set_anchors_preset(Control.PRESET_CENTER)
	inv_panel.visible = false
	ui.add_child(inv_panel)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.1, 0.8)
	bg.size = Vector2(440, 440)
	bg.position = Vector2(-220, -220)
	inv_panel.add_child(bg)

	var inv_slots: Array[Button] = []
	for i in range(8):
		var angle: float = (TAU / 8.0) * i - PI * 0.5
		var btn := Button.new()
		btn.size = Vector2(120, 46)
		btn.position = Vector2(cos(angle) * 145.0 - 60.0, sin(angle) * 145.0 - 23.0)
		btn.text = "[Пусто]"
		var idx: int = i
		btn.pressed.connect(func(): root.call("select_slot", idx))
		inv_panel.add_child(btn)
		inv_slots.append(btn)

	move_btn(ui, root, "W", Vector2(100, -220), Vector2(0, -1))
	move_btn(ui, root, "S", Vector2(100, -100), Vector2(0, 1))
	move_btn(ui, root, "A", Vector2(25, -160), Vector2(-1, 0))
	move_btn(ui, root, "D", Vector2(175, -160), Vector2(1, 0))
	act_btn(ui, "USE (E)", Vector2(-145, -100), func(): root.call("interact"))
	act_btn(ui, "BLINK", Vector2(-145, -175), func(): root.call("start_blink"))
	act_btn(ui, "INV (TAB)", Vector2(-145, -250), func(): root.call("toggle_inv"))

	var fire_b := Button.new()
	fire_b.text = "FIRE / ЮЗ"
	fire_b.size = Vector2(125, 65)
	fire_b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fire_b.position = Vector2(-280, -100)
	fire_b.button_down.connect(func(): root.call("set_firing", true))
	fire_b.button_up.connect(func(): root.call("set_firing", false))
	ui.add_child(fire_b)

	var restart_btn := Button.new()
	restart_btn.text = "ЗАНОВО (R)"
	restart_btn.size = Vector2(200, 80)
	restart_btn.set_anchors_preset(Control.PRESET_CENTER)
	restart_btn.visible = false
	restart_btn.pressed.connect(func(): root.call("restart_game"))
	ui.add_child(restart_btn)

	return {
		"blink": blink_rect, "info": info_label,
		"inv_panel": inv_panel, "slots": inv_slots, "restart": restart_btn
	}

static func act_btn(ui: Node, txt: String, pos: Vector2, cb: Callable) -> void:
	var b := Button.new()
	b.text = txt
	b.size = Vector2(125, 65)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.position = pos
	b.pressed.connect(cb)
	ui.add_child(b)

static func move_btn(ui: Node, root: Node3D, txt: String, pos: Vector2, dir: Vector2) -> void:
	var b := Button.new()
	b.text = txt
	b.size = Vector2(65, 65)
	b.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	b.position = pos
	b.button_down.connect(func(): root.move_vec += dir)
	b.button_up.connect(func(): root.move_vec -= dir)
	ui.add_child(b)
