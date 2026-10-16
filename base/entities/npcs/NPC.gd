class_name NPC
extends Entity

@export_group("NPC Settings")
@export var dialogue_id: String = ""
@export var is_vendor: bool = false

func interact() -> void:
	print("[NPC] Interacting with: ", data.entity_name)

##Takes a set amount of damage
func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	if is_passive:
		print("[%s] is passive and flees from the attacker!" % (data.entity_name if data else String(name)))
		# Add logic to run away
	else:
		print("[%s] becomes hostile and fights back!" % (data.entity_name if data else String(name)))
		# Add logic to enter combat mode
