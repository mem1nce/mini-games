extends Control
# Basılı tutulunca çalışan geri düğmesi: parmak basılı kaldıkça çevresinde bir halka dolar,
# dolunca "completed" sinyali gelir. Erken bırakılırsa halka geri söner. Böylece küçük çocuklar
# kazara dokunarak oyundan çıkmaz. Dokunmayı ana sahne yönetir (press/release çağırır).

signal completed

const ICON: Texture2D = preload("res://ortak/gorseller/geri.svg")
const BG := Color(1, 1, 1, 0.95)
const BORDER := Color(0.23, 0.18, 0.42)
const RING := Color("ff7a9a")
const RING_BG := Color(0.23, 0.18, 0.42, 0.15)

var hold_time: float = 1.0
var _progress: float = 0.0
var _holding: bool = false
var _done: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size / 2.0


func contains(point: Vector2) -> bool:
	return is_visible_in_tree() and get_global_rect().grow(10.0).has_point(point)


func press() -> void:
	_holding = true
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.08)


func release() -> void:
	_holding = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if _done:
		return
	var before := _progress
	if _holding:
		_progress = minf(1.0, _progress + delta / hold_time)
		if _progress >= 1.0:
			_done = true
			completed.emit()
	else:
		_progress = maxf(0.0, _progress - delta * 3.0)
	if _progress != before:
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center + Vector2(0, 6), radius - 6.0, Color(0.2, 0.1, 0.3, 0.16))
	draw_circle(center, radius - 8.0, BG)
	draw_arc(center, radius - 8.0, 0.0, TAU, 48, BORDER, 5.0, true)
	var icon := radius * 1.0
	draw_texture_rect(ICON, Rect2(center - Vector2(icon, icon) / 2.0, Vector2(icon, icon)), false)
	if _progress > 0.0:
		draw_arc(center, radius - 1.0, 0.0, TAU, 48, RING_BG, 10.0, true)
		draw_arc(center, radius - 1.0, -PI / 2.0, -PI / 2.0 + TAU * _progress, 48, RING, 10.0, true)
