class_name ItemPickupInteractable
extends Interactable

@export var item_data: ItemData

func _on_interact(interactor: Node3D) -> void:
	# Add item to player inventory
	if interactor.has_method("add_to_inventory"):
		interactor.add_to_inventory(item_data)
		queue_free()
