extends Node2D
# "Temizle" işleminin fırça katmanındaki karşılığı: bütün katmanı saydam yapan tek bir dikdörtgen.
# Altındaki bütün çizimleri görünmez kılar; geri alınınca silinir ve çizimler geri gelir.

const StrokeLayer := preload("res://oyunlar/boyama_kitabi/tuval/cizgi_katmani.gd")

var size := Vector2(2048, 1536)


func _ready() -> void:
	material = StrokeLayer.erase_material()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-4, -4), size + Vector2(8, 8)), Color.BLACK)


func clone() -> Node2D:
	var copy: Node2D = get_script().new()
	copy.size = size
	return copy
