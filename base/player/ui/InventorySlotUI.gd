class_name InventorySlotUI
extends PanelContainer

signal slot_dropped(origin_index: int, target_index: int)
signal slot_pin_requested(index: int)

@onready var icon: TextureRect = $Icon
@onready var quantity_label: Label = $QuantityLabel
@onready var pin_indicator: Control = get_node_or_null("PinIndicator")
@onready var selection_border: Control = get_node_or_null("SelectionBorder")
@onready var drop_preview_border: Control = get_node_or_null("DropPreviewBorder")

var slot_index: int = -1
var slot_data: SlotData

func _ready() -> void:
	# Hide drop border at start
	if drop_preview_border:
		drop_preview_border.visible = false
		
	# Connect mouse exit to clear highlight
	mouse_exited.connect(_on_mouse_exited)

func update_slot(data: SlotData, index: int, is_pinned: bool = false, is_selected: bool = false) -> void:
	slot_index = index
	slot_data = data

	if pin_indicator:
		pin_indicator.visible = is_pinned
		
	if selection_border:
		selection_border.visible = is_selected

	if slot_data and slot_data.item_data:
		icon.texture = slot_data.item_data.icon
		icon.visible = true
		
		# Build multi-line tooltip string with Name and Description
		var item_name = slot_data.item_data.get_localized_name()
		var item_desc = slot_data.item_data.get_localized_description()
		
		if item_desc.is_empty():
			tooltip_text = item_name
		else:
			tooltip_text = "%s\n%s" % [item_name, item_desc]

		if slot_data.quantity > 1:
			quantity_label.text = str(slot_data.quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		icon.texture = null
		icon.visible = false
		quantity_label.visible = false
		tooltip_text = ""

func _on_mouse_exited() -> void:
	if drop_preview_border:
		drop_preview_border.visible = false

# 1. Initiates the drag when left-clicking and dragging a filled slot
func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_data == null or slot_data.item_data == null:
		return null

	# Create a dedicated TextureRect for the drag preview
	var drag_preview = TextureRect.new()
	drag_preview.texture = slot_data.item_data.icon
	
	# Prevent texture warping & maintain aspect ratio
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_preview.custom_minimum_size = Vector2(40, 40) # Match your slot's icon size
	drag_preview.modulate = Color(1, 1, 1, 0.8)

	# Wrap in a Control container so it centers on the mouse cursor
	var preview_control = Control.new()
	preview_control.add_child(drag_preview)
	drag_preview.position = -drag_preview.custom_minimum_size / 2.0
	
	set_drag_preview(preview_control)

	return {
		"origin_index": slot_index,
		"slot_data": slot_data
	}

# 2. Checks if a dragged item can be dropped here and highlights the target slot
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var is_valid = typeof(data) == TYPE_DICTIONARY and data.has("origin_index")
	
	# Only highlight this specific slot if the drag payload is valid
	if drop_preview_border:
		drop_preview_border.visible = is_valid
		
	return true

# 3. Executes the item swap when releasing the mouse button
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if drop_preview_border:
		drop_preview_border.visible = false
		
	if typeof(data) == TYPE_DICTIONARY and data.has("origin_index"):
		slot_dropped.emit(data["origin_index"], slot_index)
	pass
	
# 4. Hide drop indicator preview if mouse leaves the slot boundary
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if drop_preview_border:
			drop_preview_border.visible = false
