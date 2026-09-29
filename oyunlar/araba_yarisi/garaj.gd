extends Control
# Giriş ekranı: küçük garaj. Ortada platformun üstünde araba; solda 6 renk, sağda 8 şoför hayvan,
# altta büyük "oynat" düğmesi. Seçim hemen arabaya uygulanır (boya sıçraması / şoför zıplayarak
# oturur); kaydetmeyi ana sahne yapar. Sol üstte basılı-tut geri: ana menüye.

signal play_pressed
signal back_completed
signal color_chosen(color: String)
signal driver_chosen(index: int)

const G := "res://oyunlar/araba_yarisi/gorseller/"
const Gorunum := preload("res://oyunlar/araba_yarisi/araba_gorunum.gd")
const Dugme := preload("res://oyunlar/araba_yarisi/dugme.gd")
const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")
const Efektler := preload("res://oyunlar/araba_yarisi/efektler.gd")
const INK := Color("3b2f6b")


# Renk düğmesi: arabanın renginde yuvarlak; seçiliyse beyaz halka
class Swatch extends Control:
	var color := Color.WHITE
	var selected := false

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0 - 8.0
		draw_circle(c + Vector2(0, 5), r, Color(0.15, 0.1, 0.3, 0.2))
		if selected:
			draw_circle(c, r + 7.0, Color.WHITE)
			draw_arc(c, r + 7.0, 0.0, TAU, 64, INK, 4.0, true)
		draw_circle(c, r, color)
		draw_circle(c + Vector2(0, r * 0.25), r * 0.75, color.darkened(0.12))
		draw_circle(c, r * 0.8, color)
		draw_circle(c + Vector2(-r * 0.32, -r * 0.34), r * 0.24, Color(1, 1, 1, 0.55))
		draw_arc(c, r, 0.0, TAU, 64, color.darkened(0.55), 5.0, true)


# Şoför düğmesi: yuvarlak köşeli beyaz kart içinde hayvan
class AnimalCard extends Control:
	var texture: Texture2D
	var selected := false
	var accent := Color("ff7a9a")

	func _draw() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.97)
		style.set_corner_radius_all(30)
		style.set_border_width_all(8 if selected else 4)
		style.border_color = accent if selected else Color(INK, 0.5)
		style.shadow_color = Color(0.15, 0.1, 0.3, 0.2)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, 5)
		draw_style_box(style, Rect2(Vector2.ZERO, size))
		var inset := size.x * 0.1
		draw_texture_rect(texture, Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), false)


var sounds: Node                    # sesler.gd (ana sahne verir)
var _car: Gorunum
var _swatches: Array[Swatch] = []
var _cards: Array[AnimalCard] = []
var _play: Control
var _back: Control
var _back_touch := -1
var _color := "kirmizi"
var _driver := 0
var _time := 0.0
var _hop_timer := 3.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for color_name in Gorunum.COLOR_NAMES:
		var swatch := Swatch.new()
		swatch.color = Gorunum.COLORS[color_name]
		swatch.size = Vector2(100, 100)
		swatch.pivot_offset = swatch.size / 2.0
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(swatch)
		_swatches.append(swatch)
	for i in Gorunum.DRIVERS.size():
		var card := AnimalCard.new()
		card.texture = load(G + "hayvanlar/%s.svg" % Gorunum.driver_name(i))
		card.size = Vector2(112, 112)
		card.pivot_offset = card.size / 2.0
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card)
		_cards.append(card)
	_car = Gorunum.new()
	add_child(_car)
	_play = Dugme.new().setup(load(G + "oynat.svg"), 140.0, Color("fffdf5"))
	_play.icon_offset = Vector2(0.06, 0)
	add_child(_play)
	resized.connect(_layout)


func show_garage(color: String, driver: int) -> void:
	visible = true
	_color = color
	_driver = driver
	_car.set_color(color)
	_car.set_driver(driver)
	_refresh()
	if _back:
		_back.queue_free()
	_back = HoldButton.new()
	_back.size = Vector2(104, 104)
	_back.position = Vector2(40, 26)
	_back.hold_time = 0.8
	_back.completed.connect(back_completed.emit)
	add_child(_back)
	_back_touch = -1
	_layout()
	# Açılış: araba sağdan platforma gelir, düğmeler sırayla belirir
	var home := _car.position
	_car.position.x += size.x * 0.6
	var tween := _car.create_tween()
	tween.tween_property(_car, "position:x", home.x, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_car.bump.bind(220.0))
	var items: Array[Control] = []
	items.append_array(_swatches)
	items.append_array(_cards)
	items.append(_play)
	for i in items.size():
		var item := items[i]
		item.scale = Vector2.ZERO
		item.create_tween().tween_property(item, "scale", Vector2.ONE, 0.4).set_delay(0.15 + i * 0.035).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _layout() -> void:
	var w := size.x
	var h := size.y
	var side := (w * 0.5 - 200.0) * 0.5
	for i in _swatches.size():
		var col := i % 2
		var row := i / 2
		_swatches[i].position = Vector2(side - 110.0 + col * 120.0, h * 0.27 + row * 128.0)
	for i in _cards.size():
		var col := i % 2
		var row := i / 2
		_cards[i].position = Vector2(w - side - 124.0 + col * 128.0, h * 0.12 + row * 128.0)
	_car.position = Vector2(w * 0.5, h * 0.63)
	_car.scale = Vector2.ONE * 1.1
	_play.position = Vector2(w * 0.5 - 70.0, h - 60.0 - 140.0 + 24.0)
	queue_redraw()


func _refresh() -> void:
	var accent: Color = Gorunum.COLORS[_color]
	for i in _swatches.size():
		_swatches[i].selected = Gorunum.COLOR_NAMES[i] == _color
		_swatches[i].queue_redraw()
	for i in _cards.size():
		_cards[i].selected = i == _driver
		_cards[i].accent = accent
		_cards[i].queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Duvar, zemin, ışık ve platform
	var wall := PackedColorArray([Color("e8efff"), Color("e8efff"), Color("d6e1fb"), Color("d6e1fb")])
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.68), Vector2(0, h * 0.68)]), wall)
	var floor_colors := PackedColorArray([Color("c3cdec"), Color("c3cdec"), Color("aab5dc"), Color("aab5dc")])
	draw_polygon(PackedVector2Array([Vector2(0, h * 0.68), Vector2(w, h * 0.68), Vector2(w, h), Vector2(0, h)]), floor_colors)
	# Arkada büyük garaj kapısı çerçevesi (yatay çıtalı)
	var door := Rect2(w * 0.5 - 300.0, h * 0.1, 600.0, h * 0.58)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4f7ff")
	style.corner_radius_top_left = 60
	style.corner_radius_top_right = 60
	style.set_border_width_all(10)
	style.border_width_bottom = 0
	style.border_color = Color("b9c4e6")
	draw_style_box(style, door)
	for k in range(1, 7):
		var y := door.position.y + 40.0 + k * (door.size.y - 40.0) / 7.0
		draw_line(Vector2(door.position.x + 18.0, y), Vector2(door.end.x - 18.0, y), Color("dfe6f8"), 6.0)
	var glow: Texture2D = preload(G + "isik.svg")
	draw_texture_rect(glow, Rect2(Vector2(w * 0.5 - 330.0, h * 0.63 - 360.0), Vector2(660, 560)), false, Color(1, 1, 1, 0.55))
	var center := Vector2(w * 0.5, h * 0.63 + 8.0)
	draw_set_transform(center + Vector2(0, 16), 0.0, Vector2(1.0, 0.17))
	draw_circle(Vector2.ZERO, 250.0, Color("8f9ac6"))
	draw_set_transform(center, 0.0, Vector2(1.0, 0.17))
	draw_circle(Vector2.ZERO, 250.0, Color("eef2ff"))
	draw_arc(Vector2.ZERO, 250.0, 0.0, TAU, 96, Color("8f9ac6"), 5.0, true)
	draw_circle(Vector2.ZERO, 180.0, Color("e2e8fb"))
	draw_set_transform(Vector2.ZERO)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	# Araba ara sıra neşeyle hoplar
	_hop_timer -= delta
	if _hop_timer <= 0.0:
		_hop_timer = randf_range(3.5, 5.5)
		_car.happy_hop(26.0, 0.4)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var touch := event as InputEventScreenTouch
	if touch == null:
		return
	if not touch.pressed:
		if touch.index == _back_touch and _back:
			_back.release()
			_back_touch = -1
		return
	if SahneGecis.gecis_suruyor:
		return
	var p := touch.position
	if _back and _back.contains(p):
		_back_touch = touch.index
		_back.press()
		return
	for i in _swatches.size():
		if _swatches[i].get_global_rect().grow(8.0).has_point(p):
			_pick_color(i)
			return
	for i in _cards.size():
		if _cards[i].get_global_rect().grow(6.0).has_point(p):
			_pick_driver(i)
			return
	if _play.contains(p):
		_play.pop()
		_sound("tik")
		play_pressed.emit()


func _pick_color(i: int) -> void:
	var color_name: String = Gorunum.COLOR_NAMES[i]
	_bounce(_swatches[i])
	if color_name == _color:
		return
	_color = color_name
	_car.set_color(color_name)
	_car.happy_hop(30.0, 0.38)
	_refresh()
	_sound("boya")
	_paint_splash(Gorunum.COLORS[color_name])
	color_chosen.emit(color_name)


func _pick_driver(i: int) -> void:
	_bounce(_cards[i])
	if i == _driver:
		return
	_driver = i
	_car.set_driver(i)
	_car.driver_pop()
	_refresh()
	_sound("hayvan")
	driver_chosen.emit(i)


func _bounce(control: Control) -> void:
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(0.86, 0.86), 0.07)
	tween.tween_property(control, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Yeni renk seçilince arabanın etrafına o renkte damlalar sıçrar
func _paint_splash(color: Color) -> void:
	var p := CPUParticles2D.new()
	p.texture = preload(G + "boya_damla.svg")
	p.amount = 18
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 1.0
	p.position = _car.position + Vector2(0, -120)
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 260.0
	p.initial_velocity_max = 480.0
	p.gravity = Vector2(0, 1100)
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.5
	p.color = color.lightened(0.1)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(150, 40)
	p.finished.connect(p.queue_free)
	add_child(p)
	p.emitting = true


func _sound(sound: String) -> void:
	if sounds:
		sounds.play(sound)
