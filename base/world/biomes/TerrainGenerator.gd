class_name TerrainGenerator
extends Node3D

@export_category("Biome System")
@export var biome_manager: BiomeManager

@export_category("Noise Sources")
## Controls macro-geography (Oceans vs. Plains vs. Mountains)
@export var continental_noise: FastNoiseLite
## Controls local surface bumps/detail
@export var detail_noise: FastNoiseLite

@export_category("Terrain Dimensions")
@export var terrain_size: Vector2i = Vector2i(64, 64)
@export var vertex_spacing: float = 1.0

@export_category("Scenery Spawning")
@export var scenery_container: Node3D
@export var scenery_density: float = 0.05

@export var force_rebuild: bool = false:
	set(val):
		if val:
			force_rebuild = false
			print("[TerrainGenerator] Button clicked! Attempting rebuild...")
			generate_terrain()

var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	print("[TerrainGenerator] _ready() called at runtime. Engine is editor: ", Engine.is_editor_hint())
	generate_terrain()


func generate_terrain() -> void:
	print("[TerrainGenerator] generate_terrain() called.")

	if biome_manager == null:
		print("[TerrainGenerator] STOPPED: biome_manager is NULL in Inspector!")
		return
		
	if biome_manager.biomes.is_empty():
		print("[TerrainGenerator] STOPPED: biomes array is EMPTY in BiomeManager!")
		return

	if continental_noise == null:
		print("[TerrainGenerator] STOPPED: continental_noise is NULL in Inspector!")
		return

	if detail_noise == null:
		print("[TerrainGenerator] STOPPED: detail_noise is NULL in Inspector!")
		return

	print("[TerrainGenerator] All checks passed. Building mesh...")
	_clear_scenery()
	_ensure_nodes_exist()
	_build_terrain_mesh()

func _build_terrain_mesh() -> void:
	_ensure_nodes_exist()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_x: float = (terrain_size.x * vertex_spacing) * 0.5
	var half_z: float = (terrain_size.y * vertex_spacing) * 0.5

	# 1. Add Vertices
	for z in range(terrain_size.y):
		for x in range(terrain_size.x):
			var local_x: float = (x * vertex_spacing) - half_x
			var local_z: float = (z * vertex_spacing) - half_z
			var world_pos := global_position + Vector3(local_x, 0, local_z)

			var cont_val := continental_noise.get_noise_2d(world_pos.x, world_pos.z)
			var biome := _get_biome_at_continental_value(cont_val)

			var height := detail_noise.get_noise_2d(world_pos.x, world_pos.z) * biome.height_scale
			var vertex_color := biome.terrain_color

			if biome.is_ocean:
				height = minf(height, biome.sea_level)

			st.set_color(vertex_color)
			var uv := Vector2(float(x) / float(terrain_size.x - 1), 1.0 - (float(z) / float(terrain_size.y - 1))) 
			st.set_uv(uv)
			st.add_vertex(Vector3(local_x, height, local_z))

	# 2. Add Triangles
	for z in range(terrain_size.y - 1):
		for x in range(terrain_size.x - 1):
			var top_left: int = z * terrain_size.x + x
			var top_right: int = top_left + 1
			var bottom_left: int = (z + 1) * terrain_size.x + x
			var bottom_right: int = bottom_left + 1

			st.add_index(top_left)
			st.add_index(bottom_left)
			st.add_index(top_right)

			st.add_index(top_right)
			st.add_index(bottom_left)
			st.add_index(bottom_right)

	st.generate_normals()
	var array_mesh := st.commit()

	if array_mesh == null or array_mesh.get_surface_count() == 0:
		push_error("[TerrainGenerator] Failed to generate terrain ArrayMesh!")
		return

	# Assign to MeshInstance3D
	mesh_instance.mesh = array_mesh

	# Assign to Physics Collision
	var shape := array_mesh.create_trimesh_shape()
	collision_shape.shape = shape
	print("[TerrainGenerator] Terrain mesh and trimesh collision successfully created!")

func _get_biome_at_continental_value(value: float) -> BiomeData:
	var closest_biome: BiomeData = biome_manager.biomes[0]
	var smallest_diff: float = 999.0

	for biome in biome_manager.biomes:
		if biome == null:
			continue
		var diff := absf(value - biome.target_continentalness)
		if diff < smallest_diff:
			smallest_diff = diff
			closest_biome = biome

	return closest_biome


func _try_spawn_scenery(biome: BiomeData, world_pos: Vector3, height: float) -> void:
	if biome.scenery_scenes.is_empty() or scenery_container == null:
		return

	if biome.is_ocean and height <= biome.sea_level:
		return

	if rng.randf() <= scenery_density:
		var selected_scene: PackedScene = biome.scenery_scenes.pick_random()
		if selected_scene:
			var instance := selected_scene.instantiate() as Node3D
			scenery_container.add_child(instance)
			instance.global_position = Vector3(world_pos.x, height, world_pos.z)
			instance.rotation.y = rng.randf_range(0.0, TAU)


func _ensure_nodes_exist() -> void:
	# Declare scene_root ONCE at the top
	var scene_root := get_tree().edited_scene_root if Engine.is_editor_hint() else owner

	if mesh_instance == null:
		mesh_instance = get_node_or_null("TerrainMesh") as MeshInstance3D
		if mesh_instance == null:
			mesh_instance = MeshInstance3D.new()
			mesh_instance.name = "TerrainMesh"
			add_child(mesh_instance)
			if scene_root:
				mesh_instance.owner = scene_root

	if static_body == null:
		static_body = get_node_or_null("TerrainStaticBody") as StaticBody3D
		if static_body == null:
			static_body = StaticBody3D.new()
			static_body.name = "TerrainStaticBody"
			add_child(static_body)
			if scene_root:
				static_body.owner = scene_root

	if collision_shape == null:
		collision_shape = static_body.get_node_or_null("TerrainCollisionShape") as CollisionShape3D
		if collision_shape == null:
			collision_shape = CollisionShape3D.new()
			collision_shape.name = "TerrainCollisionShape"
			static_body.add_child(collision_shape)
			if scene_root:
				collision_shape.owner = scene_root

	if scenery_container == null:
		scenery_container = get_node_or_null("SceneryContainer") as Node3D
		if scenery_container == null:
			scenery_container = Node3D.new()
			scenery_container.name = "SceneryContainer"
			add_child(scenery_container)
			if scene_root:
				scenery_container.owner = scene_root

func _clear_scenery() -> void:
	if scenery_container:
		for child in scenery_container.get_children():
			child.queue_free()
