extends Node2D

const UIKit = preload("res://ui/UIKit.gd")

var return_to := "res://scenes/MainMenu.tscn"
var claimed_amount := -1
var buttons: Array = []

func _ready() -> void:
	var params := Nav.take_params()
	return_to = params.get("return_to", "res://scenes/MainMenu.tscn")
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap(event.position)

func handle_tap(point: Vector2) -> void:
	for entry in buttons:
		if entry.rect.has_point(point):
			if entry.action == "claim":
				claimed_amount = Economy.claim_daily()
			elif entry.action == "continue":
				Nav.go_to(return_to)
			queue_redraw()
			return

func _draw() -> void:
	var viewport := get_viewport_rect().size
	var palette: Dictionary = ThemeData.equipped().palette
	draw_rect(Rect2(Vector2.ZERO, viewport), palette.bg)
	draw_circle(Vector2(viewport.x * 0.5, 220), 260, Color(palette.gold, 0.06))

	draw_string(ThemeDB.fallback_font, Vector2(0, 110), "DAILY GIFT", HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 30, palette.ink)
	draw_string(ThemeDB.fallback_font, Vector2(0, 142), "Day streak: %d" % SaveData.data.streak, HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 13, palette.muted)

	var cycle := Economy.streak_cycle_day()
	var card_w := (viewport.x - 44 - 6 * 10) / 7.0
	var x := 22.0
	for day in range(1, 8):
		var amount: int = Economy.REWARD_TABLE[day - 1]
		var rect := Rect2(Vector2(x, 190), Vector2(card_w, 150))
		var is_today := day == cycle
		var fill: Color = palette.gold if (is_today and SaveData.data.claimed_today) else (Color(palette.panel_light) if is_today else palette.panel)
		UIKit.draw_panel(self, rect, fill, palette.gold if is_today else palette.muted, 14)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 28), "DAY %d" % day, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 10, palette.ink)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 90), str(amount), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 20, palette.gold if not is_today else palette.tile_ink)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 118), "coins", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 10, palette.muted)
		x += card_w + 10

	buttons.clear()
	var main_rect := Rect2(Vector2(22, viewport.y - 200), Vector2(viewport.x - 44, 70))
	if claimed_amount >= 0:
		draw_string(ThemeDB.fallback_font, Vector2(0, viewport.y - 260), "+%d coins claimed!" % claimed_amount, HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 18, palette.gold)
		UIKit.draw_button(self, main_rect, "CONTINUE", Color("1a5952"), palette.gold)
		buttons.append({"rect": main_rect, "action": "continue"})
	elif not SaveData.data.claimed_today:
		UIKit.draw_button(self, main_rect, "CLAIM %d COINS" % Economy.daily_reward_amount(), Color("1a5952"), palette.gold)
		buttons.append({"rect": main_rect, "action": "claim"})
	else:
		draw_string(ThemeDB.fallback_font, Vector2(0, viewport.y - 260), "Already claimed. Santa returns tomorrow!", HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 14, palette.muted)
		UIKit.draw_button(self, main_rect, "CONTINUE", Color("28281f"), palette.ink)
		buttons.append({"rect": main_rect, "action": "continue"})
