extends RefCounted

const DistrictAuthoringRuntime = preload("res://scripts/world/district_authoring.gd")


static func run(t: SceneTree) -> void:
	var manifest := DistrictAuthoringRuntime.load_manifest()
	t.assert_true(not manifest.is_empty(), "New Bedford district manifest loads")
	var errors := DistrictAuthoringRuntime.validate_manifest(manifest)
	t.assert_eq(errors.size(), 0, "district manifest has unique ids, valid paths, bounds, anchors, and entrances")

	t.assert_eq(manifest["hero_overrides"].size(), 2, "opening route authors exactly two hero overrides")
	t.assert_eq(manifest["facade_profiles"].size(), 4, "brick, granite, clapboard, and storefront profiles ship")
	t.assert_eq(manifest["interior_entrances"].size(), 2, "safehouse and business entrances ship")
	t.assert_eq(manifest["visual_variants"]["pedestrians"].size(), 3, "three pedestrian variants ship")
	t.assert_eq(manifest["visual_variants"]["vehicles"].size(), 3, "three vehicle variants ship")

	var parent := Node3D.new()
	var authored_core := DistrictAuthoringRuntime.build(parent, manifest)
	t.assert_true(authored_core != null, "validated district manifest builds an authored core")
	t.assert_true(authored_core.has_node("SeamensBethel"), "authored core builds the Bethel hero silhouette")
	t.assert_true(authored_core.has_node("FishPier"), "authored core builds the working fish pier")
	t.assert_true(authored_core.has_node("Anchor_AnchorOpenerSafehouse"), "authored core exposes mission anchors")
	t.assert_true(authored_core.has_node("RouteLighting"), "opening-route practical lighting ships in the core")
	t.assert_true(authored_core.has_node("DeferredDressing"), "full district build includes deferred dressing")
	var initial_dressing_count := authored_core.get_node("DeferredDressing").get_child_count()
	var completed_dressing := DistrictAuthoringRuntime.populate_deferred_models(authored_core, manifest)
	t.assert_eq(
		completed_dressing.get_child_count(),
		initial_dressing_count,
		"deferred model completion is idempotent when every model already exists"
	)
	t.assert_true(
		_has_collision_shape(authored_core.get_node("SeamensBethel")),
		"Bethel hero geometry has a collision boundary"
	)
	t.assert_true(
		_has_collision_shape(authored_core.get_node("FishPier")),
		"working pier deck has a collision boundary"
	)
	parent.free()

	var lightweight_parent := Node3D.new()
	var lightweight_core := DistrictAuthoringRuntime.build_core(lightweight_parent, manifest)
	t.assert_true(lightweight_core.has_node("SeamensBethel"), "bounded core renders Bethel before deferred content")
	t.assert_true(not lightweight_core.has_node("DeferredDressing"), "bounded core excludes deferred props and ambience")
	lightweight_parent.free()

	var reduced_manifest := manifest.duplicate(true)
	reduced_manifest["prop_zones"][0]["props"][1]["asset"] = "res://deferred/not-mounted.glb"
	var reduced_parent := Node3D.new()
	var reduced_core := DistrictAuthoringRuntime.build_core(reduced_parent, reduced_manifest)
	var reduced_dressing := DistrictAuthoringRuntime.populate_dressing(reduced_core, reduced_manifest, false)
	t.assert_true(reduced_dressing != null, "core dressing tolerates model assets that are still deferred")
	t.assert_true(
		reduced_dressing.find_child("PierBench", true, false) == null,
		"unmounted deferred models are skipped without placeholders or load errors"
	)
	reduced_parent.free()

	var ambience_kinds: Array[String] = []
	for zone in manifest["ambience_zones"]:
		ambience_kinds.append(str(zone["kind"]))
	ambience_kinds.sort()
	t.assert_eq(ambience_kinds, ["harbor", "interior", "street"], "harbor, street, and interior ambience zones ship")

	var duplicate := manifest.duplicate(true)
	duplicate["mission_anchors"][0]["id"] = duplicate["mission_anchors"][1]["id"]
	t.assert_true(
		_has_error(DistrictAuthoringRuntime.validate_manifest(duplicate), "duplicate id"),
		"duplicate manifest ids are rejected"
	)

	var outside := manifest.duplicate(true)
	outside["mission_anchors"][0]["position"] = [-999.0, 0.0, -999.0]
	t.assert_true(
		_has_error(DistrictAuthoringRuntime.validate_manifest(outside), "outside district bounds"),
		"coordinates outside the authored district are rejected"
	)

	var blocked_entrance := manifest.duplicate(true)
	blocked_entrance["interior_entrances"][0]["approach_width"] = 0.5
	t.assert_true(
		_has_error(DistrictAuthoringRuntime.validate_manifest(blocked_entrance), "inaccessible approach"),
		"inaccessible entrances are rejected"
	)

	var overlapping := manifest.duplicate(true)
	overlapping["mission_anchors"][1]["position"] = overlapping["mission_anchors"][0]["position"]
	t.assert_true(
		_has_error(DistrictAuthoringRuntime.validate_manifest(overlapping), "overlapping mission anchors"),
		"overlapping mission anchors are rejected"
	)


static func _has_error(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if fragment in error:
			return true
	return false


static func _has_collision_shape(root: Node) -> bool:
	if root is CollisionShape3D:
		return true
	for child in root.get_children():
		if _has_collision_shape(child):
			return true
	return false
