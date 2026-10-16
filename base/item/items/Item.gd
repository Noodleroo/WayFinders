class_name Item
extends Resource

enum ItemType { TOOL, WEAPON, ARMOR, CONSUMABLE, ORE, RELIC, BASIC }

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var icon_path: String = ""
@export var icon: Texture2D
@export var item_mesh: Mesh 
@export var item_scene: PackedScene
@export var item_type: ItemType = ItemType.BASIC
@export var max_stack_size: int = 64
@export var weight: float = 1.0


func get_localized_name() -> String:
	return tr(name_key) if not name_key.is_empty() else id


func get_localized_description() -> String:
	return tr(description_key) if not description_key.is_empty() else ""


# Virtual stubs to be overridden by subclasses
func use_primary(_user: Node3D, _target_info: Dictionary) -> bool:
	return false


func use_secondary(_user: Node3D, _target_info: Dictionary) -> bool:
	return false


func on_equip(_user: Node3D) -> void:
	pass


func on_unequip(_user: Node3D) -> void:
	pass
