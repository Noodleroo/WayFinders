class_name ActionPlaceStructure
extends ItemAction

@export var scene_to_place: PackedScene


func execute(user: Node3D, _item_data: ItemData, target_info: Dictionary) -> bool:
	if scene_to_place and target_info.has("hit_position") and target_info.has("hit_normal"):
		var spawn_pos = target_info["hit_position"] + (target_info["hit_normal"] * 0.5)
		var new_structure = scene_to_place.instantiate() as Node3D
		user.get_tree().current_scene.add_child(new_structure)
		new_structure.global_position = spawn_pos
		return true # Consumes 1 structure item from slot
	return false
