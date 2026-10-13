class_name CameraControls
extends Node3D

signal hotbar_cycle_requested(direction: int)

@export var mouse_sensitivity: float = 0.003
@export var pivot_height: float = 2.0

var zoom: float = 5.0
var min_zoom: float = 2.0
var max_zoom: float = 10.0
var zoom_speed: float = 0.5

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera_3d: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	top_level = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func make_current() -> void:
	if camera_3d:
		camera_3d.make_current()


func _unhandled_input(event: InputEvent) -> void:
	# 1. Handle Scroll Wheel (Shift + Scroll = Cycle Hotbar | Normal Scroll = Zoom)
	if event is InputEventMouseButton and event.is_pressed():
		if Input.is_key_pressed(KEY_SHIFT):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				hotbar_cycle_requested.emit(-1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				hotbar_cycle_requested.emit(1)
		else:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom = clamp(zoom - zoom_speed, min_zoom, max_zoom)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom = clamp(zoom + zoom_speed, min_zoom, max_zoom)

	# 2. Handle Mouse Looking (Unified single pass)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate entire rig around Y axis (Yaw)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate SpringArm around X axis (Pitch) with limits
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-70.0), deg_to_rad(60.0))
		
		# Lock roll/yaw on SpringArm to prevent axis twisting
		spring_arm.rotation.y = 0.0
		spring_arm.rotation.z = 0.0


func _process(delta: float) -> void:
	if get_parent() is Node3D:
		global_position = get_parent().global_position + Vector3(0, pivot_height, 0)
		
	spring_arm.spring_length = lerp(spring_arm.spring_length, zoom, delta * 10.0)
