# res://scenes/ui/pinned_hotbar_ui.gd
class_name PinnedHotbarUI
extends Control

@export var slot_ui_scene: PackedScene = preload("res://wayfinders/base/player/ui/inventory_slot_ui.tscn")

@onready var hotbar_grid: Container = $VBoxContainer/HotbarGrid
@onready var selected_item_label: Label = $VBoxContainer/SelectedItemLabel

var bound_inventory: InventoryData
var active_pin_index: int = 0


func bind_inventory(inventory_data: InventoryData) -> void:
	if bound_inventory:
		bound_inventory.inventory_updated.disconnect(refresh_hotbar_wrapper)

	bound_inventory = inventory_data
	bound_inventory.inventory_updated.connect(refresh_hotbar_wrapper)
	refresh_hotbar()


func refresh_hotbar_wrapper(_inventory_data: InventoryData = null) -> void:
	refresh_hotbar()


func set_active_slot(pin_index: int) -> void:
	active_pin_index = pin_index
	refresh_hotbar()


func refresh_hotbar() -> void:
	if bound_inventory == null or hotbar_grid == null:
		return

	# Clear existing slot UI nodes
	for child in hotbar_grid.get_children():
		child.queue_free()

	if slot_ui_scene == null:
		return

	# Populate pinned slots
	for pin_i in range(bound_inventory.pinned_indices.size()):
		var actual_slot_index = bound_inventory.pinned_indices[pin_i]
		var slot_node = slot_ui_scene.instantiate() as InventorySlotUI
		hotbar_grid.add_child(slot_node)
		
		var is_selected = (pin_i == active_pin_index)
		var slot_data = null
		if actual_slot_index >= 0 and actual_slot_index < bound_inventory.slot_datas.size():
			slot_data = bound_inventory.slot_datas[actual_slot_index]
			
		slot_node.update_slot(slot_data, actual_slot_index, true, is_selected)

	# Update selected item name label
	_update_selected_label()


func _update_selected_label() -> void:
	if selected_item_label == null or bound_inventory == null:
		return

	if active_pin_index >= 0 and active_pin_index < bound_inventory.pinned_indices.size():
		var actual_slot_index = bound_inventory.pinned_indices[active_pin_index]
		if actual_slot_index >= 0 and actual_slot_index < bound_inventory.slot_datas.size():
			var slot_data = bound_inventory.slot_datas[actual_slot_index]
			if slot_data and slot_data.item_data:
				selected_item_label.text = slot_data.item_data.get_localized_name()
				return

	selected_item_label.text = ""
