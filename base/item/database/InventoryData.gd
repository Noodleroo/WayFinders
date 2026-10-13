class_name InventoryData
extends Resource

signal inventory_updated(inventory_data: InventoryData)

@export var slot_datas: Array[SlotData] = []
@export var pinned_indices: Array[int] = [0, 1, 2]

func _init(size: int = 20) -> void:
	if slot_datas.is_empty():
		slot_datas.resize(size)
		for i in range(size):
			slot_datas[i] = SlotData.new()

func is_slot_pinned(index: int) -> bool:
	return index in pinned_indices

func toggle_pin_slot(index: int) -> void:
	if index in pinned_indices:
		pinned_indices.erase(index)
	else:
		if pinned_indices.size() < 3: # Enforce max 3 pinned slots
			pinned_indices.append(index)
	inventory_updated.emit(self)

func add_item(item: ItemData, amount: int = 1) -> bool:
	# 1. Try stacking into existing slots
	for slot in slot_datas:
		if slot.item_data and slot.item_data.id == item.id:
			var space = item.max_stack_size - slot.quantity
			if space > 0:
				var to_add = min(amount, space)
				slot.quantity += to_add
				amount -= to_add
				if amount <= 0:
					inventory_updated.emit(self)
					return true

	# 2. Add to first empty slot
	for slot in slot_datas:
		if slot.item_data == null:
			slot.item_data = item
			slot.quantity = min(amount, item.max_stack_size)
			amount -= slot.quantity
			if amount <= 0:
				inventory_updated.emit(self)
				return true

	inventory_updated.emit(self)
	return amount <= 0


func get_total_weight() -> float:
	var total: float = 0.0
	for slot in slot_datas:
		if slot and slot.item_data:
			# Change slot.item_data.physical_weight to slot.item_data.weight
			total += slot.item_data.weight * slot.quantity
	return total

func swap_slots(index_a: int, index_b: int) -> void:
	if index_a < 0 or index_a >= slot_datas.size():
		return
	if index_b < 0 or index_b >= slot_datas.size():
		return
	if index_a == index_b:
		return

	# Swap slot items
	var temp = slot_datas[index_a]
	slot_datas[index_a] = slot_datas[index_b]
	slot_datas[index_b] = temp

	inventory_updated.emit(self)
