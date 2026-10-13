
extends Node3D

@export_category("Terrain Settings")
@export var width: int = 128
@export var depth: int = 128
@export var grid_step: float = 1.0
@export var height_scale: float = 25.0
@export var terrain_seed: int = 0
@export var use_random_seed: bool = true

@export_category("Noise Configuration")
@export var noise: FastNoiseLite

@export_category("River Settings")
@export var river_radius: float = 8.0
@export var river_depth: float = 4.0
@export var bank_smoothness: float = 2.0

@export_category("Actions")
@export var generate_terrain_button: bool = false:
	set(val):
		generate_terrain()

@export_category("Optimization")
@export var collision_step: float = 2.0

@onready var mesh_instance: MeshInstance3D = $TerrainMesh
@onready var river_path: Path3D = $RiverPath




func _ready() -> void:
	# Configure noise with random seed and jagged fractal settings
	if not noise:
		noise = FastNoiseLite.new()
	
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# LOWER FREQUENCY = Wider, smoother hill curves (less spikey)
	noise.frequency = 0.008 
	
	# FBM = Natural rolling terrain (RIDGED causes the sharp pufferfish needles)
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.3 # Lower gain reduces sharp micro-peaksness
	
	if river_path.curve == null or river_path.curve.point_count == 0:
		setup_default_river_path()
		
	generate_terrain()

func setup_default_river_path() -> void:
	var curve = Curve3D.new()
	
	# Start point (Inland / Mountain)
	var start_pos = Vector3(width * 0.15, 0, depth * 0.15)
	# End point (Coast / Ocean)
	var end_pos = Vector3(width * 0.85, 0, depth * 0.85)
	
	# 1. Add fixed starting point
	curve.add_point(start_pos)
	
	# 2. Add 2-3 randomized midpoint bends to create winding curves
	var num_midpoints = 3
	for i in range(1, num_midpoints + 1):
		var t = float(i) / float(num_midpoints + 1)
		
		# Linear interpolation from start to end
		var base_point = start_pos.lerp(end_pos, t)
		
		# Add horizontal random meander offset (X and Z only)
		var offset_x = randf_range(-15.0, 15.0)
		var offset_z = randf_range(-15.0, 15.0)
		var mid_point = base_point + Vector3(offset_x, 0, offset_z)
		
		# Add Bezier Handles (in_vector and out_vector) to smooth out the river bends
		var handle_in = Vector3(-10, 0, -10)
		var handle_out = Vector3(10, 0, 10)
		
		curve.add_point(mid_point, handle_in, handle_out)
		
	# 3. Add fixed endpoint
	curve.add_point(end_pos)
	
	# Assign the procedural curve to the Path3D node
	river_path.curve = curve

func generate_terrain() -> void:
	if mesh_instance == null or river_path == null:
		return

	# Randomize/Update the river curve every time terrain is generated
	setup_default_river_path()

	# Bake the newly updated curve points
	var baked_points = river_path.curve.get_baked_points()

	# 1. Build Visual Mesh
	var visual_mesh = build_terrain_mesh(grid_step, baked_points)
	mesh_instance.mesh = visual_mesh

	# 2. Build Low-Res Collision Mesh
	var collision_mesh = build_terrain_mesh(collision_step, baked_points)
	update_collision(collision_mesh)

func build_terrain_mesh(step_size: float, baked_points: PackedVector3Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Step through the grid using the designated step_size
	var x_steps = int((width * grid_step) / step_size)
	var z_steps = int((depth * grid_step) / step_size)

	for x in range(x_steps):
		for z in range(z_steps):
			var x0 = x * step_size
			var z0 = z * step_size
			var x1 = (x + 1) * step_size
			var z1 = (z + 1) * step_size

			var h00 = get_carved_height(x0, z0, baked_points)
			var h10 = get_carved_height(x1, z0, baked_points)
			var h01 = get_carved_height(x0, z1, baked_points)
			var h11 = get_carved_height(x1, z1, baked_points)

			var p00 = Vector3(x0, h00, z0)
			var p10 = Vector3(x1, h10, z0)
			var p01 = Vector3(x0, h01, z1)
			var p11 = Vector3(x1, h11, z1)

			st.add_vertex(p00)
			st.add_vertex(p10)
			st.add_vertex(p01)

			st.add_vertex(p10)
			st.add_vertex(p11)
			st.add_vertex(p01)

	st.generate_normals()
	return st.commit()


func update_collision(collision_mesh: ArrayMesh) -> void:
	# Clear out previous collision nodes
	for child in mesh_instance.get_children():
		if child is StaticBody3D:
			child.queue_free()

	if collision_mesh == null:
		return

	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	
	# Uses the lower-resolution collision_mesh faces
	collision_shape.shape = collision_mesh.create_trimesh_shape()
	
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)

func get_carved_height(x: float, z: float, baked_points: PackedVector3Array) -> float:
	var base_height = noise.get_noise_2d(x, z) * height_scale
	
	# Find minimum distance from (x, z) point to nearest segment on Path3D river curve
	var min_dist_sq = INF
	var flat_pos = Vector2(x, z)

	for point in baked_points:
		var point_2d = Vector2(point.x, point.z)
		var dist_sq = flat_pos.distance_squared_to(point_2d)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq

	var distance = sqrt(min_dist_sq)

	# Carve riverbed if point is inside river radius
	if distance < river_radius:
		# Smooth step factor creates sloped riverbanks
		var factor = smoothstep(0.0, river_radius, distance)
		var carved_height = lerp(-river_depth, base_height, factor)
		return min(base_height, carved_height)

	return base_height
