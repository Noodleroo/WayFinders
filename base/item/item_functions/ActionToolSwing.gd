# res://scripts/items/actions/action_tool_swing.gd
class_name ActionToolSwing
extends ItemAction

##Damage against enemies
@export var damage: float = 10.0
##[b]Multiplier[/b] against wood/ores 
@export var tool_power: float = 1.5
##The durability loss [b]multiplier[/b] when swung.[br]Usually you would want this low as it is a multiplier.
##[br][center][code]Durability Loss * Durability = Current Durability[/code][/center]
@export var durability_loss: float = 0.5

func execute(_user: Node3D, _item_data: ItemData, target_info: Dictionary) -> bool:
	if target_info.has("collider"):
		var target = target_info["collider"]
		if target and target.has_method("take_damage"):
			target.take_damage(damage, tool_power)
			print("Item swung")
			return false # Tools don't get consumed on swing!
	return false
