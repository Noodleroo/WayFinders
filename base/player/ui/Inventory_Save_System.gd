# res://scripts/inventory/inventory_save_system.gd
class_name InventorySaveSystem
extends Node

const SAVE_PATH: String = "user://inventory_save.json"


static func save_inventory(inventory: InventoryData, file_path: String = SAVE_PATH) -> bool:
	if inventory == null:
		return false

	var save_data: Array = []

	for slot in inventory.slot_datas:
		if slot and slot.item:
			save_data.append({
				"item_id": slot.item.id,
				"quantity": slot.quantity,
				"current_durability": slot.current_durability
			})
		else:
			save_data.append(null)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		return false

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	print("Inventory saved successfully to: ", file_path)
	return true


static func load_inventory(size: int = 20, file_path: String = SAVE_PATH) -> InventoryData:
	# Instantiate with 0 args, then size using _init() parameter
	var inventory = InventoryData.new(size)

	if not FileAccess.file_exists(file_path):
		print("Save file not found. Returning new empty inventory.")
		return inventory

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading.")
		return inventory

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse inventory JSON save file.")
		return inventory

	var loaded_slots = json.data
	if not loaded_slots is Array:
		return inventory

	for i in range(min(loaded_slots.size(), inventory.slot_datas.size())):
		var slot_info = loaded_slots[i]
		if slot_info != null and slot_info is Dictionary:
			var item_id: String = slot_info.get("item_id", "")
			var quantity: int = slot_info.get("quantity", 1)
			var durability: int = slot_info.get("current_durability", -1)

			# Fetch item directly from runtime ItemDatabase registry!
			var base_item = ItemRegistry.get_item(item_id) if ItemRegistry else null
			if base_item:
				var new_slot = SlotData.new()
				new_slot.item = base_item
				new_slot.quantity = quantity
				new_slot.current_durability = durability
				inventory.slot_datas[i] = new_slot

	inventory.inventory_updated.emit(inventory)
	print("Inventory loaded successfully from: ", file_path)
	return inventory
