extends Control
# Arayüz: üst çubuk (geri, meyve ikonlu ilerleme, duraklat), kalpler, güçlendirme göstergesi
# ve ekranlar: başlangıç, duraklatma, bölüm afişi, kutlama yazısı, tekrar deneme, hedef meyve.
# Oyun duraklatılınca da çalışır (bağlı olduğu CanvasLayer'ın process_mode'u ALWAYS).

signal back_pressed
signal menu_pressed       # başlangıç ekranındaki geri: ana menüye
signal pause_pressed
signal resume_pressed
signal start_pressed
signal reset_pressed

enum Mode { START, PLAY, PAUSED }


# İlerleme çubuğu: yuvarlak kenarlı zemin, iç yol ve dolan kısım
class Bar extends Control:
	var ratio := 0.0
	var left_space := 62.0
	var right_space := 64.0
	var _bg := StyleBoxFlat.new()
	var _track := StyleBoxFlat.new()
	var _fill := StyleBoxFlat.new()
	var _shine := StyleBoxFlat.new()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg.bg_color = Color(1, 1, 1, 0.94)
		_bg.set_border_width_all(5)
		_bg.border_color = Color("3b2f6b")
		_bg.set_corner_radius_all(40)
		_bg.shadow_color = Color(0.15, 0.1, 0.3, 0.25)
		_bg.shadow_size = 8
		_bg.shadow_offset = Vector2(0, 5)
		_track.bg_color = Color("ece6f7")
		_track.set_corner_radius_all(30)
		_fill.bg_color = Color("7ed957")
		_fill.set_border_width_all(3)
		_fill.border_color = Color("4a9e3a")
		_fill.set_corner_radius_all(30)
		_shine.bg_color = Color(1, 1, 1, 0.5)
		_shine.set_corner_radius_all(10)

	func track_rect() -> Rect2:
		var inner := Rect2(Vector2.ZERO, size).grow(-12.0)
		inner.position.x += left_space
		inner.size.x -= left_space + right_space
		return inner

	func head_position() -> Vector2:
		var track := track_rect()
		return global_position + Vector2(track.position.x + track.size.x * ratio, size.y / 2.0)

	func _draw() -> void:
		draw_style_box(_bg, Rect2(Vector2.ZERO, size))
		var track := track_rect()
		draw_style_box(_track, track)
		if ratio > 0.001:
			var width := maxf(track.size.x * ratio, track.size.y)
			draw_style_box(_fill, Rect2(track.position, Vector2(width, track.size.y)))
			if width > 30.0:
				draw_style_box(_shine, Rect2(track.position + Vector2(10, 5), Vector2(width - 20.0, track.size.y * 0.28)))


# Güçlendirme göstergesi: süresi azaldıkça kısalan halka
class PowerRing extends Control:
	var ratio := 1.0
	var ring_color := Color("ffb02e")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size / 2.0
		var radius := minf(size.x, size.y) / 2.0
		draw_circle(center + Vector2(0, 5), radius, Color(0.15, 0.1, 0.3, 0.22))
		draw_circle(center, radius, Color.WHITE)
		draw_arc(center, radius - 2.0, 0.0, TAU, 64, Color("3b2f6b"), 5.0, true)
		draw_arc(center, radius - 11.0, 0.0, TAU, 64, Color("ece6f7"), 9.0, true)
		if ratio > 0.0:
			draw_arc(center, radius - 11.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 64, ring_color, 9.0, true)


const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")
const TEX_BACK: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/geri.svg")
const TEX_PAUSE: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/duraklat.svg")
const TEX_PLAY: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/oynat.svg")
const TEX_RETRY: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/yeniden.svg")
const TEX_HEART: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/kalp.svg")
const TEX_GOAL: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/sepet_ikon.svg")
const TEX_GLOW: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/parilti.svg")
const TEX_POWER := {
	"buyuk_sepet": preload("res://oyunlar/meyve_topla/gorseller/guc_sepet.svg"),
	"miknatis": preload("res://oyunlar/meyve_topla/gorseller/guc_miknatis.svg"),
	"yavas": preload("res://oyunlar/meyve_topla/gorseller/guc_yavas.svg"),
}
const POWER_COLORS := {"buyuk_sepet": Color("ffb02e"), "miknatis": Color("ff5a6e"), "yavas": Color("a66bff")}
const RAINBOW := [Color("ff5a6e"), Color("ff9f40"), Color("ffc93d"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]
const OUTLINE := Color("3b2a5a")

var mode: Mode = Mode.START
var _back: Control
var _pause: Panel
var _bar: Bar
var _bar_icon: TextureRect
var _bar_ring: TextureRect
var _hearts_box: HBoxContainer
var _hearts: Array[TextureRect] = []
var _power: PowerRing
var _power_icon: TextureRect
var _start: Control
var _badge: Label
var _tap_label: Label
var _reset: Panel
var _reset_armed := false
var _pause_layer: Control
var _play_button: TextureRect
var _banner: Label
var _cheer: HBoxContainer
var _retry: TextureRect
var _announce: Control
var _announce_icon: TextureRect
var _bar_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_back = HoldButton.new()
	_back.completed.connect(_on_back_completed)
	_place(_back, Vector4(0, 0, 0, 0), Vector4(28, 44, 138, 154))
	_back.pivot_offset = _back.size / 2.0
	_pause = _round_button(TEX_PAUSE)
	_place(_pause, Vector4(1, 0, 1, 0), Vector4(-138, 44, -28, 154))

	_bar = Bar.new()
	_place(_bar, Vector4(0, 0, 1, 0), Vector4(156, 62, -156, 138))
	_bar_ring = _texture_rect(TEX_GLOW)
	_bar_ring.position = Vector2(-34, -34)
	_bar_ring.size = Vector2(144, 144)
	_bar_ring.visible = false
	_bar.add_child(_bar_ring)
	_bar_icon = _texture_rect(null)
	_bar_icon.position = Vector2(2, -2)
	_bar_icon.size = Vector2(80, 80)
	_bar.add_child(_bar_icon)
	var goal := _texture_rect(TEX_GOAL)
	_bar.add_child(goal)
	_place(goal, Vector4(1, 0, 1, 0), Vector4(-80, 4, -6, 72))

	_hearts_box = HBoxContainer.new()
	_hearts_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_hearts_box.add_theme_constant_override("separation", 10)
	_hearts_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_hearts_box, Vector4(0.5, 0, 0.5, 0), Vector4(-110, 148, 110, 202))

	_power = PowerRing.new()
	_place(_power, Vector4(1, 0, 1, 0), Vector4(-130, 172, -30, 272))
	_power_icon = _texture_rect(null)
	_power.add_child(_power_icon)
	_place(_power_icon, Vector4(0, 0, 1, 1), Vector4(22, 22, -22, -22))
	_power.visible = false

	_build_start()
	_build_overlays()
	_set_top_bar_visible(false)


# --- Yardımcılar ---

func _place(control: Control, anchors: Vector4, offsets: Vector4) -> void:
	if control.get_parent() == null:
		add_child(control)
	control.anchor_left = anchors.x
	control.anchor_top = anchors.y
	control.anchor_right = anchors.z
	control.anchor_bottom = anchors.w
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w


func _texture_rect(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _round_button(icon: Texture2D) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.set_border_width_all(5)
	style.border_color = Color("3b2f6b")
	style.set_corner_radius_all(34)
	style.shadow_color = Color(0.15, 0.1, 0.3, 0.25)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", style)
	var rect := _texture_rect(icon)
	panel.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	return panel


func _label(font_size: int, outline: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_shadow_color", Color(0.15, 0.1, 0.3, 0.35))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 8)
	return label


# Gökkuşağı renkli harflerden oluşan yazı
func _rainbow_word(box: HBoxContainer, word: String, font_size: int) -> Array[Label]:
	for child in box.get_children():
		child.queue_free()
	var letters: Array[Label] = []
	for i in word.length():
		var letter := _label(font_size, 26)
		letter.text = word[i]
		letter.add_theme_color_override("font_color", RAINBOW[i % RAINBOW.size()])
		box.add_child(letter)
		letter.pivot_offset = letter.get_minimum_size() / 2.0
		letters.append(letter)
	return letters


func _hit(control: Control, pos: Vector2) -> bool:
	return control.is_visible_in_tree() and control.get_global_rect().grow(16.0).has_point(pos)


func _press(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(0.88, 0.88), 0.06)
	tween.tween_property(control, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _pop_in(control: Control, delay: float = 0.0) -> void:
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2.ZERO
	control.create_tween().tween_property(control, "scale", Vector2.ONE, 0.5).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Dokunma ---

func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null:
		return
	# Geri düğmesi basılı tutulur (başlangıçta ana menüye, oyunda başlangıç ekranına)
	if _back.handle_touch(touch):
		get_viewport().set_input_as_handled()
		return
	if not touch.pressed:
		return
	var pos := touch.position
	match mode:
		Mode.START:
			get_viewport().set_input_as_handled()
			if _hit(_reset, pos):
				SesYoneticisi.efekt("dugme_tik")
				_on_reset_tap()
			else:
				SesYoneticisi.efekt("dugme_tik")
				start_pressed.emit()
		Mode.PLAY:
			if _hit(_pause, pos):
				get_viewport().set_input_as_handled()
				_press(_pause)
				SesYoneticisi.efekt("dugme_tik")
				pause_pressed.emit()
		Mode.PAUSED:
			get_viewport().set_input_as_handled()
			_press(_play_button)
			SesYoneticisi.efekt("dugme_tik")
			resume_pressed.emit()


func _on_back_completed() -> void:
	SesYoneticisi.efekt("geri")
	_back.reset()
	if mode == Mode.START:
		menu_pressed.emit()
	else:
		back_pressed.emit()


# --- Başlangıç ekranı ---

func _build_start() -> void:
	_start = Control.new()
	_start.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_start, Vector4(0, 0, 1, 1), Vector4.ZERO)

	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	title.add_theme_constant_override("separation", 0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start.add_child(title)
	_place(title, Vector4(0, 0, 1, 0), Vector4(0, 60, 0, 190))
	var letters := _rainbow_word(title, tr("Meyve Topla"), 96)
	# Başlık harfleri sırayla dalgalansın
	for i in letters.size():
		var wave := letters[i].create_tween().set_loops()
		wave.tween_interval(i * 0.08)
		wave.tween_property(letters[i], "position:y", -14.0, 0.45).as_relative().set_trans(Tween.TRANS_SINE)
		wave.tween_property(letters[i], "position:y", 14.0, 0.45).as_relative().set_trans(Tween.TRANS_SINE)
		wave.tween_interval(maxf(1.4 - i * 0.08, 0.1))

	_badge = _label(46, 16)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(1, 1, 1, 0.85)
	badge_style.set_corner_radius_all(36)
	badge_style.set_border_width_all(4)
	badge_style.border_color = OUTLINE
	badge_style.content_margin_left = 30
	badge_style.content_margin_right = 30
	_badge.add_theme_stylebox_override("normal", badge_style)
	_badge.add_theme_color_override("font_color", Color("ff7f50"))
	_start.add_child(_badge)
	_place(_badge, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-150, -145, 150, -75))

	_tap_label = _label(56, 20)
	_tap_label.text = "Başlamak için dokun"
	_start.add_child(_tap_label)
	_place(_tap_label, Vector4(0, 0.5, 1, 0.5), Vector4(20, -65, -20, 5))
	var pulse := _tap_label.create_tween().set_loops()
	pulse.tween_property(_tap_label, "modulate:a", 0.45, 0.7).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_tap_label, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

	_reset = _round_button(TEX_RETRY)
	_start.add_child(_reset)
	_place(_reset, Vector4(0, 1, 0, 1), Vector4(28, -136, 124, -40))


func show_start(level_number: int, can_reset: bool) -> void:
	mode = Mode.START
	_pause_layer.visible = false
	_set_top_bar_visible(false)
	_back.visible = true  # başlangıç ekranında geri ana menüye döner
	_start.visible = true
	_badge.text = tr("Bölüm %d") % level_number
	_badge.visible = level_number > 1
	_reset.visible = can_reset
	_disarm_reset()
	_start.modulate.a = 0.0
	_start.create_tween().tween_property(_start, "modulate:a", 1.0, 0.4)
	if _badge.visible:
		_pop_in(_badge, 0.2)


# "Baştan başla" düğmesi yanlışlıkla basılmasın diye iki dokunuş ister:
# ilk dokunuşta büyüyüp sallanır, 2.5 sn içinde ikinci dokunuş ilerlemeyi sıfırlar.
func _on_reset_tap() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset.pivot_offset = _reset.size / 2.0
		var tween := _reset.create_tween()
		tween.tween_property(_reset, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		for angle in [0.25, -0.25, 0.18, -0.1, 0.0]:
			tween.tween_property(_reset, "rotation", angle, 0.08)
		_reset.modulate = Color(1.0, 0.75, 0.75)
		get_tree().create_timer(2.5).timeout.connect(_disarm_reset)
		return
	_disarm_reset()
	var spin := _reset.create_tween()
	spin.tween_property(_reset, "rotation", -TAU, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spin.tween_callback(_reset.set_rotation.bind(0.0))
	spin.tween_callback(_reset.hide)
	reset_pressed.emit()


func _disarm_reset() -> void:
	_reset_armed = false
	if _reset:
		_reset.modulate = Color.WHITE
		_reset.create_tween().tween_property(_reset, "scale", Vector2.ONE, 0.2)


func set_level_badge(level_number: int) -> void:
	_badge.text = tr("Bölüm %d") % level_number
	if level_number <= 1:
		var tween := _badge.create_tween()
		tween.tween_property(_badge, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(_badge.hide)


# --- Oyun sırasında ---

func show_play() -> void:
	mode = Mode.PLAY
	if _start.visible:
		var tween := _start.create_tween()
		tween.tween_property(_start, "modulate:a", 0.0, 0.25)
		tween.tween_callback(_start.hide)
	if not _bar.visible:
		_set_top_bar_visible(true)
		for control in [_bar, _pause]:
			var target_y: float = control.position.y
			control.position.y = target_y - 200.0
			control.create_tween().tween_property(control, "position:y", target_y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_top_bar_visible(on: bool) -> void:
	_back.visible = on
	_pause.visible = on
	_bar.visible = on
	_hearts_box.visible = on
	if not on:
		_power.visible = false


func set_bar_fruit(texture: Texture2D, is_target: bool) -> void:
	_bar_icon.texture = texture
	_bar_ring.visible = is_target
	if is_target:
		_bar_ring.pivot_offset = _bar_ring.size / 2.0
		var pulse := _bar_ring.create_tween().set_loops()
		pulse.tween_property(_bar_ring, "scale", Vector2(1.15, 1.15), 0.6).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(_bar_ring, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


func set_progress(count: int, goal: int, animate: bool) -> void:
	var ratio := clampf(float(count) / maxf(goal, 1), 0.0, 1.0)
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill()
	if not animate:
		_set_bar_ratio(ratio)
		return
	_bar_tween = create_tween()
	_bar_tween.tween_method(_set_bar_ratio, _bar.ratio, ratio, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if count > 0:
		_bump_bar_icon()


func _set_bar_ratio(value: float) -> void:
	_bar.ratio = value
	_bar.queue_redraw()


# Yakalanan meyvenin küçük ikonu ekrandan ilerleme çubuğuna uçar
func fly_icon(texture: Texture2D, from_pos: Vector2) -> void:
	var icon := _texture_rect(texture)
	icon.size = Vector2(56, 56)
	icon.position = from_pos - icon.size / 2.0
	add_child(icon)
	var target := _bar.head_position() - icon.size / 2.0
	var tween := icon.create_tween()
	tween.tween_property(icon, "position", target, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(icon, "scale", Vector2(0.6, 0.6), 0.45)
	tween.tween_callback(icon.queue_free)


func set_hearts(count: int, max_count: int, animate_loss: bool) -> void:
	while _hearts.size() < max_count:
		var heart := _texture_rect(TEX_HEART)
		heart.custom_minimum_size = Vector2(58, 52)
		_hearts_box.add_child(heart)
		_hearts.append(heart)
	for i in _hearts.size():
		var heart := _hearts[i]
		heart.visible = i < max_count
		var full := i < count
		var was_full := heart.modulate.a > 0.9
		heart.pivot_offset = heart.custom_minimum_size / 2.0
		if animate_loss and was_full and not full:
			# Kalp büyüyüp söner
			var tween := heart.create_tween()
			tween.tween_property(heart, "scale", Vector2(1.5, 1.5), 0.12)
			tween.tween_property(heart, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(heart, "modulate", Color(0.4, 0.4, 0.5, 0.4), 0.25)
		else:
			heart.modulate = Color.WHITE if full else Color(0.4, 0.4, 0.5, 0.4)
			heart.scale = Vector2.ONE


# Kalpler tek tek dolar
func refill_hearts(delay: float = 0.0) -> void:
	for i in _hearts.size():
		var heart := _hearts[i]
		if not heart.visible:
			continue
		heart.pivot_offset = heart.custom_minimum_size / 2.0
		var tween := heart.create_tween()
		tween.tween_interval(delay + i * 0.18)
		tween.tween_callback(heart.set_modulate.bind(Color.WHITE))
		tween.tween_property(heart, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(heart, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func show_power(kind: String) -> void:
	_power_icon.texture = TEX_POWER[kind]
	_power.ring_color = POWER_COLORS[kind]
	_power.ratio = 1.0
	_power.visible = true
	_power.queue_redraw()
	_pop_in(_power)


func update_power(ratio: float) -> void:
	_power.ratio = clampf(ratio, 0.0, 1.0)
	# Bitmeye yakın göz kırpar
	_power.modulate.a = 1.0 if ratio > 0.25 else 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() / 90.0))
	_power.queue_redraw()


func hide_power() -> void:
	if not _power.visible:
		return
	_power.pivot_offset = _power.size / 2.0
	var tween := _power.create_tween()
	tween.tween_property(_power, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(_power.hide)
	tween.tween_callback(_power.set_modulate.bind(Color.WHITE))


# --- Ekran yazıları ve katmanlar ---

func _build_overlays() -> void:
	_banner = _label(112, 28)
	_place(_banner, Vector4(0, 0.5, 1, 0.5), Vector4(0, -320, 0, -170))
	_banner.visible = false

	_cheer = HBoxContainer.new()
	_cheer.alignment = BoxContainer.ALIGNMENT_CENTER
	_cheer.add_theme_constant_override("separation", 0)
	_cheer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_cheer, Vector4(0, 0.5, 1, 0.5), Vector4(0, -340, 0, -190))

	_retry = _texture_rect(TEX_RETRY)
	_place(_retry, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-110, -260, 110, -40))
	_retry.visible = false

	_announce = Control.new()
	_announce.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_announce, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-160, -200, 160, 120))
	var glow := _texture_rect(TEX_GLOW)
	_announce.add_child(glow)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_announce_icon = _texture_rect(null)
	_announce.add_child(_announce_icon)
	_announce_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 70)
	_announce.visible = false

	_pause_layer = Control.new()
	_pause_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_pause_layer, Vector4(0, 0, 1, 1), Vector4.ZERO)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.08, 0.22, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_play_button = _texture_rect(TEX_PLAY)
	_pause_layer.add_child(_play_button)
	_place(_play_button, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-140, -140, 140, 140))
	_pause_layer.visible = false
	# Geri düğmesi duraklatma katmanının üstünde kalsın
	move_child(_back, -1)


func show_pause() -> void:
	mode = Mode.PAUSED
	_pause_layer.visible = true
	_pause_layer.modulate.a = 0.0
	_pause_layer.create_tween().tween_property(_pause_layer, "modulate:a", 1.0, 0.2)
	_pop_in(_play_button)
	var pulse := _play_button.create_tween().set_loops()
	pulse.tween_interval(0.5)
	pulse.tween_property(_play_button, "scale", Vector2(1.08, 1.08), 0.5).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_play_button, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func hide_pause() -> void:
	mode = Mode.PLAY
	var tween := _pause_layer.create_tween()
	tween.tween_property(_pause_layer, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_pause_layer.hide)


# Büyük "Bölüm N" yazısı yaklaşık 1 sn görünür
func show_banner(text: String, duration: float = 1.0) -> void:
	_banner.text = text
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2.ZERO
	var tween := _banner.create_tween()
	tween.tween_property(_banner, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(maxf(duration - 0.6, 0.1))
	tween.tween_property(_banner, "scale", Vector2(1.2, 1.2), 0.25).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_banner, "modulate:a", 0.0, 0.25)
	tween.tween_callback(_banner.hide)


# Gökkuşağı renkli, zıplayarak beliren kutlama yazısı
func show_cheer(word: String, duration: float = 2.0) -> void:
	_cheer.visible = true
	_cheer.modulate.a = 1.0
	var letters := _rainbow_word(_cheer, word, 112)
	for i in letters.size():
		var letter := letters[i]
		letter.scale = Vector2.ZERO
		letter.rotation = randf_range(-0.4, 0.4)
		var tween := letter.create_tween()
		tween.tween_interval(i * 0.06)
		tween.tween_property(letter, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(letter, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var bounce := letter.create_tween().set_loops(3)
		bounce.tween_interval(0.7 + i * 0.06)
		bounce.tween_property(letter, "scale", Vector2(1.12, 0.9), 0.12).set_trans(Tween.TRANS_SINE)
		bounce.tween_property(letter, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var hide_tween := _cheer.create_tween()
	hide_tween.tween_interval(duration)
	hide_tween.tween_property(_cheer, "modulate:a", 0.0, 0.3)
	hide_tween.tween_callback(_cheer.hide)


# Kalpler bitince: büyük dönen ok ve kalplerin yeniden dolması
func show_retry() -> void:
	_retry.visible = true
	_retry.modulate.a = 1.0
	_retry.pivot_offset = _retry.size / 2.0
	_retry.scale = Vector2.ZERO
	_retry.rotation = -PI
	var tween := _retry.create_tween()
	tween.tween_property(_retry, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_retry, "rotation", 0.0, 0.9).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_retry, "rotation", TAU, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_retry, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(_retry.hide)
	refill_hearts(0.5)


# Hedef meyve bölümünde: meyve ekranın ortasında büyükçe görünür, sonra ilerleme çubuğuna uçar
func announce_target(texture: Texture2D) -> void:
	_announce_icon.texture = texture
	_announce.visible = true
	_announce.modulate.a = 1.0
	_announce.pivot_offset = _announce.size / 2.0
	var start_position := _announce.position
	_announce.scale = Vector2.ZERO
	var target := _bar.global_position + _bar_icon.position + _bar_icon.size / 2.0 - _announce.size / 2.0
	var tween := _announce.create_tween()
	tween.tween_property(_announce, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_announce, "rotation", 0.15, 0.15)
	tween.tween_property(_announce, "rotation", -0.15, 0.15)
	tween.tween_property(_announce, "rotation", 0.0, 0.15)
	tween.tween_interval(0.35)
	tween.tween_property(_announce, "global_position", target, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_announce, "scale", Vector2(0.3, 0.3), 0.5)
	tween.tween_callback(_announce.hide)
	tween.tween_callback(_announce.set_position.bind(start_position))
	tween.tween_callback(_bump_bar_icon)


func _bump_bar_icon() -> void:
	_bar_icon.pivot_offset = _bar_icon.size / 2.0
	var bump := _bar_icon.create_tween()
	bump.tween_property(_bar_icon, "scale", Vector2(1.4, 1.4), 0.1)
	bump.tween_property(_bar_icon, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
