extends Node2D
# Sudaki çöp (şişe, poşet, teneke kutu): yerinde hafifçe süzülür ve döner. Ağla toplanınca kayıktaki
# geri dönüşüm kutusuna gider; her çöpte su biraz berraklaşır.

const G := "res://oyunlar/balik_tutma/gorseller/"
const TURLER := ["sise", "poset", "teneke"]
const BOYLAR := {"sise": 64.0, "poset": 86.0, "teneke": 60.0}

var tur := "sise"
var serbest := true             # suda mı (ağa girince false)
var _sprite: Sprite2D
var _zaman := 0.0
var _taban := Vector2.ZERO
var _egim := 0.0


func kur(p_tur: String, yer: Vector2) -> void:
	tur = p_tur
	position = yer
	_taban = yer
	_zaman = randf() * TAU
	_egim = randf_range(-0.6, 0.6)
	_sprite = Sprite2D.new()
	_sprite.texture = load(G + "cop_%s.svg" % tur)
	var doku := _sprite.texture.get_size()
	_sprite.scale = Vector2.ONE * BOYLAR[tur] / maxf(doku.x, doku.y)
	add_child(_sprite)


func yaricap() -> float:
	return 52.0


func bilgi() -> Dictionary:
	return {"cop": true, "cop_turu": tur}


func _process(delta: float) -> void:
	_zaman += delta
	if serbest:
		position = _taban + Vector2(sin(_zaman * 0.7) * 8.0, sin(_zaman * 1.1) * 10.0)
		rotation = _egim + sin(_zaman * 0.9) * 0.15
