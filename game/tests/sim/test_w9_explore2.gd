extends TestCase

func test_tail() -> void:
	var d := Dino.new()
	d.species = &"longneck"
	d.model_scale = 1.1
	d.clip = &""
	d.posed_bones = ["Tail1", "Tail2", "Tail3", "Tail4", "Tail5"]
	add_child(d)
	await ticks(2)
	for spec: Array in [[18.0, 18.0], [12.0, 20.0], [8.0, 22.0], [4.0, 22.0], [0.0, 24.0]]:
		var a1 := deg_to_rad(spec[0] as float)
		var a2 := deg_to_rad(spec[1] as float)
		d.aim_chain(["Tail1", "Tail2"], Vector3(0.0, -sin(a1), -cos(a1)))
		# continue the rest of the chain at a2 (aim_chain resets bends of listed bones only)
		d.aim_chain(["Tail3", "Tail4", "Tail5"], Vector3(0.0, -sin(a2), -cos(a2)))
		var skin := d.skin_points()
		var pts := Dino.ridge_points(skin, -2.0, -30.0, 2.0)
		var line := ""
		var maxs := 0.0
		for i in pts.size() - 1:
			var s := rad_to_deg(atan2(pts[i].y - pts[i + 1].y, absf(pts[i].z - pts[i + 1].z)))
			maxs = maxf(maxs, s)
			line += "%.0f:%.1f(%.0f) " % [pts[i].z, pts[i].y, s]
		print("aim %s max %.0f: %s tip %.2f" % [str(spec), maxs, line, pts[pts.size() - 1].y])
	d.queue_free()
