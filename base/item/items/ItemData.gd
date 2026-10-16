class_name ItemData
extends Resource

## Base resource class for all inventory items.

@export var item_id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export var description: String = ""

## Virtual method intended to be overridden by child item scripts.
func use(user: Entity) -> bool:
	print("%s was used, but it has no effect." % display_name)
	return false # Return true if the item was successfully consumed
