extends Control

static var refuse_scp := false
static var net_players := {}
var ip_edit: LineEdit; var status_lbl: Label; var refuse_btn: Button

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color(0.06, 0.07, 0.09); bg.set_anchors_preset(PRESET_FULL_RECT); add_child(bg)

	var box := VBoxContainer.new(); box.size = Vector2(440, 460); box.set_anchors_preset(PRESET_CENTER); box.position = Vector2(-220, -230); add_child(box)
	var title := Label.new(); title.text = "SCP: SECRET BREACH\nГЛАВНОЕ МЕНЮ"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28); box.add_child(title)

	add_btn(box, "НАЧАТЬ РАУНД (Одиночная)", func(): get_tree().change_scene_to_file("res://node_3d.tscn"))

	refuse_btn = add_btn(box, "ОТКАЗАТЬСЯ ОТ РОЛИ SCP: НЕТ", func():
		refuse_scp = !refuse_scp
		refuse_btn.text = "ОТКАЗАТЬСЯ ОТ РОЛИ SCP: " + ("ДА (Только люди)" if refuse_scp else "НЕТ")
	)

	var net_title := Label.new(); net_title.text = "\n--- СЕТЕВАЯ ИГРА (ОНЛАЙН) ---"; net_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(net_title)
	add_btn(box, "СОЗДАТЬ ХОСТИНГ СЕРВЕР (Порт 7777)", host_server)

	ip_edit = LineEdit.new(); ip_edit.text = "127.0.0.1"; ip_edit.placeholder_text = "Введи IP адрес сервера"; box.add_child(ip_edit)
	add_btn(box, "ПОДКЛЮЧИТЬСЯ К СЕРВЕРУ", join_server)

	status_lbl = Label.new(); status_lbl.text = "Готов к запуску"; status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(status_lbl)

func add_btn(p: Node, t: String, cb: Callable) -> Button:
	var b := Button.new(); b.text = t; b.custom_minimum_size = Vector2(0, 48); b.pressed.connect(cb); p.add_child(b); return b
func host_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(7777, 16) == OK:
		multiplayer.multiplayer_peer = peer
		status_lbl.text = "Сервер создан! Запуск раунда..."
		get_tree().change_scene_to_file("res://node_3d.tscn")
	else: status_lbl.text = "Ошибка запуска сервера (порт занят)"

func join_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip_edit.text.strip_edges(), 7777) == OK:
		multiplayer.multiplayer_peer = peer
		status_lbl.text = "Подключение к " + ip_edit.text + "..."
		multiplayer.connected_to_server.connect(func(): get_tree().change_scene_to_file("res://node_3d.tscn"))
	else: status_lbl.text = "Не удалось подключиться"

static func sync_player(root: Node3D, my_pos: Vector3, my_rot: float, role: int) -> void:
	if root.multiplayer.multiplayer_peer == null: return
	var my_id := root.multiplayer.get_unique_id()
	root.rpc("recv_pos", my_id, my_pos, my_rot, role)
	for pid in net_players.keys():
		if not is_instance_valid(net_players[pid]):
			var av := MeshInstance3D.new(); var cm := CapsuleMesh.new(); cm.radius = 0.35; cm.height = 1.8; av.mesh = cm
			var mt := StandardMaterial3D.new(); mt.albedo_color = Color.DODGER_BLUE if role >= 2 else Color.RED; av.material_override = mt
			root.add_child(av); net_players[pid] = av
