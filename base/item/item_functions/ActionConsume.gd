class_name ActionConsume
extends ItemAction

@export var health_restored: float = 25.0
@export var stamina_restored: float = 15.0


func execute(user: Node3D, _item_data: ItemData, _target_info: Dictionary) -> bool:
	print("Consumed item! Healed: ", health_restored, " Stamina: ", stamina_restored)
	if user.has_method("heal"):
		user.heal(health_restored)
	return true # Consumes item from slot
