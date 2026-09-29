extends Node2D
# Yardımcı robot (ekranın sol kenarında): ekranında yüzü var, antenindeki ampul yanıp söner.
# - cheer(): doğru hamlede başparmak kaldırır, mutlu gözler, ampul parlar, küçük zıplama
# - shake_head(): yanlışta başını sallar (şaşkın gözler)
# - point_at(pos): kolunu bir yere uzatır (doğru kutu, ipucundaki parça)
# - wave(): bölüm başında el sallar
# Düğümün (0, 0) noktası tekerleğin yere değdiği yer.

const G := "res://oyunlar/robot_fabrikasi/gorseller/"
const WIDTH := 160.0
const SCREEN_CENTER := Vector2(100, 70)      # 200x240 tuvalde ekranın ortası
const CANVAS := Vector2(200, 240)
const SHOULDERS := [Vector2(64, 140), Vector2(136, 140)]   # karnın iki yanı

var effects: Node2D
var _k := 0.8
var _root: Node2D
var _body: Sprite2D
var _arms: Array[Node2D] = []
var _thumb: Sprite2D
var _hand: Sprite2D
var _face: Node2D
var _bulb: Sprite2D
var _mood := "normal"                 # normal, mutlu, saskin
var _blink := 0.0
var _time := 0.0
var _busy := 0.0


func setup(p_effects: Node2D) -> void:
	effects = p_effects
	_k = WIDTH / CANVAS.x
	_root = Node2D.new()
	add_child(_root)
	# Kollar gövdenin arkasında, omuzdan sarkar
	for i in 2:
		var arm := Node2D.new()
		arm.position = _canvas(SHOULDERS[i])
		arm.rotation = 0.25 if i == 0 else -0.25
		_root.add_child(arm)
		var hand := Sprite2D.new()
		hand.texture = load(G + "yardimci_kol.svg")
		hand.centered = false
		hand.scale = Vector2.ONE * 60.0 * _k / hand.texture.get_width()
		hand.offset = -Vector2(30, 10) * hand.texture.get_width() / 60.0
		arm.add_child(hand)
		arm.set_meta("rest", arm.rotation)
		_arms.append(arm)
		if i == 1:
			_hand = hand
			_thumb = Sprite2D.new()
			_thumb.texture = load(G + "yardimci_basparmak.svg")
			_thumb.centered = false
			_thumb.scale = hand.scale
			_thumb.offset = hand.offset
			_thumb.visible = false
			arm.add_child(_thumb)
	_body = Sprite2D.new()
	_body.texture = load(G + "yardimci.svg")
	_body.scale = Vector2.ONE * WIDTH / _body.texture.get_width()
	_body.position = _canvas(CANVAS * 0.5)
	_root.add_child(_body)
	_face = Node2D.new()
	_face.position = _canvas(SCREEN_CENTER)
	_face.draw.connect(_draw_face)
	_root.add_child(_face)
	_bulb = effects.glow_sprite(Color(1, 0.8, 0.4, 0.8), 40.0)
	_bulb.position = _canvas(Vector2(100, 6))
	_root.add_child(_bulb)


# Tuval noktası → yerel nokta (tuvalin alt ortası (100, 236) yere değer)
func _canvas(p: Vector2) -> Vector2:
	return (p - Vector2(100, 236)) * _k


func contains(point: Vector2) -> bool:
	return Rect2(global_position + Vector2(-WIDTH * 0.5, -CANVAS.y * _k), Vector2(WIDTH, CANVAS.y * _k)).has_point(point)


func cheer() -> void:
	_set_mood("mutlu", 1.2)
	_hand.visible = false
	_thumb.visible = true
	var arm := _arms[1]
	var tween := create_tween()
	tween.tween_property(arm, "rotation", -2.7, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.7)
	tween.tween_property(arm, "rotation", arm.get_meta("rest"), 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		_hand.visible = true
		_thumb.visible = false)
	_hop()
	_bulb_flash()


func shake_head() -> void:
	_set_mood("saskin", 1.0)
	var tween := create_tween()
	for k in 2:
		tween.tween_property(_root, "rotation", 0.12, 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_root, "rotation", -0.12, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_root, "rotation", 0.0, 0.12)


# Sağ kolu bir noktaya uzatır (bir süre tutar, sonra indirir)
func point_at(target: Vector2, hold: float = 1.2) -> void:
	var arm := _arms[1]
	var dir := target - arm.global_position
	var angle := dir.angle() - PI / 2.0         # kol aşağı sarkarken açı 0
	var tween := create_tween()
	tween.tween_property(arm, "rotation", angle, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(arm, "rotation", angle + 0.12, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(arm, "rotation", angle, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(hold)
	tween.tween_property(arm, "rotation", arm.get_meta("rest"), 0.35).set_trans(Tween.TRANS_SINE)


func wave() -> void:
	_set_mood("mutlu", 1.5)
	var arm := _arms[1]
	var tween := create_tween()
	tween.tween_property(arm, "rotation", -2.6, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for k in 3:
		tween.tween_property(arm, "rotation", -2.2, 0.14).set_trans(Tween.TRANS_SINE)
		tween.tween_property(arm, "rotation", -2.8, 0.14).set_trans(Tween.TRANS_SINE)
	tween.tween_property(arm, "rotation", arm.get_meta("rest"), 0.3).set_trans(Tween.TRANS_SINE)


# Dokununca: kıkırdar gibi zıplar
func giggle() -> void:
	_set_mood("mutlu", 1.0)
	_hop()
	effects.hearts(global_position + Vector2(0, -CANVAS.y * _k), 2)


func _hop() -> void:
	var tween := create_tween()
	tween.tween_property(_root, "position:y", -22.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_root, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _bulb_flash() -> void:
	var tween := _bulb.create_tween()
	tween.tween_property(_bulb, "scale", _bulb.scale * 1.8, 0.15)
	tween.tween_property(_bulb, "scale", _bulb.scale, 0.4).set_trans(Tween.TRANS_SINE)


func _set_mood(mood: String, time: float) -> void:
	_mood = mood
	_busy = time
	_face.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _busy > 0.0:
		_busy -= delta
		if _busy <= 0.0:
			_mood = "normal"
			_face.queue_redraw()
	# Ara sıra göz kırpar; hafifçe nefes alır; ampul yavaşça yanıp söner
	_blink -= delta
	if _blink <= -0.12:
		_blink = randf_range(2.0, 4.5)
		_face.queue_redraw()
	elif _blink <= 0.0:
		_face.queue_redraw()
	_body.scale.y = _body.scale.x * (1.0 + sin(_time * 2.0) * 0.012)
	_bulb.modulate.a = 0.45 + 0.35 * (sin(_time * 3.0) * 0.5 + 0.5)


func _draw_face() -> void:
	var s := _k
	var eye := Color("8ef0ff")
	var closed := _blink <= 0.0 and _mood == "normal"
	for side in [-1, 1]:
		var p := Vector2(side * 20.0, -4.0) * s
		if _mood == "mutlu":
			_face.draw_arc(p + Vector2(0, 4) * s, 9.0 * s, PI * 1.1, PI * 1.9, 12, eye, 5.0 * s, true)
		elif _mood == "saskin":
			_face.draw_arc(p, 9.0 * s, 0.0, TAU, 16, eye, 4.0 * s, true)
			_face.draw_circle(p, 3.0 * s, eye)
		elif closed:
			_face.draw_line(p + Vector2(-8, 0) * s, p + Vector2(8, 0) * s, eye, 4.0 * s, true)
		else:
			_face.draw_circle(p, 9.0 * s, Color(eye, 0.25))
			_face.draw_circle(p, 6.5 * s, eye)
			_face.draw_circle(p + Vector2(-2, -2) * s, 2.2 * s, Color.WHITE)
	if _mood == "saskin":
		_face.draw_circle(Vector2(0, 16) * s, 4.0 * s, eye)
	else:
		_face.draw_arc(Vector2(0, 10) * s, 9.0 * s, PI * 0.15, PI * 0.85, 12, eye, 4.0 * s, true)
