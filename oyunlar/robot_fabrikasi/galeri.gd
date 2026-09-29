extends Control
# Robot galerisi: üç rafta 15 robot. Yapılan robotlar kendi renkleriyle, gözleri yanık ve hafifçe sallanır;
# dokununca dans eder. Yapılmamışlar gri siluet. Sol üstteki düğme ya da rafların dışı kapatır.

signal closed

const Robot := preload("res://oyunlar/robot_fabrikasi/robot.gd")
const INK := Color("5a3a1e")
const COLS := 5
const ROBOT_SCALE := 0.34

var sounds: Node
var effects: Node2D
var _dim: ColorRect
var _panel: Control
var _robots: Array[Node2D] = []
var _close: Control
var _open := false
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim = ColorRect.new()
	_dim.color = Color(0.15, 0.08, 0.2, 0.5)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	_panel = Control.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.draw.connect(_draw_panel)
	add_child(_panel)
	_close = Control.new()
	_close.size = Vector2(96, 96)
	_close.pivot_offset = _close.size / 2.0
	_close.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon: Texture2D = load("res://ortak/gorseller/geri.svg")
	_close.draw.connect(func() -> void:
		_close.draw_circle(Vector2(48, 53), 42, Color(0.2, 0.1, 0.3, 0.2))
		_close.draw_circle(Vector2(48, 48), 42, Color.WHITE)
		_close.draw_arc(Vector2(48, 48), 42, 0.0, TAU, 48, Color("3b2f6b"), 5.0, true)
		_close.draw_texture_rect(icon, Rect2(Vector2(24, 24), Vector2(48, 48)), false))
	add_child(_close)
	visible = false


func is_open() -> bool:
	return _open


func open(gallery: Dictionary) -> void:
	_open = true
	visible = true
	for robot in _robots:
		robot.queue_free()
	_robots.clear()
	var s := size
	var panel_size := Vector2(minf(1100.0, s.x - 120.0), minf(610.0, s.y - 70.0))
	_panel.size = panel_size
	_panel.position = (s - panel_size) * 0.5 + Vector2(0, 16)
	_close.position = Vector2(36, 24)
	for i in Robot.ORDER.size():
		var id: String = Robot.ORDER[i]
		var robot := Robot.new()
		_panel.add_child(robot)
		var built := gallery.has(id)
		robot.build(id, gallery[id] if built else Robot.DEFAULT_LOOK)
		robot.scale *= ROBOT_SCALE
		var col := i % COLS
		var row := i / COLS
		robot.position = Vector2(panel_size.x * (col + 0.5) / COLS, _shelf_y(row) - 6.0)
		robot.set_meta("built", built)
		if built:
			robot.wake()
		else:
			robot.set_silhouette(true)
		_robots.append(robot)
	_panel.pivot_offset = panel_size * 0.5
	_panel.scale = Vector2(0.8, 0.8)
	_panel.modulate.a = 0.0
	_dim.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.25)
	_panel.queue_redraw()


func _shelf_y(row: int) -> float:
	return _panel.size.y * (0.33 + row * 0.3)


func close() -> void:
	if not _open:
		return
	_open = false
	var tween := create_tween().set_parallel()
	tween.tween_property(_panel, "scale", Vector2(0.85, 0.85), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(func() -> void:
		if not _open:
			visible = false
		closed.emit())


func touch(point: Vector2) -> void:
	if _close.get_global_rect().grow(10.0).has_point(point) or not _panel.get_global_rect().has_point(point):
		_sound("tik")
		close()
		return
	for robot in _robots:
		var area := Rect2(robot.global_position + Vector2(-70, -150), Vector2(140, 160))
		if area.has_point(point):
			if robot.get_meta("built"):
				robot.dance()
				_sound("dans")
			else:
				var tween := robot.create_tween()
				tween.tween_property(robot, "rotation", 0.08, 0.08)
				tween.tween_property(robot, "rotation", -0.08, 0.1)
				tween.tween_property(robot, "rotation", 0.0, 0.1)
				_sound("tik")
			return


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	# Yapılan robotlar rafta hafifçe sallanır
	for i in _robots.size():
		if _robots[i].get_meta("built"):
			_robots[i].rotation = sin(_time * 1.6 + i) * 0.03


func _draw_panel() -> void:
	var s := _panel.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff3e2")
	style.set_corner_radius_all(34)
	style.set_border_width_all(8)
	style.border_color = Color("c8925a")
	style.shadow_color = Color(0.1, 0.05, 0.1, 0.35)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 10)
	_panel.draw_style_box(style, Rect2(Vector2.ZERO, s))
	for row in 3:
		var y := _shelf_y(row)
		_panel.draw_rect(Rect2(28, y, s.x - 56, 16), Color("d89a5a"))
		_panel.draw_rect(Rect2(28, y + 16, s.x - 56, 8), Color("a86a38"))
		_panel.draw_line(Vector2(34, y + 3), Vector2(s.x - 34, y + 3), Color(1, 1, 1, 0.4), 3.0)
		for x in [60.0, s.x - 60.0]:
			_panel.draw_rect(Rect2(x - 6, y + 22, 12, 20), Color("a86a38"))


func _sound(sound: String) -> void:
	if sounds:
		sounds.play(sound)
