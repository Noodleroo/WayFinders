class_name SlotData
extends Resource

@export var item_data: ItemData
@export_range(1, 99) var quantity: int = 1:
	set(value):
		quantity = value
		if quantity <= 0:
			item_data = null


func can_fully_merge_with(other_slot: SlotData) -> bool:
	return item_data and other_slot.item_data \
		and item_data == other_slot.item_data \
		and quantity + other_slot.quantity <= item_data.max_stack_size
