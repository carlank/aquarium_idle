extends CharacterBody2D
class_name Fish

signal request_drop(instance, drop_position, drop_velocity)
signal grew()

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var drop_timer: Timer = $DropTimer
@onready var drop_point: Node2D = $DropPoint
@onready var growth_timer: Timer = $GrowthTimer
@onready var growth_progress_bar: TextureProgressBar = $GrowthProgressBar

var is_adult := false

@export var tank: Node2D

# 1 for right, -1 for left
var direction := 1
var lift := 0.1
var lift_delta := 0.0
var antiThrashFrames := 0
@export var reward_scene: PackedScene
@export var fish_data: FishData:
	set(value):
		fish_data = value
		if animated_sprite_2d:
			animated_sprite_2d.sprite_frames = value.sprite_frames
			animated_sprite_2d.animation = "growth_1_idle"

# Is this fish being dragged by the mouse?
var _dragging := false

func _ready() -> void:
	growth_timer.start(fish_data.growth_delay)
	self.modulate = Color.from_hsv(randf(),0.1,1.0);

func drop_reward() -> void:
	var reward_instance := reward_scene.instantiate()
	reward_instance.value = fish_data.reward_amount
	request_drop.emit(reward_instance, position + drop_point.position, velocity + randf_range(0,150) * Vector2.DOWN)

func grow() -> void:
	if is_adult:
		return
	is_adult = true
	drop_timer.start(fish_data.reward_delay)
	animated_sprite_2d.animation = "growth_2_idle"
	grew.emit()

func _physics_process(delta: float) -> void:
	if _dragging:
		global_position = lerp(global_position, get_global_mouse_position(), 0.5)
		#return
	if fish_data.swimmer:
		lift_delta = randf_range(-fish_data.lift_delta_max, fish_data.lift_delta_max)
		lift += lift_delta
		lift = clampf(lift, -fish_data.lift_max, fish_data.lift_max)
		velocity = Vector2(fish_data.thrust_max * direction, lift)
		#rotation = (acos(lift/thrust) - TAU/4.0) if direction < 0 else (TAU/4.0 - acos(lift/thrust))
		rotation = velocity.angle() - TAU/2 if direction < 0 else velocity.angle()
	else:
		velocity.x = fish_data.thrust_max * direction
		if position.y < 448:
			velocity.y += 10
		velocity *= 0.9
	var collision_info := move_and_collide(velocity * delta)
	if antiThrashFrames > 0:
		antiThrashFrames -= 1
	if collision_info and antiThrashFrames == 0:
		var normal = collision_info.get_normal()
		if velocity.length_squared() < 100:
			velocity = Vector2.ZERO
		velocity = velocity.bounce(normal)
		if abs(normal.x) > abs(normal.y):
			flip_h()
		else:
			flip_y()
		antiThrashFrames = 10
		if fish_data.collects_coins:
			var collider = collision_info.get_collider()
			if collider is Coin:
				collider.collect()
		
func _process(delta: float) -> void:
	if growth_timer.is_stopped():
		growth_progress_bar.visible = false
	else:
		growth_progress_bar.visible = true
		growth_progress_bar.value = 1.0 - growth_timer.time_left / fish_data.growth_delay

func flip_h() -> void:
	direction *= -1
	animated_sprite_2d.flip_h = direction < 0

func flip_y() -> void:
	lift *= -1

func _on_drop_timer_timeout() -> void:
	drop_reward()
	
func _on_growth_timer_timeout() -> void:
	grow()

func _on_grab_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("drag_fish"):
		_dragging = true
	if event.is_action_released("drag_fish"):
		_dragging = false
	# TODO This fails to trigger if the action is released while not over the fish.
	# Dragging should probably be a state of the player

	
