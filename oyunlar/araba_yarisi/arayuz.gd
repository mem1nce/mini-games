extends Control
# Yarış arayüzü: sol üstte geri (basılı tutunca), sağ üstte duraklat, üstte ilerleme çubuğu (üç arabanın
# küçük simgeleri bitiş bayrağına ilerler) ve yanında yıldız sayısı. Ayrıca geri sayım ışıkları,
# "basılı tut" ipucu eli ve duraklatma ekranı (büyük devam, küçük tekrar).
# Dokunmayı ana sahne yönetir: hit() hangi düğmeye basıldığını söyler.

signal back_completed

const G := "res://oyunlar/araba_yarisi/gorseller/"
const Dugme := preload("res://oyunlar/araba_yarisi/dugme.gd")
const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")
const Gorunum := preload("res://oyunlar/araba_yarisi/araba_gorunum.gd")
const INK := Color("3b2f6b")
const LIGHT_COLORS := [Color("ff5a6e"), Color("ffc93d"), Color("5cd66a")]


# Üstteki ilerleme çubuğu: yuvarlak zemin, ince yol, bitişte bayrak; arabalar çocuk olarak üstünde
class RaceBar extends Control:
	var flag: Texture2D
	var _bg := StyleBoxFlat.new()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg.bg_color = Color(1, 1, 1, 0.92)
		_bg.set_corner_radius_all(36)
		_bg.set_border_width_all(5)
		_bg.border_color = Color("3b2f6b")
		_bg.shadow_color = Color(0.15, 0.1, 0.3, 0.2)
		_bg.shadow_size = 8
		_bg.shadow_offset = Vector2(0, 5)

	func track_rect() -> Rect2:
		return Rect2(46.0, size.y * 0.5 + 12.0, size.x - 46.0 - 78.0, 8.0)

	func _draw() -> void:
		draw_style_box(_bg, Rect2(Vector2.ZERO, size))
		var track := track_rect()
		draw_line(track.position, track.position + Vector2(track.size.x, 0), Color("e3dcf2"), 10.0, true)
		for k in range(1, 4):
			draw_circle(track.position + Vector2(track.size.x * k / 4.0, 0), 5.0, Color("cfc4e8"))
		if flag:
			draw_texture_rect(flag, Rect2(Vector2(size.x - 80.0, size.y * 0.5 - 34.0), Vector2(62, 62)), false)


# Geri sayım ışıkları: kırmızı, sarı, yeşil sırayla yanar
class Lights extends Control:
	var lit := 0

	func _draw() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("2d2447", 0.94)
		style.set_corner_radius_all(40)
		style.set_border_width_all(5)
		style.border_color = Color("1c1530")
		style.shadow_color = Color(0, 0, 0, 0.25)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 6)
		draw_style_box(style, Rect2(Vector2.ZERO, size))
		for i in 3:
			var center := Vector2(size.x * (0.2 + i * 0.3), size.y * 0.5)
			var on := i < lit
			var color: Color = LIGHT_COLORS[i] if on else Color("4a4063")
			if on:
				draw_circle(center, 40.0, Color(color, 0.25))
			draw_circle(center, 30.0, color)
			if on:
				draw_circle(center + Vector2(-9, -10), 8.0, Color(1, 1, 1, 0.6))


var back: Control                 # ortak basılı-tut geri düğmesi
var _pause: Control
var _bar: RaceBar
var _markers: Array[Node2D] = []
var _star_panel: PanelContainer
var _star_label: Label
var _lights: Lights
var _hint: TextureRect
var _hint_ring: Control
var _hint_time := 0.0
var _pause_layer: Control
var _resume: Control
var _retry: Control
var _paused := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_bar = RaceBar.new()
	_bar.flag = load(G + "bayrak_ikon.svg")
	add_child(_bar)

	_star_panel = PanelContainer.new()
	_star_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.92)
	style.set_corner_radius_all(36)
	style.set_border_width_all(5)
	style.border_color = INK
	style.content_margin_left = 14
	style.content_margin_right = 20
	style.shadow_color = Color(0.15, 0.1, 0.3, 0.2)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	_star_panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star_panel.add_child(row)
	var star := TextureRect.new()
	star.texture = load(G + "yildiz.svg")
	star.custom_minimum_size = Vector2(54, 54)
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(star)
	_star_label = Label.new()
	_star_label.text = "0"
	_star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_star_label.custom_minimum_size = Vector2(54, 0)
	var settings := LabelSettings.new()
	settings.font_size = 42
	settings.font_color = INK
	_star_label.label_settings = settings
	_star_label.theme_type_variation = &"Baslik"
	row.add_child(_star_label)
	add_child(_star_panel)

	_make_back()
	_pause = Dugme.new().setup(load(G + "duraklat.svg"), 104.0)
	add_child(_pause)

	_lights = Lights.new()
	_lights.size = Vector2(300, 110)
	_lights.pivot_offset = _lights.size / 2.0
	_lights.visible = false
	add_child(_lights)

	_hint_ring = Control.new()
	_hint_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_ring.draw.connect(_draw_hint_ring)
	add_child(_hint_ring)
	_hint = TextureRect.new()
	_hint.texture = load(G + "el.svg")
	_hint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hint.size = Vector2(120, 140)
	_hint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.pivot_offset = Vector2(60, 20)
	_hint.visible = false
	add_child(_hint)

	_pause_layer = Control.new()
	_pause_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.08, 0.25, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(dim)
	_resume = Dugme.new().setup(load(G + "oynat.svg"), 190.0)
	_resume.icon_offset = Vector2(0.06, 0)
	_pause_layer.add_child(_resume)
	_retry = Dugme.new().setup(load(G + "tekrar.svg"), 112.0)
	_pause_layer.add_child(_retry)
	_pause_layer.visible = false
	add_child(_pause_layer)
	# Geri düğmesi duraklatma perdesinin de üstünde kalsın
	move_child(back, -1)

	resized.connect(_layout)
	_layout()


# Ortak basılı-tut geri düğmesi bir kez dolunca kilitlenir; her yarışta yenisi kurulur
func _make_back() -> void:
	if back:
		back.queue_free()
	back = HoldButton.new()
	back.size = Vector2(104, 104)
	back.hold_time = 0.6
	back.position = Vector2(EkranYardimcisi.kenar_payi(SIDE_LEFT, 40.0), 26)
	back.completed.connect(back_completed.emit)
	add_child(back)


func _layout() -> void:
	var w := size.x
	var h := size.y
	# Çentikli telefonlarda üst çubuk iki yandan güvenli alan kadar içeri girer
	var left := EkranYardimcisi.kenar_payi(SIDE_LEFT, 40.0)
	var right := EkranYardimcisi.kenar_payi(SIDE_RIGHT, 40.0)
	back.position = Vector2(left, 26)
	_pause.position = Vector2(w - right - 104, 26)
	_star_panel.position = Vector2(_pause.position.x - 24 - 170, 36)
	_star_panel.size = Vector2(170, 84)
	_bar.position = Vector2(left + 128, 36)
	_bar.size = Vector2(maxf(200.0, _star_panel.position.x - 24.0 - _bar.position.x), 84)
	_lights.position = Vector2(w * 0.5 - 150.0, 170)
	_hint.position = Vector2(w * 0.62, h * 0.52)
	_hint_ring.position = _hint.position + Vector2(60, 10)
	_pause_layer.size = size
	_resume.position = Vector2(w * 0.5 - 95.0, h * 0.5 - 110.0)
	_retry.position = Vector2(w * 0.5 - 56.0, h * 0.5 + 110.0)
	for i in _markers.size():
		_markers[i].position.y = _bar.track_rect().position.y + 4.0


# Yarış başında üç arabanın küçük simgelerini kurar. cars: [{color, driver}] (0 = çocuk)
func setup_race(cars: Array) -> void:
	_make_back()
	for marker in _markers:
		marker.queue_free()
	_markers.clear()
	# Rakipler önce eklenir; çocuğun simgesi en üstte ve biraz büyük
	for i in range(cars.size() - 1, -1, -1):
		var marker := Gorunum.new()
		marker.set_color(cars[i]["color"])
		marker.set_driver(cars[i]["driver"])
		marker.scale = Vector2.ONE * (0.2 if i == 0 else 0.16)
		marker.modulate = Color.WHITE if i == 0 else Color(1, 1, 1, 0.9)
		_bar.add_child(marker)
		_markers.push_front(marker)
	for i in _markers.size():
		place_marker(i, 0.0, 0.0)
	set_stars(0, false)
	set_paused(false)
	_lights.visible = false
	show_hint(false)
	set_race_visible(true)
	_layout()


func place_marker(i: int, ratio: float, distance: float) -> void:
	if i >= _markers.size():
		return
	var track := _bar.track_rect()
	var marker := _markers[i]
	marker.position = Vector2(track.position.x + track.size.x * clampf(ratio, 0.0, 1.0), track.position.y + 4.0)
	marker.spin_wheels(distance * 0.2)


func set_stars(count: int, animate: bool) -> void:
	_star_label.text = str(count)
	if animate:
		_star_panel.pivot_offset = _star_panel.size / 2.0
		var tween := _star_panel.create_tween()
		tween.tween_property(_star_panel, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(_star_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Yıldızın ekrandaki hedefi (uçan yıldız efekti için)
func star_target() -> Vector2:
	return _star_panel.position + Vector2(44, 42)


# Toplanan yıldız ekrandaki yerinden sayaca uçar; varınca on_arrive çağrılır
func fly_star(from: Vector2, on_arrive: Callable) -> void:
	var star := TextureRect.new()
	star.texture = load(G + "yildiz.svg")
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.size = Vector2(64, 64)
	star.pivot_offset = star.size / 2.0
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.position = from - star.size / 2.0
	add_child(star)
	var tween := star.create_tween()
	tween.tween_property(star, "position", star_target() - star.size / 2.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(star, "scale", Vector2(0.75, 0.75), 0.5)
	tween.parallel().tween_property(star, "rotation", TAU * 0.5, 0.5)
	tween.tween_callback(on_arrive)
	tween.tween_callback(star.queue_free)


# --- Geri sayım ---

func countdown_light(count: int) -> void:
	if not _lights.visible:
		_lights.visible = true
		_lights.scale = Vector2(0.6, 0.6)
		_lights.modulate.a = 0.0
		var show := _lights.create_tween().set_parallel()
		show.tween_property(_lights, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		show.tween_property(_lights, "modulate:a", 1.0, 0.2)
	_lights.lit = count
	_lights.queue_redraw()
	var tween := _lights.create_tween()
	tween.tween_property(_lights, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(_lights, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_countdown() -> void:
	var tween := _lights.create_tween().set_parallel()
	tween.tween_property(_lights, "position:y", _lights.position.y - 60.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_lights, "modulate:a", 0.0, 0.35).set_delay(0.1)
	tween.chain().tween_callback(func() -> void:
		_lights.visible = false
		_layout())


# --- İpucu eli: ekrana basılı tut ---

func show_hint(value: bool) -> void:
	if value == _hint.visible:
		return
	_hint.visible = value
	_hint_ring.visible = value
	_hint_time = 0.0
	if value:
		_hint.modulate.a = 0.0
		_hint.create_tween().tween_property(_hint, "modulate:a", 1.0, 0.3)


func _process(delta: float) -> void:
	if not _hint.visible:
		return
	_hint_time += delta
	# Parmak basar, basılı kalır (halka dalgalanır), kalkar
	var t := fmod(_hint_time, 1.6)
	var press := smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(1.2, 1.45, t))
	_hint.scale = Vector2.ONE * (1.0 - press * 0.1)
	_hint.position.y = size.y * 0.52 + press * 12.0
	_hint_ring.queue_redraw()


func _draw_hint_ring() -> void:
	var t := fmod(_hint_time, 1.6)
	if t < 0.25 or t > 1.3:
		return
	var k := fmod((t - 0.25) / 0.5, 1.0)
	_hint_ring.draw_arc(Vector2(0, 14), 18.0 + k * 46.0, 0.0, TAU, 40, Color(1, 1, 1, 0.8 * (1.0 - k)), 6.0, true)


# --- Duraklatma ---

func set_paused(value: bool) -> void:
	_paused = value
	_pause_layer.visible = value
	_pause.visible = not value
	if value:
		_resume.scale = Vector2(0.6, 0.6)
		_resume.create_tween().tween_property(_resume, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_race_visible(value: bool) -> void:
	for node in [_bar, _star_panel, _pause, back]:
		node.visible = value
	if not value:
		_pause_layer.visible = false
		show_hint(false)


# Dokunulan düğme: "back", "pause", "resume", "retry" ya da ""
func hit(point: Vector2) -> String:
	if back.contains(point):
		return "back"
	if _paused:
		if _resume.contains(point):
			_resume.pop()
			return "resume"
		if _retry.contains(point):
			_retry.pop()
			return "retry"
		return "paused"
	if _pause.contains(point):
		_pause.pop()
		return "pause"
	return ""
