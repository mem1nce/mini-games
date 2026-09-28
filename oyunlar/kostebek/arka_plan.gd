extends Node2D
# Arka plan: sade, yumuşak renkli çimenli bahçe. Üstte ince açık gök şeridi, dalgalı çim çizgisi,
# altta yumuşak yeşil çimen ve rastgele dağılmış soluk çiçekler / çim tutamları.
# Ekran boyutu değişince yeniden çizilir.

const TEX_FLOWER: Texture2D = preload("res://oyunlar/kostebek/gorseller/cicek.svg")
const TEX_GRASS: Texture2D = preload("res://oyunlar/kostebek/gorseller/cim.svg")
const FLOWER_COLORS: Array[Color] = [Color("ffb3cf"), Color("ffd2a8"), Color("c9b6ff"), Color("ffffff"), Color("aedbff")]
const SKY_TOP := Color("bfe6ff")
const SKY_BOTTOM := Color("e6f6ff")
const GRASS_TOP := Color("c4eba0")
const GRASS_BOTTOM := Color("98d271")
const HORIZON := 0.14    # çimenin başladığı yer (ekran yüksekliğine oran)

var _decor: Node2D


func _ready() -> void:
	_decor = Node2D.new()
	add_child(_decor)
	get_viewport().size_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	queue_redraw()
	for child in _decor.get_children():
		child.queue_free()
	var screen := get_viewport_rect().size
	var top := screen.y * HORIZON
	var count := int(screen.x * screen.y / 38000.0)
	for k in count:
		var is_flower := randf() < 0.45
		var sprite := Sprite2D.new()
		sprite.texture = TEX_FLOWER if is_flower else TEX_GRASS
		var width := randf_range(34.0, 52.0) if is_flower else randf_range(50.0, 80.0)
		sprite.scale = Vector2.ONE * width / sprite.texture.get_width()
		sprite.position = Vector2(randf_range(0.0, screen.x), randf_range(top + 40.0, screen.y))
		sprite.modulate = FLOWER_COLORS.pick_random() if is_flower else Color.WHITE
		sprite.modulate.a = 0.55
		_decor.add_child(sprite)


func _draw() -> void:
	var screen := get_viewport_rect().size
	var top := screen.y * HORIZON
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(screen.x, 0), Vector2(screen.x, top + 30.0), Vector2(0, top + 30.0)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))
	# Dalgalı çim çizgisi
	var edge := PackedVector2Array()
	var colors := PackedColorArray()
	var steps := 24
	for k in steps + 1:
		var x := screen.x * k / steps
		edge.append(Vector2(x, top + sin(k * 0.9) * 10.0))
		colors.append(GRASS_TOP)
	edge.append(Vector2(screen.x, screen.y))
	colors.append(GRASS_BOTTOM)
	edge.append(Vector2(0, screen.y))
	colors.append(GRASS_BOTTOM)
	draw_polygon(edge, colors)
	# Çimenin üst kenarında açık bir çizgi
	var rim := PackedVector2Array()
	for k in steps + 1:
		rim.append(Vector2(screen.x * k / steps, top + sin(k * 0.9) * 10.0 + 4.0))
	draw_polyline(rim, Color(1, 1, 1, 0.45), 5.0, true)
