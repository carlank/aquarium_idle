extends RigidBody2D
class_name Coin

@onready var collect_shape: CollisionShape2D = $CollectArea2D/CollisionShape2D
@onready var collect_radius_node: Node2D = $CollectArea2D/CollectRadius

@export var value_label: Label

var value := 1:
	set(v):
		value = v
		value_label.text = str(v)
		
var merged := false

func _ready() -> void:
	self.gravity_scale = 0.05
	Player.collection_radius_changed.connect(handle_collection_radius_changed)
	handle_collection_radius_changed(0, Player.collection_radius)

func handle_collection_radius_changed(old,new):
	var old_radius = new + 8
	(collect_shape.shape as CircleShape2D).radius = 0
	collect_radius_node.radius = 0
	get_tree().create_timer(0.1).timeout.connect(func(): 
		(collect_shape.shape as CircleShape2D).radius = old_radius
		collect_radius_node.radius = old_radius
		collect_radius_node.queue_redraw()
		)

func _physics_process(delta: float) -> void:
	apply_force(Vector2(randf_range(-100,100),randf_range(-1,1)))

func _on_collect_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	var is_mouse_move := event is InputEventMouseMotion
	var vacuum_pickup := is_mouse_move and Player.has_vacuum
	if event.is_action_pressed("collect") or vacuum_pickup:
		collect()

func collect() -> void:
	queue_free()
	SignalBus.coin_collected.emit(value)


func _on_collect_area_2d_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	if body is Coin:
		if not merged and not body.merged:
			if value == body.value:
				self.value += body.value
				self.mass += body.mass
				for child in self.get_children():
					if child is Label:
						child.label_settings.font_size *= 1.1
					else:
						child.scale *= Vector2(1.1,1.1)
				body.merged = true
				body.queue_free()
