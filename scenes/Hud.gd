extends Node2D

const UIKit = preload("res://ui/UIKit.gd")

var game: Node3D

const HEADER_HEIGHT := 92.0
const CONTROLS_HEIGHT := 162.0
const CONTROLS_BOTTOM_MARGIN := 28.0
const ACTION_HEIGHT := 46.0

func _input(event: InputEvent) -> void:
	var point: Variant = null
	if event is InputEventScreenTouch and event.pressed:
		point = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
	if point == null: return
	if _handle_tap(point):
		get_viewport().set_input_as_handled()

func _handle_tap(point: Vector2) -> bool:
	var viewport := get_viewport_rect().size
	if Rect2(Vector2(viewport.x - 104, 30), Vector2(80, 40)).has_point(point):
		game.go_to_menu()
		return true
	if game.finished or game.stuck:
		for entry in game.overlay_buttons:
			if entry.rect.has_point(point):
				game._run_overlay_action(entry.action)
				return true
		return true
	var button_y := viewport.y - CONTROLS_BOTTOM_MARGIN - 20.0 - ACTION_HEIGHT
	if point.y >= button_y and point.y <= button_y + ACTION_HEIGHT:
		if point.x < viewport.x / 3.0:
			game.show_hint()
		elif point.x < viewport.x * 2.0 / 3.0:
			game.undo()
		else:
			game.new_deal()
		return true
	return false

func _draw() -> void:
	var viewport := get_viewport_rect().size
	draw_header(viewport)
	draw_controls(viewport)
	if game.finished or game.stuck: draw_overlay(viewport)

func draw_header(viewport: Vector2) -> void:
	var palette: Dictionary = game.palette
	var header := Rect2(Vector2(22, 22), Vector2(viewport.x - 44, HEADER_HEIGHT))
	UIKit.draw_panel(self, header, Color(palette.panel, 0.82), Color(palette.accent, 0.70), 22)
	draw_circle(Vector2(54, 80), 24, palette.gold)
	draw_circle(Vector2(54, 80), 18, palette.panel_light)
	draw_string(ThemeDB.fallback_font, Vector2(44, 88), "M", HORIZONTAL_ALIGNMENT_CENTER, 20, 18, palette.gold)
	draw_string(ThemeDB.fallback_font, Vector2(92, 58), game.title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, palette.ink)
	draw_string(ThemeDB.fallback_font, Vector2(94, 80), "MAHJONG CHRISTMAS  •  FESTIVE TABLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, palette.accent)
	draw_string(ThemeDB.fallback_font, Vector2(94, 108), game.feedback, HORIZONTAL_ALIGNMENT_LEFT, viewport.x - 220, 12, palette.muted)
	UIKit.draw_button(self, Rect2(Vector2(viewport.x - 104, 30), Vector2(80, 40)), "MENU", Color(palette.panel_light, 0.9), palette.ink)
	UIKit.draw_coin_badge(self, Vector2(viewport.x - 170, 46), SaveData.data.coins, palette.gold, palette.ink)

func draw_controls(viewport: Vector2) -> void:
	var palette: Dictionary = game.palette
	var card := Rect2(Vector2(22, viewport.y - CONTROLS_BOTTOM_MARGIN - CONTROLS_HEIGHT), Vector2(viewport.x - 44, CONTROLS_HEIGHT))
	UIKit.draw_panel(self, card.grow(5), Color(palette.bg, 0.97), palette.panel_light, 24)
	UIKit.draw_panel(self, card, Color(palette.panel, 0.9), palette.panel_light, 24)
	UIKit.draw_metric(self, Vector2(card.position.x + 24, card.position.y + 48), "SCORE", str(game.score), palette.muted, palette.gold)
	UIKit.draw_metric(self, Vector2(card.position.x + viewport.x * 0.29, card.position.y + 48), "PAIRS", str(game.pairs), palette.muted, palette.accent)
	UIKit.draw_metric(self, Vector2(card.position.x + viewport.x * 0.53, card.position.y + 48), "TIME", game.time_text(), palette.muted, palette.ink)
	UIKit.draw_metric(self, Vector2(card.position.x + viewport.x * 0.77, card.position.y + 48), "MOVES", str(game.moves), palette.muted, palette.ink)
	var button_y := card.end.y - 20.0 - ACTION_HEIGHT
	var gap := 8.0
	var bw := (viewport.x - 44 - 2 * gap) / 3.0
	UIKit.draw_button(self, Rect2(Vector2(22, button_y), Vector2(bw, ACTION_HEIGHT)), "HINT", palette.panel_light, palette.gold)
	UIKit.draw_button(self, Rect2(Vector2(22 + bw + gap, button_y), Vector2(bw, ACTION_HEIGHT)), "UNDO", Color("28281f"), palette.ink)
	UIKit.draw_button(self, Rect2(Vector2(22 + 2 * (bw + gap), button_y), Vector2(bw, ACTION_HEIGHT)), "RESTART", Color("28281f"), palette.ink)

func draw_overlay(viewport: Vector2) -> void:
	var palette: Dictionary = game.palette
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.03, 0.075, 0.09, 0.86))
	game.overlay_buttons.clear()
	if game.stuck:
		draw_string(ThemeDB.fallback_font, Vector2(0, viewport.y * 0.40), "THE SLEIGH IS STUCK", HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 34, palette.warn)
		draw_string(ThemeDB.fallback_font, Vector2(0, viewport.y * 0.46), "Reshuffle the gifts or restart.", HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 14, palette.ink)
		var r1 := Rect2(Vector2(22, viewport.y - 280), Vector2(viewport.x - 44, 64))
		var r2 := Rect2(Vector2(22, viewport.y - 206), Vector2(viewport.x - 44, 64))
		UIKit.draw_button(self, r1, "SHUFFLE TILES  •  %d COINS" % Economy.SHUFFLE_COST, palette.panel_light, palette.gold)
		UIKit.draw_button(self, r2, "RESTART", Color("1a5952"), palette.ink)
		game.overlay_buttons.append({"rect": r1, "action": "shuffle"})
		game.overlay_buttons.append({"rect": r2, "action": "restart"})
	else:
		var title := "WORKSHOP CLEARED" if game.zen_mode else "GIFTS DELIVERED"
		draw_string(ThemeDB.fallback_font, Vector2(0, viewport.y * 0.36), title, HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 32, palette.gold)
		if not game.zen_mode:
			var stars_str := ""
			for i in range(3):
				stars_str += "★" if i < game.last_stars else "☆"
			draw_string(ThemeDB.fallback_font, Vector2(0, viewport.y * 0.42), stars_str, HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 36, palette.gold)
		draw_string(ThemeDB.fallback_font, Vector2(0, viewport.y * 0.48), "+%d coins earned" % game.last_reward, HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 16, palette.ink)
		var r1 := Rect2(Vector2(22, viewport.y - 280), Vector2(viewport.x - 44, 64))
		var r2 := Rect2(Vector2(22, viewport.y - 206), Vector2(viewport.x - 44, 64))
		if game.zen_mode:
			UIKit.draw_button(self, r1, "PLAY AGAIN", Color("1a5952"), palette.gold)
			game.overlay_buttons.append({"rect": r1, "action": "restart"})
		else:
			var has_next: bool = game._next_level_id() != ""
			UIKit.draw_button(self, r1, "NEXT LEVEL" if has_next else "HOLIDAY SELECT", Color("1a5952"), palette.gold)
			game.overlay_buttons.append({"rect": r1, "action": "next" if has_next else "levels"})
		UIKit.draw_button(self, r2, "MENU", Color("28281f"), palette.ink)
		game.overlay_buttons.append({"rect": r2, "action": "menu"})
