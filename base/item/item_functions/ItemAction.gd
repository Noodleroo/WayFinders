class_name ItemAction
extends Resource


# Virtual method to be overridden by custom actions
func execute(user: Node3D, item_data: ItemData, target_info: Dictionary) -> bool:
	return false # Return true if the action consumes 1 quantity from the stack
