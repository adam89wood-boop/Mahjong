extends Node

const HINT_COST := 25
const UNDO_COST := 15
const SHUFFLE_COST := 40
const REWARD_TABLE := [50, 70, 90, 120, 160, 220, 400]
const DAY_SECONDS := 86400

signal coins_changed(new_total: int)

func _ready() -> void:
	_check_daily_login()

func add_coins(amount: int) -> void:
	SaveData.data.coins += amount
	SaveData.save_data()
	coins_changed.emit(SaveData.data.coins)

func spend_coins(amount: int) -> bool:
	if SaveData.data.coins < amount:
		return false
	SaveData.data.coins -= amount
	SaveData.save_data()
	coins_changed.emit(SaveData.data.coins)
	return true

func today_string(offset_days: int = 0) -> String:
	var now := Time.get_unix_time_from_system()
	var shifted := now + offset_days * DAY_SECONDS
	var d := Time.get_datetime_dict_from_unix_time(int(shifted))
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func _check_daily_login() -> void:
	var today := today_string()
	if SaveData.data.last_login == today:
		return
	var yesterday := today_string(-1)
	if SaveData.data.last_login == yesterday:
		SaveData.data.streak += 1
	else:
		SaveData.data.streak = 1
	SaveData.data.last_login = today
	SaveData.data.claimed_today = false
	SaveData.data.free_hint_used = false
	SaveData.data.free_undo_used = false
	SaveData.save_data()

func reward_pending() -> bool:
	return not SaveData.data.claimed_today

func streak_cycle_day() -> int:
	return ((SaveData.data.streak - 1) % 7) + 1

func daily_reward_amount() -> int:
	return REWARD_TABLE[streak_cycle_day() - 1]

func claim_daily() -> int:
	if SaveData.data.claimed_today:
		return 0
	var amount := daily_reward_amount()
	add_coins(amount)
	SaveData.data.claimed_today = true
	if streak_cycle_day() == 7 and not SaveData.data.unlocked_skins.has("golden_bells"):
		SaveData.data.unlocked_skins.append("golden_bells")
	SaveData.save_data()
	return amount

func has_free_hint() -> bool:
	return not SaveData.data.free_hint_used

func use_free_hint() -> void:
	SaveData.data.free_hint_used = true
	SaveData.save_data()

func has_free_undo() -> bool:
	return not SaveData.data.free_undo_used

func use_free_undo() -> void:
	SaveData.data.free_undo_used = true
	SaveData.save_data()
