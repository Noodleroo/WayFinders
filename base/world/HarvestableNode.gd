class_name HarvestableNode
extends StaticBody3D

@export var required_tool: ToolItem.ToolType = ToolItem.ToolType.AXE
@export var min_tier: int = 1
@export var health: float = 30.0

func on_tool_hit(tool_type: ToolItem.ToolType, harvest_power: float, harvest_tier: int) -> void:
	# Ignore wrong tool types or insufficient tool tier
	if tool_type != required_tool:
		print("Wrong tool for this resource!")
		return
		
	if harvest_tier < min_tier:
		print("Tool tier too low!")
		return

	health -= harvest_power
	print("Harvested! Remaining health: ", health)

	if health <= 0.0:
		_on_harvested()

func _on_harvested() -> void:
	# Spawn resource items (e.g. Wood / Stone) in 3D world
	queue_free()
