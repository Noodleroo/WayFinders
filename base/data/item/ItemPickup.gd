class_name ItemPickup
extends Interactable

## Drag your Item resource (e.g., MushroomItem.tres) here in the Inspector
@export var item_data: Item
@export var pickup_quantity: int = 3

@onready var default_mesh_instance: MeshInstance3D = $MeshInstance3D

var _spawned_model_instance: Node3D = null

func _ready() -> void:
	_setup_visuals()

func _setup_visuals() -> void:
	if item_data == null:
		prompt_message = "Empty Item"
		return

	prompt_message = "Pick up %s" % item_data.get_localized_name()

	# 1. Clean up old spawned model instances
	if is_instance_valid(_spawned_model_instance):
		_spawned_model_instance.queue_free()
		_spawned_model_instance = null

	# 2. Spawn the .glb scene if assigned on Item resource
	if item_data.item_scene:
		# Hide default placeholder mesh so it doesn't clip
		if default_mesh_instance:
			default_mesh_instance.visible = false

		_spawned_model_instance = item_data.item_scene.instantiate() as Node3D
		if _spawned_model_instance:
			add_child(_spawned_model_instance)

	# 3. Fallback to raw Mesh if no scene is provided
	elif item_data.item_mesh and default_mesh_instance:
		default_mesh_instance.mesh = item_data.item_mesh
		default_mesh_instance.visible = true

## OVERRIDE: Runs when player presses 'E'
func _on_interact(interactor: Node3D) -> void:
	if interactor == null or item_data == null:
		return

	var target_inventory: InventoryData = null

	if "inventory" in interactor and interactor.inventory != null:
		target_inventory = interactor.inventory
	elif "inventory_data" in interactor and interactor.inventory_data != null:
		target_inventory = interactor.inventory_data

	if target_inventory:
		# Pass pickup_quantity (e.g. 3) instead of hardcoded 1
		var leftover: int = target_inventory.add_item(item_data, pickup_quantity)
		
		if leftover == 0:
			print("Successfully collected %d %ss!" % [pickup_quantity, item_data.get_localized_name()])
			queue_free()
		else:
			print("Inventory couldn't fit all items. Leftover: %d" % leftover)
