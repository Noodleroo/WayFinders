class_name PlayerInteractable
extends Interactable

## Attached to the player scene so OTHER players can look at and interact with them

func _ready() -> void:
	var parent_player := get_parent() as Node3D
	if parent_player:
		prompt_message = "Inspect " + parent_player.name

func _on_interact(interactor: Node3D) -> void:
	# Ignore if the local player triggers their own interact area
	if interactor == get_parent() or interactor == owner:
		return

	print("%s interacted with %s!" % [interactor.name, get_parent().name])
