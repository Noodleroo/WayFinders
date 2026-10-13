extends CharacterBody3D

@onready var coyote_check: RayCast3D = $CoyoteCheck
@onready var ceiling_check: RayCast3D = $CeilingCheck
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D
@onready var camera_rig: CameraControls

@export var hotbar_ui_scene: PackedScene = preload("res://wayfinders/base/player/ui/pinned_hotbar_ui.tscn")
@export var inventory_ui_scene: PackedScene
var inventory_ui: InventoryUI
var hotbar_ui: PinnedHotbarUI
var inventory: InventoryData
var active_pin_index: int = 0

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 7.0
const STAND_HEIGHT: float = 2.0
const CROUCH_HEIGHT: float = 1.0

var crouch_speed: float = SPEED * 0.5
var current_speed: float = SPEED
var is_crouching: bool = false

# Jump Buffer & Coyote Time
var jump_buffer_timer: float = 0.0
const JUMP_BUFFER_DURATION: float = 0.15

var coyote_timer: float = 0.0
const COYOTE_DURATION: float = 0.15

# Get default gravity from Godot project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree() -> void:
	var id := name.to_int()
	if id != 0:
		set_multiplayer_authority(id)
	else:
		set_multiplayer_authority(multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1)

func _ready() -> void:
	inventory = InventorySaveSystem.load_inventory(20)
	inventory.inventory_updated.connect(_on_inventory_updated)
	
	var hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	if camera_rig:
		camera_rig.hotbar_cycle_requested.connect(cycle_hotbar_slot)

	if hotbar_ui_scene:
		hotbar_ui = hotbar_ui_scene.instantiate() as PinnedHotbarUI
		hud_layer.add_child(hotbar_ui)
		hotbar_ui.bind_inventory(inventory)
		# Hotbar remains visible at all times!

	if inventory_ui_scene:
		var instance = inventory_ui_scene.instantiate()
		if instance is InventoryUI:
			inventory_ui = instance
			hud_layer.add_child(inventory_ui)
			inventory_ui.bind_inventory(inventory)
			inventory_ui.visible = false

	if inventory_ui_scene:
		# Instantiate the UI
		var instance = inventory_ui_scene.instantiate()
		
		# Verify casting succeeded
		if instance is InventoryUI:
			inventory_ui = instance
			
			# Wrap in CanvasLayer so it stays on screen
			var canvas_layer = CanvasLayer.new()
			canvas_layer.add_child(inventory_ui)
			add_child(canvas_layer)
			
			inventory_ui.bind_inventory(inventory)
			inventory_ui.visible = false
		else:
			push_error("inventory_ui_scene root node does not extend InventoryUI!")
	else:
		push_error("Inventory UI Scene is missing on Player! Assign it in the Inspector.")

func _on_inventory_updated(inv_data: InventoryData) -> void:
	print("Player inventory updated! Current cargo weight: ", inv_data.get_total_weight())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Shift + Scroll Wheel -> Hotbar Slot Cycling
		if Input.is_key_pressed(KEY_SHIFT):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				cycle_hotbar_slot(-1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cycle_hotbar_slot(1)
		# Regular Scroll Wheel -> Camera Zooming
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		var axe = ItemDatabase.get_item("forest_axe")
		if axe and inventory:
			inventory.add_item(axe, 1)
			print("Gave player: ", axe.get_localized_name())

func select_hotbar_slot(index: int) -> void:
	active_pin_index = index
	
	# Update Pinned HUD Hotbar
	if hotbar_ui:
		hotbar_ui.set_active_slot(active_pin_index)
		
	# Update Main Grid UI Selection Highlight
	if inventory_ui:
		inventory_ui.set_active_slot(active_pin_index)

func cycle_hotbar_slot(direction: int) -> void:
	if inventory == null or inventory.pinned_indices.is_empty():
		return
		
	var max_pins = inventory.pinned_indices.size()
	active_pin_index = posmod(active_pin_index + direction, max_pins)
	select_hotbar_slot(active_pin_index)

func use_pinned_item(pin_slot_index: int) -> void:
	if inventory and pin_slot_index < inventory.pinned_indices.size():
		var actual_slot_index = inventory.pinned_indices[pin_slot_index]
		var slot = inventory.slot_datas[actual_slot_index]
		
		if slot and slot.item_data:
			# Use get_localized_name() instead of .name
			print("Used pinned item: ", slot.item_data.get_localized_name())
			
			# Execute the item's action if present
			if slot.item_data.primary_action:
				var target_info = {} # Add raycast/target dictionary here if needed
				slot.item_data.primary_action.execute(self, slot.item_data, target_info)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if inventory_ui:
			inventory_ui.visible = not inventory_ui.visible
			
			if inventory_ui.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	if inventory:
		InventorySaveSystem.save_inventory(inventory)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 1. Update Timers
	if is_on_floor():
		coyote_timer = COYOTE_DURATION
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("movement_jump"):
		jump_buffer_timer = JUMP_BUFFER_DURATION
	else:
		jump_buffer_timer -= delta

	# 2. Check Jump Conditions
	var can_coyote_jump := coyote_timer > 0.0 and coyote_check.is_colliding()
	var has_buffered_jump := jump_buffer_timer > 0.0

	if has_buffered_jump and (is_on_floor() or can_coyote_jump):
		coyote_timer = 0.0
		jump_buffer_timer = 0.0  # Consume buffer

		if is_crouching:
			if can_uncrouch():
				toggle_crouch()
				velocity.y = JUMP_VELOCITY
		else:
			velocity.y = JUMP_VELOCITY

	# 3. Crouch Input
	if Input.is_action_just_pressed("movement_crouch"):
		toggle_crouch()

	# 4. Movement Calculation
	var input_dir := Input.get_vector("movement_left", "movement_right", "movement_up", "movement_down")
	var direction := Vector3.ZERO

	if input_dir != Vector2.ZERO:
		var active_cam := get_viewport().get_camera_3d()
		var cam_basis: Basis

		if active_cam:
			cam_basis = active_cam.global_transform.basis
		elif camera_rig:
			cam_basis = camera_rig.global_transform.basis
		else:
			cam_basis = global_transform.basis

		# Correct Forward (-Z) and Right (+X) vectors relative to camera
		var cam_forward: Vector3 = cam_basis.z
		var cam_right: Vector3 = cam_basis.x

		cam_forward.y = 0.0
		cam_right.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

		direction = (cam_right * input_dir.x) + (cam_forward * input_dir.y)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		var target_look := global_position + direction
		target_look.y = global_position.y

		if not global_position.is_equal_approx(target_look):
			look_at(target_look, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Sync Camera Rig Position
	if camera_rig:
		camera_rig.global_position = global_position


func toggle_crouch() -> void:
	if is_crouching and not can_uncrouch():
		return

	is_crouching = not is_crouching

	if is_crouching:
		current_speed = crouch_speed
		
		# 1. Shrink collision shape height
		collision_shape.shape.height = CROUCH_HEIGHT
		
		# 2. Offset the mesh slightly so it visually matches the crouch height
		mesh_instance.mesh.height = CROUCH_HEIGHT
		
		# Keep collision shape centered at origin (0) so move_and_slide() doesn't force it underground
		collision_shape.position.y = 0.0
		mesh_instance.position.y = 0.0
	else:
		current_speed = SPEED
		
		# Restore standing heights
		collision_shape.shape.height = STAND_HEIGHT
		mesh_instance.mesh.height = STAND_HEIGHT
		
		collision_shape.position.y = 0.0
		mesh_instance.position.y = 0.0


func can_uncrouch() -> bool:
	return not ceiling_check.is_colliding()
