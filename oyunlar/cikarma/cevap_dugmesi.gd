extends Node2D
# AnswerButton: alttaki büyük sayı düğmesi. Dokunmayı oyun sahnesi yönetir (contains ile sorar).
# Yanlışta sallanıp küçülerek kaybolur (reject), doğruda sonuç kartının üstüne uçar (fly_to).

const TEXTURE: Texture2D = preload("res://oyunlar/cikarma/gorseller/dugme.svg")
const FONT: FontVariation = preload("res://oyunlar/cikarma/rakam_yazisi.tres")
const OUTLINE := Color("4a3b6b")

var value: int = 0
var size := Vector2(170, 150)
var active: bool = false     # dokunulabilir mi (görünür ve kaybolmuyor)


func setup(number: int, color: Color, button_size: Vector2) -> void:
	value = number
	size = button_size
	var bg := Sprite2D.new()
	bg.texture = TEXTURE
	bg.scale = size / Vector2(TEXTURE.get_size())
	bg.self_modulate = color
	add_child(bg)
	var label := Label.new()
	label.text = str(number)
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 108 if number < 10 else 92)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 20)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Yazı düğmenin üst yüzünde (alttaki kabartmanın üstünde) ortalı
	label.position = -size / 2.0 + Vector2(0.0, -6.0)
	label.size = size - Vector2(0.0, size.y * 0.14)
	add_child(label)


func contains(point: Vector2) -> bool:
	return active and Rect2(global_position - size * global_scale / 2.0, size * global_scale).grow(14.0).has_point(point)


func appear(delay: float) -> void:
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: active = true)


# Yanlış: hafifçe sallanır, sonra küçülerek kaybolur
func reject() -> void:
	active = false
	var tween := create_tween()
	for angle in [0.14, -0.12, 0.09, -0.06, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.28)
	tween.tween_callback(queue_free)


# Doğru: yukarı doğru kavis çizerek hedefe uçar ve küçülür. Tween döner (bitişi beklenebilir).
func fly_to(target: Vector2, target_scale: float, time: float) -> Tween:
	active = false
	z_index = 10
	var start := global_position
	var control := (start + target) / 2.0 + Vector2(0.0, -minf(260.0, start.distance_to(target) * 0.5))
	var tween := create_tween().set_parallel()
	tween.tween_method(_move_on_curve.bind(start, control, target), 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * target_scale, time).set_trans(Tween.TRANS_SINE)
	return tween


func _move_on_curve(t: float, start: Vector2, control: Vector2, target: Vector2) -> void:
	global_position = start.lerp(control, t).lerp(control.lerp(target, t), t)


# Doğru cevap seçilince diğer düğmeler sessizce kaybolur
func fade_out(delay: float) -> void:
	active = false
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE * 0.6, 0.25).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
