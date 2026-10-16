class_name EntityData
extends Resource

@export_group("General Info")
@export var entity_name: String = "Default Entity"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Base Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 5.0
@export var acceleration: float = 10.0

@export_group("Loot & Rewards")
@export var exp_reward: int = 10
# You can assign your ItemData resources here if you have an item system!
@export var possible_drops: Array[Resource] = []
