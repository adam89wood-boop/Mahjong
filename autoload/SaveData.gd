extends Node

const SAVE_PATH := "user://mahjong_save.json"

var data: Dictionary = {}

func _ready() -> void:
	load_data()

func default_data() -> Dictionary:
	return {
		"coins": 300,
		"streak": 0,
		"last_login": "",
		"claimed_today": false,
		"free_hint_used": false,
		"free_undo_used": false,
		"levels": {},
		"unlocked_skins": ["evergreen"],
		"equipped_skin": "evergreen",
		"settings": {"sfx": true},
	}

func load_data() -> void:
	data = default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in parsed.keys():
			data[key] = parsed[key]
	# JSON.parse_string() always returns float for numbers; coerce back to int
	# so integer-only ops (%, maxi) downstream don't choke on a float.
	data.coins = int(data.coins)
	data.streak = int(data.streak)
	for level_id in data.levels.keys():
		var lvl: Dictionary = data.levels[level_id]
		data.levels[level_id] = {
			"stars": int(lvl.stars),
			"best_time": int(lvl.best_time),
			"best_moves": int(lvl.best_moves),
		}

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()

func level_result(level_id: String) -> Dictionary:
	return data.levels.get(level_id, {"stars": 0, "best_time": -1, "best_moves": -1})

func set_level_result(level_id: String, stars: int, time_sec: int, moves: int) -> void:
	var prev: Dictionary = level_result(level_id)
	var best_time: int = prev.best_time
	var best_moves: int = prev.best_moves
	if best_time < 0 or time_sec < best_time:
		best_time = time_sec
	if best_moves < 0 or moves < best_moves:
		best_moves = moves
	data.levels[level_id] = {
		"stars": maxi(prev.stars, stars),
		"best_time": best_time,
		"best_moves": best_moves,
	}
	save_data()

func reset_progress() -> void:
	data = default_data()
	save_data()
