class_name God
extends Entity

## Physical representation or shrine node of a God in the world.

@export var god_data: GodData

@export_group("Shrine / Favor Settings")
@export var current_favor: int = 0

func _ready() -> void:
	super._ready()
	_apply_god_data()

func _apply_god_data() -> void:
	if god_data:
		var god_name: String = god_data.get_localized_name()
		
		# If god_data is assigned, sync it with base Entity values
		if status_label:
			status_label.text = "%s\n[Favor: %d]" % [god_name, current_favor]

func offer_item(item: Item, quantity: int = 1) -> bool:
	if god_data and item in god_data.offering_items:
		current_favor += 10 * quantity
		print("Offered %s to %s! Current Favor: %d" % [item.get_localized_name(), god_data.get_localized_name(), current_favor])
		_apply_god_data()
		return true
	
	print("This god rejects your offering.")
	return false
