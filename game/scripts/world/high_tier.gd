class_name HighTier
extends RefCounted
## Build 6 upper-tier pieces (Ashwin: "more verticality... a whole other world at higher levels").
## World coordinates throughout. Slopes stay under ~22 degrees so every way up is a walk.

## A walkway from a to b (deck-edge points, tops), with low rails you can't fall past.
static func bridge(parent: Node3D, a: Vector3, b: Vector3, width: float = 3.4, color: StringName = &"wood_plank", rails: bool = true, rail_color: StringName = &"bark_dark") -> Node3D:
	var holder := Node3D.new()
	holder.position = (a + b) * 0.5
	parent.add_child(holder)
	var d := b - a
	holder.basis = Basis.looking_at(d.normalized(), Vector3.UP)
	var length := d.length() + 0.6
	Kit.block(holder, Vector3.ZERO, Vector3(width, 0.5, length), color, Layers.WORLD | Layers.CAMERA_BLOCKER, &"")
	if rails:
		for side: float in [-1.0, 1.0]:
			Kit.block(holder, Vector3(side * (width * 0.5 - 0.12), 0.9, 0.0), Vector3(0.24, 0.9, length), rail_color, Layers.WORLD, &"")
	return holder


## A square spiral ramp round a solid core, from base_y up to a flat top at top_y (the core's
## top is the arrival landing). The way in is on the core's +Z/-X corner.
static func ramp_tower(parent: Node3D, center: Vector3, base_y: float, top_y: float, core: float = 8.0, width: float = 4.0, color: StringName = &"stone_light", lane_color: StringName = &"wood_plank", top_color: StringName = &"auto") -> void:
	Kit.block(parent, Vector3(center.x, top_y, center.z), Vector3(core, top_y - base_y, core), color, Layers.WORLD | Layers.CAMERA_BLOCKER, top_color)
	center.y = 0.0
	var h := core * 0.5 + width * 0.5
	var corners: Array[Vector3] = [Vector3(-h, 0.0, h), Vector3(h, 0.0, h), Vector3(h, 0.0, -h), Vector3(-h, 0.0, -h)]
	var side := 2.0 * h - width
	var max_rise := side * tan(deg_to_rad(20.0))
	var n := int(ceil((top_y - base_y) / max_rise))
	var rise := (top_y - base_y) / float(n)
	for k in n + 1:
		var y := base_y + rise * k
		var c := center + corners[k % 4] + Vector3(0.0, y, 0.0)
		Kit.block(parent, c, Vector3(width, 0.6 if k > 0 else 0.3, width), lane_color, Layers.WORLD | Layers.CAMERA_BLOCKER, &"")
		if k < n:
			var c2 := center + corners[(k + 1) % 4] + Vector3(0.0, y + rise, 0.0)
			var dir := (c2 - c) * Vector3(1.0, 0.0, 1.0)
			dir = dir.normalized()
			bridge(parent, c + dir * width * 0.5, c2 - dir * width * 0.5, width, lane_color, false)
			# Outer rail only (the core is the inner wall).
			var out := Vector3(dir.z, 0.0, -dir.x)
			if out.dot((c - center) * Vector3(1.0, 0.0, 1.0)) < 0.0:
				out = -out
			bridge(parent, c + dir * width * 0.5 + out * (width * 0.5 - 0.12) + Vector3.UP * 0.9, c2 - dir * width * 0.5 + out * (width * 0.5 - 0.12) + Vector3.UP * 0.9, 0.24, &"bark_dark", false)
	# A flat last lane along the next face, so you step straight off it onto the core's top.
	var last := center + corners[n % 4] + Vector3(0.0, top_y, 0.0)
	var nxt := center + corners[(n + 1) % 4] + Vector3(0.0, top_y, 0.0)
	Kit.block(parent, (last + nxt) * 0.5, Vector3(absf(nxt.x - last.x) + width, 0.6, absf(nxt.z - last.z) + width), lane_color, Layers.WORLD | Layers.CAMERA_BLOCKER, &"")


## A platform that rides straight up and down between base and top_y.
static func lift(parent: Node3D, base: Vector3, top_y: float, period: float = 7.0, color: StringName = &"wood_plank") -> MovingPlatform:
	var m := MovingPlatform.new()
	m.rounded = false
	m.size = Vector3(4.6, 0.8, 4.6)
	m.travel = Vector3(0.0, top_y - base.y, 0.0)
	m.period = period
	m.color_name = color
	m.position = base + Vector3.DOWN * 0.4
	parent.add_child(m)
	return m
