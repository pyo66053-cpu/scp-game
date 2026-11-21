class_name SoundFX
extends Node

static var players := {}

static func init_sounds(root: Node3D) -> void:
	players["door"] = make_p(root, tone(240.0, 680.0, 0.25, false), -8.0)
	players["deny"] = make_p(root, tone(150.0, 100.0, 0.25, true), -6.0)
	players["pickup"] = make_p(root, tone(540.0, 920.0, 0.14, false), -10.0)
	players["step"] = make_p(root, noise(0.07, 0.3), -18.0)
	players["shot"] = make_p(root, noise(0.09, 0.8), -8.0)
	players["hid"] = make_p(root, tone(95.0, 440.0, 0.4, true), -6.0)
	players["scream"] = make_p(root, noise(0.65, 1.0), -2.0)
	players["shy"] = make_p(root, tone(320.0, 880.0, 0.85, true), -3.0)

static func play(nm: String) -> void:
	if players.has(nm):
		var p: AudioStreamPlayer = players[nm]
		if not p.playing or (nm != "hid" and nm != "shy"):
			p.play()

static func make_p(root: Node3D, s: AudioStreamWAV, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.stream = s; p.volume_db = db; root.add_child(p); return p

static func tone(f1: float, f2: float, dur: float, sq: bool) -> AudioStreamWAV:
	var rate := 22050; var cnt := int(rate * dur); var data := PackedByteArray(); data.resize(cnt * 2); var ph := 0.0
	for i in range(cnt):
		var t := float(i) / float(cnt); ph += TAU * lerp(f1, f2, t) / float(rate)
		var s := sin(ph); if sq: s = 1.0 if s > 0.0 else -1.0
		data.encode_s16(i * 2, int(clamp(s * (1.0 - t) * 24000.0, -32767.0, 32767.0)))
	var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = rate; w.data = data; return w

static func noise(dur: float, pwr: float) -> AudioStreamWAV:
	var rate := 22050; var cnt := int(rate * dur); var data := PackedByteArray(); data.resize(cnt * 2)
	for i in range(cnt):
		var t := float(i) / float(cnt)
		data.encode_s16(i * 2, int(randf_range(-1.0, 1.0) * (1.0 - t) * pwr * 28000.0))
	var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = rate; w.data = data; return w
