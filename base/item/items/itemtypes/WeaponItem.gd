class_name WeaponItem
extends Item

@export_group("Weapon Stats")
@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 3.0
@export var attack_cooldown: float = 0.3

@export_group("Durability")
@export var max_durability: int = 100
@export var current_durability: int = 100

func _init() -> void:
	item_type = ItemType.WEAPON
	max_stack_size = 1

func use_primary(user: Node3D, _target_info: Dictionary = {}) -> bool:
	if user == null:
		return false

	# 1. Check durability
	if current_durability <= 0:
		print("Weapon is broken!")
		return false

	# 2. Check attack cooldown flag
	if user.get_meta("is_attacking", false):
		return false

	# 3. Trigger weapon execution
	_execute_attack(user)
	return true

func _execute_attack(user: Node3D) -> void:
	user.set_meta("is_attacking", true)

	# Try playing swing animation on user or user's visual model
	if user.has_node("AnimationPlayer"):
		var anim_player := user.get_node("AnimationPlayer") as AnimationPlayer
		if anim_player and anim_player.has_animation(&"swing"):
			anim_player.play(&"swing")

	# Check for hit targets
	_check_melee_hit(user)

	# Safe cooldown timer reset
	var tree := user.get_tree()
	if tree:
		var timer := tree.create_timer(attack_cooldown)
		await timer.timeout
		if is_instance_valid(user):
			user.set_meta("is_attacking", false)

func _check_melee_hit(user: Node3D) -> void:
	var space_state := user.get_world_3d().direct_space_state
	var camera := user.get_viewport().get_camera_3d()

	# Default origin and direction from user if camera is missing
	var origin := user.global_position + Vector3(0, 1.2, 0) # Chest/head height
	var forward_dir := -user.global_transform.basis.z

	# If first-person camera exists, shoot ray directly from crosshair
	if camera:
		origin = camera.global_position
		forward_dir = -camera.global_transform.basis.z

	var destination := origin + (forward_dir * attack_range)

	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [user.get_rid()] # Exclude attacker

	var result := space_state.intersect_ray(query)

	if not result.is_empty():
		var hit_collider: Node3D = result.collider
		
		if hit_collider.has_method(&"take_damage"):
			hit_collider.take_damage(base_damage)
			print("Dealt %.0f damage to %s" % [base_damage, hit_collider.name])
			
			# Reduce durability on successful hit
			_reduce_durability(1)

func _reduce_durability(amount: int) -> void:
	current_durability = max(0, current_durability - amount)
	if current_durability == 0:
		print("Weapon broke!")
