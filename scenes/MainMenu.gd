extends Node2D

const UIKit = preload("res://ui/UIKit.gd")

var buttons: Array = []

func _ready() -> void:
	if Economy.reward_pending():
		Nav.go_to("res://scenes/DailyReward.tscn", {"return_to": "res://scenes/MainMenu.tscn"})
		return
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap(event.position)

func handle_tap(point: Vector2) -> void:
	for entry in buttons:
		if entry.rect.has_point(point):
			match entry.action:
				"levels": Nav.go_to("res://scenes/LevelSelect.tscn")
				"zen": Nav.go_to("res://scenes/Game.tscn", {"zen": true})
				"store": Nav.go_to("res://scenes/Store.tscn")
				"settings": Nav.go_to("res://scenes/Settings.tscn")
				"daily": Nav.go_to("res://scenes/DailyReward.tscn", {"return_to": "res://scenes/MainMenu.tscn"})
			return

func _draw() -> void:
	var viewport := get_viewport_rect().size
	var palette: Dictionary = ThemeData.equipped().palette
	draw_rect(Rect2(Vector2.ZERO, viewport), palette.bg)
	var bands := 14
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, viewport.y * t, viewport.x, viewport.y / bands + 2), Color(palette.bg).lerp(palette.bg_mid, t * 0.7))
	draw_circle(Vector2(viewport.x * 0.82, 140), 200, Color(palette.accent, 0.08))
	draw_circle(Vector2(viewport.x * 0.1, viewport.y * 0.3), 160, Color(palette.gold, 0.05))

	var header := Rect2(Vector2(22, 60), Vector2(viewport.x - 44, 150))
	UIKit.draw_panel(self, header, Color(palette.panel, 0.85), palette.accent, 26)
	draw_string(ThemeDB.fallback_font, header.position + Vector2(26, 56), "MAHJONG CHRISTMAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, palette.ink)
	draw_string(ThemeDB.fallback_font, header.position + Vector2(28, 84), "A FESTIVE TABLE  •  DAILY GIFTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, palette.accent)
	UIKit.draw_coin_badge(self, header.position + Vector2(40, 122), SaveData.data.coins, palette.gold, palette.ink)
	draw_string(ThemeDB.fallback_font, header.position + Vector2(220, 128), "Day streak: %d" % SaveData.data.streak, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, palette.muted)

	buttons.clear()
	var y := header.position.y + header.size.y + 30
	var w := viewport.x - 44
	var entries := [
		["PLAY HOLIDAYS", "levels", Color("1a5952"), palette.gold],
		["ZEN WORKSHOP", "zen", palette.panel_light, palette.ink],
		["DAILY GIFT", "daily", palette.panel_light, palette.gold],
		["GIFT SHOP", "store", palette.panel_light, palette.ink],
		["SETTINGS", "settings", Color("28281f"), palette.muted],
	]
	for entry in entries:
		var rect := Rect2(Vector2(22, y), Vector2(w, 70))
		UIKit.draw_button(self, rect, entry[0], entry[2], entry[3])
		buttons.append({"rect": rect, "action": entry[1]})
		y += 82
