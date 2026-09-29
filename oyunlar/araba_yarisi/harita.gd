extends Control
# Pist seçme haritası (yatay): soldan sağa 4 tema bölgesi (orman, çöl, kar, gece şehri) ve noktalı
# bir yolla bağlı 8 pist düğmesi. Açılmamış pistler gri ve kilitli; sıradaki pist nabız gibi atar ve
# arabamız onun üstünde bekler. Bitirilen pistlerin altında en iyi yıldız sayısı.
# Sol üstte basılı-tut geri: garaja.

signal track_chosen(index: int)
signal back_completed

const G := "res://oyunlar/araba_yarisi/gorseller/"
const Pistler := preload("res://oyunlar/araba_yarisi/pistler.gd")
const Gorunum := preload("res://oyunlar/araba_yarisi/araba_gorunum.gd")
const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")
const INK := Color("3b2f6b")
const REGION_COLORS := [Color("d9f2cf"), Color("fde6c2"), Color("e3f0fb"), Color("cfd3f2")]
const HILL_COLORS := [Color("b4dd9a"), Color("f2cb8c"), Color("f8fbff"), Color("a3a9dc")]
const NODE_SIZE := 108.0
const THEMES := ["orman", "col", "kar", "sehir"]


# Pist düğmesi: beyaz daire, tema renginde halka ve simge; kilitliyse gri ve kilit
class TrackNode extends Control:
	var icon: Texture2D
	var lock: Texture2D
	var ring := Color.WHITE
	var locked := true
	var stars := -1          # -1: hiç bitirilmedi

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0 - 8.0
		draw_circle(c + Vector2(0, 7), r, Color(0.15, 0.1, 0.3, 0.22))
		draw_circle(c, r, Color("e4e0ee") if locked else Color.WHITE)
		draw_arc(c, r - 6.0, 0.0, TAU, 64, Color("bdb6d0") if locked else ring, 12.0, true)
		draw_arc(c, r, 0.0, TAU, 64, INK, 5.0, true)
		var tex := lock if locked else icon
		var side := r * (1.05 if locked else 1.25)
		var rect := Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side))
		if not locked and tex.get_height() > tex.get_width():
			# Uzun simgeler (lamba, ağaç) kutuya oranını koruyarak sığsın
			var k := side / tex.get_height()
			rect = Rect2(c - Vector2(tex.get_width() * k, side) * 0.5, Vector2(tex.get_width() * k, side))
		draw_texture_rect(tex, rect, false)


var sounds: Node
var _nodes: Array[TrackNode] = []
var _star_labels: Array[Control] = []
var _car: Gorunum
var _back: Control
var _back_touch := -1
var _unlocked := 1
var _choosing := false
var _time := 0.0
var _points: Array[Vector2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in Pistler.TRACKS.size():
		var theme: String = Pistler.TRACKS[i]["theme"]
		var node := TrackNode.new()
		node.icon = load(G + Pistler.THEME_ICON[theme] + ".svg")
		node.lock = load(G + "kilit.svg")
		node.ring = Pistler.THEME_COLOR[theme]
		node.size = Vector2(NODE_SIZE, NODE_SIZE)
		node.pivot_offset = node.size / 2.0
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(node)
		_nodes.append(node)
		_star_labels.append(_star_badge())
	_car = Gorunum.new()
	_car.scale = Vector2.ONE * 0.34
	add_child(_car)
	resized.connect(_layout)


func _star_badge() -> Control:
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.set_corner_radius_all(20)
	style.set_border_width_all(3)
	style.border_color = INK
	style.content_margin_left = 8
	style.content_margin_right = 12
	badge.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(row)
	var star := TextureRect.new()
	star.texture = load(G + "yildiz.svg")
	star.custom_minimum_size = Vector2(30, 30)
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(star)
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = 24
	settings.font_color = INK
	label.label_settings = settings
	label.theme_type_variation = &"Baslik"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	add_child(badge)
	return badge


# unlocked: açık pist sayısı, best: her pistin en iyi yıldızı (-1: bitirilmedi)
func show_map(unlocked: int, best: Array, color: String, driver: int) -> void:
	visible = true
	_choosing = false
	_unlocked = unlocked
	_car.set_color(color)
	_car.set_driver(driver)
	for i in _nodes.size():
		_nodes[i].locked = i >= unlocked
		_nodes[i].stars = best[i]
		_nodes[i].queue_redraw()
		var badge := _star_labels[i]
		badge.visible = best[i] >= 0
		var label: Label = badge.get_child(0).get_child(1)
		label.text = str(maxi(best[i], 0))
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
	for i in _nodes.size():
		var node := _nodes[i]
		node.scale = Vector2.ZERO
		node.create_tween().tween_property(node, "scale", Vector2.ONE, 0.45).set_delay(0.1 + i * 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var home := _car.position
	_car.position.y -= 160.0
	_car.modulate.a = 0.0
	var tween := _car.create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(_car, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(_car, "position:y", home.y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func current_index() -> int:
	return clampi(_unlocked - 1, 0, _nodes.size() - 1)


func _layout() -> void:
	var w := size.x
	var h := size.y
	var margin := 70.0
	_points.clear()
	for i in _nodes.size():
		var x := margin + (i + 0.5) * (w - 2.0 * margin) / _nodes.size()
		var y := h * 0.52 + (h * 0.14 if i % 2 == 0 else -h * 0.14) + sin(i * 2.1) * 12.0
		_points.append(Vector2(x, y))
		_nodes[i].position = _points[i] - _nodes[i].size / 2.0
		var badge := _star_labels[i]
		badge.reset_size()
		badge.position = _points[i] + Vector2(-badge.size.x * 0.5, NODE_SIZE * 0.5 + 2.0)
	var cur := _points[current_index()]
	_car.position = cur + Vector2(0, -NODE_SIZE * 0.45)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Tema bölgeleri: yan yana, sınırları yumuşak geçişli
	var band := w / 4.0
	for i in 4:
		var left: Color = REGION_COLORS[i]
		var right: Color = REGION_COLORS[mini(i + 1, 3)]
		var x0 := i * band
		var x1 := x0 + band
		var mid := x0 + band * 0.75
		draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(mid, 0), Vector2(mid, h), Vector2(x0, h)]),
				PackedColorArray([left, left, left, left]))
		draw_polygon(PackedVector2Array([Vector2(mid, 0), Vector2(x1, 0), Vector2(x1, h), Vector2(mid, h)]),
				PackedColorArray([left, right, right, left]))
	# Alt kısımda yumuşak tepeler (tema renginin koyusu) ve birkaç soluk süs
	var hills := PackedVector2Array()
	var colors := PackedColorArray()
	for k in 65:
		var x := w * k / 64.0
		var region := clampi(int(x / band), 0, 3)
		var c: Color = HILL_COLORS[region]
		hills.append(Vector2(x, h * 0.86 + sin(x * 0.012) * 14.0 + sin(x * 0.031) * 7.0))
		colors.append(c)
	hills.append(Vector2(w, h))
	colors.append(HILL_COLORS[3].darkened(0.08))
	hills.append(Vector2(0, h))
	colors.append(HILL_COLORS[0].darkened(0.08))
	draw_polygon(hills, colors)
	for i in 4:
		var icon: Texture2D = load(G + Pistler.THEME_ICON[THEMES[i]] + ".svg")
		for k in 2:
			var height := 120.0 - k * 34.0
			var k_w := height / icon.get_height() * icon.get_width()
			var x := i * band + band * (0.25 + k * 0.5)
			draw_texture_rect(icon, Rect2(x - k_w * 0.5, h * 0.87 - height + 6.0, k_w, height), false, Color(1, 1, 1, 0.85))
	# Gece bölgesinde birkaç yıldız
	for k in 9:
		var p := Vector2(3.0 * band + band * fposmod(k * 0.37, 1.0), h * (0.08 + fposmod(k * 0.53, 0.3)))
		draw_circle(p, 3.0, Color(1, 1, 1, 0.7))
	# Pistleri bağlayan noktalı yol
	if _points.size() < 2:
		return
	# Yumuşak eğri üstünde geniş, açık renkli bir şerit ve beyaz noktalar
	for i in _points.size() - 1:
		var open := i + 1 < _unlocked
		var curve := _segment(i)
		draw_polyline(curve, Color(1, 1, 1, 0.6 if open else 0.3), 30.0, true)
		var walked := 0.0
		for k in range(1, curve.size()):
			walked += curve[k].distance_to(curve[k - 1])
			if walked >= 26.0:
				walked = 0.0
				draw_circle(curve[k], 7.5, Color(INK, 0.3 if open else 0.1))
				draw_circle(curve[k], 5.5, Color("ffd84a") if open else Color(1, 1, 1, 0.7))


# İki pist arasındaki yumuşak eğri (Catmull-Rom)
func _segment(i: int) -> PackedVector2Array:
	var p0 := _points[maxi(i - 1, 0)]
	var p1 := _points[i]
	var p2 := _points[i + 1]
	var p3 := _points[mini(i + 2, _points.size() - 1)]
	var out := PackedVector2Array()
	for k in 25:
		var t := k / 24.0
		var t2 := t * t
		var t3 := t2 * t
		out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	return out


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	if _choosing:
		return
	# Sıradaki pist nabız gibi atar
	var cur := current_index()
	for i in _nodes.size():
		if i == cur and _nodes[i].scale.x > 0.95:
			_nodes[i].scale = Vector2.ONE * (1.0 + sin(_time * 4.0) * 0.05)


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
	if _choosing or SahneGecis.gecis_suruyor:
		return
	var p := touch.position
	if _back and _back.contains(p):
		_back_touch = touch.index
		_back.press()
		return
	for i in _nodes.size():
		if _nodes[i].get_global_rect().grow(10.0).has_point(p):
			_choose(i)
			return


func _choose(i: int) -> void:
	var node := _nodes[i]
	if node.locked:
		# Kilitli: hafifçe sallanır
		_sound("kilit")
		var shake := node.create_tween()
		for k in 4:
			shake.tween_property(node, "rotation", 0.12 * (1 if k % 2 == 0 else -1), 0.05)
		shake.tween_property(node, "rotation", 0.0, 0.05)
		return
	_choosing = true
	_sound("tik")
	var pop := node.create_tween()
	pop.tween_property(node, "scale", Vector2(1.18, 1.18), 0.1)
	pop.tween_property(node, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Araba seçilen pistin üstüne zıplayarak gider, sonra yarış başlar
	var target := _points[i] + Vector2(0, -NODE_SIZE * 0.45)
	var tween := _car.create_tween()
	tween.tween_property(_car, "position", target, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_car, "scale", Vector2.ONE * 0.4, 0.2)
	tween.tween_property(_car, "scale", Vector2.ONE * 0.34, 0.2)
	tween.tween_interval(0.15)
	tween.tween_callback(track_chosen.emit.bind(i))


func _sound(sound: String) -> void:
	if sounds:
		sounds.play(sound)
