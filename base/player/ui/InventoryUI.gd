# res://scenes/ui/inventory_ui.gd
class_name InventoryUI
extends Control

@export var slot_ui_scene: PackedScene = preload("res://wayfinders/base/player/ui/inventory_slot_ui.tscn")

@onready var item_grid: GridContainer = $PanelContainer/VBoxContainer/ItemGrid

var bound_inventory: InventoryData
var active_pin_index: int = 0


func bind_inventory(inventory_data: InventoryData) -> void:
	if bound_inventory:
		bound_inventory.inventory_updated.disconnect(refresh_ui_wrapper)

	bound_inventory = inventory_data
	bound_inventory.inventory_updated.connect(refresh_ui_wrapper)
	refresh_ui()


func refresh_ui_wrapper(_inventory_data: InventoryData = null) -> void:
	refresh_ui()


func set_active_slot(pin_index: int) -> void:
	active_pin_index = pin_index
	refresh_ui()


func refresh_ui() -> void:
	if bound_inventory == null or item_grid == null:
		return

	# Clear existing slot UI nodes
	for child in item_grid.get_children():
		child.queue_free()

	# Wait for Godot to clear the old nodes out of the Scene Tree
	if item_grid.get_child_count() > 0:
		await get_tree().process_frame

	if slot_ui_scene == null:
		return

	# Sort pinned indices to guarantee visual left-to-right alignment
	bound_inventory.pinned_indices.sort()

	# Determine active grid slot index
	var active_slot_index: int = -1
	if active_pin_index >= 0 and active_pin_index < bound_inventory.pinned_indices.size():
		active_slot_index = bound_inventory.pinned_indices[active_pin_index]

	# Populate inventory grid sequentially
	for i in range(bound_inventory.slot_datas.size()):
		var slot_node = slot_ui_scene.instantiate() as InventorySlotUI
		item_grid.add_child(slot_node)

		var is_pinned = bound_inventory.is_slot_pinned(i)
		var is_selected = (i == active_slot_index)

		slot_node.update_slot(bound_inventory.slot_datas[i], i, is_pinned, is_selected)

		# Connect pin & drop signals
		slot_node.slot_pin_requested.connect(_on_slot_pin_requested)
		slot_node.slot_dropped.connect(_on_slot_dropped)


func _on_slot_pin_requested(slot_index: int) -> void:
	if bound_inventory:
		bound_inventory.toggle_pin_slot(slot_index)


func _on_slot_dropped(origin_index: int, target_index: int) -> void:
	if bound_inventory:
		bound_inventory.swap_slots(origin_index, target_index)
