extends Node2D
class_name Tank

signal request_add_coins(value)

@export var fishes: Array[Fish] = []
@export var capacity := 10

func _ready() -> void:
	for fish in fishes:
		fish.request_drop.connect(_on_drop_request)

func _on_drop_request(instance, pos, vel) -> void:
	add_to_tank(instance, pos, vel)

func add_fish(fish: Fish) -> bool:
	if len(fishes) >= capacity:
		return false
	add_to_tank(fish, Vector2(randi_range(300,340),randi_range(20,240)))
	fishes.append(fish)
	fish.request_drop.connect(add_to_tank)
	if randf() < 0.5:
		fish.flip_h()
	return true
	
func add_to_tank(instance: PhysicsBody2D, pos: Vector2, vel := Vector2.ZERO) -> void:
	add_child(instance)
	instance.position = pos
	if instance is RigidBody2D:
		instance.linear_velocity = vel
	elif instance is CharacterBody2D:
		instance.velocity = vel

func how_many_fry(fish_data: FishData) -> int:
	return len(fishes.filter(func(fish): return fish.fish_data == fish_data and not fish.is_adult))
	
func how_many_fish(fish_data: FishData) -> int:
	return len(fishes.filter(func(fish): return fish.fish_data == fish_data and fish.is_adult))
