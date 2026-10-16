class_name PlayerInteractor
extends RayCast3D

## Emitted when hovering over an interactable object (useful for UI prompts)
signal focus_changed(interactable: Interactable)

var current_interactable: Interactable = null

func _physics_process(_delta: float) -> void:
	_check_interaction()

func _unhandled_input(event: InputEvent) -> void:
	# Press 'E' (or whatever input action you configure in Project Settings)
	if event.is_action_pressed(&"interact"):
		if current_interactable and current_interactable.is_interactable:
			current_interactable.interact(get_owner())

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

## Searches up the node tree to find an Interactable node
func _find_interactable(node: Node) -> Interactable:
	var current := node
	while current != null and current is Node3D:
		if current is Interactable:
			return current as Interactable
		current = current.get_parent()
	return null
