class_name ConsumableItem
extends Item

@export var heal_amount: float = 25.0

func use_primary(user: Node3D, target_info: Dictionary = {}) -> bool:
	# Your item logic here...
	print("Item used by ", user.name)
	
	return true
