extends Node

const RANKS := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var themes: Dictionary = {}
var order: Array = []

func _ready() -> void:
	_register("evergreen", "Evergreen", 0, {
		"bg": Color("05140a"), "bg_mid": Color("0a2214"),
		"panel": Color("0d2a18"), "panel_light": Color("16452a"),
		"ink": Color("eef7ef"), "muted": Color("8fb59b"),
		"gold": Color("f6c445"), "accent": Color("3fae5a"), "warn": Color("e94f4f"),
		"tile_top": Color("fff8ea"), "tile_bottom": Color("e3dcc2"), "tile_ink": Color("1f3326"),
	})

	_register("candy_cane", "Candy Cane", 600, {
		"bg": Color("160808"), "bg_mid": Color("2a0d0d"),
		"panel": Color("3a1212"), "panel_light": Color("551a1a"),
		"ink": Color("fdf1ef"), "muted": Color("caa0a0"),
		"gold": Color("ffe3e3"), "accent": Color("e94f4f"), "warn": Color("3fae5a"),
		"tile_top": Color("fff5f3"), "tile_bottom": Color("f2d6d6"), "tile_ink": Color("3a1414"),
	})

	_register("golden_bells", "Golden Bells", 600, {
		"bg": Color("160f05"), "bg_mid": Color("2a1d08"),
		"panel": Color("3a280c"), "panel_light": Color("553c12"),
		"ink": Color("fbf0d8"), "muted": Color("c2a876"),
		"gold": Color("ffd56b"), "accent": Color("e6b23e"), "warn": Color("8a2f2f"),
		"tile_top": Color("fff6df"), "tile_bottom": Color("e9d6a6"), "tile_ink": Color("3a2b12"),
	})

	_register("frosted_pine", "Frosted Pine", 900, {
		"bg": Color("05161a"), "bg_mid": Color("0a2a30"),
		"panel": Color("0e3238"), "panel_light": Color("154852"),
		"ink": Color("eaf8fb"), "muted": Color("85b3bc"),
		"gold": Color("d8f3ff"), "accent": Color("4fd1c5"), "warn": Color("e94f4f"),
		"tile_top": Color("f2fbff"), "tile_bottom": Color("cfe9f2"), "tile_ink": Color("12333b"),
	})

	_register("nutcracker", "Nutcracker", 900, {
		"bg": Color("0a0a18"), "bg_mid": Color("14142a"),
		"panel": Color("1c1c3a"), "panel_light": Color("2a2a55"),
		"ink": Color("f0eefb"), "muted": Color("9d9ac2"),
		"gold": Color("ffd56b"), "accent": Color("e94f4f"), "warn": Color("3fae5a"),
		"tile_top": Color("fff9ec"), "tile_bottom": Color("ded0e8"), "tile_ink": Color("201a3a"),
	})

	order = ["evergreen", "candy_cane", "golden_bells", "frosted_pine", "nutcracker"]

func _register(id: String, display_name: String, cost: int, palette: Dictionary) -> void:
	themes[id] = {"id": id, "name": display_name, "cost": cost, "palette": palette}

func get_theme(id: String) -> Dictionary:
	return themes.get(id, themes["evergreen"])

func equipped() -> Dictionary:
	return get_theme(SaveData.data.equipped_skin)
