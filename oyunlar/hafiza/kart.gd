extends Node2D
# Tek bir hafıza kartı: gölge, parıltı, arka yüz ve ön yüz (çerçeve + resim).
# Bütün animasyonlar Tween ile; kart kendi merkezinden döner ve büyür.

const FLIP_TIME := 0.36

var item_id: String = ""
var is_open: bool = false
var is_matched: bool = false
var card_size := Vector2(200, 240)

var _body: Node2D        # çevrilen kısım (arka ve ön yüz)
var _back: Sprite2D
var _front: Node2D
var _shadow: Sprite2D
var _glow: Sprite2D
var _shadow_scale := Vector2.ONE
var _glow_scale := Vector2.ONE
var _tween: Tween


func setup(id: String, size: Vector2, front_tex: Texture2D, picture_tex: Texture2D,
		back_tex: Texture2D, shadow_tex: Texture2D, glow_tex: Texture2D) -> void:
	item_id = id
	card_size = size

	_glow = _make_sprite(glow_tex, size * 1.7)
	_glow_scale = _glow.scale
	_glow.modulate.a = 0.0
	add_child(_glow)

	_shadow = _make_sprite(shadow_tex, size * 1.02)
	_shadow.position = Vector2(0, size.y * 0.035)
	_shadow_scale = _shadow.scale
	add_child(_shadow)

	_body = Node2D.new()
	add_child(_body)
	_back = _make_sprite(back_tex, size)
	_body.add_child(_back)

	_front = Node2D.new()
	_front.visible = false
	_body.add_child(_front)
	_front.add_child(_make_sprite(front_tex, size))
	var picture := _make_sprite(picture_tex, Vector2.ONE * size.x * 0.8)
	picture.position.y = -size.y * 0.02
	_front.add_child(picture)


func _make_sprite(texture: Texture2D, target_size: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = target_size / texture.get_size()
	return sprite


func contains(point: Vector2) -> bool:
	return Rect2(global_position - card_size / 2.0, card_size).has_point(point)


func _new_tween() -> Tween:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween


# Masaya dağıtılma: ekranın altından dönerek gelip yerine oturur
func deal(from: Vector2, delay: float) -> void:
	var target := position
	position = from
	rotation = randf_range(-0.6, 0.6)
	scale = Vector2(0.6, 0.6)
	modulate.a = 0.0
	var tween := _new_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, 0.15).set_delay(delay)
	tween.tween_property(self, "position", target, 0.55).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0.0, 0.55).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Dokununca: hafifçe basılır, sonra açılır
func tap_open() -> void:
	var tween := _new_tween()
	tween.tween_property(_body, "scale", Vector2(0.92, 0.92), 0.06).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(flip.bind(true))


# 3B dönme hissi: kart yana doğru daralır (kenarından görünür gibi), yüz değişir, genişleyerek açılır.
# Bu sırada kart hafifçe kalkar ve büyür, gölgesi de onunla birlikte daralır.
func flip(open: bool) -> void:
	is_open = open
	var half := FLIP_TIME / 2.0
	var tween := _new_tween().set_parallel()
	tween.tween_property(_body, "scale", Vector2(0.0, 1.1), half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_body, "position:y", -card_size.y * 0.06, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "modulate", Color(0.82, 0.82, 0.9), half)
	tween.tween_property(_shadow, "scale", _shadow_scale * Vector2(0.0, 1.0), half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_show_face.bind(open))
	tween.tween_property(_body, "scale", Vector2.ONE, half * 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position:y", 0.0, half * 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "modulate", Color.WHITE, half)
	tween.tween_property(_shadow, "scale", _shadow_scale, half * 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_face(open: bool) -> void:
	_front.visible = open
	_back.visible = not open


# Eşleşme: zıplar, parlar
func celebrate() -> void:
	is_matched = true
	var tween := _new_tween()
	tween.tween_property(_body, "scale", Vector2(1.18, 1.18), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_body, "position:y", -card_size.y * 0.1, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_body, "modulate", Color(1.35, 1.3, 1.15), 0.16)
	tween.tween_property(_body, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_body, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_body, "modulate", Color.WHITE, 0.5)

	_glow.scale = _glow_scale * 0.6
	var glow := create_tween().set_parallel()
	glow.tween_property(_glow, "modulate:a", 0.95, 0.2)
	glow.tween_property(_glow, "scale", _glow_scale, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	glow.chain().tween_property(_glow, "modulate:a", 0.0, 0.6)


# Eşleşmedi: ceza hissi vermeden hafifçe sallanır, sonra kapanır
func shake_and_close() -> void:
	var tween := _new_tween()
	for angle in [0.07, -0.07, 0.05, -0.03, 0.0]:
		tween.tween_property(_body, "rotation", angle, 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(flip.bind(false))


# Bölüm sonunda kartlar dalga gibi zıplar
func hop(delay: float) -> void:
	var tween := _new_tween()
	tween.tween_interval(delay)
	tween.tween_property(_body, "position:y", -card_size.y * 0.12, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
