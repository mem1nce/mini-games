extends Control
# Arayüz (UI CanvasLayer içinde): sol üstte basılı-tut geri düğmesi, üst ortada yıldız + skor ve
# küçük seviye rozeti, sağ üstte kalpler; 3-2-1 geri sayımı, süzülen "+30"/"+10" yazıları,
# seviye atlama bildirimi ve oyun bitti paneli. Dokunmayı ana sahne yönetir (contains / hit_* sorar).

const G := "res://oyunlar/kostebek/gorseller/"
const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")
const TEX_STAR: Texture2D = preload(G + "yildiz.svg")
const TEX_HEART: Texture2D = preload(G + "kalp.svg")
const TEX_TROPHY: Texture2D = preload(G + "kupa.svg")
const TEX_REPLAY: Texture2D = preload(G + "yeniden.svg")
const TEX_HOME: Texture2D = preload(G + "ev.svg")
const TEX_SPARKLE: Texture2D = preload(G + "isilti.svg")
const OUTLINE := Color("3b2a5a")
const INK := Color("3b2f6b")
const GOLD := Color("ffc928")
const EMPTY_HEART := Color(0.4, 0.4, 0.5, 0.35)

var back_button: HoldButton
var _score_panel: Panel
var _score_label: Label
var _level_badge: Control
var _level_label: Label
var _hearts: Array[TextureRect] = []
var _count_label: Label
var _over_layer: Control
var _over_panel: Panel
var _over_score: Label
var _over_best: Label
var _over_trophy: TextureRect
var _new_best_glow: TextureRect
var _replay: Panel
var _home: Panel
var _loops: Array[Tween] = []     # oyun bitti ekranındaki sonsuz animasyonlar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	back_button = HoldButton.new()
	_place(back_button, Vector4(0, 0, 0, 0), Vector4(40, 50, 150, 160))

	_score_panel = _panel(Color(1, 1, 1, 0.94), 46)
	_place(_score_panel, Vector4(0.5, 0, 0.5, 0), Vector4(-105, 20, 105, 92))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_panel.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var star := _texture_rect(TEX_STAR)
	star.custom_minimum_size = Vector2(48, 48)
	row.add_child(star)
	_score_label = _label(44, 0, INK)
	_score_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(_score_label)

	_level_badge = Control.new()
	_level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_level_badge, Vector4(0.5, 0, 0.5, 0), Vector4(118, 24, 182, 88))
	var badge_star := _texture_rect(TEX_STAR)
	_level_badge.add_child(badge_star)
	badge_star.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_label = _label(28, 10, Color.WHITE)
	_level_badge.add_child(_level_label)
	_level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_label.offset_top = 6.0

	var hearts_box := HBoxContainer.new()
	hearts_box.alignment = BoxContainer.ALIGNMENT_END
	hearts_box.add_theme_constant_override("separation", 8)
	hearts_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(hearts_box, Vector4(1, 0, 1, 0), Vector4(-250, 26, -40, 82))
	for k in 6:
		var heart := _texture_rect(TEX_HEART)
		heart.custom_minimum_size = Vector2(62, 56)
		hearts_box.add_child(heart)
		_hearts.append(heart)

	_count_label = _label(260, 40, Color("ff7a9a"))
	_place(_count_label, Vector4(0, 0.5, 1, 0.5), Vector4(0, -200, 0, 120))
	_count_label.visible = false

	_build_game_over()


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


func _label(font_size: int, outline: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_color_override("font_outline_color", OUTLINE)
		label.add_theme_constant_override("outline_size", outline)
	return label


func _panel(color: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_width_all(5)
	style.border_color = INK
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.15, 0.1, 0.3, 0.25)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _round_button(icon: Texture2D, margin: int) -> Panel:
	var panel := _panel(Color(1, 1, 1, 0.97), 999)
	var rect := _texture_rect(icon)
	panel.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, margin)
	return panel


func _pop(control: Control, from: float = 1.35) -> void:
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2.ONE * from
	control.create_tween().tween_property(control, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _hit(control: Control, pos: Vector2) -> bool:
	return control.is_visible_in_tree() and control.get_global_rect().grow(16.0).has_point(pos)


# --- Skor, seviye, can ---

func set_score(score: int, animate: bool) -> void:
	_score_label.text = str(score)
	if animate:
		_pop(_score_panel, 1.12)


func set_level(level: int, animate: bool) -> void:
	_level_label.text = str(level)
	if animate:
		_pop(_level_badge, 1.8)


func set_lives(lives: int, max_lives: int, animate_loss: bool) -> void:
	for k in _hearts.size():
		var heart := _hearts[k]
		heart.visible = k < max_lives
		heart.pivot_offset = heart.custom_minimum_size / 2.0
		var full := k < lives
		var was_full := heart.modulate.a > 0.9
		if animate_loss and was_full and not full:
			# Kalp büyür, sallanır, küçülerek söner; yerinde soluk bir kalp kalır
			var tween := heart.create_tween()
			tween.tween_property(heart, "scale", Vector2(1.6, 1.6), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(heart, "rotation", 0.3, 0.06)
			tween.tween_property(heart, "rotation", -0.3, 0.08)
			tween.tween_property(heart, "rotation", 0.0, 0.06)
			tween.tween_property(heart, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(heart.set_modulate.bind(EMPTY_HEART))
			tween.tween_property(heart, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_sparkle_at(heart.get_global_rect().get_center(), Color("ff9ab6"))
		else:
			heart.modulate = Color.WHITE if full else EMPTY_HEART
			heart.scale = Vector2.ONE
			heart.rotation = 0.0


# Dokunulan yerden yukarı süzülüp kaybolan "+30" / "+10"
func float_text(pos: Vector2, text: String, color: Color) -> void:
	var label := _label(64, 18, color)
	label.text = text
	add_child(label)
	label.size = label.get_combined_minimum_size()
	label.position = pos - label.size / 2.0
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(0.4, 0.4)
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:y", label.position.y - 120.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.55)
	tween.tween_callback(label.queue_free)


# Seviye atlama: oyunu durdurmadan, üstte büyük bir yıldız içinde yeni seviye numarası belirir,
# parlar ve küçük seviye rozetine doğru uçup kaybolur
func show_level_up(level: int) -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = Vector2(200, 200)
	var screen := get_viewport_rect().size
	holder.position = Vector2(screen.x / 2.0 - 100.0, screen.y * 0.3)
	holder.pivot_offset = holder.size / 2.0
	add_child(holder)
	var glow := _texture_rect(TEX_SPARKLE)
	holder.add_child(glow)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.pivot_offset = holder.size / 2.0
	glow.scale = Vector2(1.6, 1.6)
	var star := _texture_rect(TEX_STAR)
	holder.add_child(star)
	star.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var number := _label(76, 20, Color.WHITE)
	number.text = str(level)
	holder.add_child(number)
	number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number.offset_top = 16.0
	holder.scale = Vector2.ZERO
	holder.modulate.a = 0.95
	var spin := glow.create_tween()
	spin.tween_property(glow, "rotation", PI, 1.6)
	var target := _level_badge.get_global_rect().get_center() - holder.size / 2.0
	var tween := holder.create_tween()
	tween.tween_property(holder, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(holder, "position", target, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(holder, "scale", Vector2(0.3, 0.3), 0.45)
	tween.tween_callback(set_level.bind(level, true))
	tween.tween_callback(holder.queue_free)


func _sparkle_at(pos: Vector2, color: Color) -> void:
	for k in 6:
		var glint := _texture_rect(TEX_SPARKLE)
		glint.size = Vector2(40, 40)
		glint.position = pos - glint.size / 2.0
		glint.pivot_offset = glint.size / 2.0
		glint.modulate = color
		add_child(glint)
		var direction := Vector2.from_angle(TAU * k / 6.0 + randf_range(-0.3, 0.3))
		var tween := glint.create_tween()
		tween.tween_property(glint, "position", glint.position + direction * randf_range(50.0, 80.0), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(glint, "scale", Vector2(0.2, 0.2), 0.45)
		tween.parallel().tween_property(glint, "modulate:a", 0.0, 0.45)
		tween.tween_callback(glint.queue_free)


# --- Geri sayım ---

func show_count(text: String, color: Color) -> void:
	_count_label.text = text
	_count_label.add_theme_color_override("font_color", color)
	_count_label.visible = true
	_count_label.modulate.a = 1.0
	_count_label.pivot_offset = _count_label.size / 2.0
	_count_label.scale = Vector2.ZERO
	var tween := _count_label.create_tween()
	tween.tween_property(_count_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.25)
	tween.tween_property(_count_label, "scale", Vector2(1.3, 1.3), 0.15)
	tween.parallel().tween_property(_count_label, "modulate:a", 0.0, 0.15)
	tween.tween_callback(_count_label.hide)


# --- Oyun bitti ---

func _build_game_over() -> void:
	_over_layer = Control.new()
	_over_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_over_layer, Vector4(0, 0, 1, 1), Vector4.ZERO)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.08, 0.22, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_over_panel = _panel(Color("fffaf0"), 60)
	_over_layer.add_child(_over_panel)
	_place(_over_panel, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-270, -330, 270, 330))

	# Skor: büyük yıldız + sayı
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 16)
	score_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over_panel.add_child(score_row)
	_place(score_row, Vector4(0, 0, 1, 0), Vector4(20, 50, -20, 200))
	var star := _texture_rect(TEX_STAR)
	star.custom_minimum_size = Vector2(120, 120)
	score_row.add_child(star)
	_over_score = _label(110, 26, Color.WHITE)
	score_row.add_child(_over_score)

	# Rekor: kupa + sayı (yeni rekorsa kupanın arkasında dönen ışıltı)
	var best_row := HBoxContainer.new()
	best_row.alignment = BoxContainer.ALIGNMENT_CENTER
	best_row.add_theme_constant_override("separation", 16)
	best_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over_panel.add_child(best_row)
	_place(best_row, Vector4(0, 0, 1, 0), Vector4(20, 220, -20, 330))
	var trophy_holder := Control.new()
	trophy_holder.custom_minimum_size = Vector2(100, 100)
	trophy_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	best_row.add_child(trophy_holder)
	_new_best_glow = _texture_rect(TEX_SPARKLE)
	trophy_holder.add_child(_new_best_glow)
	_place(_new_best_glow, Vector4(0, 0, 1, 1), Vector4(-40, -40, 40, 40))
	_over_trophy = _texture_rect(TEX_TROPHY)
	trophy_holder.add_child(_over_trophy)
	_over_trophy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_over_best = _label(72, 20, GOLD)
	best_row.add_child(_over_best)

	# Düğmeler: küçük ev (ana menü) ve büyük "tekrar oyna"
	_home = _round_button(TEX_HOME, 26)
	_over_panel.add_child(_home)
	_place(_home, Vector4(0.5, 1, 0.5, 1), Vector4(-220, -210, -70, -60))
	_replay = _round_button(TEX_REPLAY, 34)
	_over_panel.add_child(_replay)
	_place(_replay, Vector4(0.5, 1, 0.5, 1), Vector4(-30, -260, 200, -30))
	_over_layer.visible = false


func show_game_over(score: int, best: int, is_new_best: bool) -> void:
	_over_score.text = str(score)
	_over_best.text = str(best)
	_new_best_glow.visible = is_new_best
	_over_layer.visible = true
	_over_layer.modulate.a = 0.0
	_over_layer.create_tween().tween_property(_over_layer, "modulate:a", 1.0, 0.25)
	_over_panel.pivot_offset = _over_panel.size / 2.0
	_over_panel.scale = Vector2(0.6, 0.6)
	_over_panel.create_tween().tween_property(_over_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_new_best:
		_new_best_glow.pivot_offset = _new_best_glow.size / 2.0
		var spin := _new_best_glow.create_tween().set_loops()
		spin.tween_property(_new_best_glow, "rotation", TAU, 3.0).from(0.0)
		_loops.append(spin)
		_over_trophy.pivot_offset = _over_trophy.size / 2.0
		var bounce := _over_trophy.create_tween().set_loops()
		bounce.tween_property(_over_trophy, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_SINE)
		bounce.tween_property(_over_trophy, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
		_loops.append(bounce)
	# "Tekrar oyna" düğmesi hafifçe nabız gibi atar
	_replay.pivot_offset = _replay.size / 2.0
	var pulse := _replay.create_tween().set_loops()
	pulse.tween_interval(0.6)
	pulse.tween_property(_replay, "scale", Vector2(1.08, 1.08), 0.45).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_replay, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)
	_loops.append(pulse)


func hide_game_over() -> void:
	for loop in _loops:
		loop.kill()
	_loops.clear()
	_over_trophy.scale = Vector2.ONE
	_replay.scale = Vector2.ONE
	var tween := _over_layer.create_tween()
	tween.tween_property(_over_layer, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_over_layer.hide)


func is_game_over_visible() -> bool:
	return _over_layer.visible


func hit_replay(pos: Vector2) -> bool:
	return _hit(_replay, pos)


func hit_home(pos: Vector2) -> bool:
	return _hit(_home, pos)


func press(control_name: String) -> void:
	var control := _replay if control_name == "replay" else _home
	control.pivot_offset = control.size / 2.0
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(0.88, 0.88), 0.06)
	tween.tween_property(control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
