extends ColoringTool
# Fırça (ve gökkuşağı fırçası): parmakla serbest çizim. Hızlı harekette noktaların arası doldurulur
# (aralık kalınlığın ~%30'u), parmak titremesi hafifçe yumuşatılır. Bir parmak darbesi = bir geri alma kaydı.
# rainbow: renk çizilen yol boyunca kendiliğinden değişir.

const StrokeLayer := preload("res://oyunlar/boyama_kitabi/tuval/cizgi_katmani.gd")

var width: float = 32.0
var rainbow: bool = false
var eraser: bool = false

var _node: Node2D
var _last := Vector2.ZERO
var _smooth := Vector2.ZERO
var _raw := Vector2.ZERO
var _length: float = 0.0
var _hue_start: float = 0.0


func begin(pos: Vector2) -> void:
	_node = StrokeLayer.new()
	_node.width = width
	_node.eraser = eraser
	_length = 0.0
	_hue_start = randf()
	_last = pos
	_smooth = pos
	_raw = pos
	_node.add_point(pos, _color_at(0.0))
	canvas.add_layer_node(_node)


func move(pos: Vector2) -> void:
	if _node == null:
		return
	_raw = pos
	_smooth = _smooth.lerp(pos, 0.55)
	_extend(_smooth)


func end() -> void:
	if _node == null:
		return
	_extend(_raw)
	canvas.commit({"kind": "layer", "node": _node})
	_node = null


func cancel() -> void:
	if _node != null:
		canvas.remove_layer_node(_node)
	_node = null


func is_small() -> bool:
	return _length * canvas.view_scale() < 90.0


func loop_sound() -> String:
	return "silgi" if eraser else "firca"


func _extend(target: Vector2) -> void:
	var distance := _last.distance_to(target)
	if distance < maxf(1.5, width * 0.06):
		return
	var step := maxf(1.5, width * 0.3)
	var count := ceili(distance / step)
	for i in range(1, count + 1):
		_length += distance / count
		_node.add_point(_last.lerp(target, float(i) / count), _color_at(_length))
	_last = target
	canvas.request_redraw()
	canvas.stroke_moved(distance)


func _color_at(length: float) -> Color:
	if not rainbow:
		return color
	return Color.from_hsv(fposmod(_hue_start + length / (width * 8.0 + 260.0), 1.0), 0.72, 1.0)
