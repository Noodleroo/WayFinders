class_name Entity
extends CharacterBody3D

signal health_changed(new_health: float, max_health: float)
signal died

@export_group("Entity Data")
## Drag your .tres EntityData resource into this slot in the Inspector
@export var data: EntityData

@export_group("Visuals & Animation")
## Node container holding the 3D mesh model (e.g. MeshInstance3D or imported .gltf/.scn node)
@export var model_node: Node3D

## Optional AnimationPlayer node attached to the entity's model
@export var anim_player: AnimationPlayer

## Optional AnimationTree node if using blend trees for locomotion
@export var anim_tree: AnimationTree

@export_group("Display Settings")
## Controls whether the 3D name and health label is visible above the entity
@export var show_label: bool = true:
	set(value):
		show_label = value
		if is_instance_valid(status_label):
			status_label.visible = show_label

## Height offset above the entity's origin for the floating label
@export var label_offset: Vector3 = Vector3(0, 2.2, 0)

@export_group("Behavior Settings")
## If true, this entity will not initiate attacks or flee by default
@export var is_passive: bool = true

var current_health: float = 100.0
var move_speed: float = 5.0
var acceleration: float = 10.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var status_label: Label3D

func _ready() -> void:
	set_physics_process(true)
	_setup_status_label()
	_apply_entity_data()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	_update_locomotion_animation()
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

## Automatically updates locomotion animations (idle vs move) based on current velocity
func _update_locomotion_animation() -> void:
	if anim_player == null:
		return

	# Calculate horizontal speed ignoring vertical gravity
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var speed_sq := horizontal_velocity.length_squared()

	if speed_sq > 0.1:
		play_animation("walk") # Plays "walk" or "run" animation if available
	else:
		play_animation("idle") # Plays "idle" animation when standing still

## Helper method to play animations safely without crashing if the animation name doesn't exist
func play_animation(anim_name: StringName, custom_blend: float = -1.0, custom_speed: float = 1.0) -> bool:
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name, custom_blend, custom_speed)
		return true
	return false

func take_damage(amount: float) -> void:
	var max_hp := data.max_health if data else 100.0
	current_health = maxf(0.0, current_health - amount)
	
	# Try playing a "hurt" animation if one exists
	play_animation("hurt")

	update_status_label()
	health_changed.emit(current_health, max_hp)
	
	if current_health <= 0.0:
		die()

func die() -> void:
	# Try playing a "death" animation before freeing node
	if play_animation("death"):
		# Wait for death animation to finish before freeing node
		await anim_player.animation_finished
	
	died.emit()
	queue_free()

func _setup_status_label() -> void:
	status_label = Label3D.new()
	status_label.name = "StatusLabel3D"
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.pixel_size = 0.005
	status_label.position = label_offset
	status_label.visible = show_label
	status_label.font_size = 32
	status_label.outline_size = 8
	add_child(status_label)

func _apply_entity_data() -> void:
	if data:
		current_health = data.max_health
		move_speed = data.move_speed
		acceleration = data.acceleration
	
	update_status_label()

func update_status_label() -> void:
	if status_label == null:
		return
		
	var display_name: String = data.entity_name if data else String(name)
	var max_hp := data.max_health if data else 100.0
	
	status_label.text = "%s\n[%.0f / %.0f]" % [display_name, current_health, max_hp]
