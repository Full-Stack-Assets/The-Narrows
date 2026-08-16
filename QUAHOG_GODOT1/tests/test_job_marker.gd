extends RefCounted

const JobMarkerRuntime = preload("res://scripts/world/job_marker.gd")


static func run(t: SceneTree) -> void:
	var target := Node3D.new()
	var marker := JobMarkerRuntime.new()
	marker.radius = 10.0
	marker.target = target
	marker._build(Color.GOLD)
	var beam := marker.get_child(0) as MeshInstance3D
	var ring := marker.get_child(1) as MeshInstance3D
	t.assert_true(beam.mesh is CylinderMesh, "objective beacon uses a bounded cylinder")
	t.assert_true(
		(beam.mesh as CylinderMesh).bottom_radius <= 1.15,
		"objective beacon never expands to the interaction radius"
	)
	t.assert_eq(
		(ring.mesh as TorusMesh).outer_radius,
		10.0,
		"ground ring still communicates the full interaction radius"
	)
	marker.free()
	target.free()
