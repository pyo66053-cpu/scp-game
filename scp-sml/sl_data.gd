class_name SLData
extends Node

const CARDS := [
	{"id": "Card0", "title": "Уборщик", "lvl": 0, "col": Color(0.9, 0.9, 0.9)},
	{"id": "Card1", "title": "Учёный", "lvl": 1, "col": Color(0.95, 0.85, 0.2)},
	{"id": "Card2", "title": "Науч. Рук.", "lvl": 2, "col": Color(0.95, 0.55, 0.15)},
	{"id": "Card3", "title": "Менеджер Зон", "lvl": 3, "col": Color(0.15, 0.85, 0.85)},
	{"id": "Card4", "title": "Охранник", "lvl": 4, "col": Color(0.55, 0.6, 0.65)},
	{"id": "Card5", "title": "Кадет МОГ", "lvl": 5, "col": Color(0.35, 0.7, 0.95)},
	{"id": "Card6", "title": "Инженер", "lvl": 6, "col": Color(0.55, 0.35, 0.2)},
	{"id": "Card7", "title": "Лейтенант МОГ", "lvl": 7, "col": Color(0.15, 0.45, 0.95)},
	{"id": "Card8", "title": "Командир МОГ", "lvl": 8, "col": Color(0.1, 0.22, 0.75)},
	{"id": "Card9", "title": "Менеджер Компл.", "lvl": 9, "col": Color(0.85, 0.15, 0.15)},
	{"id": "Card10", "title": "Хаос", "lvl": 10, "col": Color(0.15, 0.75, 0.25)},
	{"id": "Card11", "title": "Совет O5", "lvl": 11, "col": Color(0.12, 0.12, 0.15)}
]

static func get_lvl(id: String) -> int:
	for c in CARDS:
		if c["id"] == id: return int(c["lvl"])
	return -1

static func upgrade(id: String, mode: String) -> Dictionary:
	var lvl := get_lvl(id)
	if lvl < 0: return {}
	if mode == "Fine": lvl = min(11, lvl + 1)
	elif mode == "Very Fine": lvl = min(11, lvl + 2)
	return CARDS[lvl].duplicate()
