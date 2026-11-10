extends RefCounted
class_name UIKit

static func panel_style(fill: Color, border: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box

static func draw_panel(ci: CanvasItem, rect: Rect2, fill: Color, border: Color, radius: float = 20.0) -> void:
	ci.draw_style_box(panel_style(fill, border, radius), rect)

static func draw_button(ci: CanvasItem, rect: Rect2, label: String, fill: Color, text_color: Color, enabled: bool = true) -> void:
	var f := fill if enabled else fill.darkened(0.35)
	var t := text_color if enabled else text_color.darkened(0.3)
	ci.draw_style_box(panel_style(f, t, 12), rect)
	ci.draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.5 + 6), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, t)

static func draw_metric(ci: CanvasItem, pos: Vector2, label: String, value: String, muted: Color, color: Color) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, muted)
	ci.draw_string(ThemeDB.fallback_font, pos + Vector2(0, 29), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, color)

static func draw_coin_badge(ci: CanvasItem, pos: Vector2, coins: int, gold: Color, ink: Color) -> void:
	ci.draw_circle(pos, 14, Color(gold, 0.22))
	ci.draw_circle(pos, 10, gold)
	ci.draw_string(ThemeDB.fallback_font, pos + Vector2(20, 5), str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
