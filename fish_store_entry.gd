extends PanelContainer
class_name FishStoreEntry

@onready var name_label: RichTextLabel = $HBoxContainer/Name
@onready var drop_amount_label: RichTextLabel = $HBoxContainer/DropAmount
@onready var drop_delay_label: RichTextLabel = $HBoxContainer/DropDelay
@onready var cost_label: RichTextLabel = $HBoxContainer/Cost
@onready var growth_delay_label: RichTextLabel = $HBoxContainer/GrowthDelay
@onready var quantity_label: RichTextLabel = $HBoxContainer/Quantity
@onready var buy_button: Button = $HBoxContainer/Buy
@onready var sell_button: Button = $HBoxContainer/Sell

@onready var locked_mask: PanelContainer = $LockedMask
@onready var locked_label: RichTextLabel = $LockedMask/CenterContainer/LockedLabel

@export var fish: FishData:
	set(value):
		fish = value
		if is_visible_in_tree():
			update()

signal request_buy(fish_data)
signal request_sell(fish_data)

func _ready() -> void:
	update()

func update() -> void:
	update_text()
	Player.max_coins_changed.connect(func(old,new):
		locked_mask.visible = new < fish.cost
	)
	locked_mask.visible = Player.max_coins < fish.cost


func update_text() -> void:
	name_label.text = fish.name
	drop_amount_label.text = str(fish.reward_amount) + " coins\nper drop"
	drop_delay_label.text = str(fish.reward_delay) + "s\nper drop"
	cost_label.text = str(fish.cost) + " coins"
	growth_delay_label.text = str(fish.growth_delay) + "s\nto adult"
	buy_button.text = "Buy Fry\n" + str(fish.cost) + " coins"
	sell_button.text = "Sell Adult\n" + str(fish.sell_price) + " coins"
	locked_label.text = "Unlock at " + str(fish.cost) + " coins"

func update_quantity(fry: int, adult: int) -> void:
	quantity_label.text = str(fry) +" - " + str(adult) + "\nfry - adult"

func buy():
	request_buy.emit(fish)

func sell():
	request_sell.emit(fish)
