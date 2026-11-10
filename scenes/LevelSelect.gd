extends Node2D

const UIKit = preload("res://ui/UIKit.gd")
const ITEM_H := 96.0
const HEADER_H := 150.0

var scroll_y := 0.0
var max_scroll := 0.0
var drag_active := false
var press_pos := Vector2.ZERO
var press_scroll := 0.0
var item_buttons: Array = []

func _ready() -> void:
	var viewport := get_viewport_rect().size
	var content_h := LevelData.levels.size() * ITEM_H
	max_scroll = maxf(0.0, content_h - (viewport.y - HEADER_H - 110.0))
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_active = true
			press_pos = event.position
			press_scroll = scroll_y
		else:
			if drag_active and press_pos.distance_to(event.position) < 14:
				handle_tap(event.position)
			drag_active = false
	elif event is InputEventScreenDrag:
		scroll_y = clampf(press_scroll - (event.position.y - press_pos.y), 0.0, max_scroll)
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_active = true
			press_pos = event.position
			press_scroll = scroll_y
		else:
			if drag_active and press_pos.distance_to(event.position) < 14:
				handle_tap(event.position)
			drag_active = false
	elif event is InputEventMouseMotion and drag_active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		scroll_y = clampf(press_scroll - (event.position.y - press_pos.y), 0.0, max_scroll)
		queue_redraw()

func handle_tap(point: Vector2) -> void:
	var viewport := get_viewport_rect().size
	if Rect2(Vector2(22, 24), Vector2(100, 44)).has_point(point):
		Nav.go_to("res://scenes/MainMenu.tscn")
		return
	for entry in item_buttons:
		if entry.rect.has_point(point):
			if entry.unlocked:
				Nav.go_to("res://scenes/Game.tscn", {"level_id": entry.id})
			return

func _draw() -> void:
	var viewport := get_viewport_rect().size
	var palette: Dictionary = ThemeData.equipped().palette
	draw_rect(Rect2(Vector2.ZERO, viewport), palette.bg)
	UIKit.draw_button(self, Rect2(Vector2(22, 24), Vector2(100, 44)), "BACK", palette.panel_light, palette.ink)
	draw_string(ThemeDB.fallback_font, Vector2(0, 92), "HOLIDAY SELECT", HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 24, palette.ink)
	UIKit.draw_coin_badge(self, Vector2(viewport.x - 70, 46), SaveData.data.coins, palette.gold, palette.ink)

	var clip_top := HEADER_H
	item_buttons.clear()
	var y := clip_top - scroll_y
	for lvl in LevelData.levels:
		if y + ITEM_H >= clip_top - ITEM_H and y <= viewport.y:
			var rect := Rect2(Vector2(22, y), Vector2(viewport.x - 44, ITEM_H - 14))
			var unlocked: bool = LevelData.is_unlocked(lvl.id)
			var result: Dictionary = SaveData.level_result(lvl.id)
			var fill: Color = palette.panel if unlocked else Color(palette.panel, 0.4)
			UIKit.draw_panel(self, rect, fill, palette.accent if unlocked else palette.muted, 16)
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(20, 32), lvl.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, palette.ink if unlocked else palette.muted)
			if unlocked:
				var stars_str := ""
				for i in range(3):
					stars_str += "★" if i < result.stars else "☆"
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(20, 58), stars_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, palette.gold)
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 150, 45), "+%d coins" % lvl.reward, HORIZONTAL_ALIGNMENT_RIGHT, 130, 11, palette.muted)
			else:
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(20, 58), "Locked — clear the previous level", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, palette.muted)
			item_buttons.append({"rect": rect, "id": lvl.id, "unlocked": unlocked})
		y += ITEM_H
