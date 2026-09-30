extends Node2D
# Denizanası: yavaşça aşağı yukarı süzülür, çan kısmı nabız gibi atar. Ağa değerse ağ gıdıklanır
# (içindeki balık yüzüp gider). Ceza yok.

const G := "res://oyunlar/balik_tutma/gorseller/"

var alan := Rect2()
var _sprite: Sprite2D
var _zaman := 0.0
var _hedef_y := 0.0
var _hiz_x := 0.0


func kur(p_alan: Rect2, boy: float) -> void:
	alan = p_alan
	_zaman = randf() * TAU
	_sprite = Sprite2D.new()
	_sprite.texture = load(G + "denizanasi.svg")
	_sprite.scale = Vector2.ONE * boy / _sprite.texture.get_width()
	add_child(_sprite)
	_hedef_y = randf_range(alan.position.y, alan.end.y)
	_hiz_x = randf_range(-18.0, 18.0)


func yaricap() -> float:
	return 46.0


func _process(delta: float) -> void:
	_zaman += delta
	var nabiz := sin(_zaman * 2.4)
	_sprite.scale.y = absf(_sprite.scale.x) * (1.0 + nabiz * 0.06)
	_sprite.skew = sin(_zaman * 1.7) * 0.08
	# Nabızla birlikte yukarı itilir, sonra yavaşça süzülür
	position.y = move_toward(position.y, _hedef_y, (22.0 + maxf(0.0, nabiz) * 30.0) * delta)
	position.x = clampf(position.x + _hiz_x * delta, alan.position.x, alan.end.x)
	if absf(position.y - _hedef_y) < 4.0:
		_hedef_y = randf_range(alan.position.y, alan.end.y)
		_hiz_x = randf_range(-18.0, 18.0)
