extends Node2D

@onready var coins_label: Label = %CoinsLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var collection_radius_label: Label = %CollectionRadiusLabel

@onready var tank: Tank = $Tank
@onready var buy_vacuum_button: Button = %BuyVacuum
@onready var buy_capacity_button: Button = %BuyCapacity
@onready var buy_collection_radius_button: Button = %BuyCollectionRadius

@export var store_fish: Array[FishData] = []
@onready var store: VBoxContainer = $CanvasLayer/VBoxContainer/Store

@export var fish_scene: PackedScene
@export var fish_store_entry_scene: PackedScene

var vacuum_cost := 50
var capacity_cost := 100
var collection_radius_cost := 50

func _ready() -> void:
	SignalBus.coin_collected.connect(Player.add_coins)
	Player.coins_changed.connect(handle_coins_changed)
	handle_coins_changed(0,Player.coins)
	Player.collection_radius_changed.connect(func (old,new): set_collection_radius_label())
	set_collection_radius_label()
	for fish_data in store_fish:
		var fish_store_entry = fish_store_entry_scene.instantiate()
		store.add_child(fish_store_entry)
		if fish_store_entry is FishStoreEntry:
			fish_store_entry.fish = fish_data
			fish_store_entry.update_text()
			fish_store_entry.request_buy.connect(buy_fish.bind(fish_store_entry))
			fish_store_entry.request_sell.connect(sell_fish.bind(fish_store_entry))

func handle_coins_changed(old, new):
	coins_label.text = "Coins\n" + str(new)
	buy_vacuum_button.disabled = new < vacuum_cost
	buy_capacity_button.disabled = new < capacity_cost
	buy_collection_radius_button.disabled = new < collection_radius_cost


func quit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func set_capacity_label() -> void:
	capacity_label.text = "Fish\n" + str(len(tank.fishes)) + " / " + str(tank.capacity)

func set_collection_radius_label() -> void:
	collection_radius_label.text = "Collect Distance\n" + str(Player.collection_radius) 

func buy_fish(fish_data, fish_store_entry) -> void:
	var fish = add_fish(fish_data)
	if fish != null:
		var update_quantity = func():fish_store_entry.update_quantity(tank.how_many_fry(fish.fish_data), tank.how_many_fish(fish.fish_data))
		fish.grew.connect(update_quantity)
		update_quantity.call()

func add_fish(fish_data) -> Fish:
	if Player.spend_coins(fish_data.cost):
		var fish = fish_scene.instantiate()
		if not tank.add_fish(fish): # Refund if the tank is unable to add the fish
			Player.add_coins(fish_data.cost)
			return null
		else:
			fish.fish_data = fish_data
			set_capacity_label()
			return fish
	return null

func sell_fish(fish_data, fish_store_entry = null) -> void:
	var to_erase = tank.fishes.find_custom(func(f):return f.fish_data == fish_data and f.is_adult)
	if to_erase == -1:
		return
	var fish = tank.fishes[to_erase]
	fish.queue_free()
	Player.add_coins(fish.fish_data.sell_price)
	tank.fishes.remove_at(to_erase)
	set_capacity_label()
	if fish_store_entry:
		fish_store_entry.update_quantity(tank.how_many_fry(fish.fish_data), tank.how_many_fish(fish.fish_data))

func buy_vacuum() -> void:
	if Player.has_vacuum:
		return
	if Player.spend_coins(vacuum_cost):
		Player.has_vacuum = true
		buy_vacuum_button.disabled = true
		buy_vacuum_button.text = "AutoCollect - Already Purchased"
		
func buy_capacity() -> void:
	if Player.spend_coins(capacity_cost):
		capacity_cost = ceili(capacity_cost * 2)
		tank.capacity += 1
		buy_capacity_button.text = "Buy +1 Capacity - " + str(capacity_cost) + " coins"
		set_capacity_label()

func buy_collection_radius() -> void:
	if Player.spend_coins(collection_radius_cost):
		collection_radius_cost = ceili(collection_radius_cost * 2)
		Player.add_collection_radius(1)
		buy_collection_radius_button.text = "Buy +1 Merge/Collect Distance - " + str(collection_radius_cost) + " coins"
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_add_money"):
		Player.add_coins(10000)
	if event.is_action_pressed("debug_add_collection_radius"):
		Player.add_collection_radius(1)
	if event.is_action_pressed("grow_all"):
		for fish in tank.fishes:
			fish.grow()
