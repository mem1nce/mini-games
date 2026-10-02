extends Node2D
# Denizanası: yavaşça aşağı yukarı süzülür, çan kısmı nabız gibi atar. Ağa değerse ağ gıdıklanır
# (içindeki balık yüzüp gider). Ceza yok.

const G := "res://oyunlar/balik_tutma/gorseller/"

var alan := Rect2()
var _sprite: Sprite2D
var _zaman := 0.0
var _hiz_x := 0.0
var _hedef_hiz_x := 0.0
var _sure := 0.0           # yatay hedef hız bu kadar saniye sonra değişir


func kur(p_alan: Rect2, boy: float) -> void:
	alan = p_alan
	_zaman = randf() * TAU
	_sprite = Sprite2D.new()
	_sprite.texture = load(G + "denizanasi.svg")
	_sprite.scale = Vector2.ONE * boy / _sprite.texture.get_width()
	add_child(_sprite)
	_hedef_hiz_x = randf_range(-18.0, 18.0)
	_hiz_x = _hedef_hiz_x


func yaricap() -> float:
	return 46.0


func _process(delta: float) -> void:
	_zaman += delta
	var nabiz := sin(_zaman * 2.4)
	_sprite.scale.y = absf(_sprite.scale.x) * (1.0 + nabiz * 0.06)
	_sprite.skew = sin(_zaman * 1.7) * 0.08
	# Alanın ortasında yavaşça aşağı yukarı süzülür; nabızla hafifçe yukarı itilir (hepsi yumuşak dalga)
	var genlik := maxf(alan.size.y * 0.5 - 10.0, 0.0)
	var hedef_y := alan.get_center().y + sin(_zaman * 0.45) * genlik - cos(_zaman * 2.4) * 6.0
	position.y = lerpf(position.y, hedef_y, 1.0 - exp(-2.0 * delta))
	# Yatay hız ara sıra değişir, yeni hıza yavaşça döner; kenara gelince öbür yana döner
	_sure -= delta
	if _sure <= 0.0:
		_sure = randf_range(3.0, 6.0)
		_hedef_hiz_x = randf_range(-18.0, 18.0)
	if position.x <= alan.position.x:
		_hedef_hiz_x = absf(_hedef_hiz_x) + 6.0
	elif position.x >= alan.end.x:
		_hedef_hiz_x = -absf(_hedef_hiz_x) - 6.0
	_hiz_x = lerpf(_hiz_x, _hedef_hiz_x, 1.0 - exp(-1.0 * delta))
	position.x = clampf(position.x + _hiz_x * delta, alan.position.x, alan.end.x)
