class_name ColoringIconButton
extends Control
# Yuvarlak simge düğmesi: beyaz zemin, koyu hat, simge; istenirse simgenin bir katmanı seçili renkle boyanır
# (tint_icon, "_renk" SVG'leri). Seçiliyken renkli halka ve açık renkli zemin. Dokunmayı ekran yönetir:
# contains(), press(), release(); kısa bir sıçrama için bounce(), "olmaz" için shake().

const OUT := Color("3b2f6b")

var icon: Texture2D
var tint_icon: Texture2D
var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()
var accent: Color = Color("8a6cf0")
var bg: Color = Color(1, 1, 1, 0.97)
var icon_scale: float = 0.7
var selected: bool = false:
	set(value):
		if selected != value:
			selected = value
			queue_redraw()
			_scale_to(1.08 if value else 1.0, 0.15)
## Simgenin üstüne ek çizim (ör. fırça kalınlığı noktası): func(button: Control) -> void
var extra_draw: Callable


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	pivot_offset = size * 0.5


func contains(point: Vector2) -> bool:
	return is_visible_in_tree() and get_global_rect().grow(6.0).has_point(point)


func press() -> void:
	_scale_to(0.9, 0.07)


func release() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * (1.08 if selected else 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func bounce() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.22, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * (1.08 if selected else 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func shake() -> void:
	var tween := create_tween()
	for angle in [0.18, -0.16, 0.1, -0.06, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.06)


func _scale_to(value: float, time: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * value, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 4.0
	draw_circle(center + Vector2(0, 5), radius, Color(0.23, 0.18, 0.42, 0.16))
	draw_circle(center, radius, accent.lerp(Color.WHITE, 0.78) if selected else bg)
	draw_arc(center, radius, 0.0, TAU, 48, accent if selected else OUT, 7.0 if selected else 4.0, true)
	var side := radius * 2.0 * icon_scale
	var rect := Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side))
	if icon:
		draw_texture_rect(icon, rect, false)
	if tint_icon:
		draw_texture_rect(tint_icon, rect, false, tint)
	if extra_draw.is_valid():
		extra_draw.call(self)
