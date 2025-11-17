extends Node

#region coins
signal coins_changed(old_value, new_value)
@export var coins := 10
signal max_coins_changed(old_value, new_value)
@export var max_coins := 10

func add_coins(value) -> void:
	set_coins(coins + value)

func set_coins(value) -> void:
	var old_value = coins
	coins = value
	if coins > max_coins:
		max_coins_changed.emit(max_coins, coins)
		max_coins = coins
	coins_changed.emit(old_value, coins)
	
func spend_coins(value) -> bool:
	if coins < value:
		return false
	add_coins(-value)
	return true
#endregion

#region vacuum
@export var has_vacuum := false
#endregion

#region collection_radius
signal collection_radius_changed(old_value, new_value)
@export var collection_radius := 0

func add_collection_radius(value) -> void:
	set_collection_radius(collection_radius + value)

func set_collection_radius(value) -> void:
	var old_value = collection_radius
	collection_radius = value
	collection_radius_changed.emit(old_value, collection_radius)
#endregion
