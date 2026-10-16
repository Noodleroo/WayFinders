extends Node

var _registry: Dictionary = {}

@export_dir var items_folder_path: String = "res://resources/wayfinders/items/"

func _ready():
	register_all_items()

# Automatically scans the items directory and registers all .tres resources
func register_all_items():
	_registry.clear()
	var dir = DirAccess.open(items_folder_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = items_folder_path + "/" + file_name
				var item_res = load(full_path) as Item

				if item_res:
					register_item(item_res)

			file_name = dir.get_next()

# Registers a single item resource
func register_item(item: Item):
	if item == null or item.id.is_empty():
		push_error("ItemRegistry: Cannot register invalid or empty item resource!")
		return

	if _registry.has(item.id):
		push_warning("ItemRegistry: Overwriting existing item ID: " + item.id)

	_registry[item.id] = item
	print("Registered Item to Registry: ", item.id)

# Safe lookup that returns a duplicated copy of the item
func get_item(id: String) -> Item:
	if _registry.has(id):
		return _registry[id].duplicate()

	push_error("ItemRegistry: Item ID not found: " + id)
	return null

# Check if an item ID exists
func has_item(id: String) -> bool:
	return _registry.has(id)
