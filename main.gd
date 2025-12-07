extends Node2D
class_name Main

@onready var coins_label: Label = %CoinsLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var collection_radius_label: Label = %CollectionRadiusLabel
@onready var coin_lifespan_label: Label = %CoinLifespanLabel

@onready var tank: Tank = $Tank
@onready var buy_vacuum_button: Button = %BuyVacuum
@onready var buy_capacity_button: Button = %BuyCapacity
@onready var buy_collection_radius_button: Button = %BuyCollectionRadius
@onready var buy_coin_lifespan_button: Button = %BuyCoinLifespan


@export var store_fish: Array[FishData] = []
@onready var store: VBoxContainer = $CanvasLayer/VBoxContainer/Store

@export var fish_scene: PackedScene
@export var fish_store_entry_scene: PackedScene

var produced = {}

var vacuum_cost := 50
var capacity_cost := 100
var collection_radius_cost := 50
var coin_lifespan_cost := 1
var touchscreen := false

func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		touchscreen = true
	SignalBus.coin_collected.connect(Player.add_coins)
	Player.coins_changed.connect(handle_coins_changed)
	handle_coins_changed(0,Player.coins)
	Player.collection_radius_changed.connect(func (old,new): set_collection_radius_label())
	set_collection_radius_label()
	Player.coin_lifespan_changed.connect(func (old,new): set_coin_lifespan_label())
	set_coin_lifespan_label()
	var unlock = preload("res://unlocks/unlock.tscn")
	for fish_data in store_fish:
		var fish_store_entry = fish_store_entry_scene.instantiate()
		var unlock_instance : Unlock = unlock.instantiate()
		unlock_instance.setup(fish_data.name, fish_data.cost/10, fish_store_entry)
		unlocks.append(unlock_instance)
		fish_store_entry.add_child(unlock_instance)
		unlock_instance.update()
		store.add_child(fish_store_entry)
		if fish_store_entry is FishStoreEntry:
			fish_store_entry.fish = fish_data
			fish_store_entry.update_text()
			fish_store_entry.request_buy.connect(buy_fish.bind(fish_store_entry))
			fish_store_entry.request_sell.connect(sell_fish.bind(fish_store_entry))
	update_unlocks()
	
func handle_coins_changed(old, new):
	coins_label.text = "Coins\n" + str(new)
	buy_vacuum_button.disabled = new < vacuum_cost
	buy_capacity_button.disabled = new < capacity_cost
	buy_collection_radius_button.disabled = new < collection_radius_cost
	buy_coin_lifespan_button.disabled = new < coin_lifespan_cost || len(tank.fishes) < 1
	if quantity_multiplier == -1:
		update_store()

func quit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func set_capacity_label() -> void:
	capacity_label.text = "Fish\n" + str(len(tank.fishes)) + " / " + str(tank.capacity)

func set_collection_radius_label() -> void:
	collection_radius_label.text = "Collect Distance\n" + str(Player.collection_radius) 

func set_coin_lifespan_label() -> void:
	coin_lifespan_label.text = "Coin Lifespan\n" + str(Player.coin_lifespan)

func buy_fish(fish_data, fish_store_entry) -> void:
	if quantity_multiplier == -1:
		while Player.coins >= fish_data.cost and len(tank.fishes) < tank.capacity:
			print("Player.coins %s, fish_data.cost %s" % [Player.coins, fish_data.cost])
			_buy_fish(fish_data, fish_store_entry)
	else:
		for i in range(quantity_multiplier):
			_buy_fish(fish_data, fish_store_entry)
			
func _buy_fish(fish_data, fish_store_entry) -> void:
	var fish = add_fish(fish_data)
	if fish != null:
		var update_quantity = func():fish_store_entry.update_quantity(tank.how_many_fry(fish.fish_data), tank.how_many_fish(fish.fish_data))
		fish.grew.connect(update_quantity)
		update_quantity.call()
		if fish_data.name not in produced:
			produced[fish_data.name] = 0
		produced[fish_data.name] += 1

func add_fish(fish_data) -> Fish:
	if Player.spend_coins(fish_data.cost):
		var fish = fish_scene.instantiate()
		fish.fish_data = fish_data
		if not tank.add_fish(fish): # Refund if the tank is unable to add the fish
			Player.add_coins(fish_data.cost)
			return null
		else:
			fish.fish_data = fish_data
			set_capacity_label()
			return fish
	return null

func sell_fish(fish_data, fish_store_entry = null) -> void:
	if quantity_multiplier == -1:
		while tank.how_many_fish(fish_data) > 0:
			_sell_fish(fish_data, fish_store_entry)
	else:
		for i in range(quantity_multiplier):
			_sell_fish(fish_data, fish_store_entry)
			
func _sell_fish(fish_data, fish_store_entry) -> void:
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
		capacity_cost = ceili(capacity_cost * 1.5)
		tank.capacity += 1
		buy_capacity_button.text = "Buy +1 Capacity - " + str(capacity_cost) + " coins"
		set_capacity_label()

func buy_collection_radius() -> void:
	if Player.spend_coins(collection_radius_cost):
		collection_radius_cost = ceili(collection_radius_cost * 1.7)
		Player.add_collection_radius(1)
		buy_collection_radius_button.text = "Buy +1 Merge/Collect Distance - " + str(collection_radius_cost) + " coins"

func buy_coin_lifespan() -> void:
	if Player.spend_coins(coin_lifespan_cost):
		coin_lifespan_cost += 1
		Player.add_coin_lifespan(1)
		buy_coin_lifespan_button.text = "Buy +1 Coin Lifespan - " + str(coin_lifespan_cost) + " coins"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_add_money"):
		Player.add_coins(10000)
	if event.is_action_pressed("debug_add_collection_radius"):
		Player.add_collection_radius(1)
	if event.is_action_pressed("grow_all"):
		for fish in tank.fishes:
			fish.grow()


#region unlocks


@export var unlocks : Array[Unlock] = []

	#Unlock.new("add_vacuum", buy_vacuum_button, func(): return Player.coins >= 5),
	#Unlock.new("add_collection_radius", buy_collection_radius_button, func(): return Player.coins >= 15),
	#Unlock.new("add_capacity", buy_capacity_button, func(): return Player.coins >= 10),
	#Unlock.new("add_coin_lifespan", buy_coin_lifespan_button, func(): return Player.coins >= 1),

func update_unlocks() -> void:
	for unlock in unlocks:
		unlock.update()


func _on_update_timer_timeout() -> void:
	update_unlocks()
	handle_coins_changed(Player.coins, Player.coins)

#endregion

@onready var quantity_buttons: HBoxContainer = $CanvasLayer/VBoxContainer/Store/QuantityButtons
var quantity_multiplier := 1
var quantities : Array[int]= [
	1,5,10,25,-1
]
func _on_quantity_button_pressed() -> void:
	var children := quantity_buttons.get_children()
	for i in range(len(children)):
		var option := children[i]
		if option is Button:
			if option.button_pressed:
				quantity_multiplier = quantities[i]
				update_store()

func update_store():
	var children: Array[Node] = store.get_children().filter(func(child):return child is FishStoreEntry)
	for i in range(len(children)):
		var store_entry := children[i]
		if store_entry is FishStoreEntry:
			if quantity_multiplier == -1:
				var quantity_to_buy := mini(Player.coins / store_fish[i].cost, tank.capacity - len(tank.fishes))
				var quantity_to_sell := tank.how_many_fish(store_fish[i])
				store_entry.buy_button.text = "Buy %s Fry - Max\n%s coins" % [quantity_to_buy, store_fish[i].cost * quantity_to_buy]
				store_entry.sell_button.text = "Sell %s Adults - Max\n%s coins" % [quantity_to_sell, store_fish[i].sell_price * quantity_to_sell]
				print("----\nq2b: %s\nq2s: %s\n" % [quantity_to_buy, quantity_to_sell])
			else:
				store_entry.buy_button.text = "Buy %s Fry\n%s coins" % [quantity_multiplier, store_fish[i].cost * quantity_multiplier]
				store_entry.sell_button.text = "Sell %s Adults\n%s coins" % [quantity_multiplier, store_fish[i].sell_price * quantity_multiplier]
