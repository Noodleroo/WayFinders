class_name EntityHelpers
extends Node

## Utility/Helper functions for handling Entities, Loot Tables, and Spatial Checks.
## All functions are static, so you can call them anywhere without instantiating this class.

## Gets the closest Entity to a given origin point within a maximum search radius.
static func get_closest_entity(origin: Vector3, search_group: StringName = &"entities", max_distance: float = 100.0) -> Entity:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null

	var closest_entity: Entity = null
	var shortest_dist_sq := max_distance * max_distance

	for node in tree.get_nodes_in_group(search_group):
		if node is Entity and is_instance_valid(node):
			var dist_sq := origin.distance_squared_to(node.global_position)
			if dist_sq < shortest_dist_sq:
				shortest_dist_sq = dist_sq
				closest_entity = node

	return closest_entity


## Checks if two entities have clear line-of-sight (unobstructed by environment collision).
static func has_line_of_sight(from_entity: Node3D, to_entity: Node3D, collision_mask: int = 1) -> bool:
	if from_entity == null or to_entity == null:
		return false

	var space_state := from_entity.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		from_entity.global_position + Vector3.UP, # Ray starts at eye height
		to_entity.global_position + Vector3.UP,
		collision_mask,
		[from_entity.get_rid(), to_entity.get_rid()] # Exclude self and target
	)

	var result := space_state.intersect_ray(query)
	return result.is_empty() # If ray hit nothing in between, line of sight is clear

## Calculates damage after applying a flat defense/armor reduction.
static func calculate_mitigated_damage(raw_damage: float, defense: float) -> float:
	var final_damage := raw_damage - defense
	return maxf(1.0, final_damage) # Always deal at least 1 damage


## Returns the percentage of health remaining (from 0.0 to 1.0).
static func get_health_percent(current_hp: float, max_hp: float) -> float:
	if max_hp <= 0.0:
		return 0.0
	return clampf(current_hp / max_hp, 0.0, 1.0)

## Rolls an array of Item drops from an EntityData loot table.
static func roll_loot_drops(possible_drops: Array[Item], drop_chance_mult: float = 1.0) -> Array[Item]:
	var awarded_drops: Array[Item] = []

	for item in possible_drops:
		if item == null:
			continue

		# Basic drop roll check
		if randf() <= (0.5 * drop_chance_mult): # Adjust formula based on drop weight
			awarded_drops.append(item)

	return awarded_drops


## Spawns a physical 3D world drop representation for an Item at a target position.
static func spawn_world_drop(item: Item, quantity: int, spawn_pos: Vector3, parent_node: Node) -> void:
	if item == null or parent_node == null:
		return

	var rigid_body := RigidBody3D.new()
	rigid_body.name = "Drop_" + item.id
	rigid_body.global_position = spawn_pos + Vector3(0, 0.5, 0) # Spawn slightly above ground

	# Add Mesh
	if item.item_mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = item.item_mesh
		rigid_body.add_child(mesh_instance)

	# Add default collision shape for rigid body physics
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	col_shape.shape = box
	rigid_body.add_child(col_shape)

	parent_node.add_child(rigid_body)
