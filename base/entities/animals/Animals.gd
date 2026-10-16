class_name Animal
extends Entity

@export_group("AI Settings")
@export var flee_speed: float = 8.0

var is_fleeing: bool = false

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	move_and_slide()
	
	if is_passive:
		# Passive behavior: Wander around or ignore the player
		_handle_passive_behavior()
	else:
		# Aggressive / Skittish behavior: Attack or flee on sight
		_handle_hostile_behavior()

##Handles what the animal does when passive such as wandering or eating.
func _handle_passive_behavior() -> void:
	# Idle or calm wandering logic
	pass

##Handles what the animal does when hostile such as hurting the player.
func _handle_hostile_behavior() -> void:
	# Attack or flee logic
	pass
