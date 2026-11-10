extends Node2D

const UIKit = preload("res://ui/UIKit.gd")
const TileArt = preload("res://ui/ChristmasTileArt.gd")

var item_buttons: Array = []
var feedback := ""

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap(event.position)

func handle_tap(point: Vector2) -> void:
	if Rect2(Vector2(22, 24), Vector2(100, 44)).has_point(point):
		Nav.go_to("res://scenes/MainMenu.tscn")
		return
	for entry in item_buttons:
		if entry.rect.has_point(point):
			var id: String = entry.id
			var owned: bool = SaveData.data.unlocked_skins.has(id)
			if owned:
				SaveData.data.equipped_skin = id
				SaveData.save_data()
				feedback = "Equipped %s." % ThemeData.get_theme(id).name
			else:
				var cost: int = ThemeData.get_theme(id).cost
				if Economy.spend_coins(cost):
					SaveData.data.unlocked_skins.append(id)
					SaveData.data.equipped_skin = id
					SaveData.save_data()
					feedback = "Unlocked %s!" % ThemeData.get_theme(id).name
				else:
					feedback = "Not enough coins for %s." % ThemeData.get_theme(id).name
			queue_redraw()
			return

func _draw() -> void:
	var viewport := get_viewport_rect().size
	var palette: Dictionary = ThemeData.equipped().palette
	draw_rect(Rect2(Vector2.ZERO, viewport), palette.bg)
	UIKit.draw_button(self, Rect2(Vector2(22, 24), Vector2(100, 44)), "BACK", palette.panel_light, palette.ink)
	draw_string(ThemeDB.fallback_font, Vector2(0, 92), "GIFT SHOP", HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 24, palette.ink)
	UIKit.draw_coin_badge(self, Vector2(viewport.x - 70, 46), SaveData.data.coins, palette.gold, palette.ink)

	item_buttons.clear()
	var y := 130.0
	for id in ThemeData.order:
		var theme: Dictionary = ThemeData.get_theme(id)
		var owned: bool = SaveData.data.unlocked_skins.has(id)
		var equipped: bool = SaveData.data.equipped_skin == id
		var rect := Rect2(Vector2(22, y), Vector2(viewport.x - 44, 132))
		var tp: Dictionary = theme.palette
		UIKit.draw_panel(self, rect, Color(tp.panel, 0.95), tp.accent if not equipped else tp.gold, 18)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(20, 34), theme.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, tp.ink)
		for i in range(5):
			var thumb_rect := Rect2(rect.position + Vector2(16 + i * 46, 46), Vector2(40, 55))
			draw_texture_rect(TileArt.get_texture(i), thumb_rect, false)
		var btn_rect := Rect2(rect.position + Vector2(rect.size.x - 190, 76), Vector2(170, 44))
		var label := "EQUIPPED" if equipped else ("EQUIP" if owned else "UNLOCK • %d" % theme.cost)
		UIKit.draw_button(self, btn_rect, label, tp.gold if not equipped else tp.panel_light, tp.tile_ink if not equipped else tp.gold, not equipped)
		item_buttons.append({"rect": btn_rect, "id": id})
		y += 144

	if feedback != "":
		draw_string(ThemeDB.fallback_font, Vector2(0, y + 20), feedback, HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 13, palette.gold)
