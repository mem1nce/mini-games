extends Control
# Sağ üstte sesli saymayı açıp kapatan yuvarlak düğme (yazısız: hoparlör / üstü çizili hoparlör).
# Geri düğmesiyle aynı görünüm. Dokunmayı oyun sahnesi yönetir (contains ile sorar).

const ICON_ON: Texture2D = preload("res://oyunlar/cikarma/gorseller/hoparlor.svg")
const ICON_OFF: Texture2D = preload("res://oyunlar/cikarma/gorseller/hoparlor_kapali.svg")
const BG := Color(1, 1, 1, 0.95)
const BORDER := Color(0.23, 0.18, 0.42)

var is_on: bool = true:
	set(value):
		is_on = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size / 2.0


func contains(point: Vector2) -> bool:
	return is_visible_in_tree() and get_global_rect().grow(10.0).has_point(point)


func toggle() -> void:
	is_on = not is_on
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.88, 0.88), 0.07)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center + Vector2(0, 6), radius - 6.0, Color(0.2, 0.1, 0.3, 0.16))
	draw_circle(center, radius - 8.0, BG)
	draw_arc(center, radius - 8.0, 0.0, TAU, 48, BORDER, 5.0, true)
	var icon := radius * 1.05
	draw_texture_rect(ICON_ON if is_on else ICON_OFF, Rect2(center - Vector2(icon, icon) / 2.0, Vector2(icon, icon)), false)
