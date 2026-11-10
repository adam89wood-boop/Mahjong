extends Node

var pending_params: Dictionary = {}

func go_to(path: String, params: Dictionary = {}) -> void:
	pending_params = params
	get_tree().call_deferred("change_scene_to_file", path)

func take_params() -> Dictionary:
	var p := pending_params
	pending_params = {}
	return p
