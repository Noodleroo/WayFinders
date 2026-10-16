class_name Interactable
extends Area3D

## Signal emitted when an entity successfully interacts with this object
signal interacted(interactor: Node3D)

@export_group("Interaction Settings")
## Display text shown on screen when player looks at this object (e.g. "Pick Up Frog Legs", "Open Chest")
@export var prompt_message: String = "Interact"

## Whether this object can currently be interacted with
@export var is_interactable: bool = true

## Main entry point called when player presses the interact key (e.g., 'E' or 'F')
func interact(interactor: Node3D) -> void:
	if not is_interactable:
		return

	_on_interact(interactor)
	interacted.emit(interactor)

## Virtual method to override in child scripts or handle directly via signals
func _on_interact(interactor: Node3D) -> void:
	print("%s interacted with %s" % [interactor.name, name])
