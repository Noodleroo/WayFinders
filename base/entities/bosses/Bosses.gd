class_name Bosses
extends Entity

@export_group("Boss Settings")
@export var boss_title: String = "The Destroyer"
@export var phase_count: int = 2

func take_damage(amount: float) -> void:
	# Custom boss damage handling (e.g. invulnerability phases)
	super.take_damage(amount)
