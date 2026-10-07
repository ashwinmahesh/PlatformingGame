class_name Dino
extends Node3D
## World 9 (Dinodew Jungle): a big gentle dinosaur (Quaternius Animated Dinosaur Bundle, CC0) that
## the hero climbs and rides. The model plays its own clips under the toon shader, recoloured
## from the palette. Chosen bones are posed in code instead of by the clip (a tail laid down as a
## ramp, a neck that bends to eat): those bones lose their clip tracks and take a model-space
## bend at their joint.
## What you stand on (moss carpets, saddles, plate steps) are separate kinematic bodies that follow
## their bone every physics tick, so the surface is always exactly where its mesh is drawn, and a
## rider inherits the dinosaur's motion. A Dino can walk a looped path and stop at stations.
## The clip is advanced by hand inside the physics tick so bones, surfaces and tests all agree.

const DIR := "res://assets/models/q_dinos/"
const MODELS: Dictionary[StringName, String] = {
	&"longneck": "Apatosaurus.glb", &"stego": "Stegosaurus.glb", &"trike": "Triceratops.glb",
	&"rex": "TRex.glb", &"honker": "Parasaurolophus.glb",
}

var species: StringName = &"longneck"
var model_scale: float = 1.0
## Source material name -> palette colour.
var colours: Dictionary[String, StringName] = {}
## Clip name suffix (Idle, Walk, Run, Attack, Jump, Death); &"" holds the rest pose.
var clip: StringName = &"Idle"
var clip_speed: float = 1.0
## How much of a clip's whole-body bob and sway to keep (1 = all of it, 0 = a steady body).
var calm: float = 1.0
## Bones posed by code (their clip tracks are dropped).
var posed_bones: Array[String] = []
var outline: float = 0.035
## Looping path (world positions on the ground), walked at `speed`; `stops` are
## (distance along the loop, seconds to wait).
var path: PackedVector3Array = []
var speed: float = 2.4
var stops: Array[Vector2] = []
var walk_clip: StringName = &"Walk"
var stop_clip: StringName = &"Idle"
var turn_rate: float = 2.5
## Distance along the loop and the stop being waited at (-1 while walking).
var travelled: float = 0.0
var waiting: int = -1
var wait_left: float = 0.0
var paused: bool = false

var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
## Skeleton-space bone transforms (own forward kinematics, so they never lag a frame).
var glob: Array[Transform3D] = []
var _order: Array[int] = []
var _to_local: Transform3D
var _rot: Basis
var _bends: Dictionary[int, Quaternion] = {}
var _posed: Dictionary[int, bool] = {}
var _clips: Dictionary[StringName, StringName] = {}
var _pieces: Array[Dictionary] = []
var _seg_len: PackedFloat32Array = []
var _loop_len: float = 0.0


func _ready() -> void:
	_setup_model()
	if not path.is_empty():
		_prepare_path()
		_place_on_path(true)
	tick(0.0)


func _setup_model() -> void:
	model = Models.instance(DIR + MODELS[species], outline)
	model.scale = Vector3.ONE * model_scale
	add_child(model)
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s)
			var key := src.resource_name if src != null else ""
			if colours.has(key):
				var m := (mi.get_surface_override_material(s) as ShaderMaterial).duplicate() as ShaderMaterial
				m.set_shader_parameter(&"albedo_color", Palette.color(colours[key]))
				mi.set_surface_override_material(s, m)
		# Big and moving: some slack so a swinging tail never pops out of view.
		mi.extra_cull_margin = 4.0
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	anim = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_to_local = _chain(self, skeleton)
	_rot = Basis(_to_local.basis.get_rotation_quaternion())
	for b in posed_bones:
		var i := skeleton.find_bone(b)
		if i >= 0:
			_posed[i] = true
	# Own copies of the clips: posed bones lose their tracks, the body bob is calmed.
	var lib := AnimationLibrary.new()
	for a in anim.get_animation_list():
		var src := anim.get_animation(a)
		var dup := src.duplicate(true) as Animation
		for t in range(dup.get_track_count() - 1, -1, -1):
			var bone := skeleton.find_bone(str(dup.track_get_path(t).get_concatenated_subnames()))
			if _posed.has(bone):
				dup.remove_track(t)
			elif bone >= 0 and skeleton.get_bone_name(bone) == "Body" and calm < 1.0:
				_calm_track(dup, t)
		var short := StringName(String(a).get_slice("_", String(a).get_slice_count("_") - 1))
		_clips[short] = StringName("w9/" + short)
		lib.add_animation(short, dup)
	anim.add_animation_library(&"w9", lib)
	var depth: Array[int] = []
	for b in skeleton.get_bone_count():
		var d := 0
		var p := skeleton.get_bone_parent(b)
		while p >= 0:
			d += 1
			p = skeleton.get_bone_parent(p)
		depth.append(d)
	for b in skeleton.get_bone_count():
		_order.append(b)
	_order.sort_custom(func(x: int, y: int) -> bool: return depth[x] < depth[y])
	glob.resize(skeleton.get_bone_count())
	play(clip, 0.0)


static func _chain(root: Node, n: Node) -> Transform3D:
	var x := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != root:
		if c is Node3D:
			x = (c as Node3D).transform * x
		c = c.get_parent()
	return x


func _calm_track(a: Animation, t: int) -> void:
	var n := a.track_get_key_count(t)
	if n < 2:
		return
	match a.track_get_type(t):
		Animation.TYPE_POSITION_3D:
			var mean := Vector3.ZERO
			for k in n:
				mean += a.track_get_key_value(t, k) as Vector3
			mean /= n
			for k in n:
				a.track_set_key_value(t, k, mean.lerp(a.track_get_key_value(t, k) as Vector3, calm))
		Animation.TYPE_ROTATION_3D:
			var first := a.track_get_key_value(t, 0) as Quaternion
			var sum := Quaternion(0.0, 0.0, 0.0, 0.0)
			for k in n:
				var q := a.track_get_key_value(t, k) as Quaternion
				if q.dot(first) < 0.0:
					q = -q
				sum = Quaternion(sum.x + q.x, sum.y + q.y, sum.z + q.z, sum.w + q.w)
			var mean := sum.normalized()
			for k in n:
				a.track_set_key_value(t, k, mean.slerp(a.track_get_key_value(t, k) as Quaternion, calm))


## Switches clip (by suffix: Idle, Walk, Run, Attack, Jump, Death); &"" holds still. A one-shot
## clip asked for again restarts.
func play(c: StringName, blend: float = 0.25, spd: float = -1.0) -> void:
	clip = c
	if spd > 0.0:
		clip_speed = spd
	if c == &"" or not _clips.has(c):
		anim.stop()
		return
	var full := _clips[c]
	var looping := c in [&"Idle", &"Walk", &"Run"]
	anim.get_animation(full).loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	if anim.current_animation != full:
		anim.play(full, blend)
	elif not looping:
		anim.seek(0.0, false)
	anim.speed_scale = clip_speed


## Seconds into the current clip, and its length.
func clip_time() -> float:
	return anim.current_animation_position if anim.is_playing() else 0.0


func clip_length() -> float:
	return anim.current_animation_length if anim.is_playing() else 0.0


## A model-space rotation (in this node's frame) applied at a posed bone's joint.
func bend(bone: String, q: Quaternion) -> void:
	var i := skeleton.find_bone(bone)
	assert(_posed.has(i), "Dino.bend needs %s in posed_bones" % bone)
	_bends[i] = q


func bend_pitch(bone: String, degrees: float) -> void:
	bend(bone, Quaternion(Vector3.RIGHT, deg_to_rad(degrees)))


## Poses a chain of posed bones so each segment points along `dir` (this node's frame); the
## last bone points along it too.
func aim_chain(bones: Array[String], dir: Vector3) -> void:
	dir = dir.normalized()
	for i in bones.size():
		var b := skeleton.find_bone(bones[i])
		assert(_posed.has(b), "Dino.aim_chain needs %s in posed_bones" % bones[i])
		_bends.erase(b)
		_solve()
		var head := (_to_local * glob[b]).origin
		var seg: Vector3
		if i + 1 < bones.size():
			seg = (_to_local * glob[skeleton.find_bone(bones[i + 1])]).origin - head
		else:
			seg = _to_local.basis * glob[b].basis.y
		_bends[b] = Quaternion(seg.normalized(), dir)
	_solve()


func bone_index(bone: String) -> int:
	return skeleton.find_bone(bone)


## A bone's transform in this node's local frame (includes the model scale).
func bone_local(bone: String) -> Transform3D:
	return _to_local * glob[skeleton.find_bone(bone)]


func bone_point(bone: String) -> Vector3:
	return global_transform * (_to_local * glob[skeleton.find_bone(bone)]).origin


# --- The tick ---------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not path.is_empty() and not paused:
		_walk(delta)
	if anim.is_playing():
		anim.advance(delta)
	_solve()
	for p in _pieces:
		var body := p["body"] as AnimatableBody3D
		var xf := global_transform * _to_local * glob[int(p["bone"])] * (p["local"] as Transform3D)
		body.global_transform = xf.orthonormalized()


## Forward kinematics from the clip's local poses, with code poses applied at their joints.
func _solve() -> void:
	for b in _order:
		var local: Transform3D
		if _posed.has(b):
			local = skeleton.get_bone_rest(b)
		else:
			local = skeleton.get_bone_pose(b)
		var parent := skeleton.get_bone_parent(b)
		var g := local if parent < 0 else glob[parent] * local
		if _bends.has(b):
			g.basis = (_rot.inverse() * Basis(_bends[b]) * _rot) * g.basis
			var l := g if parent < 0 else glob[parent].affine_inverse() * g
			skeleton.set_bone_pose_rotation(b, l.basis.get_rotation_quaternion())
			skeleton.set_bone_pose_position(b, l.origin)
		elif _posed.has(b):
			skeleton.set_bone_pose_rotation(b, local.basis.get_rotation_quaternion())
			skeleton.set_bone_pose_position(b, local.origin)
		glob[b] = g


# --- Riding surfaces ----------------------------------------------------------------------------

## A riding surface following `bone`: a box of `size` placed at `xf` (this node's frame, at the
## current pose). look: &"moss" carpet, &"saddle" planks, &"pad" plate step, &"skin" (no mesh: it
## matches the hide it sits in).
func add_piece(bone: String, xf: Transform3D, size: Vector3, look: StringName = &"moss", color: StringName = &"moss") -> AnimatableBody3D:
	var b := skeleton.find_bone(bone)
	var body := AnimatableBody3D.new()
	body.sync_to_physics = true
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.top_level = true
	body.name = "Ride_%s_%d" % [bone, _pieces.size()]
	body.transform = (global_transform * xf).orthonormalized()
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	Kit.add_shape(body, shape)
	match look:
		&"moss":
			Kit.mesh_instance(body, RoundMesh.box(size, minf(0.18, size.y * 0.45)), Kit.mat(color, 0.02, &"grass_light"))
		&"saddle":
			Kit.mesh_instance(body, RoundMesh.box(size, 0.08), Kit.mat(&"wood_plank", 0.02))
			for k in int(size.z / 0.9):
				Kit.mesh_instance(body, RoundMesh.box(Vector3(size.x + 0.04, 0.06, 0.08), 0.02), Kit.mat(&"bark_mid"), Vector3(0.0, size.y * 0.5, -size.z * 0.5 + 0.45 + k * 0.9))
		&"pad":
			var c := CylinderMesh.new()
			c.top_radius = size.x * 0.5
			c.bottom_radius = size.x * 0.46
			c.height = size.y
			Kit.mesh_instance(body, c, Kit.mat(color, 0.03))
	var local := (_to_local * glob[b]).affine_inverse() * xf
	_pieces.append({"body": body, "bone": b, "local": local})
	return body


## A flat carpet strip along a bone from a to b (this node's frame, on the skin top), `width`
## wide and `thick` thick; its underside rests on the highest skin under it.
func carpet(bone: String, a: Vector3, b: Vector3, width: float, thick: float = 0.35, look: StringName = &"moss", color: StringName = &"moss", skin: PackedVector3Array = PackedVector3Array()) -> AnimatableBody3D:
	if skin.is_empty():
		skin = skin_points()
	var mid := (a + b) * 0.5
	var dir := b - a
	var flat := Vector3(dir.x, 0.0, dir.z)
	var basis := Basis.looking_at(dir.normalized(), Vector3.UP) if flat.length() > 0.01 else Basis()
	var length := dir.length()
	var xf := Transform3D(basis, mid)
	# Lift the strip until nothing of the skin pokes through its underside.
	var inv := xf.affine_inverse()
	var lift := -INF
	for p in skin:
		var q := inv * p
		if absf(q.x) <= width * 0.5 and absf(q.z) <= length * 0.5:
			lift = maxf(lift, q.y)
	if lift == -INF:
		lift = 0.0
	xf.origin += basis.y * (lift + thick * 0.5)
	return add_piece(bone, xf, Vector3(width, thick, length), look, color)


## Carpet strips along the skin's top ridge from local z0 to z1, one strip per `step` metres,
## each tied to the bone (of the `chain`, listed head to tail of the chain) it lies along.
## Neighbouring strips share their end points, so the walk is one continuous surface with no
## lips, and each joint is lifted until no skin pokes up through a strip.
func ridge_carpets(z0: float, z1: float, step: float, width: float, chain: Array[String], look: StringName = &"moss", color: StringName = &"moss", thick: float = 0.35, skin: PackedVector3Array = PackedVector3Array()) -> Array[AnimatableBody3D]:
	var zs: Array[float] = []
	var n := maxi(int(ceil(absf(z1 - z0) / step)), 1)
	for i in n + 1:
		zs.append(lerpf(z0, z1, float(i) / n))
	return ridge_carpets_at(zs, width, chain, look, color, thick, skin)


## The same, through the ridge at the given local z positions (in walking order).
func ridge_carpets_at(zs: Array[float], width: float, chain: Array[String], look: StringName = &"moss", color: StringName = &"moss", thick: float = 0.35, skin: PackedVector3Array = PackedVector3Array()) -> Array[AnimatableBody3D]:
	if skin.is_empty():
		skin = skin_points()
	var tops: Array[Vector3] = []
	for z in zs:
		var pts := ridge_points(skin, z, z, 1.4)
		if not pts.is_empty():
			tops.append(pts[0] + Vector3.UP * thick)
	for pass_i in 4:
		for i in tops.size() - 1:
			var poke := _poke(skin, tops[i], tops[i + 1], width, thick)
			if poke > 0.001:
				tops[i].y += poke
				tops[i + 1].y += poke
	var out: Array[AnimatableBody3D] = []
	for i in tops.size() - 1:
		out.append(strip(nearest_bone((tops[i] + tops[i + 1]) * 0.5, chain), tops[i], tops[i + 1], width, thick, look, color))
	return out


## How far skin pokes up through the underside of a strip whose top runs from a to b.
static func _poke(skin: PackedVector3Array, a: Vector3, b: Vector3, width: float, thick: float) -> float:
	var dir := b - a
	var basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	var inv := Transform3D(basis, a).affine_inverse()
	var length := dir.length()
	var worst := 0.0
	for q in skin:
		var l := inv * q
		if absf(l.x) <= width * 0.5 and l.z <= 0.0 and -l.z <= length:
			worst = maxf(worst, l.y + thick)
	return worst


## A strip whose top surface runs exactly from a to b (this node's frame), slightly overlapping
## its neighbours at both ends.
func strip(bone: String, a: Vector3, b: Vector3, width: float, thick: float = 0.35, look: StringName = &"moss", color: StringName = &"moss") -> AnimatableBody3D:
	var dir := (b - a).normalized()
	var basis := Basis.looking_at(dir, Vector3.UP)
	var length := a.distance_to(b) + 0.2
	var xf := Transform3D(basis, (a + b) * 0.5 - basis.y * thick * 0.5)
	return add_piece(bone, xf, Vector3(width, thick, length), look, color)


## The skin's top ridge sampled every `step` metres along local z.
static func ridge_points(skin: PackedVector3Array, z0: float, z1: float, step: float) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var n := maxi(int(ceil(absf(z1 - z0) / step)), 1)
	for i in n + 1:
		var z := lerpf(z0, z1, float(i) / n)
		var best := Vector3(0.0, -INF, z)
		for q in skin:
			if absf(q.z - z) < step * 0.35 and q.y > best.y:
				best = q
		if best.y > -INF:
			pts.append(Vector3(best.x, best.y, z))
	return pts


## The bone of `chain` whose segment (to the next bone in the chain) passes closest to p.
func nearest_bone(p: Vector3, chain: Array[String]) -> String:
	var best := chain[0]
	var best_d := INF
	for i in chain.size():
		var b := skeleton.find_bone(chain[i])
		var a := (_to_local * glob[b]).origin
		var e: Vector3
		if i + 1 < chain.size():
			e = (_to_local * glob[skeleton.find_bone(chain[i + 1])]).origin
		else:
			e = a + (_to_local.basis * glob[b].basis.y).normalized() * 4.0 * model_scale
		var ab := e - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best_d:
			best_d = d
			best = chain[i]
	return best


## Every vertex of the skinned mesh at the current pose, in this node's frame (CPU skinning).
## `dense` adds points across every triangle (the low-poly rings are metres apart).
func skin_points(dense: bool = true) -> PackedVector3Array:
	var out := PackedVector3Array()
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var sk := mi.skin
		if sk == null:
			continue
		var to_local := _chain(self, mi)
		var mats: Array[Transform3D] = []
		for i in sk.get_bind_count():
			var bone := sk.get_bind_bone(i)
			if bone < 0:
				bone = skeleton.find_bone(sk.get_bind_name(i))
			mats.append(_to_local * glob[bone] * sk.get_bind_pose(i))
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bo: PackedInt32Array = arr[Mesh.ARRAY_BONES]
			var we: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
			var k := bo.size() / maxi(v.size(), 1)
			var posed := PackedVector3Array()
			for i in v.size():
				if k == 0:
					posed.append(to_local * v[i])
					continue
				var p := Vector3.ZERO
				for j in k:
					var w := we[i * k + j]
					if w > 0.0:
						p += (mats[bo[i * k + j]] * v[i]) * w
				posed.append(p)
			out.append_array(posed)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if dense:
				for t in range(0, idx.size() - 2, 3):
					var a := posed[idx[t]]
					var b := posed[idx[t + 1]]
					var c := posed[idx[t + 2]]
					var div := clampi(int(maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a))) / 0.6), 1, 8)
					for u in div + 1:
						for w in div + 1 - u:
							var fu := float(u) / div
							var fw := float(w) / div
							out.append(a * (1.0 - fu - fw) + b * fu + c * fw)
	return out


## Highest skin point within `r` (horizontally) of `p` (this node's frame); -INF if none.
static func skin_top(skin: PackedVector3Array, p: Vector3, r: float) -> float:
	var top := -INF
	for q in skin:
		if Vector2(q.x - p.x, q.z - p.z).length() <= r:
			top = maxf(top, q.y)
	return top


func pieces() -> Array[AnimatableBody3D]:
	var out: Array[AnimatableBody3D] = []
	for p in _pieces:
		out.append(p["body"] as AnimatableBody3D)
	return out


# --- Walking a loop -----------------------------------------------------------------------------

func _prepare_path() -> void:
	_seg_len.clear()
	_loop_len = 0.0
	for i in path.size():
		var d := path[i].distance_to(path[(i + 1) % path.size()])
		_seg_len.append(d)
		_loop_len += d


## Point and heading on the loop at distance d.
func path_at(d: float) -> Array:
	d = fposmod(d, _loop_len)
	for i in path.size():
		if d <= _seg_len[i] or i == path.size() - 1:
			var a := path[i]
			var b := path[(i + 1) % path.size()]
			var t := clampf(d / maxf(_seg_len[i], 0.001), 0.0, 1.0)
			return [a.lerp(b, t), (b - a).normalized()]
		d -= _seg_len[i]
	return [path[0], Vector3.FORWARD]


func loop_length() -> float:
	return _loop_len


## Puts it at distance d along its loop, facing along the path (for building around a stop).
func place_at(d: float) -> void:
	travelled = d
	_place_on_path(true)
	tick(0.0)


func _place_on_path(snap: bool) -> void:
	var at: Array = path_at(travelled)
	var dir := at[1] as Vector3
	global_position = at[0] as Vector3
	var want := atan2(dir.x, dir.z)
	if snap:
		rotation.y = want
		reset_physics_interpolation()


func _walk(delta: float) -> void:
	if waiting >= 0:
		wait_left -= delta
		if wait_left <= 0.0:
			waiting = -1
			play(walk_clip, 0.4)
		return
	var before := travelled
	travelled += speed * delta
	for i in stops.size():
		# The next time this stop comes round after `before`.
		var at_stop := floorf(before / _loop_len) * _loop_len + stops[i].x
		if at_stop <= before:
			at_stop += _loop_len
		if travelled >= at_stop:
			travelled = at_stop
			waiting = i
			wait_left = stops[i].y
			play(stop_clip, 0.4)
			break
	var at: Array = path_at(travelled)
	var dir := at[1] as Vector3
	global_position = at[0] as Vector3
	var want := atan2(dir.x, dir.z)
	rotation.y = rotate_toward(rotation.y, want, turn_rate * delta)
