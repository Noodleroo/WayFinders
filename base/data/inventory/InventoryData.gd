class_name InventoryData
extends Resource

signal inventory_updated(inventory_data: InventoryData)

@export var slot_datas: Array[SlotData] = []
@export var pinned_indices: Array[int] = [0, 1, 2, 3, 4]
@export var max_pins: int = 5

##[b]Toggles pin slots[/b], probably not very useful for editing.
func toggle_pin_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slot_datas.size():
		return

	if pinned_indices.has(slot_index):
		pinned_indices.erase(slot_index)
		inventory_updated.emit(self)
	else:
		if pinned_indices.size() < max_pins:
			pinned_indices.append(slot_index)
			inventory_updated.emit(self)
		else:
			print("Cannot pin more than ", max_pins, " slots!")

##Just used to [b]drag-and-drop[/b] items, may be useful.
func swap_slots(index_a: int, index_b: int) -> void:
	if index_a >= 0 and index_a < slot_datas.size() and index_b >= 0 and index_b < slot_datas.size():
		var temp = slot_datas[index_a]
		slot_datas[index_a] = slot_datas[index_b]
		slot_datas[index_b] = temp

		pinned_indices.sort()

		inventory_updated.emit(self)
		
##Get the [b]item[/b] in the selected slot of the inventory.
func get_item_in_slot(slot_index: int):
	if slot_index >= 0 and slot_index < slot_datas.size():
		var selected_slot = slot_datas[slot_index]
		if selected_slot != null:
			return selected_slot.item
		return "Fists"
	return "Not Valid slot Index"

##Gets the [b]name[/b] of an item in a specified spot.
func get_item_name(slot_index: int):
	if slot_index >= 0 and slot_index < slot_datas.size():
		var current_item: Item = get_item_in_slot(slot_index)
		if current_item != null:
			return current_item.get_localized_name()
		return "Fists"
	return "Not Valid slot Index"

##Gets the [b]description[/b] of an item in a specified spot.
func get_item_desc(slot_index: int):
	if slot_index >= 0 and slot_index < slot_datas.size():
		var current_item: Item = get_item_in_slot(slot_index)
		if current_item != null:
			var _item_name: String = current_item.get_localized_description()
	return "Not Valid slot Index"

##Get the [b]items[/b] in the inventory.
func get_items_in_inventory() -> Array[Item]:
	var items: Array[Item] = []

	for slot in slot_datas:
		if slot != null and slot.item != null:
			items.append(slot.item)

	return items

func _init(size: int = 20) -> void:
	if slot_datas.is_empty() and size > 0:
		slot_datas.resize(size)
		# Initialize slots with empty SlotData instances
		for i in range(size):
			slot_datas[i] = SlotData.new()

##Checks if a [b]specified slot[/b] is [b]pinned[/b].
func is_slot_pinned(slot_index: int) -> bool:
	return pinned_indices.has(slot_index)

##Gets the [b]total weight[/b] in the inventory.
func get_total_weight() -> float:
	var total_weight: float = 0.0
	for slot in slot_datas:
		if slot and slot.item:
			total_weight += slot.item.weight * slot.quantity
	return total_weight

##Adds an item directly into the players inventory.
func add_item(item: Item, quantity: int = 1) -> int:
	if item == null or quantity <= 0:
		return quantity

	var remaining_quantity = quantity

	# 1. Try to stack onto existing matching items
	for slot_data in slot_datas:
		if slot_data and slot_data.item and slot_data.item.id == item.id:
			var max_stack = item.max_stack_size
			var space_left = max_stack - slot_data.quantity
			
			if space_left > 0:
				var amount_to_add = min(remaining_quantity, space_left)
				slot_data.quantity += amount_to_add
				remaining_quantity -= amount_to_add

				if remaining_quantity <= 0:
					inventory_updated.emit(self)
					return 0

	# 2. Place remaining quantity into empty slots
	for i in range(slot_datas.size()):
		var slot_data = slot_datas[i]

		# Found an empty slot (or null entry)
		if slot_data == null or slot_data.item == null:
			var max_stack = item.max_stack_size
			var amount_to_add = min(remaining_quantity, max_stack)

			if slot_data == null:
				slot_data = SlotData.new()
				slot_datas[i] = slot_data

			slot_data.item = item
			slot_data.quantity = amount_to_add
			remaining_quantity -= amount_to_add

			if remaining_quantity <= 0:
				inventory_updated.emit(self)
				return 0

	# Emit update signal if partial amount was added
	if remaining_quantity < quantity:
		inventory_updated.emit(self)

	# Return any leftover quantity that couldn't fit
	return remaining_quantity
