class_name ItemPickupInteractable
extends Interactable

@export var item_data: Item

func _on_interact(interactor: Node3D) -> void:
	if interactor == null or item_data == null:
		return

	# Assuming player has an inventory_data property of type InventoryData
	if "inventory_data" in interactor and interactor.inventory_data != null:
		var leftover = interactor.inventory_data.add_item(item_data, 1)
		
		# If leftover is 0, the item was fully placed in inventory!
		if leftover == 0:
			queue_free()
		else:
			print("Inventory full!")
