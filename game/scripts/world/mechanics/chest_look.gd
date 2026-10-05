class_name ChestLook
extends RefCounted
## Shared chest model for real chests and Mimics (so a Mimic looks exactly like the real thing).


static func build(parent: Node3D) -> void:
	var base := Kit.mesh_instance(parent, RoundMesh.box(Vector3(1.5, 0.8, 1.0), 0.12), Kit.mat(&"wood_warm", 0.03), Vector3(0.0, 0.4, 0.0))
	base.name = "Base"
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0.0, 0.8, -0.5)
	parent.add_child(lid)
	Kit.mesh_instance(lid, RoundMesh.box(Vector3(1.55, 0.45, 1.05), 0.18), Kit.mat(&"wood_plank", 0.03), Vector3(0.0, 0.2, 0.5))
	for x: float in [-0.55, 0.55]:
		var band := BoxMesh.new()
		band.size = Vector3(0.12, 1.3, 1.1)
		Kit.mesh_instance(parent, band, Kit.mat(&"gold"), Vector3(x, 0.62, 0.0))
	var lock := BoxMesh.new()
	lock.size = Vector3(0.25, 0.3, 0.1)
	Kit.mesh_instance(parent, lock, Kit.mat(&"gold", 0.02), Vector3(0.0, 0.75, 0.52))
