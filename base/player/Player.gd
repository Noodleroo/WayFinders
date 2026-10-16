extends CharacterBody3D

@onready var coyote_check: RayCast3D = $CoyoteCheck
@onready var ceiling_check: RayCast3D = $CeilingCheck
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D
@onready var camera_rig: CameraControls
@onready var active_item_mesh: MeshInstance3D = $ItemHoldPoint/ActiveItemMesh
@onready var interaction_ray: RayCast3D = $CameraRig/SpringArm3D/Camera3D/InteractionRay

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

var jump_buffer_timer: float = 0.0
const JUMP_BUFFER_DURATION: float = 0.15
var coyote_timer: float = 0.0
const COYOTE_DURATION: float = 0.15

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _enter_tree() -> void:
	var id := name.to_int()
	if id != 0:
		set_multiplayer_authority(id)
	else:
		set_multiplayer_authority(multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1)


func _ready() -> void:
	inventory = InventorySaveSystem.load_inventory(20)
	if inventory:
		inventory.inventory_updated.connect(_on_inventory_updated)

	var hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	if hotbar_ui_scene:
		hotbar_ui = hotbar_ui_scene.instantiate() as PinnedHotbarUI
		hud_layer.add_child(hotbar_ui)
		hotbar_ui.bind_inventory(inventory)

	if inventory_ui_scene:
		var instance = inventory_ui_scene.instantiate()
		if instance is InventoryUI:
			inventory_ui = instance
			hud_layer.add_child(inventory_ui)
			inventory_ui.bind_inventory(inventory)
			inventory_ui.visible = false

	select_hotbar_slot(0)

func _on_inventory_updated(_inv_data: InventoryData) -> void:
	if hotbar_ui:
		hotbar_ui.refresh_hotbar_wrapper()

func _unhandled_input(event: InputEvent) -> void:
	if inventory == null or inventory.pinned_indices.is_empty():
		return

	var pin_count = inventory.pinned_indices.size()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var target_index = event.keycode - KEY_1
			if target_index < pin_count:
				select_hotbar_slot(target_index)

	if event.is_action_pressed("hotbar_next"):
		cycle_hotbar_slot(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hotbar_prev"):
		cycle_hotbar_slot(-1)
		get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		var axe = ItemRegistry.get_item("forest_axe")
		if axe and inventory:
			inventory.add_item(axe, 1)
			var target_slot_index = inventory.pinned_indices[active_pin_index]
			var slot = inventory.slot_datas[target_slot_index]
			_update_held_item_mesh(slot)

	if event.is_action_pressed("primary_action"):
		var pinned_item = inventory.get_item_in_slot(active_pin_index)
		if pinned_item != null:
			print("Using primary action with ", inventory.get_item_name(active_pin_index))
		else: print("Using primary action with Fists")
		use_pinned_item(active_pin_index)
		get_viewport().set_input_as_handled()

func select_hotbar_slot(index: int) -> void:
	active_pin_index = index

	if hotbar_ui:
		hotbar_ui.set_active_slot(active_pin_index)

	if inventory == null or inventory.pinned_indices.is_empty():
		_update_held_item_mesh(null)
		return

	if active_pin_index >= 0 and active_pin_index < inventory.pinned_indices.size():
		var target_slot_index = inventory.pinned_indices[active_pin_index]
		if target_slot_index >= 0 and target_slot_index < inventory.slot_datas.size():
			var slot = inventory.slot_datas[target_slot_index]
			_update_held_item_mesh(slot)
		else:
			_update_held_item_mesh(null)
	else:
		_update_held_item_mesh(null)

func cycle_hotbar_slot(direction: int) -> void:
	if inventory == null or inventory.pinned_indices.is_empty():
		return

	var max_pins = inventory.pinned_indices.size()
	active_pin_index = posmod(active_pin_index + direction, max_pins)
	select_hotbar_slot(active_pin_index)

func use_pinned_item(pin_slot_index: int) -> void:
	if inventory and pin_slot_index < inventory.pinned_indices.size():
		var actual_slot_index = inventory.pinned_indices[pin_slot_index]
		if actual_slot_index >= 0 and actual_slot_index < inventory.slot_datas.size():
			var slot = inventory.slot_datas[actual_slot_index]
			if slot and slot.item:
				var target_info = {}
				slot.item.use_primary(self, target_info)

func use_active_tool_or_weapon() -> void:
	if inventory == null or active_pin_index >= inventory.pinned_indices.size():
		print("[Debug] Inventory is null or slot index out of bounds.")
		return

	var actual_slot_index = inventory.pinned_indices[active_pin_index]
	var slot = inventory.slot_datas[actual_slot_index]

	if slot == null or slot.item == null:
		print("[Debug] Selected slot is empty!")
		return

	print("[Debug] Attempting to use item: ", slot.item.resource_path)

	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		print("[Debug] RayCast hit object: ", collider.name, " | Path: ", collider.get_path())
		
		var target_info = {
			"collider": collider,
			"point": interaction_ray.get_collision_point(),
			"normal": interaction_ray.get_collision_normal()
		}

		if slot.item.has_method("use_primary"):
			slot.item.use_primary(self, target_info)
	else:
		print("[Debug] RayCast is NOT colliding with anything.")

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
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_on_floor():
		coyote_timer = COYOTE_DURATION
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("movement_jump"):
		jump_buffer_timer = JUMP_BUFFER_DURATION
	else:
		jump_buffer_timer -= delta

	var can_coyote_jump := coyote_timer > 0.0 and coyote_check.is_colliding()
	var has_buffered_jump := jump_buffer_timer > 0.0

	if has_buffered_jump and (is_on_floor() or can_coyote_jump):
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		if is_crouching and can_uncrouch():
			toggle_crouch()
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("movement_crouch"):
		toggle_crouch()

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
		
		var target_angle := atan2(direction.x, direction.z) + PI
		# Adjust 12.0 to control rotation speed (higher = faster turn, lower = smoother turn)
		rotation.y = lerp_angle(rotation.y, target_angle, 6.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	if camera_rig:
		camera_rig.global_position = global_position

func toggle_crouch() -> void:
	if is_crouching and not can_uncrouch():
		return

	is_crouching = not is_crouching

	if is_crouching:
		current_speed = crouch_speed
		collision_shape.shape.height = CROUCH_HEIGHT
		mesh_instance.mesh.height = CROUCH_HEIGHT
	else:
		current_speed = SPEED
		collision_shape.shape.height = STAND_HEIGHT
		mesh_instance.mesh.height = STAND_HEIGHT

	collision_shape.position.y = 0.0
	mesh_instance.position.y = 0.0

func can_uncrouch() -> bool:
	return not ceiling_check.is_colliding()

func _update_held_item_mesh(slot: SlotData) -> void:
	if active_item_mesh == null:
		return

	if slot and slot.item:
		if "item_mesh" in slot.item and slot.item.item_mesh:
			active_item_mesh.mesh = slot.item.item_mesh
			active_item_mesh.visible = true
			return

		if not slot.item.id.is_empty():
			var mesh_path = "res://resources/wayfinders/items/meshes/" + slot.item.id + "_mesh.tres"
			if ResourceLoader.exists(mesh_path):
				active_item_mesh.mesh = load(mesh_path) as Mesh
				active_item_mesh.visible = true
				return

	active_item_mesh.mesh = null
	active_item_mesh.visible = false
