extends Node

# Stores all preloaded items by ID: {"relic_ash": ItemData, "forest_axe": ItemData}
var _database: Dictionary = {}


func _ready() -> void:
	_load_items_from_directory("res://resources/wayfinders/items/")


func _load_items_from_directory(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
		return

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
				var item = load(path + file_name) as ItemData
				if item and not item.id.is_empty():
					_database[item.id] = item
					print("Loaded Item to Database: ", item.id)
			file_name = dir.get_next()


func get_item(item_id: String) -> ItemData:
	if _database.has(item_id):
		return _database[item_id]
	push_error("ItemDatabase: Item ID '" + item_id + "' not found!")
	return null
