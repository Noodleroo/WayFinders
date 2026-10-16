class_name GodData
extends Resource

## Data definition for a deity/god in the world.

enum Alignment { NEUTRAL, LAWFUL, CHAOTIC, GOOD, EVIL }

@export_group("Identity")
@export var god_id: String = ""
@export var display_name_key: String = ""
@export_multiline var description_key: String = ""
@export var symbol_icon: Texture2D

@export_group("Attributes")
@export var alignment: Alignment = Alignment.NEUTRAL
@export var favored_biome: Resource # Optional link to BiomeData
@export var passive_buffs: Array[Resource] = [] # Optional links to Item/Buff resources

@export_group("Loot & Rewards")
@export var favor_level_required: int = 100
@export var offering_items: Array[Item] = [] # Items this god accepts

func get_localized_name() -> String:
	return tr(display_name_key) if not display_name_key.is_empty() else god_id

func get_localized_description() -> String:
	return tr(description_key) if not description_key.is_empty() else ""
