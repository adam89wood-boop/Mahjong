extends Node2D

const UIKit = preload("res://ui/UIKit.gd")

var confirm_reset := false
var confirm_until := 0.0
var buttons: Array = []

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap(event.position)

func _process(_delta: float) -> void:
	if confirm_reset and Time.get_ticks_msec() / 1000.0 > confirm_until:
		confirm_reset = false
		queue_redraw()

func handle_tap(point: Vector2) -> void:
	for entry in buttons:
		if entry.rect.has_point(point):
			match entry.action:
				"back": Nav.go_to("res://scenes/MainMenu.tscn")
				"sfx":
					SaveData.data.settings.sfx = not SaveData.data.settings.sfx
					SaveData.save_data()
				"reset":
					if confirm_reset:
						SaveData.reset_progress()
						confirm_reset = false
						Nav.go_to("res://scenes/MainMenu.tscn")
					else:
						confirm_reset = true
						confirm_until = Time.get_ticks_msec() / 1000.0 + 4.0
			queue_redraw()
			return

func _draw() -> void:
	var viewport := get_viewport_rect().size
	var palette: Dictionary = ThemeData.equipped().palette
	draw_rect(Rect2(Vector2.ZERO, viewport), palette.bg)
	buttons.clear()

	var back_rect := Rect2(Vector2(22, 24), Vector2(100, 44))
	UIKit.draw_button(self, back_rect, "BACK", palette.panel_light, palette.ink)
	buttons.append({"rect": back_rect, "action": "back"})
	draw_string(ThemeDB.fallback_font, Vector2(0, 92), "SETTINGS", HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 24, palette.ink)

	var sfx_rect := Rect2(Vector2(22, 140), Vector2(viewport.x - 44, 70))
	var sfx_on: bool = SaveData.data.settings.sfx
	UIKit.draw_button(self, sfx_rect, "SOUND EFFECTS: %s" % ("ON" if sfx_on else "OFF"), Color("1a5952") if sfx_on else Color("28281f"), palette.gold if sfx_on else palette.muted)
	buttons.append({"rect": sfx_rect, "action": "sfx"})

	var reset_rect := Rect2(Vector2(22, 230), Vector2(viewport.x - 44, 70))
	var label := "TAP AGAIN TO CONFIRM RESET" if confirm_reset else "RESET PROGRESS"
	UIKit.draw_button(self, reset_rect, label, Color("5a1f1f") if confirm_reset else Color("28281f"), palette.warn)
	buttons.append({"rect": reset_rect, "action": "reset"})

	draw_string(ThemeDB.fallback_font, Vector2(24, 330), "Resetting clears coins, streak, levels and skins.", HORIZONTAL_ALIGNMENT_LEFT, viewport.x - 48, 11, palette.muted)
