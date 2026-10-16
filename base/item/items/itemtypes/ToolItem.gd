class_name ToolItem
extends Item

enum ToolType { AXE, PICKAXE, SICKLE }

@export_category("Tool Parameters")
@export var tool_type: ToolType = ToolType.AXE
@export var harvest_power: float = 15.0
@export var harvest_tier: int = 1
@export var cooldown: float = 0.5
@export var reach: float = 2.5

@export_category("Combat & Durability")
@export var base_damage: float = 2.5
@export var attack_speed: float = 1.0
@export var max_durability: int = 128
@export var current_durability: int = 128

func _init() -> void:
	item_type = ItemType.TOOL
	max_stack_size = 1

func use_primary(user: Node3D, target_info: Dictionary = {}) -> bool:
	if user == null:
		return false

	# 1. Check durability
	if current_durability <= 0:
		print("Tool is broken!")
		return false

	# 2. Check tool usage cooldown flag
	if user.get_meta("is_using_tool", false):
		return false

	# 3. Execute tool action
	_execute_tool_use(user, target_info)
	return true

func _execute_tool_use(user: Node3D, target_info: Dictionary) -> void:
	user.set_meta("is_using_tool", true)

	var hit_node: Node3D = target_info.get("collider", null)
	if hit_node == null:
		hit_node = _check_tool_hit(user)

	if hit_node:
		# Priority 1: Resource Nodes (Trees, Rocks)
		if hit_node.has_method(&"on_tool_hit"):
			hit_node.on_tool_hit(tool_type, harvest_power, harvest_tier)
			_reduce_durability(1)
			print("Tool harvested resource: ", hit_node.name)

		# Priority 2: Living Entities (Frogs, Enemies)
		elif hit_node.has_method(&"take_damage"):
			hit_node.take_damage(harvest_power)
			_reduce_durability(1)
			print("Tool dealt %.1f damage to %s!" % [harvest_power, hit_node.name])

	# Reset cooldown
	var tree := user.get_tree()
	if tree:
		var timer := tree.create_timer(cooldown)
		await timer.timeout
		if is_instance_valid(user):
			user.set_meta("is_using_tool", false)

## Helper to walk up the parent tree to find the root Entity node
func _find_entity_target(node: Node) -> Node:
	var current := node
	while current != null:
		if current is Entity or current.has_method(&"take_damage"):
			return current
		current = current.get_parent()
	return null

func _check_tool_hit(user: Node3D) -> Node3D:
	var space_state := user.get_world_3d().direct_space_state
	var camera := user.get_viewport().get_camera_3d()

	# Start raycast at user's chest level (1.2 units up)
	var origin := user.global_position + Vector3(0, 1.2, 0)
	
	# Facing vector: uses player forward vector (-Z) by default
	var forward_dir := -user.global_transform.basis.z

	# If first-person camera exists, shoot forward from camera gaze
	if camera:
		origin = camera.global_position
		forward_dir = -camera.global_transform.basis.z

	var destination := origin + (forward_dir.normalized() * reach)

	# Setup physics query
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [user.get_rid()] # Don't hit self
	query.collide_with_bodies = true
	query.collide_with_areas = true # Detect Area3D hitboxes if present

	var result := space_state.intersect_ray(query)

	if not result.is_empty():
		var hit_collider: Node3D = result.collider
		print("Raycast hit collider: ", hit_collider.name)
		return _find_valid_target(hit_collider)

	print("Raycast hit nothing!")
	return null

## Searches up the node tree for a node that responds to tool hits or damage
func _find_valid_target(node: Node) -> Node3D:
	var current := node
	while current != null and current is Node3D:
		if current.has_method(&"on_tool_hit") or current.has_method(&"take_damage"):
			return current as Node3D
		current = current.get_parent()
	return null

func _reduce_durability(amount: int) -> void:
	current_durability = max(0, current_durability - amount)
	if current_durability == 0:
		print("Tool broke!")
