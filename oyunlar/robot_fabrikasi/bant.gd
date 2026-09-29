extends Node2D
# Taşıma bandı: soldan sağa akar. Bant gövdesi ve kayan çizgiler kodla çizilir, uçlarda makara dişlileri
# döner. Parçalar soldaki borudan düşer, bantla ilerler; sağ uca varan parça boruya girer ve bir süre sonra
# (kutusu hâlâ doluysa değil) soldaki borudan yeniden düşer. Parçaların sırası ve üretimi bölüm yöneticisindedir.

signal part_recycled(part: Node2D)       # boruya giren parça yeniden gelmek için sıraya girdi
signal need_part                          # bantta yer var: yeni parça istenir

const G := "res://oyunlar/robot_fabrikasi/gorseller/"
const HEIGHT := 50.0                     # bant gövdesinin kalınlığı
const STRIPE_GAP := 46.0
const MIN_GAP := 170.0                   # iki parça arası en az mesafe
const MAX_PARTS := 5
const RECYCLE_TIME := 2.4

var surface_y := 262.0
var left_x := 150.0
var right_x := 1130.0
var speed := 55.0
var running := true
var parts: Array[Node2D] = []

var _offset := 0.0
var _rollers: Array[Sprite2D] = []
var _queue: Array = []                   # boruda bekleyen parçalar: [parça, kalan süre]
var _parts_root: Node2D


func setup(width: float, y: float) -> void:
	surface_y = y
	left_x = 190.0
	right_x = width - 150.0
	_parts_root = Node2D.new()
	for x in [left_x, right_x]:
		var roller := Sprite2D.new()
		roller.texture = load(G + "makara.svg")
		roller.scale = Vector2.ONE * 64.0 / roller.texture.get_width()
		roller.position = Vector2(x, surface_y + HEIGHT * 0.5)
		add_child(roller)
		_rollers.append(roller)
	add_child(_parts_root)
	var entry := Sprite2D.new()
	entry.texture = load(G + "boru_agiz.svg")
	entry.scale = Vector2.ONE * 130.0 / entry.texture.get_width()
	entry.position = Vector2(left_x + 10.0, surface_y - 150.0)
	add_child(entry)
	var exit := Sprite2D.new()
	exit.texture = load(G + "boru_agiz.svg")
	exit.scale = Vector2.ONE * 130.0 / exit.texture.get_width()
	exit.rotation = -PI / 2.0
	exit.position = Vector2(right_x + 118.0, surface_y - 44.0)
	add_child(exit)
	queue_redraw()


func entry_point() -> Vector2:
	return Vector2(left_x + 10.0, surface_y - 90.0)


# Bandın başındaki borudan bir parça düşer
func drop_in(part: Node2D) -> void:
	if part.get_parent() != _parts_root:
		if part.get_parent():
			part.reparent(_parts_root)
		else:
			_parts_root.add_child(part)
	part.on_belt = false
	part.visible = true
	part.modulate.a = 1.0
	part.scale = Vector2(0.5, 0.5)
	var start := entry_point()
	part.position = start
	var land := Vector2(start.x + 30.0, surface_y - part.half_height())
	var tween := part.create_tween()
	tween.tween_property(part, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(part, "position", land, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if not part.held:
			part.on_belt = true)
	if not parts.has(part):
		parts.append(part)


# Parça banda geri döner (yanlış kutu ya da boşa bırakma): x'te en yakın boş yere yay çizerek iner
func return_to_belt(part: Node2D, from: Vector2) -> void:
	part.reparent(_parts_root)
	part.global_position = from
	part.on_belt = false
	var x := clampf(from.x, left_x + 60.0, right_x - 60.0)
	var target := Vector2(x, surface_y - part.half_height())
	var mid := (from + target) * 0.5 + Vector2(0, -160.0)
	var tween := part.create_tween()
	tween.tween_method(func(t: float) -> void:
		part.position = from.lerp(mid, t).lerp(mid.lerp(target, t), t)
		part.rotation = t * TAU, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		part.rotation = 0.0
		part.on_belt = true)
	if not parts.has(part):
		parts.append(part)


func take(part: Node2D) -> void:
	parts.erase(part)


func has_room() -> bool:
	if parts.size() + _queue.size() >= MAX_PARTS:
		return false
	return has_room_at_entry()


func clear() -> void:
	for part in parts:
		part.queue_free()
	for item in _queue:
		item[0].queue_free()
	parts.clear()
	_queue.clear()


func _process(delta: float) -> void:
	var moving := running
	if moving:
		_offset = fposmod(_offset + speed * delta, STRIPE_GAP)
		for roller in _rollers:
			roller.rotation += speed * delta / 32.0
		queue_redraw()
	for part in parts.duplicate():
		if not part.on_belt or part.held:
			continue
		if moving:
			part.position.x += speed * delta
		part.position.y = surface_y - part.half_height()
		if part.position.x > right_x + 30.0:
			_into_pipe(part)
	for item in _queue.duplicate():
		item[1] -= delta
		if item[1] <= 0.0 and has_room_at_entry():
			_queue.erase(item)
			if is_instance_valid(item[0]):
				part_recycled.emit(item[0])
	if moving and has_room():
		need_part.emit()


func has_room_at_entry() -> bool:
	# Borudan düşmekte olan (henüz banda oturmamış) parçalar da girişi kapatır
	for part in parts:
		if part.position.x < left_x + MIN_GAP:
			return false
	return true


func _into_pipe(part: Node2D) -> void:
	parts.erase(part)
	part.on_belt = false
	var tween := part.create_tween()
	tween.tween_property(part, "position", Vector2(right_x + 110.0, surface_y - 40.0), 0.3).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(part, "scale", Vector2(0.4, 0.4), 0.3)
	tween.tween_callback(func() -> void: part.visible = false)
	_queue.append([part, RECYCLE_TIME])


func _draw() -> void:
	var rect := Rect2(left_x - 34.0, surface_y, right_x - left_x + 68.0, HEIGHT)
	var body := StyleBoxFlat.new()
	body.bg_color = Color("4a4466")
	body.set_corner_radius_all(int(HEIGHT * 0.5))
	body.set_border_width_all(5)
	body.border_color = Color("2a2440")
	body.shadow_color = Color(0.2, 0.1, 0.1, 0.25)
	body.shadow_size = 10
	body.shadow_offset = Vector2(0, 8)
	draw_style_box(body, rect)
	# Üst yüzey ve kayan çizgiler
	var top := Rect2(left_x, surface_y + 5.0, right_x - left_x, 14.0)
	draw_rect(top, Color("6a6488"))
	var x := left_x + _offset
	while x < right_x:
		draw_line(Vector2(x, surface_y + 6.0), Vector2(x - 10.0, surface_y + 18.0), Color("8e88aa"), 4.0, true)
		x += STRIPE_GAP
	draw_line(Vector2(left_x, surface_y + 4.0), Vector2(right_x, surface_y + 4.0), Color(1, 1, 1, 0.35), 3.0, true)
	# Alt taraftaki geri dönen kayış
	var y := surface_y + HEIGHT - 14.0
	x = right_x - _offset
	while x > left_x:
		draw_circle(Vector2(x, y), 3.5, Color("2a2440"))
		x -= STRIPE_GAP
	# Ayaklar
	for fx in [left_x + 60.0, (left_x + right_x) * 0.5, right_x - 60.0]:
		draw_rect(Rect2(fx - 9.0, surface_y + HEIGHT - 4.0, 18.0, 60.0), Color("6a6488"))
		draw_rect(Rect2(fx - 22.0, surface_y + HEIGHT + 52.0, 44.0, 10.0), Color("4a4466"))
