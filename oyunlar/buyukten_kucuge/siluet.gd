extends Node2D
# Yuvadaki ipucu: gelecek nesnenin soluk dolgulu, kesik çizgili silueti (aynı boyutta).
# Dış çizgi SizeArt.outline() çokgenlerinden çizilir; çizgiler çokgen boyunca kesintisiz kesik kesik ilerler.

const SHADER: Shader = preload("res://oyunlar/buyukten_kucuge/siluet.gdshader")
const LINE := Color(0.23, 0.18, 0.42, 0.55)
const DASH := 13.0
const SPACE := 9.0
const WIDTH := 4.0

var _polygons: Array[PackedVector2Array] = []


func setup(art: String, visual: Vector2, color: Color) -> void:
	var fill := Sprite2D.new()
	fill.texture = SizeArt.texture(art, visual, color)
	fill.scale = Vector2.ONE / SizeArt.RASTER
	var material := ShaderMaterial.new()
	material.shader = SHADER
	fill.material = material
	add_child(fill)
	_polygons = SizeArt.outline(art, visual, color)
	queue_redraw()


func _draw() -> void:
	for polygon in _polygons:
		_dashed(polygon)


# Kapalı çokgen boyunca kesik çizgi: DASH kadar çiz, SPACE kadar boş bırak (köşelerde de devam eder)
func _dashed(polygon: PackedVector2Array) -> void:
	var drawing := true
	var left := DASH
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		var length := a.distance_to(b)
		var done := 0.0
		while done < length:
			var part := minf(left, length - done)
			if drawing:
				draw_line(a.lerp(b, done / length), a.lerp(b, (done + part) / length), LINE, WIDTH, true)
			done += part
			left -= part
			if left <= 0.001:
				drawing = not drawing
				left = DASH if drawing else SPACE
