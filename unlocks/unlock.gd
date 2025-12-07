@tool
class_name Unlock
extends Node

@export var display_name := "Unnamed Unlock"
@export var value := false
@export var coin_value := 10
@export var to_hide : Node = null
var unlock_condition : Callable = func(): return Player.coins >= coin_value

func setup(name, coin_value, target):
	self.display_name = name
	self.coin_value = coin_value
	self.to_hide = target
	

func check() -> bool:
	if not value and unlock_condition.call():
		unlock()
	return value

func unlock() -> void:
	self.value = true

@export_tool_button("Update") var update_tool_button = Callable(self, "update")
func update() -> void:
	if self.to_hide:
		self.to_hide.visible = self.check()
