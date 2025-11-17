extends Node2D

@export var radius = 8.0

func _draw():
	var center = Vector2(0, 0) # Center of the circle
	var color = Color.GOLD # Color of the circle
	draw_circle(center, radius, color, false)
