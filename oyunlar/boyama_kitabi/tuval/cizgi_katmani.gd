extends Node2D
# Fırça katmanında tek bir fırça darbesi (ya da silgi darbesi). Noktalar tuval pikselindedir; her nokta
# bir daire, ardışık noktalar kalın çizgiyle birleşir: hızlı harekette bile kesintisiz, uçları yuvarlak.
# Gökkuşağı fırçasında her noktanın kendi rengi vardır. Silgi darbesi silgi shader'ıyla çizilir (saydam yapar).

const ERASE_SHADER := preload("res://oyunlar/boyama_kitabi/tuval/silgi.gdshader")

static var _erase_material: ShaderMaterial

var points := PackedVector2Array()
var colors := PackedColorArray()
var width: float = 20.0
var eraser: bool = false


static func erase_material() -> ShaderMaterial:
	if _erase_material == null:
		_erase_material = ShaderMaterial.new()
		_erase_material.shader = ERASE_SHADER
	return _erase_material


func _ready() -> void:
	if eraser:
		material = erase_material()


func add_point(point: Vector2, color: Color) -> void:
	points.append(point)
	colors.append(color)
	queue_redraw()


func clone() -> Node2D:
	var copy: Node2D = get_script().new()
	copy.points = points.duplicate()
	copy.colors = colors.duplicate()
	copy.width = width
	copy.eraser = eraser
	return copy


func _draw() -> void:
	var smooth := not eraser
	var radius := width * 0.5
	for i in range(1, points.size()):
		draw_line(points[i - 1], points[i], colors[i], width, smooth)
	for i in points.size():
		draw_circle(points[i], radius, colors[i], true, -1.0, smooth)
