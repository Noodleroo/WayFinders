class_name PlayerInteractor
extends RayCast3D

signal focus_changed(interactable: Interactable)

var current_interactable: Interactable = null

func _ready() -> void:
	enabled = true
	collide_with_areas = true
	collide_with_bodies = true
	target_position = Vector3(0, 0, -4.0)
	
	# Exclude local player body AND interaction areas
	_exclude_owner_player()

func _exclude_owner_player() -> void:
	var player_node := owner as Node3D
	if player_node:
		# Exclude the root node
		if player_node is CollisionObject3D:
			add_exception(player_node)
			
		# Recursively exclude all child physics bodies and Area3Ds
		_exclude_children_recursive(player_node)

func _exclude_children_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionObject3D:
			add_exception(child)
			print("Excluded player collision object: ", child.name)
		_exclude_children_recursive(child)

func _physics_process(_delta: float) -> void:
	_check_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact"):
		if current_interactable and current_interactable.is_interactable:
			var player := owner as Node3D
			current_interactable.interact(player if player else get_parent())

func _check_interaction() -> void:
	var new_interactable: Interactable = null

	if is_colliding():
		var collider = get_collider()
		new_interactable = _find_interactable(collider)

	if new_interactable != current_interactable:
		current_interactable = new_interactable
		focus_changed.emit(current_interactable)
		
		if current_interactable:
			print("Looking at: %s [%s]" % [current_interactable.name, current_interactable.prompt_message])

func _find_interactable(node: Node) -> Interactable:
	var current := node
	while current != null and current is Node3D:
		if current is Interactable:
			return current as Interactable
		current = current.get_parent()
	return null
