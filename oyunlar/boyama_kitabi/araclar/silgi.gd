extends "res://oyunlar/boyama_kitabi/araclar/firca.gd"
# Silgi: fırçayla çizilenleri ve damgaları siler (fırça katmanını saydam yapar). Kovayla boyanmış bir
# bölgeye silgiyle dokununca (sürüklemeden) bölge de beyaza döner. İkisi birlikte tek kayıt.

const TAP_LENGTH := 24.0     # ekran pikseli: bundan kısa darbe "dokunma" sayılır

var _start := Vector2.ZERO


func _init() -> void:
	eraser = true


func begin(pos: Vector2) -> void:
	_start = pos
	super.begin(pos)


func end() -> void:
	if _node == null:
		return
	var node := _node
	var tapped := _length * canvas.view_scale() < TAP_LENGTH
	_extend(_raw)
	_node = null
	var entry := {"kind": "layer", "node": node}
	var region := canvas.region_at(_start)
	if tapped and canvas.colors[region] != canvas.paper_color():
		var paint := {"kind": "region", "region": region, "before": canvas.colors[region], "after": canvas.paper_color(), "at": _start}
		canvas.set_region_color(region, canvas.paper_color(), _start, true)
		entry = {"kind": "group", "items": [entry, paint]}
	canvas.commit(entry)
