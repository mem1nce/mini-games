extends Node2D
# Atölye arka planı: sıcak renkli duvar ve hafif panel çizgileri, tavanda borular, yavaşça dönen iki büyük
# dişli, yumuşakça yanıp sönen üç lamba ve tahta zemin. Sade tutuldu: bant ve kutuların önünde dikkat dağıtmasın.

const G := "res://oyunlar/robot_fabrikasi/gorseller/"
const FLOOR_Y := 430.0

var _size := Vector2(1280, 720)
var _gears: Array[Sprite2D] = []
var _lamps: Array[Sprite2D] = []
var _time := 0.0


func setup(effects: Node2D) -> void:
	_size = get_viewport_rect().size
	queue_redraw()
	# Tavandaki boru hattı
	var pipe_tex: Texture2D = load(G + "boru.svg")
	var x := -40.0
	while x < _size.x + 200.0:
		var pipe := Sprite2D.new()
		pipe.texture = pipe_tex
		pipe.scale = Vector2.ONE * 200.0 / pipe_tex.get_width()
		pipe.position = Vector2(x, 132)
		pipe.modulate = Color(1, 1, 1, 0.85)
		add_child(pipe)
		x += 200.0
	# Büyük dekor dişlileri (duvarda, soluk)
	for data in [[Vector2(_size.x * 0.3, 190), 170.0, Color("f4d9b6"), 1.0], [Vector2(_size.x * 0.3 + 128.0, 238), 110.0, Color("e8c8a0"), -1.55],
			[Vector2(_size.x * 0.78, 200), 150.0, Color("f0d0ac"), -0.8]]:
		var gear := Sprite2D.new()
		gear.texture = load(G + "dekor_disli.svg")
		gear.scale = Vector2.ONE * data[1] / gear.texture.get_width()
		gear.position = data[0]
		gear.modulate = data[2]
		gear.set_meta("speed", data[3] * 0.25)
		add_child(gear)
		_gears.append(gear)
	# Lambalar ve ışıkları
	for i in 3:
		var lx := _size.x * (0.16 + i * 0.34)
		var lamp := Sprite2D.new()
		lamp.texture = load(G + "lamba.svg")
		lamp.scale = Vector2.ONE * 58.0 / lamp.texture.get_width()
		lamp.position = Vector2(lx, 64)
		add_child(lamp)
		var glow: Sprite2D = effects.glow_sprite(Color(1, 0.85, 0.45, 0.5), 150.0)
		glow.position = lamp.position + Vector2(0, 8)
		glow.set_meta("phase", i * 2.1)
		add_child(glow)
		_lamps.append(glow)


func _draw() -> void:
	# Duvar: üstten aşağı sıcak krem → şeftali
	var wall := PackedColorArray([Color("fff1dc"), Color("fff1dc"), Color("f8d8b8"), Color("f8d8b8")])
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(_size.x, 0), Vector2(_size.x, FLOOR_Y), Vector2(0, FLOOR_Y)]), wall)
	var panel := Color(0.85, 0.65, 0.5, 0.18)
	var x := 80.0
	while x < _size.x:
		draw_line(Vector2(x, 150), Vector2(x, FLOOR_Y), panel, 3.0)
		x += 240.0
	draw_line(Vector2(0, 300), Vector2(_size.x, 300), panel, 3.0)
	# Duvar dibinde süpürgelik ve zemin
	draw_rect(Rect2(0, FLOOR_Y - 14, _size.x, 14), Color("d8a878"))
	var floor_colors := PackedColorArray([Color("e8b882"), Color("e8b882"), Color("c8925a"), Color("c8925a")])
	draw_polygon(PackedVector2Array([Vector2(0, FLOOR_Y), Vector2(_size.x, FLOOR_Y), Vector2(_size.x, _size.y), Vector2(0, _size.y)]), floor_colors)
	var y := FLOOR_Y + 40.0
	while y < _size.y:
		draw_line(Vector2(0, y), Vector2(_size.x, y), Color(0.5, 0.3, 0.15, 0.18), 3.0)
		y += 46.0 + (y - FLOOR_Y) * 0.15


func _process(delta: float) -> void:
	_time += delta
	for gear in _gears:
		gear.rotation += float(gear.get_meta("speed")) * delta
	for glow in _lamps:
		glow.modulate.a = 0.35 + 0.2 * (sin(_time * 1.6 + float(glow.get_meta("phase"))) * 0.5 + 0.5)
