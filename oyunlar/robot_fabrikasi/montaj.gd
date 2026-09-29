extends Node2D
# Bölüm sonu robot montajı: kutular açılır, robotun parçaları kutulardan sırayla havaya uçup ekranın
# ortasında birleşir (her biri yerine "çıt" diye oturur). Robot canlanır: gözleri yanar, göğüs ışıkları
# yanıp söner, dans eder, el sallar; konfeti ve "Harika!" / "Süper!" / "Tebrikler!". Sonra galeri simgesine uçar.

signal finished

const Robot := preload("res://oyunlar/robot_fabrikasi/robot.gd")
const WORDS := ["Harika!", "Süper!", "Tebrikler!"]
const WORD_COLORS := [Color("ff5a6e"), Color("ff9f40"), Color("ffc93d"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var effects: Node2D
var sounds: Node
var running := false

var _dim: ColorRect


func _ready() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.2, 0.1, 0.25, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.size = get_viewport_rect().size
	add_child(_dim)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func run(robot_id: String, look: Dictionary, boxes: Array, gallery_pos: Vector2) -> void:
	running = true
	var size := get_viewport_rect().size
	create_tween().tween_property(_dim, "color:a", 0.5, 0.4)
	for box in boxes:
		box.open_lid()
	await _wait(0.4)
	var robot := Robot.new()
	add_child(robot)
	robot.build(robot_id, look)
	robot.position = Vector2(size.x * 0.5, 500.0)
	robot.hide_parts()
	# Parçalar sırayla kutulardan uçup yerine oturur
	for i in robot.slots.size():
		var slot: Node2D = robot.slots[i]
		var sprite := Robot.slot_sprite(slot)
		if sprite == null:
			robot.show_slot(slot)
			continue
		var box: Node2D = boxes[i % boxes.size()]
		_fly(sprite, slot, robot, box.global_position + Vector2(0, -10))
		await _wait(0.16)
	await _wait(0.6)
	robot.wake()
	_sound("uyan")
	effects.sparkles(robot.global_position + Vector2(0, -160), Color("8ef0ff"), 16, 80.0)
	await _wait(0.8)
	robot.dance()
	_sound("dans")
	_cheer(size)
	effects.confetti(Vector2(size.x * 0.5, size.y + 20.0), size.x * 0.8)
	await _wait(2.2)
	robot.wave()
	await _wait(1.2)
	_sound("ucus")
	var tween := robot.create_tween()
	tween.tween_property(robot, "global_position", gallery_pos + Vector2(0, 30), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(robot, "scale", robot.scale * 0.15, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_dim, "color:a", 0.0, 0.8)
	await tween.finished
	robot.queue_free()
	running = false
	finished.emit()


# Parçanın kopyası kutudan yay çizerek robottaki yerine uçar; varınca asıl parça görünür
func _fly(sprite: Sprite2D, slot: Node2D, robot: Node2D, from: Vector2) -> void:
	var copy := Sprite2D.new()
	copy.texture = sprite.texture
	copy.centered = sprite.centered
	copy.offset = sprite.offset
	copy.flip_h = sprite.flip_h
	add_child(copy)
	var target := sprite.global_transform
	copy.global_position = from
	copy.global_scale = target.get_scale() * 0.6
	var mid := (from + target.origin) * 0.5 + Vector2(randf_range(-80, 80), -220.0)
	var tween := copy.create_tween()
	tween.tween_method(func(t: float) -> void:
		copy.global_position = from.lerp(mid, t).lerp(mid.lerp(target.origin, t), t)
		copy.global_rotation = lerpf(TAU * 0.5, target.get_rotation(), t)
		copy.global_scale = target.get_scale() * lerpf(0.6, 1.0, t), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		robot.show_slot(slot)
		effects.sparkles(target.origin, Color("fff6b0"), 6, 20.0)
		_sound("montaj")
		copy.queue_free())


# Ortada büyük, zıplayan tek kelime: harfler farklı renklerde
func _cheer(size: Vector2) -> void:
	var word: String = WORDS.pick_random()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)
	row.size = Vector2(size.x, 120)
	row.position = Vector2(0, 110)
	add_child(row)
	for i in word.length():
		var letter := Label.new()
		letter.text = word[i]
		var settings := LabelSettings.new()
		settings.font_size = 92
		settings.font_color = WORD_COLORS[i % WORD_COLORS.size()]
		settings.outline_size = 18
		settings.outline_color = Color.WHITE
		settings.shadow_size = 6
		settings.shadow_color = Color(0.3, 0.15, 0.3, 0.35)
		settings.shadow_offset = Vector2(0, 5)
		letter.label_settings = settings
		letter.theme_type_variation = &"Baslik"
		row.add_child(letter)
	row.pivot_offset = row.size * 0.5
	row.scale = Vector2.ZERO
	var tween := row.create_tween()
	tween.tween_property(row, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.6)
	tween.tween_property(row, "modulate:a", 0.0, 0.4)
	tween.tween_callback(row.queue_free)
	# Harfler sırayla zıplar
	await get_tree().process_frame
	for i in row.get_child_count():
		var letter: Label = row.get_child(i)
		var y := letter.position.y
		var hop := letter.create_tween()
		hop.tween_interval(0.35 + i * 0.06)
		hop.tween_property(letter, "position:y", y - 26.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		hop.tween_property(letter, "position:y", y, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _sound(sound: String) -> void:
	if sounds:
		sounds.play(sound)
