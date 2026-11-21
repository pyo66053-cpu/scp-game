class_name NavAgent
extends RefCounted

var stuck_t := 0.0; var last_pos := Vector3.ZERO

func get_smart_dir(me: CharacterBody3D, delta: float, kind: int, card_lvl: int, mobs: Array) -> Vector3:
	if me.global_position.distance_to(last_pos) < 0.25: stuck_t += delta
	else: stuck_t = 0.0; last_pos = me.global_position

	var goal := Vector3(300, 0, 12)
	if kind == 3 or kind == 4:
		if me.global_position.x < 100.0:
			goal = Vector3(24, 0, -4) if card_lvl >= 3 else (Vector3(36, 0, 0) if card_lvl < 1 else Vector3(48, 0, 48))
		elif me.global_position.x < 270.0:
			goal = Vector3(144, 0, -4) if card_lvl >= 8 else (Vector3(144, 0, 12) if me.global_position.x < 180.0 else Vector3(204, 0, 0))
	elif kind == 2 or kind == 5:
		goal = Vector3(348, 0, 16) if me.global_position.x > 270.0 else Vector3(36, 0, 12)
	else:
		goal = Vector3(36, 0, 24) if me.global_position.x < 100.0 else Vector3(180, 0, 12)

	var next_p := bfs_step(me.global_position, goal)
	if stuck_t > 1.0:
		stuck_t = 0.0
		var keys := WorldGrid.graph.keys()
		if not keys.is_empty(): next_p = keys[randi() % keys.size()]

	var move_d := Vector3(next_p.x - me.global_position.x, 0, next_p.z - me.global_position.z).normalized()
	move_d = avoid_walls(me, move_d)

	var sep := Vector3.ZERO
	for m: Node3D in mobs:
		if m != me and is_instance_valid(m) and m.alive:
			var diff := me.global_position - m.global_position; diff.y = 0.0
			var dist := diff.length()
			if dist > 0.01 and dist < 1.5:
				sep += diff.normalized() * ((1.5 - dist) / 1.5) * 1.2
	return (move_d + sep).normalized()

func avoid_walls(me: CharacterBody3D, dir: Vector3) -> Vector3:
	if dir.length() < 0.1: return dir
	var space := me.get_world_3d().direct_space_state
	var origin := me.global_position + Vector3(0, 0.5, 0)
	var fwd := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + dir * 1.4, 1, [me]))
	if fwd.is_empty(): return dir
	var left_d := dir.rotated(Vector3.UP, 0.85)
	var right_d := dir.rotated(Vector3.UP, -0.85)
	var l_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + left_d * 1.5, 1, [me]))
	if l_hit.is_empty(): return left_d
	var r_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + right_d * 1.5, 1, [me]))
	if r_hit.is_empty(): return right_d
	return -dir

func bfs_step(from_p: Vector3, to_p: Vector3) -> Vector3:
	var g: Dictionary = WorldGrid.graph
	if g.is_empty(): return to_p
	var s_n := Vector3.ZERO; var e_n := Vector3.ZERO; var ds := 99999.0; var de := 99999.0
	for k: Vector3 in g.keys():
		var d1 := Vector2(from_p.x, from_p.z).distance_to(Vector2(k.x, k.z))
		if d1 < ds: ds = d1; s_n = k
		var d2 := Vector2(to_p.x, to_p.z).distance_to(Vector2(k.x, k.z))
		if d2 < de: de = d2; e_n = k
	if ds > 2.2: return s_n
	if s_n == e_n: return to_p
	var q := [s_n]; var came := {s_n: s_n}; var idx := 0
	while idx < q.size():
		var cur: Vector3 = q[idx]; idx += 1
		if cur == e_n: break
		for nxt: Vector3 in g[cur]:
			if not came.has(nxt): came[nxt] = cur; q.append(nxt)
	if not came.has(e_n): return to_p
	var step_n := e_n
	while came[step_n] != s_n: step_n = came[step_n]
	return step_n
