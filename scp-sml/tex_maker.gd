class_name TexMaker
extends Node

static func wall_mat() -> StandardMaterial3D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.12
	for y in range(128):
		for x in range(128):
			var n := noise.get_noise_2d(x, y) * 0.08
			var col := Color(0.36 + n, 0.38 + n, 0.42 + n)
			# Жёлто-чёрная полоса безопасности внизу стены
			if y > 102 and y < 114:
				col = Color(0.85, 0.65, 0.1) if ((x / 16 + y / 16) % 2 == 0) else Color(0.12, 0.12, 0.14)
			elif y % 64 == 0 or x % 64 == 0:
				col = col.darkened(0.25)
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.35, 0.35, 0.35)
	mat.roughness = 0.85
	return mat

static func floor_mat() -> StandardMaterial3D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.2
	for y in range(128):
		for x in range(128):
			var n := noise.get_noise_2d(x, y) * 0.05
			var col := Color(0.2 + n, 0.22 + n, 0.25 + n)
			# Швы плитки и точки противоскольжения
			if x % 32 == 0 or y % 32 == 0:
				col = Color(0.08, 0.09, 0.11)
			elif (x % 16 == 8 and y % 16 == 8):
				col = col.lightened(0.18)
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	mat.metallic = 0.25
	mat.roughness = 0.55
	return mat

static func door_mat(tint: Color) -> StandardMaterial3D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var c := tint
			if x < 4 or x > 59 or y < 4 or y > 59 or (y > 29 and y < 34):
				c = c.darkened(0.45)
			elif (x + y) % 8 == 0:
				c = c.lightened(0.08)
			img.set_pixel(x, y, c)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.metallic = 0.6
	mat.roughness = 0.35
	return mat
