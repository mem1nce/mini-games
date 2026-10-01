extends Control
# Yarış sonu: podyum. 2-1-3 dizilişli basamaklar yükselir, arabalar sırayla üstlerine iner ve neşeyle
# zıplar, konfeti yağar. Çocuk kaçıncı olursa olsun kutlama aynıdır; onun arabasının arkasında ışık var.
# Üstte toplanan yıldızlar tek tek sayılır. Sağ altta büyük "sonraki pist" oku, sol altta küçük "tekrar".
# Sol üstte basılı-tut geri: haritaya.

signal next_pressed
signal retry_pressed
signal back_completed

const G := "res://oyunlar/araba_yarisi/gorseller/"
const Pistler := preload("res://oyunlar/araba_yarisi/pistler.gd")
const Gorunum := preload("res://oyunlar/araba_yarisi/araba_gorunum.gd")
const Dugme := preload("res://oyunlar/araba_yarisi/dugme.gd")
const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")
const Efektler := preload("res://oyunlar/araba_yarisi/efektler.gd")
const INK := Color("3b2f6b")
# Basamaklar: sıra -> (yatay kayma, yükseklik, renk)
const STEPS := [
	[0.0, 190.0, Color("ffd23f")],
	[-250.0, 140.0, Color("cfd8ea")],
	[250.0, 100.0, Color("f2a66b")],
]


# Tek basamak: yuvarlak üst köşeler, üstte açık şerit, önünde büyük rakam
class Step extends Control:
	var color := Color.WHITE
	var number := 1

	func _draw() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.corner_radius_top_left = 26
		style.corner_radius_top_right = 26
		style.set_border_width_all(6)
		style.border_width_bottom = 0
		style.border_color = color.darkened(0.45)
		draw_style_box(style, Rect2(Vector2.ZERO, size + Vector2(0, 40)))
		draw_rect(Rect2(10, 10, size.x - 20, 16), Color(1, 1, 1, 0.45))
		var font := get_theme_font("font", &"Baslik")
		var text := str(number)
		var font_size := 84
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var pos := Vector2((size.x - width) * 0.5, size.y * 0.5 + 44.0)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 14, color.darkened(0.5))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


var sounds: Node
var _steps: Array[Step] = []
var _cars: Array[Gorunum] = []
var _glow: Sprite2D
var _stars_panel: PanelContainer
var _stars_label: Label
var _next: Control
var _retry: Control
var _back: Control
var _back_touch := -1
var _confetti: CPUParticles2D
var _sky := Gradient.new()
var _ready_for_input := false
var _hop_time := 0.0
var _player_place := 0
var _count_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sky := TextureRect.new()
	var tex := GradientTexture2D.new()
	tex.gradient = _sky
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	sky.texture = tex
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	_glow = Sprite2D.new()
	_glow.texture = load(G + "isik.svg")
	add_child(_glow)
	for i in 3:
		var step := Step.new()
		step.mouse_filter = Control.MOUSE_FILTER_IGNORE
		step.number = i + 1
		step.color = STEPS[i][2]
		add_child(step)
		_steps.append(step)
	for i in 3:
		var car := Gorunum.new()
		car.scale = Vector2.ONE * 0.62
		add_child(car)
		_cars.append(car)
	_make_stars_panel()
	_next = Dugme.new().setup(load(G + "ok.svg"), 168.0, Color("fffdf5"))
	add_child(_next)
	_retry = Dugme.new().setup(load(G + "tekrar.svg"), 108.0)
	add_child(_retry)
	_confetti = CPUParticles2D.new()
	_confetti.texture = load(G + "konfeti.svg")
	_confetti.amount = 90
	_confetti.lifetime = 4.5
	_confetti.emitting = false
	_confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_confetti.direction = Vector2(0, 1)
	_confetti.spread = 25.0
	_confetti.initial_velocity_min = 60.0
	_confetti.initial_velocity_max = 140.0
	_confetti.gravity = Vector2(0, 120)
	_confetti.angular_velocity_min = -240.0
	_confetti.angular_velocity_max = 240.0
	_confetti.angle_max = 360.0
	_confetti.scale_amount_min = 0.3
	_confetti.scale_amount_max = 0.5
	_confetti.color_initial_ramp = Efektler.confetti_ramp()
	add_child(_confetti)
	resized.connect(_layout)


func _make_stars_panel() -> void:
	_stars_panel = PanelContainer.new()
	_stars_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.set_corner_radius_all(44)
	style.set_border_width_all(6)
	style.border_color = INK
	style.content_margin_left = 20
	style.content_margin_right = 30
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(0.15, 0.1, 0.3, 0.22)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	_stars_panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stars_panel.add_child(row)
	var star := TextureRect.new()
	star.texture = load(G + "yildiz.svg")
	star.custom_minimum_size = Vector2(76, 76)
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(star)
	_stars_label = Label.new()
	var settings := LabelSettings.new()
	settings.font_size = 58
	settings.font_color = INK
	_stars_label.label_settings = settings
	_stars_label.theme_type_variation = &"Baslik"
	_stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stars_label.custom_minimum_size = Vector2(70, 0)
	row.add_child(_stars_label)
	add_child(_stars_panel)


# order: sıraya göre arabalar [{color, driver, player}], stars: toplanan yıldız
func show_results(order: Array, stars: int, theme_name: String, has_next: bool) -> void:
	visible = true
	_ready_for_input = false
	var sky: Array = Pistler.THEMES[theme_name]["sky"]
	_sky.offsets = PackedFloat32Array([0.0, 1.0])
	_sky.colors = PackedColorArray([sky[0].lerp(Color.WHITE, 0.15), sky[1].lerp(Color.WHITE, 0.3)])
	for i in 3:
		_cars[i].set_color(order[i]["color"])
		_cars[i].set_driver(order[i]["driver"])
		if order[i]["player"]:
			_player_place = i
	_next.icon = load(G + ("ok.svg" if has_next else "oynat.svg"))
	_next.queue_redraw()
	if _back:
		_back.queue_free()
	_back = HoldButton.new()
	_back.size = Vector2(104, 104)
	_back.position = Vector2(40, 26)
	_back.hold_time = 0.6
	_back.completed.connect(back_completed.emit)
	add_child(_back)
	_back_touch = -1
	_stars_label.text = "0"
	_layout()
	_animate_in(stars)


func _layout() -> void:
	var w := size.x
	var h := size.y
	var base := h - 40.0
	for i in 3:
		var step := _steps[i]
		step.size = Vector2(230, STEPS[i][1])
		step.position = Vector2(w * 0.5 + STEPS[i][0] - 115.0, base - STEPS[i][1])
		_cars[i].position = Vector2(w * 0.5 + STEPS[i][0], base - STEPS[i][1] + 2.0)
	_glow.scale = Vector2.ONE * 460.0 / _glow.texture.get_width()
	_glow.position = _cars[_player_place].position + Vector2(0, -70)
	_glow.modulate = Color(1, 1, 0.85, 0.85)
	_stars_panel.reset_size()
	_stars_panel.position = Vector2(w * 0.5 - _stars_panel.size.x * 0.5, 34)
	_next.position = Vector2(w - 60.0 - 168.0, h - 60.0 - 168.0)
	_retry.position = Vector2(60, h - 60.0 - 108.0)
	_confetti.position = Vector2(w * 0.5, -30)
	_confetti.emission_rect_extents = Vector2(w * 0.55, 10)


func _animate_in(stars: int) -> void:
	# Basamaklar aşağıdan yükselir
	for i in 3:
		var step := _steps[i]
		var home := step.position
		step.position.y = size.y + 20.0
		step.create_tween().tween_property(step, "position:y", home.y, 0.55).set_delay(0.1 + i * 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Arabalar 3., 2., 1. sırayla yukarıdan iner
	for i in 3:
		var car := _cars[i]
		var home := car.position
		car.position.y = -200.0
		var delay := 0.6 + (2 - i) * 0.35
		var tween := car.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(car, "position:y", home.y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(car.bump.bind(280.0))
	_glow.modulate.a = 0.0
	_glow.create_tween().tween_property(_glow, "modulate:a", 0.85, 0.5).set_delay(1.6)
	for item in [_stars_panel, _next, _retry]:
		item.pivot_offset = item.size / 2.0
		item.scale = Vector2.ZERO
	_stars_panel.create_tween().tween_property(_stars_panel, "scale", Vector2.ONE, 0.4).set_delay(1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var finish := create_tween()
	finish.tween_interval(1.7)
	finish.tween_callback(func() -> void:
		_confetti.emitting = true
		_sound("podyum")
		_count_stars(stars))
	# Düğmeler sayma bitmesini beklemeden gelir
	finish.tween_interval(1.1)
	finish.tween_callback(func() -> void:
		for item in [_next, _retry]:
			item.create_tween().tween_property(item, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_ready_for_input = true)
	_hop_time = -1.8


# Yıldızlar tek tek sayılır; her birinde perde biraz yükselir
func _count_stars(stars: int) -> void:
	if _count_tween:
		_count_tween.kill()
	_count_tween = create_tween()
	var step := clampf(1.0 / maxf(stars, 1), 0.03, 0.12)
	for k in range(1, stars + 1):
		_count_tween.tween_interval(step)
		_count_tween.tween_callback(func() -> void:
			_stars_label.text = str(k)
			if sounds:
				sounds.play("say", 1.0 + minf(k * 0.02, 0.6))
			_stars_panel.scale = Vector2(1.08, 1.08))
		_count_tween.tween_property(_stars_panel, "scale", Vector2.ONE, step * 0.8)


func _process(delta: float) -> void:
	if not visible:
		return
	# Arabalar sırayla neşeyle zıplar (çocuğunki biraz daha yüksek)
	_hop_time += delta
	if _hop_time > 0.0:
		_hop_time -= 0.45
		var i := randi() % 3
		_cars[i].happy_hop(44.0 if i == _player_place else 30.0, 0.42)
	if _next.scale.x > 0.99 and _ready_for_input:
		_next.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.04)


func hide_screen() -> void:
	visible = false
	_confetti.emitting = false


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
	if not _ready_for_input:
		return
	if _next.contains(p):
		_ready_for_input = false
		_next.pop()
		_sound("tik")
		next_pressed.emit()
	elif _retry.contains(p):
		_ready_for_input = false
		_retry.pop()
		_sound("tik")
		retry_pressed.emit()


func _sound(sound: String) -> void:
	if sounds:
		sounds.play(sound)
