extends Node

# Property / business empire — buy fronts, passive income, revenue events (web economy.ts parity).

const RADIUS: float = 7.0
const DAY_LENGTH: float = 600.0  # matches game_world.gd day cycle

const BUSINESSES: Array = [
	{"id": "anvil", "name": "The Anvil Garage", "blurb": "chop shop", "pos": Vector3(-320.0, 0.0, -60.0), "cost": 500, "per_day": 220},
	{"id": "quohog", "name": "Quohog Republic", "blurb": "dockside bar", "pos": Vector3(-220.0, 0.0, -130.0), "cost": 800, "per_day": 320},
	{"id": "linq", "name": "Linguiça Linq", "blurb": "all-night diner", "pos": Vector3(-300.0, 0.0, -72.0), "cost": 650, "per_day": 260},
	{"id": "marealta", "name": "Maré Alta Records", "blurb": "record shop", "pos": Vector3(-262.0, 0.0, -60.0), "cost": 700, "per_day": 280},
	{"id": "whalingcab", "name": "Whaling City Cab", "blurb": "taxi depot", "pos": Vector3(-220.0, 0.0, -176.0), "cost": 900, "per_day": 360},
	{"id": "longisland", "name": "Off the Hook Bar and Grill", "blurb": "Long Island waterfront bar & marina", "pos": Vector3(6092.0, 0.0, -4485.0), "cost": 1800, "per_day": 600},
	{"id": "dartmall", "name": "Dartmouth Mall", "blurb": "Route 6 retail hub", "pos": Vector3(-3921.0, 0.0, -398.0), "cost": 2500, "per_day": 850},
]

const BOOM: PackedStringArray = [
	"{name}: feast-week rush — takings up {amt}",
	"{name}: a tour bus emptied out front — +{amt}",
	"{name}: the fleet came in heavy, big spenders — +{amt}",
	"{name}: cash-only Friday, clean books — +{amt}",
	"{name}: cruise-night crowd packed it — +{amt}",
]
const LEAK: PackedStringArray = [
	"{name}: health inspector 'visit' — -{amt}",
	"{name}: walk-in freezer died — -{amt}",
	"{name}: register came up short — -{amt}",
	"{name}: a pipe let go out back — -{amt}",
	"{name}: protection envelope came due — -{amt}",
]

signal near_buy_changed(index: int)

var near_buy_index: int = -1

var _rev_acc: float = 0.0
var _next_rev: float = 75.0
var _income_acc: float = 0.0
var _active: bool = false


func _ready() -> void:
	if GameManager and not GameManager.business_state.is_empty():
		restore(GameManager.business_state)


func snapshot() -> Dictionary:
	return {
		"owned_mask": GameManager.owned_business_mask if GameManager else 0,
		"revenue_accumulator": _rev_acc,
		"next_revenue_event": _next_rev,
		"income_accumulator": _income_acc,
	}


func restore(saved: Dictionary) -> void:
	_rev_acc = maxf(float(saved.get("revenue_accumulator", 0.0)), 0.0)
	_next_rev = maxf(float(saved.get("next_revenue_event", 75.0)), 1.0)
	_income_acc = maxf(float(saved.get("income_accumulator", 0.0)), 0.0)


func business_count() -> int:
	return BUSINESSES.size()


func owned_count() -> int:
	if GameManager == null:
		return 0
	return GameManager.businesses_owned()


func is_owned(index: int) -> bool:
	if GameManager == null:
		return false
	return GameManager.is_business_owned(index)


func income_per_sec() -> float:
	var per_day: float = 0.0
	for i in BUSINESSES.size():
		if is_owned(i):
			per_day += float(BUSINESSES[i]["per_day"])
	return per_day / DAY_LENGTH


func set_active(on: bool) -> void:
	_active = on


func set_near_buy(index: int) -> void:
	if index == near_buy_index:
		return
	near_buy_index = index
	near_buy_changed.emit(near_buy_index)


func try_buy(index: int) -> bool:
	if index < 0 or index >= BUSINESSES.size():
		return false
	if is_owned(index):
		return false
	var b: Dictionary = BUSINESSES[index]
	var cost: int = int(b["cost"])
	if not GameManager.spend_cash(cost):
		return false
	GameManager.own_business(index)
	var name: String = str(b["name"])
	var per_day: int = int(b["per_day"])
	var blurb: String = str(b["blurb"])
	if AudioManager:
		var snd: = load("res://assets/audio/sfx/ui/ui_shop_buy.mp3")
		if snd:
			AudioManager.play_sfx(snd, -6.0)
	GameManager.show_message("Bought %s — +$%d/day" % [name, per_day])
	if RadioHooks and RadioHooks.has_method("on_business_bought"):
		RadioHooks.on_business_bought(name, blurb)
	return true


func roll_revenue_event() -> Dictionary:
	var owned: Array[int] = []
	for i in BUSINESSES.size():
		if is_owned(i):
			owned.append(i)
	if owned.is_empty():
		return {}
	var idx: int = owned[randi() % owned.size()]
	var b: Dictionary = BUSINESSES[idx]
	var good: bool = randf() < 0.55
	var per_day: int = int(b["per_day"])
	var amount: int = int(round(float(per_day) * (0.4 + randf() * 0.8)))
	var pool: PackedStringArray = BOOM if good else LEAK
	var text: String = pool[randi() % pool.size()]
	text = text.replace("{name}", str(b["name"])).replace("{amt}", "$%d" % amount)
	return {"good": good, "text": text, "amount": amount if good else -amount}


func _process(delta: float) -> void:
	if not _active or GameManager == null:
		return
	if get_tree().paused:
		return
	var income: float = income_per_sec()
	if income > 0.0:
		_income_acc += income * delta
		if _income_acc >= 1.0:
			var payout: int = int(_income_acc)
			_income_acc -= float(payout)
			GameManager.add_cash_silent(payout)
	_rev_acc += delta
	if _rev_acc >= _next_rev:
		_rev_acc = 0.0
		_next_rev = 90.0 + randf() * 120.0
		var ev: Dictionary = roll_revenue_event()
		if not ev.is_empty():
			GameManager.add_cash_silent(int(ev["amount"]))
			var col: String = "#7CFC00" if ev["good"] else "#ff6a6a"
			GameManager.show_message(ev["text"])
			if AudioManager:
				var snd_path: String = "res://assets/audio/sfx/ui/ui_shop_buy.mp3" if ev["good"] else "res://assets/audio/sfx/ui/ui_menu_click.mp3"
				var snd: = load(snd_path)
				if snd:
					AudioManager.play_sfx(snd, -10.0)
