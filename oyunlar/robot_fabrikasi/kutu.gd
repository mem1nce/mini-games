extends Node2D
# Kutu: üstünde kuralı gösteren tabela (renk lekesi, şekil silueti, renkli şekil, büyük/küçük, sayma noktaları),
# önünde dolumu gösteren lambalar. Doğru parça yayla içine zıplar, lamba yanar; yanlış parçada kutu "boing" diye
# esner ve parçayı banda geri fırlatır. Dolunca kapak kapanır; montajda kapak açılır.
# Düğümün (0, 0) noktası kutunun ağzının ortası.

signal filled

const Bolumler := preload("res://oyunlar/robot_fabrikasi/bolumler.gd")
const G := "res://oyunlar/robot_fabrikasi/gorseller/"
const WIDTH := 186.0
const SIGN_POS := Vector2(0, -118)
const SIGN_SIZE := Vector2(132, 104)
const LAMP_Y := 34.0
const COLOR_VALUES := {"kirmizi": Color("f2454f"), "mavi": Color("3e8eeb"), "sari": Color("ffd02e"), "yesil": Color("3cc66a")}

var rule: Dictionary = {}
var capacity := 3
var stored: Array[Dictionary] = []
var effects: Node2D

var _back: Sprite2D
var _front: Sprite2D
var _lid: Sprite2D
var _sign: Node2D
var _icon: Texture2D
var _lamps: Node2D
var _inside: Node2D
var _glow := 0.0
var _time := 0.0
var _closed := false


func setup(p_rule: Dictionary, p_capacity: int, p_effects: Node2D) -> void:
	rule = p_rule
	capacity = p_capacity
	effects = p_effects
	var k := WIDTH / 200.0
	_sign = Node2D.new()
	_sign.draw.connect(_draw_sign)
	_sign.position = SIGN_POS
	add_child(_sign)
	_back = _canvas_sprite("kutu_arka.svg", k)
	_inside = Node2D.new()
	add_child(_inside)
	_front = _canvas_sprite("kutu_on.svg", k)
	_lamps = Node2D.new()
	_lamps.draw.connect(_draw_lamps)
	add_child(_lamps)
	_lid = Sprite2D.new()
	_lid.texture = load(G + "kapak.svg")
	_lid.scale = Vector2.ONE * k * 200.0 / _lid.texture.get_width()
	_lid.position = Vector2(0, -8)
	_lid.visible = false
	add_child(_lid)
	_icon = _rule_icon()


# Kutu tuvali 200x170; ağız (100, 52) noktasında
func _canvas_sprite(file: String, k: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(G + file)
	sprite.scale = Vector2.ONE * k * 200.0 / sprite.texture.get_width()
	sprite.position = (Vector2(100, 85) - Vector2(100, 52)) * k
	add_child(sprite)
	return sprite


func _rule_icon() -> Texture2D:
	if rule.has("color") and rule.has("shape"):
		return load(G + "simge_%s_%s.svg" % [rule["shape"], rule["color"]])
	if rule.has("shape"):
		return load(G + "simge_%s.svg" % rule["shape"])
	if rule.has("color"):
		return load(G + "simge_renk_%s.svg" % rule["color"])
	return load(G + "simge_daire.svg")     # boyut: büyük ya da küçük daire


func is_full() -> bool:
	return stored.size() >= capacity


func accepts(part: Dictionary) -> bool:
	return not is_full() and Bolumler.matches(rule, part)


# Bırakma alanı (tabela dahil), dünya koordinatında
func drop_rect() -> Rect2:
	return Rect2(global_position + Vector2(-WIDTH * 0.62, SIGN_POS.y - SIGN_SIZE.y * 0.5), Vector2(WIDTH * 1.24, -SIGN_POS.y + SIGN_SIZE.y * 0.5 + 130.0))


# Doğru parça: yay çizerek kutunun ağzına zıplar, içine kayar; lamba yanar
func receive(part: Node2D) -> void:
	stored.append(part.data)
	var from := part.global_position
	part.reparent(_inside)
	part.global_position = from
	part.on_belt = false
	var target := Vector2(randf_range(-40, 40), 18.0)
	var mid := (part.position + target) * 0.5 + Vector2(0, -120.0)
	var start := part.position
	var tween := part.create_tween()
	tween.tween_method(func(t: float) -> void:
		part.position = start.lerp(mid, t).lerp(mid.lerp(target, t), t), 0.0, 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(part, "scale", Vector2(0.7, 0.7), 0.4)
	tween.tween_callback(func() -> void:
		_squash(Vector2(1.08, 0.9))
		effects.sparkles(global_position + Vector2(0, -10), COLOR_VALUES.get(rule.get("color", ""), Color("fff6b0")), 12, 50.0))
	tween.tween_property(part, "position:y", 70.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(part.hide)
	tween.tween_callback(func() -> void:
		_lamps.queue_redraw()
		if is_full():
			_close_lid()
			filled.emit())


# Yanlış parça: kutu esner, parça banda geri fırlar
func reject(part: Node2D, belt: Node2D) -> void:
	_squash(Vector2(0.82, 1.18))
	var from := part.global_position
	belt.return_to_belt(part, from)


func _squash(amount: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", amount, 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Doğru kutu kısaca parlar (yanlışta ve ipucunda)
func flash() -> void:
	_glow = 1.6
	var tween := create_tween()
	tween.tween_property(_sign, "scale", Vector2(1.12, 1.12), 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sign, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _close_lid() -> void:
	_closed = true
	_lid.visible = true
	_lid.position = Vector2(0, -140)
	_lid.modulate.a = 0.0
	var tween := _lid.create_tween()
	tween.tween_property(_lid, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(_lid, "position:y", -8.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func open_lid() -> void:
	if not _lid.visible:
		return
	var tween := _lid.create_tween()
	tween.tween_property(_lid, "position", _lid.position + Vector2(60, -90), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_lid, "rotation", 0.8, 0.3)
	tween.tween_property(_lid, "modulate:a", 0.0, 0.25)


# Kutu ve tabela aşağıdan belirir / aşağı iner
func appear(delay: float) -> void:
	var home := position
	position.y += 320.0
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "position", home, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func leave(delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "position:y", position.y + 340.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	if _glow > 0.0:
		_glow = maxf(0.0, _glow - delta)
		_sign.queue_redraw()


# --- Çizim ---

func _draw_sign() -> void:
	var half := SIGN_SIZE * 0.5
	# Direk
	_sign.draw_rect(Rect2(-7, half.y - 4, 14, -SIGN_POS.y - half.y - 20), Color("8a7458"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffaf0")
	style.set_corner_radius_all(24)
	style.set_border_width_all(6)
	style.border_color = Color("6e4418")
	style.shadow_color = Color(0.2, 0.1, 0.05, 0.25)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	if _glow > 0.0:
		var a := clampf(_glow, 0.0, 1.0) * (0.6 + 0.4 * sin(_time * 18.0))
		_sign.draw_circle(Vector2.ZERO, half.x + 26.0, Color(1, 0.95, 0.5, 0.35 * a))
		style.border_color = Color("6e4418").lerp(Color("ffb020"), a)
	_sign.draw_style_box(style, Rect2(-half, SIGN_SIZE))
	var counting := rule.has("count")
	var icon_box := 70.0 if not counting else 52.0
	var icon_center := Vector2(0, 0 if not counting else -16)
	if rule.has("size") and not rule.has("color") and not rule.has("shape"):
		# Büyük: tabelayı dolduran daire; küçük: soluk büyük dairenin içinde küçük daire
		if rule["size"] == "buyuk":
			_sign.draw_texture_rect(_icon, Rect2(Vector2(-41, -41), Vector2(82, 82)), false)
		else:
			_sign.draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 48, Color("cbbfa8"), 3.0, true)
			_sign.draw_texture_rect(_icon, Rect2(Vector2(-17, 6), Vector2(34, 34)), false)
		return
	_sign.draw_texture_rect(_icon, Rect2(icon_center - Vector2(icon_box, icon_box) * 0.5, Vector2(icon_box, icon_box)), false)
	if counting:
		var n: int = rule["count"]
		var color: Color = COLOR_VALUES.get(rule.get("color", ""), Color("4a4466"))
		var gap := 21.0
		for i in n:
			var p := Vector2((i - (n - 1) * 0.5) * gap, 30.0)
			_sign.draw_circle(p, 8.5, Color("3a3456"))
			_sign.draw_circle(p, 6.0, color.lightened(0.15))


func _draw_lamps() -> void:
	var n := capacity
	var gap := minf(30.0, 150.0 / n)
	for i in n:
		var p := Vector2((i - (n - 1) * 0.5) * gap, LAMP_Y + 40.0)
		var on := i < stored.size()
		if on:
			_lamps.draw_circle(p, 13.0, Color(1, 0.9, 0.4, 0.35))
		_lamps.draw_circle(p, 9.0, Color("4a2e18"))
		_lamps.draw_circle(p, 6.5, Color("ffe066") if on else Color("8a6a4a"))
		if on:
			_lamps.draw_circle(p + Vector2(-2, -2), 2.2, Color.WHITE)
