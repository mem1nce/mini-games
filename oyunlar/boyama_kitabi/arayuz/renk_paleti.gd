class_name ColoringPalette
extends Control
# Renk paleti: 16 büyük yuvarlak renk kutusu, iki sütun. Seçili renk büyür ve kalın çerçeve alır.
# Ekran kısaysa palet dikey kaydırılır. Dokunmayı ekran yönetir: contains / press / drag / release.

signal color_selected(index: int)

const Settings := preload("res://oyunlar/boyama_kitabi/ayarlar.gd")
const OUT := Color("3b2f6b")
const ROW := 74.0
const RADIUS := 28.0
const SELECTED_RADIUS := 35.0

var selected: int = 0
var _radii: Array[float] = []
var _scroller := ColoringScroller.new()
var _pressed: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	for i in Settings.COLORS.size():
		_radii.append(SELECTED_RADIUS if i == selected else RADIUS)
	resized.connect(_update_scroll)
	_update_scroll()


func color() -> Color:
	return Settings.COLORS[selected]


func select(index: int) -> void:
	selected = index
	queue_redraw()


func contains(point: Vector2) -> bool:
	return is_visible_in_tree() and get_global_rect().has_point(point)


func press(point: Vector2) -> void:
	_scroller.press(point)
	_pressed = _index_at(point - global_position)


func drag(point: Vector2) -> void:
	if _scroller.drag(point):
		_pressed = -1
		queue_redraw()


func release(point: Vector2) -> void:
	var was_scrolling := _scroller.scrolling
	_scroller.release()
	if not was_scrolling and _pressed != -1 and _index_at(point - global_position) == _pressed:
		selected = _pressed
		color_selected.emit(selected)
	_pressed = -1


func _update_scroll() -> void:
	var rows := ceili(Settings.COLORS.size() / 2.0)
	_scroller.max_offset = maxf(0.0, rows * ROW + 10.0 - size.y)
	_scroller.offset = minf(_scroller.offset, _scroller.max_offset)
	queue_redraw()


func _center(index: int) -> Vector2:
	var column := index % 2
	var row := index / 2
	return Vector2(size.x * (0.27 + 0.46 * column), ROW * (row + 0.5) + 5.0 - _scroller.offset)


func _index_at(local: Vector2) -> int:
	for i in Settings.COLORS.size():
		if _center(i).distance_to(local) <= ROW * 0.5:
			return i
	return -1


func _process(delta: float) -> void:
	var redraw := _scroller.step(delta)
	for i in _radii.size():
		var target := SELECTED_RADIUS if i == selected else RADIUS
		if not is_equal_approx(_radii[i], target):
			_radii[i] = move_toward(_radii[i], target, delta * 90.0)
			redraw = true
	if redraw:
		queue_redraw()


func _draw() -> void:
	for i in Settings.COLORS.size():
		var center := _center(i)
		var radius := _radii[i]
		var fill: Color = Settings.COLORS[i]
		draw_circle(center + Vector2(0, 4), radius, Color(0.23, 0.18, 0.42, 0.18))
		if i == selected:
			draw_circle(center, radius + 5.0, Color.WHITE)
			draw_arc(center, radius + 5.0, 0.0, TAU, 48, OUT, 4.0, true)
		draw_circle(center, radius, fill)
		draw_arc(center, radius, 0.0, TAU, 48, OUT, 3.5 if i != selected else 3.0, true)
		# Küçük parıltı
		draw_circle(center + Vector2(-radius * 0.38, -radius * 0.4), radius * 0.2, Color(1, 1, 1, 0.55))
	if _scroller.max_offset > 0.0:
		# Kaydırılabildiğini belli eden ince çubuk
		var track := size.y - 20.0
		var bar := track * size.y / (size.y + _scroller.max_offset)
		var y := 10.0 + (track - bar) * _scroller.offset / _scroller.max_offset
		draw_line(Vector2(size.x - 4, y), Vector2(size.x - 4, y + bar), Color(0.23, 0.18, 0.42, 0.25), 5.0, true)
