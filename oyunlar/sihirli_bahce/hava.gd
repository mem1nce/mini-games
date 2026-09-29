extends Control
# Hava kontrolleri (ekranın üstünde büyük simgeler): yağmur bulutu (sürüklenir, altına yağmur yağar),
# güneş, rüzgar ve ay (dokunulur). Ne olacağına ana sahne karar verir; burası düğmeleri, bulutun
# sürüklenmesini, yağmur parçacıklarını ve ipucu nabzını yönetir. Dokunmayı ana sahne yönlendirir.

const G := "res://oyunlar/sihirli_bahce/gorseller/"
const KINDS := ["cloud", "sun", "wind", "moon"]
const ICONS := {"cloud": "yagmur_bulutu.svg", "sun": "gunes.svg", "wind": "ruzgar.svg", "moon": "ay.svg"}
const SIZE := 136.0
const GAP := 34.0
const CLOUD_Y_RANGE := Vector2(70.0, 360.0)


# Yuvarlak, yumuşak zeminli hava düğmesi; ipucu için nabız atabilir, ay gece "açık" halkası gösterir
class WeatherButton extends Control:
	var icon: Texture2D
	var active := false
	var hint := false
	var backdrop := true
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		if hint:
			var k := 1.0 + (sin(_time * 5.0) * 0.5 + 0.5) * 0.09
			scale = Vector2(k, k)
			queue_redraw()
		elif active:
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		if backdrop:
			draw_circle(c + Vector2(0, 5), r - 4.0, Color(0.15, 0.1, 0.3, 0.14))
			draw_circle(c, r - 4.0, Color(1, 1, 1, 0.55))
			draw_arc(c, r - 4.0, 0.0, TAU, 64, Color(1, 1, 1, 0.9), 4.0, true)
		if active:
			draw_arc(c, r + 2.0, 0.0, TAU, 64, Color(1, 0.9, 0.5, 0.6 + sin(_time * 3.0) * 0.25), 7.0, true)
		if hint:
			draw_arc(c, r + 4.0, 0.0, TAU, 64, Color(1, 1, 1, 0.35 + sin(_time * 5.0) * 0.3), 6.0, true)
		var side := size.x * 0.78
		var aspect := icon.get_height() / float(icon.get_width())
		var box := Vector2(side, side * aspect) if aspect <= 1.0 else Vector2(side / aspect, side)
		draw_texture_rect(icon, Rect2(c - box / 2.0, box), false)


var dragging := false
var buttons := {}
var _rain: CPUParticles2D
var _home := Vector2.ZERO
var _grab := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for kind in KINDS:
		var button := WeatherButton.new()
		button.icon = load(G + ICONS[kind])
		button.size = Vector2(SIZE, SIZE)
		button.pivot_offset = button.size / 2.0
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(button)
		buttons[kind] = button
	_rain = CPUParticles2D.new()
	_rain.texture = load(G + "damla.svg")
	_rain.amount = 40
	_rain.lifetime = 0.55
	_rain.emitting = false
	_rain.local_coords = false
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = Vector2(46, 4)
	_rain.direction = Vector2(0, 1)
	_rain.spread = 4.0
	_rain.initial_velocity_min = 560.0
	_rain.initial_velocity_max = 700.0
	_rain.gravity = Vector2(0, 500)
	_rain.scale_amount_min = 0.1
	_rain.scale_amount_max = 0.16
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.1, 0.85, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
	_rain.color_ramp = ramp
	_rain.position = Vector2(SIZE * 0.5, SIZE * 0.72)
	buttons["cloud"].add_child(_rain)
	buttons["cloud"].move_child(_rain, 0)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var total := SIZE * KINDS.size() + GAP * (KINDS.size() - 1)
	var x := size.x * 0.5 - total * 0.5
	for kind in KINDS:
		var button: Control = buttons[kind]
		if not (kind == "cloud" and dragging):
			button.position = Vector2(x, 18)
		x += SIZE + GAP
	_home = buttons["cloud"].position


func hit(point: Vector2) -> String:
	for kind in KINDS:
		var button: Control = buttons[kind]
		if button.get_global_rect().grow(6.0).has_point(point):
			return kind
	return ""


func center(kind: String) -> Vector2:
	var button: Control = buttons[kind]
	return button.global_position + button.size * 0.5


# Dokunulan düğme zıplar; güneş ayrıca bir an büyüyüp parlar
func press(kind: String) -> void:
	var button: Control = buttons[kind]
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.86, 0.86), 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(button, "scale", Vector2(1.12, 1.12) if kind == "sun" else Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if kind == "sun":
		tween.tween_property(button, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
		var spin := button.create_tween()
		spin.tween_property(button, "rotation", TAU / 12.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		spin.tween_callback(func() -> void: button.rotation = 0.0)


func set_night(value: bool) -> void:
	buttons["moon"].active = value
	buttons["moon"].queue_redraw()


func set_hint(kind: String, value: bool) -> void:
	var button = buttons[kind]
	if button.hint == value:
		return
	button.hint = value
	if not value and not (kind == "cloud" and dragging):
		button.scale = Vector2.ONE
	button.queue_redraw()


# --- Bulut sürükleme ---

func begin_drag(point: Vector2) -> void:
	var cloud: Control = buttons["cloud"]
	dragging = true
	set_hint("cloud", false)
	_grab = point - cloud.global_position
	cloud.backdrop = false
	cloud.queue_redraw()
	cloud.create_tween().tween_property(cloud, "scale", Vector2(1.18, 1.18), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_rain.emitting = true
	drag(point)


func drag(point: Vector2) -> void:
	var cloud: Control = buttons["cloud"]
	var pos := point - _grab
	pos.x = clampf(pos.x, -SIZE * 0.2, size.x - SIZE * 0.8)
	pos.y = clampf(pos.y, CLOUD_Y_RANGE.x - SIZE * 0.5, CLOUD_Y_RANGE.y - SIZE * 0.5)
	cloud.position = pos


func end_drag() -> void:
	var cloud: Control = buttons["cloud"]
	dragging = false
	_rain.emitting = false
	cloud.backdrop = true
	var tween := cloud.create_tween().set_parallel()
	tween.tween_property(cloud, "position", _home, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cloud, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(cloud.queue_redraw)


# Yağmurun düştüğü x (bulut sürüklenirken)
func rain_x() -> float:
	return center("cloud").x
