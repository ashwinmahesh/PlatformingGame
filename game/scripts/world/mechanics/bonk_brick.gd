class_name BonkBrick
extends AnimatableBody3D
## World 8 (Brickbloom Heights): a chunky brick floating at head height. Jump into it from below
## (or Plunge onto it) and it bonks: a seed brick pops its hidden Glimmer Seed out of the top and
## goes dull, a crumbly brick bursts into bits, and a switch brick fires `bonked` for puzzles.
## Seed bricks glint now and then (the cue); a Star Rush bowls straight through crumbly ones.
## `position` is the centre of the brick's top face, like Kit.block.

signal bonked

enum Kind { PLAIN, BREAK, SEED, SWITCH }

var kind: Kind = Kind.PLAIN
var size: Vector3 = Vector3(2.4, 2.4, 2.4)
var color_name: StringName = &"roof_red"
var used: bool = false
var _cool: int = 0
var _last_id: int = -1
var _visual: Node3D
var _body: MeshInstance3D
var _seed: Pickup
var _t: float = 0.0


## Mortar lines over every side and the top of a box of size `s` (its top centre at the
## origin), as one mesh: courses `course` metres high (half the box by default), bricks twice as
## long, every other course offset. (No static cache: the test runner frees every resource.)
static func mortar_mesh(s: Vector3, course: float = -1.0, top: bool = true) -> Mesh:
	if course <= 0.0:
		course = s.y * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var t := 0.09
	var out := 0.03
	var courses := maxi(int(round(s.y / course)), 1)
	var ch := s.y / courses
	for face in 4:
		var turn := Basis(Vector3.UP, face * PI * 0.5)
		var w := s.x if face % 2 == 0 else s.z
		var d := (s.z if face % 2 == 0 else s.x) * 0.5 + out
		var bricks := maxi(int(round(w / (ch * 2.0))), 1)
		var bl := w / bricks
		for k in courses:
			var y0 := -k * ch
			if k > 0:
				_bar(st, turn, Vector3(0.0, y0, d), Vector3(w * 0.98, t, t))
			var shift := 0.5 if k % 2 == 1 else 0.0
			for j in range(1, bricks + 1):
				var x := -w * 0.5 + (j - shift) * bl
				if x <= -w * 0.5 + 0.2 or x >= w * 0.5 - 0.2:
					continue
				_bar(st, turn, Vector3(x, y0 - ch * 0.5, d), Vector3(t, ch - 0.04, t))
	if top:
		_bar(st, Basis(), Vector3(0.0, out, 0.0), Vector3(s.x * 0.98, t, t))
		_bar(st, Basis(), Vector3(0.0, out, 0.0), Vector3(t, t, s.z * 0.98))
	return st.commit()


static func _bar(st: SurfaceTool, turn: Basis, at: Vector3, box: Vector3) -> void:
	var bm := BoxMesh.new()
	bm.size = box
	st.append_from(bm, 0, Transform3D(turn, turn * at))


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	sync_to_physics = false
	var b := BoxShape3D.new()
	b.size = size
	Kit.add_shape(self, b, Vector3(0.0, -size.y * 0.5, 0.0))
	_visual = Node3D.new()
	add_child(_visual)
	_body = Kit.mesh_instance(_visual, RoundMesh.box(size, 0.18), Kit.unique_mat(color_name, 0.03), Vector3(0.0, -size.y * 0.5, 0.0))
	Kit.mesh_instance(_visual, mortar_mesh(size), Kit.mat(&"cloth_cream"))
	if kind == Kind.SWITCH:
		var disc := CylinderMesh.new()
		disc.top_radius = size.x * 0.22
		disc.bottom_radius = size.x * 0.22
		disc.height = 0.1
		for face in 4:
			var basis := Basis(Vector3.UP, face * PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
			var dm := Kit.mesh_instance(_visual, disc, Kit.mat(&"cloth_cream", 0.02), Basis(Vector3.UP, face * PI * 0.5) * Vector3(0.0, -size.y * 0.5, size.z * 0.5 + 0.06))
			dm.basis = basis
	var area := Area3D.new()
	area.collision_layer = Layers.ENEMY_HURTBOX
	area.monitoring = false
	area.set_meta(&"actor", self)
	var hb := BoxShape3D.new()
	hb.size = size + Vector3.ONE * 0.3
	Kit.add_shape(area, hb, Vector3(0.0, -size.y * 0.5, 0.0))
	add_child(area)


## Hide a seed inside (World 8 seed bricks). It stays switched off until the brick is bonked.
func hold(p: Pickup) -> void:
	if p == null:
		used = true
		_set_color(&"bark_mid")
		return
	kind = Kind.SEED
	_seed = p
	p.process_mode = Node.PROCESS_MODE_DISABLED
	p.visible = false
	p.global_position = global_position + Vector3.DOWN * size.y * 0.5


func set_color(c: StringName) -> void:
	color_name = c
	_set_color(c)


func _set_color(c: StringName) -> void:
	if _body == null:
		return
	(_body.material_override as ShaderMaterial).set_shader_parameter(&"cell", Vector2(Palette.cell(c)))


func _physics_process(delta: float) -> void:
	if _cool > 0:
		_cool -= 1
	if kind == Kind.SEED and not used:
		_t += delta
		if _t > 1.4:
			_t = 0.0
			Fx.burst(get_parent(), global_position + Vector3(0.0, 0.2, 0.0), Palette.color(&"gold"), 3, 0.8, 0.07, 1.0, 0.6)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null or _cool > 0:
		return
	var to := p.global_position - global_position
	if absf(to.x) > size.x + 1.0 or absf(to.z) > size.z + 1.0 or to.y > 0.0 or to.y < -size.y - 3.0:
		return
	for i in p.get_slide_collision_count():
		var c := p.get_slide_collision(i)
		if c.get_collider() == self and c.get_normal().y < -0.5:
			bonk()
			return


## Hit from below (or from above with a Plunge).
func bonk() -> void:
	if _cool > 0:
		return
	_cool = 20
	var t := create_tween()
	t.tween_property(_visual, "position:y", 0.35, 0.08).set_trans(Tween.TRANS_SINE)
	t.tween_property(_visual, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_BOUNCE)
	AudioDirector.play(&"boss_bonk", -6.0, 1.5)
	match kind:
		Kind.BREAK:
			_break()
		Kind.SEED:
			if not used:
				used = true
				_release_seed()
				_set_color(&"bark_mid")
	bonked.emit()


func _release_seed() -> void:
	if _seed == null or not is_instance_valid(_seed):
		return
	var p := _seed
	_seed = null
	p.process_mode = Node.PROCESS_MODE_INHERIT
	p.visible = true
	p.global_position = global_position + Vector3.UP * 0.2
	var tw := p.create_tween()
	tw.tween_property(p, "global_position", global_position + Vector3.UP * 1.3, 0.25).set_trans(Tween.TRANS_BACK)
	AudioDirector.play(&"seed", -6.0, 1.3)
	Fx.burst(get_parent(), global_position + Vector3.UP * 0.6, Palette.color(&"gold"), 14, 3.5, 0.09, -3.0, 0.6)


func _break() -> void:
	if not is_inside_tree():
		return
	AudioDirector.play(&"coconut_break", -3.0, 1.3)
	Fx.burst(get_parent(), global_position + Vector3.DOWN * size.y * 0.5, Palette.color(color_name), 18, 5.0, 0.22, -14.0, 0.8)
	Fx.burst(get_parent(), global_position + Vector3.DOWN * size.y * 0.5, Palette.color(&"cloth_cream"), 8, 4.0, 0.12, -12.0, 0.6)
	if _seed != null:
		_release_seed()
	collision_layer = 0
	queue_free()


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	var k := StringName(str(atk.get("kind", "")))
	if k == &"plunge":
		_cool = 0
		bonk()
		return {"hit": true, "bounce": 3.5}
	if k == &"rush" and kind in [Kind.BREAK, Kind.SEED]:
		if kind == Kind.SEED and not used:
			used = true
			_release_seed()
			_set_color(&"bark_mid")
		elif kind == Kind.BREAK:
			_break()
		return {"hit": true}
	if kind == Kind.SWITCH and k != &"":
		_cool = 0
		bonk()
		return {"hit": true}
	return {}
