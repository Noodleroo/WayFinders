# res://scripts/inventory/slot_data.gd
class_name SlotData
extends Resource

@export var item: Item # Reference to the new base Item class
@export var quantity: int = 1: set = set_quantity

# Tracks instance-specific state (e.g., remaining durability)
@export var current_durability: int = -1


func set_quantity(value: int) -> void:
	quantity = value
	if quantity < 1:
		quantity = 0
		item = null


func can_fully_merge_with(other_slot: SlotData) -> bool:
	return (
		item != null
		and other_slot.item != null
		and item.id == other_slot.item.id
		and item.max_stack_size > 1
		and quantity + other_slot.quantity <= item.max_stack_size
	)


func create_single_item_slot() -> SlotData:
	var new_slot = SlotData.new()
	new_slot.item = item
	new_slot.quantity = 1
	new_slot.current_durability = current_durability
	return new_slot
