extends Node

class LevelDef:
	var id: String
	var display_name: String
	var layout_id: int
	var gold_time: int
	var silver_time: int
	var reward: int
	var unlock_after: String

	func _init(p_id: String, p_name: String, p_layout: int, p_gold: int, p_silver: int, p_reward: int, p_unlock_after: String = "") -> void:
		id = p_id
		display_name = p_name
		layout_id = p_layout
		gold_time = p_gold
		silver_time = p_silver
		reward = p_reward
		unlock_after = p_unlock_after

var levels: Array = []
var by_id: Dictionary = {}

func _ready() -> void:
	_add("L1", "First Snowfall", 0, 90, 150, 80)
	_add("L2", "Frozen Pond", 1, 100, 160, 90, "L1")
	_add("L3", "Candy Cane Steps", 2, 110, 170, 100, "L2")
	_add("L4", "Ornament Hall", 3, 110, 175, 110, "L3")
	_add("L5", "Sleigh Crossroads", 4, 115, 180, 120, "L4")
	_add("L6", "Second Snowfall", 0, 120, 190, 130, "L5")
	_add("L7", "Deep Frost Pond", 1, 125, 195, 140, "L6")
	_add("L8", "Twin Candy Steps", 2, 130, 200, 150, "L7")
	_add("L9", "Evergreen Diamond", 3, 130, 205, 160, "L8")
	_add("L10", "Golden Bells Crossroads", 4, 135, 210, 175, "L9")
	_add("L11", "Third Snowfall", 0, 140, 215, 190, "L10")
	_add("L12", "Silent Night Pond", 1, 145, 220, 200, "L11")
	_add("L13", "High Mantel Steps", 2, 150, 225, 215, "L12")
	_add("L14", "Royal Ornament Diamond", 3, 150, 230, 230, "L13")
	_add("L15", "Midnight Sleigh Crossroads", 4, 155, 235, 250, "L14")
	for lvl in levels:
		by_id[lvl.id] = lvl

func _add(id: String, name: String, layout: int, gold: int, silver: int, reward: int, unlock_after: String = "") -> void:
	levels.append(LevelDef.new(id, name, layout, gold, silver, reward, unlock_after))

func get_level(id: String) -> LevelDef:
	if by_id.has(id):
		return by_id[id]
	return levels[0]

func is_unlocked(id: String) -> bool:
	var lvl := get_level(id)
	if lvl.unlock_after == "":
		return true
	var prev: Dictionary = SaveData.level_result(lvl.unlock_after)
	return prev.stars >= 1

func stars_for(id: String, time_sec: int) -> int:
	var lvl := get_level(id)
	if time_sec <= lvl.gold_time:
		return 3
	elif time_sec <= lvl.silver_time:
		return 2
	return 1
