
@tool
extends Node3D
class_name ObjectScatter

@export_group("Scatter Settings")
@export var objects: Array[PackedScene] = []
@export_range(1, 1000, 1) var object_count: int = 100
@export var area_size: Vector2 = Vector2(20, 20)
@export_range(0.0, 10.0, 0.1) var min_distance: float = 1.0

@export_group("Randomization")
@export var random_rotation: bool = true
@export var random_scale: bool = true
@export var scale_range: Vector2 = Vector2(0.8, 1.2)
@export var random_seed: int = 0

@export_tool_button("Generate Scatter") var generate_button = generate_scatter
@export_tool_button("Clear Scatter") var clear_button = clear_scatter


func generate_scatter() -> void:
	if objects.is_empty():
		push_warning("Masukkan minimal satu PackedScene.")
		return

	var scene_root = get_tree().edited_scene_root
	if scene_root == null:
		return

	clear_scatter()

	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed if random_seed != 0 else Time.get_ticks_usec()

	var container = Node3D.new()
	container.name = "ScatterGenerated"
	add_child(container)
	container.owner = scene_root

	var positions: Array[Vector3] = []
	var attempts = 0
	var max_attempts = object_count * 20

	while positions.size() < object_count and attempts < max_attempts:
		attempts += 1

		var pos = Vector3(
			rng.randf_range(-area_size.x / 2.0, area_size.x / 2.0),
			0.0,
			rng.randf_range(-area_size.y / 2.0, area_size.y / 2.0)
		)

		var valid = true

		for existing_pos in positions:
			if pos.distance_to(existing_pos) < min_distance:
				valid = false
				break

		if not valid:
			continue

		var packed_scene = objects[rng.randi_range(0, objects.size() - 1)]
		if packed_scene == null:
			continue

		var instance = packed_scene.instantiate()
		container.add_child(instance)
		instance.owner = scene_root
		instance.position = pos

		if random_rotation:
			instance.rotation.y = rng.randf_range(0.0, TAU)

		if random_scale:
			var scale_value = rng.randf_range(
				scale_range.x,
				scale_range.y
			)
			instance.scale = Vector3.ONE * scale_value

		positions.append(pos)

	print("Scatter selesai: ", positions.size(), " objek.")


func clear_scatter() -> void:
	var container = get_node_or_null("ScatterGenerated")

	if container:
		remove_child(container)
		container.free()
