extends RefCounted
class_name DistrictAuthoring

const MANIFEST_PATH := "res://data/world/new_bedford_core.json"


static func load_manifest(path: String = MANIFEST_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null:
		return {}
	var parsed: Variant = JSON.parse_string(source.get_as_text())
	return parsed if parsed is Dictionary else {}


static func validate_manifest(manifest: Dictionary, require_assets: bool = true) -> PackedStringArray:
	var errors := PackedStringArray()
	if str(manifest.get("id", "")).is_empty():
		errors.append("missing district id")
	var bounds: Dictionary = manifest.get("bounds", {})
	var minimum: Array = bounds.get("min", [])
	var maximum: Array = bounds.get("max", [])
	if minimum.size() != 2 or maximum.size() != 2:
		errors.append("bounds must contain two-dimensional min/max coordinates")
		return errors

	var seen_ids: Dictionary = {}
	for section in [
		"hero_overrides",
		"facade_profiles",
		"facade_placements",
		"prop_zones",
		"interior_entrances",
		"ambience_zones",
		"mission_anchors",
	]:
		var entries: Variant = manifest.get(section, [])
		if not entries is Array:
			errors.append("%s must be an array" % section)
			continue
		for entry in entries:
			if not entry is Dictionary:
				errors.append("%s contains a non-object entry" % section)
				continue
			var entry_id := str(entry.get("id", ""))
			if entry_id.is_empty():
				errors.append("%s contains an empty id" % section)
			elif seen_ids.has(entry_id):
				errors.append("duplicate id: %s" % entry_id)
			else:
				seen_ids[entry_id] = true
			if entry.has("position"):
				_validate_position(entry["position"], minimum, maximum, entry_id, errors)
			if entry.has("entrance"):
				_validate_position(entry["entrance"], minimum, maximum, "%s entrance" % entry_id, errors)
			var asset := str(entry.get("asset", ""))
			if require_assets and not asset.is_empty() and not ResourceLoader.exists(asset):
				errors.append("missing asset: %s" % asset)
			if section == "interior_entrances":
				if float(entry.get("radius", 0.0)) < 1.2:
					errors.append("inaccessible entrance radius: %s" % entry_id)
				if float(entry.get("approach_width", 0.0)) < 1.2:
					errors.append("inaccessible approach width: %s" % entry_id)
			if section == "prop_zones":
				for prop in entry.get("props", []):
					if not prop is Dictionary:
						errors.append("%s contains an invalid prop" % entry_id)
						continue
					var prop_id := str(prop.get("id", ""))
					if prop_id.is_empty() or seen_ids.has(prop_id):
						errors.append("duplicate or empty prop id: %s" % prop_id)
					else:
						seen_ids[prop_id] = true
					_validate_position(prop.get("position", []), minimum, maximum, prop_id, errors)
					var prop_asset := str(prop.get("asset", ""))
					if require_assets and not prop_asset.is_empty() and not ResourceLoader.exists(prop_asset):
						errors.append("missing asset: %s" % prop_asset)

	var anchors: Array = manifest.get("mission_anchors", [])
	for i in range(anchors.size()):
		for j in range(i + 1, anchors.size()):
			var a: Dictionary = anchors[i]
			var b: Dictionary = anchors[j]
			var ap := _vector3(a.get("position", []))
			var bp := _vector3(b.get("position", []))
			if ap.distance_to(bp) < float(a.get("radius", 0.0)) + float(b.get("radius", 0.0)):
				errors.append("overlapping mission anchors: %s/%s" % [a.get("id", ""), b.get("id", "")])

	var variants: Dictionary = manifest.get("visual_variants", {})
	for kind in ["pedestrians", "vehicles"]:
		var paths: Array = variants.get(kind, [])
		if paths.size() < 3:
			errors.append("%s requires at least three visual variants" % kind)
		for path in paths:
			if require_assets and not ResourceLoader.exists(str(path)):
				errors.append("missing visual variant: %s" % path)
	return errors


static func build(parent: Node3D, manifest: Dictionary = {}) -> Node3D:
	var root := build_core(parent, manifest)
	if root == null:
		return null
	if manifest.is_empty():
		manifest = load_manifest()
	if populate_dressing(root, manifest) == null:
		return null
	return root


static func build_core(parent: Node3D, manifest: Dictionary = {}) -> Node3D:
	if manifest.is_empty():
		manifest = load_manifest()
	var errors := validate_manifest(manifest, false)
	if not errors.is_empty():
		push_error("District core manifest rejected: %s" % "; ".join(errors))
		return null

	var root := Node3D.new()
	root.name = "NewBedfordAuthoredCore"
	root.add_to_group("authored_district")
	parent.add_child(root)

	var materials: Dictionary = {}
	for profile in manifest.get("facade_profiles", []):
		var material_path := str(profile["asset"])
		if ResourceLoader.exists(material_path):
			materials[str(profile["id"])] = load(material_path)
	for placement in manifest.get("facade_placements", []):
		_build_facade(root, placement, materials.get(str(placement["profile"])))
	for hero in manifest.get("hero_overrides", []):
		match str(hero.get("kind", "")):
			"bethel":
				_build_bethel(root, hero, materials)
			"working_pier":
				_build_pier(root, hero, materials)
	for anchor in manifest.get("mission_anchors", []):
		var marker := Node3D.new()
		marker.name = "Anchor_%s" % str(anchor["id"]).to_pascal_case()
		marker.position = _vector3(anchor["position"])
		marker.set_meta("mission_anchor_id", anchor["id"])
		marker.set_meta("radius", anchor["radius"])
		root.add_child(marker)
	_build_route_lighting(root)
	return root


static func populate_dressing(
	root: Node3D,
	manifest: Dictionary = {},
	require_all_assets: bool = true
) -> Node3D:
	if root == null:
		return null
	var existing := root.get_node_or_null("DeferredDressing") as Node3D
	if existing:
		return existing
	if manifest.is_empty():
		manifest = load_manifest()
	var errors := validate_manifest(manifest, require_all_assets)
	if not errors.is_empty():
		push_error("District dressing manifest rejected: %s" % "; ".join(errors))
		return null
	var dressing := Node3D.new()
	dressing.name = "DeferredDressing"
	root.add_child(dressing)
	for zone in manifest.get("prop_zones", []):
		for prop in zone.get("props", []):
			_build_prop(dressing, prop)
	for zone in manifest.get("ambience_zones", []):
		_build_ambience(dressing, zone)
	return dressing


static func populate_deferred_models(root: Node3D, manifest: Dictionary = {}) -> Node3D:
	if root == null:
		return null
	if manifest.is_empty():
		manifest = load_manifest()
	var errors := validate_manifest(manifest)
	if not errors.is_empty():
		push_error("District deferred models rejected: %s" % "; ".join(errors))
		return null
	var dressing := root.get_node_or_null("DeferredDressing") as Node3D
	if dressing == null:
		dressing = Node3D.new()
		dressing.name = "DeferredDressing"
		root.add_child(dressing)
	for zone in manifest.get("prop_zones", []):
		for prop in zone.get("props", []):
			if str(prop.get("kind", "")) != "model":
				continue
			var prop_name := str(prop.get("id", "")).to_pascal_case()
			if dressing.find_child(prop_name, true, false) == null:
				_build_prop(dressing, prop)
	return dressing


static func _validate_position(
	value: Variant,
	minimum: Array,
	maximum: Array,
	label: String,
	errors: PackedStringArray
) -> void:
	if not value is Array or value.size() != 3:
		errors.append("invalid position: %s" % label)
		return
	var x := float(value[0])
	var z := float(value[2])
	if x < float(minimum[0]) or x > float(maximum[0]) or z < float(minimum[1]) or z > float(maximum[1]):
		errors.append("position outside district bounds: %s" % label)


static func _vector3(value: Variant) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO


static func _box(
	parent: Node3D,
	name: String,
	size: Vector3,
	position: Vector3,
	material: Material,
	collision: bool = false
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = position
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	if collision:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.position = position
		body.add_child(shape)
		parent.add_child(body)
	return mesh_instance


static func _build_facade(root: Node3D, placement: Dictionary, material: Material) -> void:
	var position := _vector3(placement["position"])
	var size := _vector3(placement["size"])
	position.y += size.y * 0.5
	var building := _box(root, str(placement["id"]).to_pascal_case(), size, position, material, true)
	var window_material := _material(
		Color(0.08, 0.18, 0.22),
		0.3,
		Color(0.2, 0.3, 0.3),
		0.12
	)
	var trim := _material(Color(0.72, 0.69, 0.59), 0.84)
	var floor_count := maxi(1, int(size.y / 3.0))
	var column_count := clampi(int(size.x / 3.6), 2, 5)
	for floor_index in range(floor_count):
		for column_index in range(column_count):
			var x := (
				-float(column_count - 1) * 1.55
				+ float(column_index) * 3.1
			)
			var y := -size.y * 0.38 + float(floor_index) * 2.7
			_box(
				building,
				"WindowTrim",
				Vector3(1.65, 1.25, 0.16),
				Vector3(x, y, size.z * 0.505),
				trim
			)
			var pane := _box(
				building,
				"Window",
				Vector3(1.34, 0.96, 0.2),
				Vector3(x, y, size.z * 0.516),
				window_material
			)
			pane.add_to_group("facade_emissive")
	_box(
		building,
		"Cornice",
		Vector3(size.x + 0.7, 0.35, size.z + 0.4),
		Vector3(0.0, size.y * 0.49, 0.0),
		trim
	)
	_box(
		building,
		"StreetDoor",
		Vector3(1.8, 2.45, 0.25),
		Vector3(0.0, -size.y * 0.5 + 1.23, size.z * 0.516),
		_material(Color(0.11, 0.09, 0.075), 0.68)
	)


static func _build_bethel(root: Node3D, hero: Dictionary, materials: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "SeamensBethel"
	hub.position = _vector3(hero["position"])
	root.add_child(hub)
	var granite: Material = materials.get("granite")
	var clapboard: Material = materials.get("clapboard")
	var slate := _material(Color(0.075, 0.105, 0.13), 0.78)
	var trim := _material(Color(0.86, 0.84, 0.73), 0.82)
	var door_material := _material(Color(0.24, 0.055, 0.035), 0.62)
	var glass := _material(Color(0.12, 0.25, 0.30), 0.28, Color(0.18, 0.34, 0.38), 0.32)
	var brass := _material(Color(0.52, 0.34, 0.10), 0.38)

	# A pale stone forecourt separates the landmark from the streamed asphalt and
	# gives the opening objective a readable pedestrian approach in every light.
	_box(hub, "Forecourt", Vector3(23.0, 0.18, 31.0), Vector3(0.0, 0.09, 2.0), granite, true)
	_box(hub, "Nave", Vector3(16.0, 8.2, 22.0), Vector3(0.0, 4.2, 0.0), clapboard, true)
	_box(hub, "GraniteFoundation", Vector3(16.6, 1.1, 22.6), Vector3(0.0, 0.55, 0.0), granite)

	# One solid gable avoids the disconnected roof bars from the blockout while
	# keeping the colonial Bethel silhouette legible at mobile scale.
	var roof := MeshInstance3D.new()
	roof.name = "SlateGableRoof"
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(17.8, 4.1, 23.4)
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, 10.2, 0.0)
	roof.material_override = slate
	hub.add_child(roof)

	_box(hub, "FrontPediment", Vector3(12.4, 0.55, 0.8), Vector3(0.0, 8.0, 11.4), trim)
	_box(hub, "BellTower", Vector3(5.4, 7.2, 5.4), Vector3(0.0, 11.1, 6.1), clapboard)
	_box(hub, "BelfryCap", Vector3(6.4, 0.7, 6.4), Vector3(0.0, 14.7, 6.1), trim)
	var belfry_roof := MeshInstance3D.new()
	belfry_roof.name = "BelfryRoof"
	var belfry_mesh := PrismMesh.new()
	belfry_mesh.size = Vector3(7.1, 2.6, 7.1)
	belfry_roof.mesh = belfry_mesh
	belfry_roof.position = Vector3(0.0, 16.3, 6.1)
	belfry_roof.material_override = slate
	hub.add_child(belfry_roof)

	# Symmetrical colonial frontage: individual windows, pilasters, steps, and a
	# deep red entrance read as architecture instead of one unscaled box.
	for x in [-5.3, 5.3]:
		_box(hub, "Pilaster", Vector3(0.55, 7.7, 0.5), Vector3(x, 4.1, 11.28), trim)
		for y in [2.5, 5.8]:
			_box(hub, "WindowTrim", Vector3(2.25, 2.35, 0.28), Vector3(x * 0.74, y, 11.25), trim)
			_box(hub, "WindowGlass", Vector3(1.72, 1.82, 0.34), Vector3(x * 0.74, y, 11.42), glass)
			_box(hub, "WindowMullion", Vector3(0.12, 1.82, 0.38), Vector3(x * 0.74, y, 11.62), trim)
			_box(hub, "WindowMullion", Vector3(1.72, 0.12, 0.38), Vector3(x * 0.74, y, 11.62), trim)
	_box(hub, "DoorTrim", Vector3(3.65, 5.05, 0.35), Vector3(0.0, 2.65, 11.3), trim)
	_box(hub, "Entrance", Vector3(2.8, 4.35, 0.45), Vector3(0.0, 2.35, 11.55), door_material)
	_box(hub, "DoorTransom", Vector3(2.35, 0.62, 0.5), Vector3(0.0, 4.55, 11.62), glass)
	_box(hub, "DoorHandle", Vector3(0.12, 0.12, 0.18), Vector3(0.85, 2.3, 11.86), brass)
	for step in range(3):
		_box(
			hub,
			"GraniteStep",
			Vector3(5.6 + float(step) * 0.75, 0.28, 1.0),
			Vector3(0.0, 0.14 + float(step) * 0.23, 12.4 + float(step) * 0.62),
			granite,
			true
		)

	for x in [-2.35, 2.35]:
		_add_warm_lantern(hub, Vector3(x, 4.2, 11.9))
	var label := Label3D.new()
	label.text = "SEAMEN'S BETHEL"
	label.font_size = 46
	label.pixel_size = 0.014
	label.position = Vector3(0.0, 7.15, 11.75)
	label.modulate = Color(0.88, 0.78, 0.48)
	label.outline_modulate = Color(0.04, 0.05, 0.06)
	label.outline_size = 8
	hub.add_child(label)


static func _build_pier(root: Node3D, hero: Dictionary, materials: Dictionary) -> void:
	var hub := Node3D.new()
	hub.name = "FishPier"
	hub.position = _vector3(hero["position"])
	root.add_child(hub)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.32, 0.23, 0.15)
	wood.roughness = 0.96
	var water := _material(Color(0.045, 0.18, 0.25, 0.94), 0.12)
	water.metallic = 0.34
	_box(hub, "HarborWater", Vector3(58.0, 0.22, 28.0), Vector3(0.0, -0.35, -15.0), water)
	_box(hub, "PierDeck", Vector3(38.0, 0.7, 15.0), Vector3(0.0, 0.35, 0.0), wood, true)
	var brick: Material = materials.get("brick")
	_box(hub, "PierShed", Vector3(12.0, 5.0, 7.0), Vector3(-8.0, 2.5, -2.0), brick)
	var shed_roof := MeshInstance3D.new()
	shed_roof.name = "PierShedRoof"
	var shed_roof_mesh := PrismMesh.new()
	shed_roof_mesh.size = Vector3(13.2, 2.2, 8.2)
	shed_roof.mesh = shed_roof_mesh
	shed_roof.position = Vector3(-8.0, 6.0, -2.0)
	shed_roof.material_override = _material(Color(0.08, 0.12, 0.15), 0.72)
	hub.add_child(shed_roof)
	var shed_trim := _material(Color(0.8, 0.74, 0.58), 0.82)
	var shed_glass := _material(Color(0.08, 0.26, 0.31), 0.26, Color(0.2, 0.38, 0.4), 0.25)
	for x in [-11.0, -5.0]:
		_box(hub, "PierWindowTrim", Vector3(2.3, 1.8, 0.25), Vector3(x, 2.8, 1.58), shed_trim)
		_box(hub, "PierWindow", Vector3(1.9, 1.4, 0.3), Vector3(x, 2.8, 1.75), shed_glass)
	_box(hub, "PierDoor", Vector3(2.3, 3.2, 0.32), Vector3(-8.0, 1.7, 1.75), _material(Color(0.1, 0.22, 0.24), 0.66))
	var pier_label := Label3D.new()
	pier_label.text = "NEW BEDFORD FISH PIER"
	pier_label.font_size = 38
	pier_label.pixel_size = 0.012
	pier_label.position = Vector3(-8.0, 5.15, 1.85)
	pier_label.modulate = Color(0.92, 0.76, 0.36)
	pier_label.outline_modulate = Color(0.04, 0.05, 0.06)
	pier_label.outline_size = 7
	hub.add_child(pier_label)
	var steel := _material(Color(0.22, 0.3, 0.32), 0.62)
	for x in [5.0, 14.0]:
		_box(hub, "HoistPost", Vector3(0.45, 7.5, 0.45), Vector3(x, 3.75, -1.0), steel)
	_box(hub, "HoistBeam", Vector3(10.0, 0.5, 0.5), Vector3(9.5, 7.2, -1.0), steel)
	_box(hub, "HoistHook", Vector3(0.18, 4.0, 0.18), Vector3(9.5, 5.0, -1.0), steel)
	for x in [-16.0, -8.0, 0.0, 8.0, 16.0]:
		for z in [-6.0, 6.0]:
			var post_material := StandardMaterial3D.new()
			post_material.albedo_color = Color(0.18, 0.13, 0.09)
			_box(hub, "Timber", Vector3(0.7, 2.2, 0.7), Vector3(x, -0.7, z), post_material)


static func _build_route_lighting(root: Node3D) -> void:
	var lighting := Node3D.new()
	lighting.name = "RouteLighting"
	root.add_child(lighting)
	var pole_material := _material(Color(0.12, 0.15, 0.17), 0.68)
	var bulb_material := _material(
		Color(0.9, 0.56, 0.22),
		0.32,
		Color(1.0, 0.44, 0.13),
		1.6
	)
	for index in range(4):
		var position: Vector3 = [
			Vector3(-280.0, 0.0, -76.0),
			Vector3(-318.0, 0.0, -68.0),
			Vector3(-248.0, 0.0, -114.0),
			Vector3(-308.0, 0.0, -56.0),
		][index]
		var fixture := Node3D.new()
		fixture.name = "RouteLamp%d" % (index + 1)
		fixture.position = position
		lighting.add_child(fixture)
		_box(fixture, "Pole", Vector3(0.18, 4.8, 0.18), Vector3(0.0, 2.4, 0.0), pole_material, true)
		_box(fixture, "Arm", Vector3(1.2, 0.14, 0.14), Vector3(0.52, 4.65, 0.0), pole_material)
		var bulb := _box(fixture, "Bulb", Vector3(0.28, 0.34, 0.28), Vector3(1.05, 4.42, 0.0), bulb_material)
		bulb.add_to_group("facade_emissive")
		var light := OmniLight3D.new()
		light.name = "RouteLight"
		light.position = Vector3(1.05, 4.25, 0.0)
		light.light_color = Color(1.0, 0.62, 0.34)
		light.light_energy = 2.0
		light.omni_range = 14.0
		light.shadow_enabled = false
		light.add_to_group("authored_streetlight")
		fixture.add_child(light)


static func _material(
	color: Color,
	roughness: float,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


static func _add_warm_lantern(root: Node3D, position: Vector3) -> void:
	var fixture := _box(
		root,
		"BethelLantern",
		Vector3(0.32, 0.48, 0.32),
		position,
		_material(Color(0.95, 0.58, 0.22), 0.32, Color(1.0, 0.43, 0.12), 1.8)
	)
	fixture.add_to_group("facade_emissive")
	var lamp := OmniLight3D.new()
	lamp.name = "LanternLight"
	lamp.position = position + Vector3(0.0, 0.0, 0.45)
	lamp.light_color = Color(1.0, 0.58, 0.30)
	lamp.light_energy = 1.4
	lamp.omni_range = 7.5
	lamp.shadow_enabled = false
	lamp.add_to_group("authored_lantern")
	root.add_child(lamp)


static func _build_prop(root: Node3D, prop: Dictionary) -> bool:
	var position := _vector3(prop["position"])
	match str(prop.get("kind", "")):
		"model":
			var asset_path := str(prop.get("asset", ""))
			if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
				return false
			var packed := load(asset_path) as PackedScene
			if packed:
				var model := packed.instantiate() as Node3D
				model.name = str(prop["id"]).to_pascal_case()
				model.position = position
				model.rotation_degrees.y = float(prop.get("yaw", 0.0))
				root.add_child(model)
		"crates":
			var crate_material := StandardMaterial3D.new()
			crate_material.albedo_color = Color(0.38, 0.24, 0.12)
			for i in range(5):
				_box(
					root,
					"FishCrate",
					Vector3(1.3, 0.8, 0.9),
					position + Vector3(float(i % 3) * 1.45, 0.4 + float(i / 3) * 0.85, float(i % 2) * 1.0),
					crate_material
				)
		"bollards":
			var bollard_material := StandardMaterial3D.new()
			bollard_material.albedo_color = Color(0.16, 0.17, 0.18)
			for offset in [-5.0, 0.0, 5.0]:
				var bollard := MeshInstance3D.new()
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.28
				cylinder.bottom_radius = 0.38
				cylinder.height = 1.2
				bollard.mesh = cylinder
				bollard.position = position + Vector3(offset, 0.6, 0.0)
				bollard.material_override = bollard_material
				root.add_child(bollard)
		"crosswalk":
			var paint := StandardMaterial3D.new()
			paint.albedo_color = Color(0.86, 0.84, 0.73)
			for offset in range(-4, 5, 2):
				_box(root, "CrosswalkStripe", Vector3(0.75, 0.04, 7.0), position + Vector3(offset, 0.08, 0.0), paint)
		"parking":
			var line := StandardMaterial3D.new()
			line.albedo_color = Color(0.75, 0.72, 0.56)
			for offset in [-6.0, -2.0, 2.0, 6.0]:
				_box(root, "ParkingLine", Vector3(0.12, 0.04, 5.0), position + Vector3(offset, 0.08, 0.0), line)
		"sign":
			var post := StandardMaterial3D.new()
			post.albedo_color = Color(0.2, 0.22, 0.24)
			_box(root, "SignPost", Vector3(0.15, 3.0, 0.15), position + Vector3(0.0, 1.5, 0.0), post)
			var label := Label3D.new()
			label.text = str(prop.get("label", ""))
			label.position = position + Vector3(0.0, 3.2, 0.0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 30
			label.pixel_size = 0.018
			root.add_child(label)
	return true


static func _build_ambience(root: Node3D, zone: Dictionary) -> void:
	var asset_path := str(zone.get("asset", ""))
	if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
		return
	var player := AudioStreamPlayer3D.new()
	player.name = str(zone["id"]).to_pascal_case()
	player.stream = load(asset_path)
	player.position = _vector3(zone["position"])
	player.max_distance = float(zone.get("radius", 30.0))
	player.volume_db = float(zone.get("volume_db", -18.0))
	player.autoplay = true
	player.bus = "Ambience" if AudioServer.get_bus_index("Ambience") >= 0 else "Master"
	root.add_child(player)
