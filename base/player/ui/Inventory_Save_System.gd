class_name InventorySaveSystem
extends Node

const SAVE_PATH: String = "user://inventory_save.json"

# Dictionary database matching Item IDs to their Resource paths
static var item_database: Dictionary = {
	"wood": "res://resources/items/wood.tres",
	"stone": "res://resources/items/stone.tres",
	"relic_ash": "res://resources/items/relic_ash.tres",
	"iron_sword": "res://resources/items/iron_sword.tres"
}


static func save_inventory(inventory: InventoryData, file_path: String = SAVE_PATH) -> bool:
	var save_data: Array = []

	for slot in inventory.slot_datas:
		if slot and slot.item_data:
			save_data.append({
				"item_id": slot.item_data.id,
				"quantity": slot.quantity,
				"custom_attributes": slot.item_data.custom_attributes
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

	var loaded_slots: Array = json.data

	for i in range(min(loaded_slots.size(), inventory.slot_datas.size())):
		var slot_info = loaded_slots[i]
		if slot_info != null and slot_info is Dictionary:
			var item_id: String = slot_info.get("item_id", "")
			var quantity: int = slot_info.get("quantity", 1)

			if item_database.has(item_id):
				var item_res_path = item_database[item_id]
				if ResourceLoader.exists(item_res_path):
					var loaded_item: ItemData = load(item_res_path).duplicate()
					
					# Load custom attribute overrides
					if slot_info.has("custom_attributes"):
						loaded_item.custom_attributes = slot_info["custom_attributes"]

					inventory.slot_datas[i].item_data = loaded_item
					inventory.slot_datas[i].quantity = quantity

	inventory.inventory_updated.emit(inventory)
	print("Inventory loaded successfully from: ", file_path)
	return inventory
