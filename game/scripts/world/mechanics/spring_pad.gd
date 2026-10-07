class_name SpringPad
extends Springcap
## World 8: a springy toy pad (KayKit Platformer spring pad) that works like a Springcap: land
## on it for a bounce, Plunge onto it to go much higher.

var colour: String = "red"


func _ready() -> void:
	look = Look.CLOUD
	super._ready()
	for c in _cap.get_children():
		if c is MeshInstance3D:
			c.queue_free()
	var path := "res://assets/models/kk_platformer/%s/spring_pad_%s.gltf" % [colour, colour]
	Models.fit(_cap, path, Vector3(0.0, 0.5, 0.0), Vector3(1.9, 1.2, 1.9))
