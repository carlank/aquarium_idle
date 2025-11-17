extends Resource
class_name FishData

signal spawned()
signal grown()

@export var name := "Unnamed Fish"
@export var sprite_frames: SpriteFrames

@export var cost := 10
@export var sell_price := 20

@export var thrust_max := 25.0
@export var lift_max := 50.0
@export var lift_delta_max := 1.0
@export var reward_amount := 1
@export var reward_delay := 1.0

# How many seconds until this fish becomes an adult?
@export var growth_delay := 10.0
