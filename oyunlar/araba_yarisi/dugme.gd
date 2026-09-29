extends Control
# Yuvarlak simge düğmesi. Dokunmayı ekranın script'i yönetir: contains() ile bakar, pop() ile zıplatır.

var icon: Texture2D
var fill := Color(1, 1, 1, 0.96)
var border := Color("3b2f6b")
var icon_scale := 0.62
var icon_offset := Vector2.ZERO


func setup(p_icon: Texture2D, diameter: float, p_fill: Color = Color(1, 1, 1, 0.96)) -> Control:
	icon = p_icon
	fill = p_fill
	size = Vector2(diameter, diameter)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func contains(point: Vector2) -> bool:
	return is_visible_in_tree() and modulate.a > 0.5 and get_global_rect().grow(10.0).has_point(point)


func pop() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.86, 0.86), 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center + Vector2(0, 6), radius - 5.0, Color(0.15, 0.1, 0.3, 0.2))
	draw_circle(center, radius - 6.0, fill)
	draw_arc(center, radius - 6.0, 0.0, TAU, 64, border, 5.0, true)
	if icon:
		var side := radius * 2.0 * icon_scale
		draw_texture_rect(icon, Rect2(center - Vector2(side, side) / 2.0 + icon_offset * radius, Vector2(side, side)), false)
