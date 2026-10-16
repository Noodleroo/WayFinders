# res://scenes/ui/pinned_hotbar_ui.gd
class_name PinnedHotbarUI
extends Control

@export var slot_ui_scene: PackedScene = preload("res://wayfinders/base/player/ui/inventory_slot_ui.tscn")

@onready var hotbar_grid: Container = $VBoxContainer/HotbarGrid
@onready var selected_item_label: Label = $VBoxContainer/SelectedItemLabel

var bound_inventory: InventoryData
var active_pin_index: int = 0


func bind_inventory(inventory_data: InventoryData) -> void:
	if bound_inventory and bound_inventory.inventory_updated.is_connected(refresh_hotbar_wrapper):
		bound_inventory.inventory_updated.disconnect(refresh_hotbar_wrapper)

	bound_inventory = inventory_data
	
	if bound_inventory:
		bound_inventory.inventory_updated.connect(refresh_hotbar_wrapper)

	# If the node isn't inside the tree yet (ready hasn't fired), wait for ready
	if not is_inside_tree():
		await ready

	_rebuild_hotbar_structure()

func refresh_hotbar_wrapper(_inventory_data: InventoryData = null) -> void:
	_update_hotbar_contents()


func set_active_slot(pin_index: int) -> void:
	active_pin_index = pin_index
	_update_hotbar_contents()


# 1. Instantiates child nodes ONLY ONCE when binding or when pin count changes
func _rebuild_hotbar_structure() -> void:
	if hotbar_grid == null or slot_ui_scene == null or bound_inventory == null:
		return

	# Clear out all previous nodes immediately
	for child in hotbar_grid.get_children():
		child.free()

	# Create exactly one slot node per pinned index
	for pin_i in range(bound_inventory.pinned_indices.size()):
		var slot_node = slot_ui_scene.instantiate() as InventorySlotUI
		hotbar_grid.add_child(slot_node)

	_update_hotbar_contents()


# 2. Updates icons, text, and selection borders on existing nodes (NEVER creates new nodes)
func _update_hotbar_contents() -> void:
	if bound_inventory == null or hotbar_grid == null:
		return

	var children = hotbar_grid.get_children()
	var total_pins = bound_inventory.pinned_indices.size()

	# If the number of pinned slots changed (e.g. pinned/unpinned an item), rebuild structure
	if children.size() != total_pins:
		_rebuild_hotbar_structure()
		return

	for pin_i in range(total_pins):
		var slot_node = children[pin_i] as InventorySlotUI
		if slot_node:
			var actual_slot_index = bound_inventory.pinned_indices[pin_i]
			var is_selected = (pin_i == active_pin_index)
			var slot_data = null

			if actual_slot_index >= 0 and actual_slot_index < bound_inventory.slot_datas.size():
				slot_data = bound_inventory.slot_datas[actual_slot_index]

			slot_node.update_slot(slot_data, actual_slot_index, true, is_selected)

	_update_selected_label()


func _update_selected_label() -> void:
	if selected_item_label == null or bound_inventory == null:
		return

	if active_pin_index >= 0 and active_pin_index < bound_inventory.pinned_indices.size():
		var actual_slot_index = bound_inventory.pinned_indices[active_pin_index]
		if actual_slot_index >= 0 and actual_slot_index < bound_inventory.slot_datas.size():
			var slot_data = bound_inventory.slot_datas[actual_slot_index]
			if slot_data and slot_data.item:
				selected_item_label.text = slot_data.item.get_localized_name()
				return

	selected_item_label.text = ""
