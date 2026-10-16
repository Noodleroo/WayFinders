@tool
class_name RiverGenerator
extends Path3D

@export var river_width: float = 4.0
@export var resolution_per_unit: float = 2.0  # Points per meter along curve
@export var water_material: Material
@export_category("Terrain Snapping")
@export var terrain_collision_mask: int = 2  # Layer 2: Terrain
@export var ray_height_offset: float = 0.1   # Prevents z-fighting with ground

var mesh_instance: MeshInstance3D


func _ready() -> void:
	generate_river()


func generate_river() -> void:
	if curve == null or curve.get_baked_points().size() < 2:
		return

	# Ensure child MeshInstance3D exists
	if mesh_instance == null:
		mesh_instance = get_node_or_null("RiverMesh") as MeshInstance3D
		if mesh_instance == null:
			mesh_instance = MeshInstance3D.new()
			mesh_instance.name = "RiverMesh"
			add_child(mesh_instance)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var total_length := curve.get_baked_length()
	var step_count := int(total_length * resolution_per_unit)
	if step_count < 2:
		step_count = 2

	var space_state := get_world_3d().direct_space_state

	for i in range(step_count + 1):
		var progress := float(i) / float(step_count)
		var distance := progress * total_length
		
		var global_center := curve.sample_baked(distance) + global_position
		var center_pos := _snap_to_terrain(global_center, space_state)
		
		# Get forward direction vector along curve
		var forward: Vector3 = curve.sample_baked_forward(distance).normalized()
		var right: Vector3 = forward.cross(Vector3.UP).normalized() * (river_width * 0.5)

		var left_pos: Vector3 = center_pos - right
		var right_pos: Vector3 = center_pos + right

		# Convert to local space for mesh creation
		var local_left := to_local(left_pos)
		var local_right := to_local(right_pos)

		# Add vertices with UV coordinates (UV.y maps downstream flow)
		st.set_uv(Vector2(0.0, progress * (total_length / river_width)))
		st.add_vertex(local_left)

		st.set_uv(Vector2(1.0, progress * (total_length / river_width)))
		st.add_vertex(local_right)

		# Build triangle indices
		if i < step_count:
			var vert_idx := i * 2
			# First triangle
			st.add_index(vert_idx)
			st.add_index(vert_idx + 1)
			st.add_index(vert_idx + 2)

			# Second triangle
			st.add_index(vert_idx + 1)
			st.add_index(vert_idx + 3)
			st.add_index(vert_idx + 2)

	st.generate_normals()
	var array_mesh := st.commit()
	mesh_instance.mesh = array_mesh

	if water_material:
		mesh_instance.material_override = water_material


func _snap_to_terrain(pos: Vector3, space_state: PhysicsDirectSpaceState3D) -> Vector3:
	if space_state == null:
		return pos

	var ray_start := pos + Vector3(0, 100.0, 0)
	var ray_end := pos + Vector3(0, -100.0, 0)

	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = terrain_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := space_state.intersect_ray(query)
	if result:
		return Vector3(pos.x, result.position.y + ray_height_offset, pos.z)

	return pos
