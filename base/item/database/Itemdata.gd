class_name ItemData
extends Resource

# --- ENUMS ---

enum ItemCategory {
	TOOL,
	ITEM,
	FOOD_AND_POTION,
	EXTRAS
}

enum ToolType {
	NONE,
	AXE,
	PICKAXE,
	SWORD_GREAT,
	SWORD_SHORT,
	SHIELD_TOWER,
	SHIELD_SMALL,
	BOW_LIGHT,
	BOW_HEAVY,
	SPEAR
}

enum ItemSubtype {
	NONE,
	ARMOR_PIECE,
	ACCESSORY,
	BASIC_ITEM,
	SUMMON_ITEM,
	ORE_RAW,
	ORE_SMELTED,
	RELIC_ASH,
	RELIC_CORE,
	RELIC_EQUIPPABLE
}

enum FoodPotionType {
	NONE,
	POTION,
	FOOD_STAMINA,
	FOOD_HEALTH,
	WAYFINDER_POUCH
}

enum RenderType {
	MODEL_PREVIEW,
	EXTERNAL_IMAGE
}

# --- INSPECTOR PROPERTIES ---

@export_group("Identification")
@export var id: String = ""
@export_placeholder("KEY_ITEM_NAME") var name_key: String = ""
@export_placeholder("KEY_ITEM_DESC") var description_key: String = ""

@export_group("Rendering")
@export var render_type: RenderType = RenderType.EXTERNAL_IMAGE
@export var icon: Texture2D
@export var item_model: PackedScene # Used when RenderType == MODEL_PREVIEW

@export_group("Classification")
@export var category: ItemCategory = ItemCategory.ITEM

# Dynamic Subcategory Selection
@export_subgroup("Category Details")
@export var tool_type: ToolType = ToolType.NONE
@export var item_subtype: ItemSubtype = ItemSubtype.NONE
@export var food_potion_type: FoodPotionType = FoodPotionType.NONE

@export_subgroup("Potions Logic")
@export var custom_potion_script: Script # Custom behavior override for special potions

@export_group("Item Stats")
@export var max_durability: int = 100
@export var max_stack_size: int = 1
@export var weight: float = 1

@export_group("Item Actions")
@export var primary_action: ItemAction   # Left Click
@export var secondary_action: ItemAction # Right Click
@export var extra_action: ItemAction     # Custom Keybind

# --- LOCALIZATION HELPER METHODS ---

func get_localized_name() -> String:
	return tr(name_key) if not name_key.is_empty() else id

func get_localized_description() -> String:
	return tr(description_key) if not description_key.is_empty() else ""

# --- ITEM USAGE HANDLERS ---

func execute_primary(user: Node3D, target_info: Dictionary) -> bool:
	if primary_action:
		return primary_action.execute(user, self, target_info)
	return false

func execute_secondary(user: Node3D, target_info: Dictionary) -> bool:
	if secondary_action:
		return secondary_action.execute(user, self, target_info)
	return false

func execute_extra(user: Node3D, target_info: Dictionary) -> bool:
	# Check custom potion script override first
	if custom_potion_script:
		var custom_instance = custom_potion_script.new()
		if custom_instance.has_method("execute_custom"):
			return custom_instance.execute_custom(user, self, target_info)

	if extra_action:
		return extra_action.execute(user, self, target_info)
	return false
