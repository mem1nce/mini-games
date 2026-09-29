extends Node2D
# SoundPad: enstrümanın dokunulabilir bir parçası (ksilofon tuşu, davul, hayvan). Düğümün konumu parçanın
# merkezidir; görsel `_art` altında durur, böylece canlandırmalar (çökme, titreme, zıplama) konumu bozmaz.
# Dokunma alanı görselden biraz büyük tutulur (küçük parmaklar için). Sesi enstrüman çalar; burası sadece
# görünüş: hit() dokununca, set_target() şarkı modunda yanıp sönme, invite() uzun süre dokunulmayınca davet.

enum Style { PRESS, WOBBLE, SING }

const TEX_GLOW: Texture2D = preload("res://oyunlar/muzik_kutusu/gorseller/isik.svg")

var sound: String = ""
var color: Color = Color.WHITE
var style: Style = Style.PRESS
## Dokunma alanı (enstrümanın tasarım birimiyle), merkezi hit_offset kadar kayık
var hit_size: Vector2 = Vector2(120, 120)
var hit_offset: Vector2 = Vector2.ZERO
var hit_ellipse: bool = false
## SING: ağzı açık görsel (ses süresince gösterilir)
var open_texture: Texture2D

var _art: Node2D
var _sprite: Sprite2D
var _glow: Sprite2D
var _closed_texture: Texture2D
var _tween: Tween
var _glow_tween: Tween
var _targeted: bool = false
var _sing_left: float = 0.0
var _time: float = 0.0


## width: görselin genişliği; touch_size / touch_offset: dokunma alanının boyu ve merkezinin kayması
func setup(texture: Texture2D, width: float, touch_size: Vector2, ellipse: bool = false, touch_offset: Vector2 = Vector2.ZERO) -> void:
	hit_size = touch_size
	hit_ellipse = ellipse
	hit_offset = touch_offset
	_closed_texture = texture
	_glow = Sprite2D.new()
	_glow.texture = TEX_GLOW
	_glow.modulate = Color(color, 0.0)
	add_child(_glow)
	_art = Node2D.new()
	add_child(_art)
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.scale = Vector2.ONE * width / texture.get_width()
	_art.add_child(_sprite)
	_fit_glow()


## Görseli dokunma alanının neresinde duruyorsa oraya kaydırır (ör. zilin sehpası alanın dışında kalır)
func set_art_offset(offset: Vector2) -> void:
	_sprite.position = offset


func _fit_glow() -> void:
	_glow.position = hit_offset
	_glow.scale = hit_size * Vector2(1.6, 1.2) / TEX_GLOW.get_width()


func contains(global_point: Vector2) -> bool:
	if not is_visible_in_tree():
		return false
	var p := to_local(global_point) - hit_offset
	var half := hit_size / 2.0
	if hit_ellipse:
		return (p.x * p.x) / (half.x * half.x) + (p.y * p.y) / (half.y * half.y) <= 1.0
	return absf(p.x) <= half.x and absf(p.y) <= half.y


func touch_center() -> Vector2:
	return to_global(hit_offset)


# --- Dokunma canlandırmaları ---

func hit(seconds: float = 0.0) -> void:
	if _tween:
		_tween.kill()
	_art.position = Vector2.ZERO
	_art.rotation = 0.0
	_tween = create_tween()
	match style:
		Style.PRESS:
			# Tuş hafifçe çöker ve esneyerek geri gelir
			_art.scale = Vector2(0.96, 0.95)
			_art.position = Vector2(0, 7)
			_tween.set_parallel()
			_tween.tween_property(_art, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			_tween.tween_property(_art, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Style.WOBBLE:
			# Davul: basılıp genişler, titreyerek eski haline döner
			_art.scale = Vector2(1.1, 0.9)
			_tween.set_parallel()
			_tween.tween_property(_art, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			_tween.tween_method(_shake, 1.0, 0.0, 0.45)
		Style.SING:
			# Hayvan: ağzını açar, zıplar ve ses süresince neşeyle sallanır
			_sing_left = maxf(_sing_left, seconds)
			if open_texture:
				_sprite.texture = open_texture
			_art.scale = Vector2(1.08, 0.9)
			_tween.tween_property(_art, "scale", Vector2(0.94, 1.08), 0.1).set_trans(Tween.TRANS_SINE)
			_tween.parallel().tween_property(_art, "position:y", -34.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_tween.tween_property(_art, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			_tween.parallel().tween_property(_art, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Kısa bir ışık parlaması (şarkı hedefiyse yanıp sönme sürer)
	if not _targeted:
		_flash(0.55, 0.35)


func _shake(amount: float) -> void:
	_art.rotation = sin(amount * 38.0) * 0.07 * amount


func _process(delta: float) -> void:
	_time += delta
	if _sing_left > 0.0:
		_sing_left -= delta
		_art.rotation = sin(_time * 16.0) * 0.09
		if _sing_left <= 0.0:
			_art.rotation = 0.0
			_sprite.texture = _closed_texture


func is_singing() -> bool:
	return _sing_left > 0.0


# --- Işık: şarkı hedefi ve davet ---

func _flash(strength: float, seconds: float) -> void:
	if _glow_tween:
		_glow_tween.kill()
	_glow.modulate = Color(color.lightened(0.35), strength)
	_glow_tween = create_tween()
	_glow_tween.tween_property(_glow, "modulate:a", 0.0, seconds)


## Şarkı modunda sıradaki tuş: kendi renginde bir hale ve parlaklık nabzıyla yanıp söner
func set_target(on: bool) -> void:
	if on == _targeted:
		return
	_targeted = on
	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween()
	if not on:
		_glow_tween.set_parallel()
		_glow_tween.tween_property(_glow, "modulate:a", 0.0, 0.15)
		_glow_tween.tween_property(_art, "modulate", Color.WHITE, 0.15)
		return
	_glow.modulate = Color(color, 0.0)
	_glow_tween.set_loops()
	_glow_tween.tween_property(_glow, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	_glow_tween.parallel().tween_property(_art, "modulate", Color(1.3, 1.3, 1.3), 0.3).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_glow, "modulate:a", 0.35, 0.34).set_trans(Tween.TRANS_SINE)
	_glow_tween.parallel().tween_property(_art, "modulate", Color.WHITE, 0.34).set_trans(Tween.TRANS_SINE)


func is_target() -> bool:
	return _targeted


## Uzun süre dokunulmayınca: hafifçe parlar ve iki kez zıplar
func invite() -> void:
	if not _targeted:
		_flash(0.8, 1.2)
	if _tween:
		_tween.kill()
	_art.position = Vector2.ZERO
	_tween = create_tween()
	for k in 2:
		_tween.tween_property(_art, "position:y", -22.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_property(_art, "position:y", 0.0, 0.26).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
