class_name PlayerInteractionZone
extends Area3D

## Stores all interactable objects currently within the proximity sphere
var nearby_interactables: Array[Interactable] = []

## The closest object the player can currently interact with
var focused_interactable: Interactable = null

func _ready() -> void:
	# Connect area signals to auto-detect items entering/exiting reach
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _physics_process(_delta: float) -> void:
	_update_focused_interactable()

func _unhandled_input(event: InputEvent) -> void:
	# Press interact key ('E')
	if event.is_action_pressed(&"interact"):
		if focused_interactable and focused_interactable.is_interactable:
			focused_interactable.interact(get_owner())

func _on_area_entered(area: Area3D) -> void:
	var interactable := _find_interactable(area)
	if interactable and not nearby_interactables.has(interactable):
		nearby_interactables.append(interactable)

func _on_area_exited(area: Area3D) -> void:
	var interactable := _find_interactable(area)
	if interactable:
		nearby_interactables.erase(interactable)

## Calculates which item in the sphere is closest to the player
func _update_focused_interactable() -> void:
	# Clean out invalid or deleted nodes
	nearby_interactables = nearby_interactables.filter(func(item): return is_instance_valid(item))

	if nearby_interactables.is_empty():
		_set_focused(null)
		return

	var closest_item: Interactable = null
	var shortest_distance := INF
	var player_pos := global_position

	for item in nearby_interactables:
		if not item.is_interactable:
			continue
			
		var dist := player_pos.distance_squared_to(item.global_position)
		if dist < shortest_distance:
			shortest_distance = dist
			closest_item = item

	_set_focused(closest_item)

func _set_focused(new_focus: Interactable) -> void:
	if focused_interactable != new_focus:
		focused_interactable = new_focus
		if focused_interactable:
			print("Focused item: %s [%s]" % [focused_interactable.name, focused_interactable.prompt_message])

## Recursively searches node tree for Interactable script
func _find_interactable(node: Node) -> Interactable:
	var current := node
	while current != null and current is Node3D:
		if current is Interactable:
			return current as Interactable
		current = current.get_parent()
	return null
