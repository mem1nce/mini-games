extends Node2D
# Tek ray parçası (hücrenin ortasında). Dokununca "klik" ile saat yönünde 90° döner (hafif zıplama + yumuşak dönme).
# Sabit parçanın köşesinde cıvata var, dokununca sadece hafifçe sallanır. Başlangıca bağlıyken altında sıcak bir
# parlama belirir. İpucunda hafifçe sallanır.

const G := "res://oyunlar/tren_rayi/gorseller/"
const PARLAMA_RENGI := Color(1.0, 0.86, 0.32)

var tip := "duz"
var yon := 0
var sabit := false
var bagli := false

var _ray: Sprite2D
var _isik: Sprite2D
var _civata: Sprite2D
var _donme: Tween
var _isik_tween: Tween


func kur(p_tip: String, p_yon: int, p_sabit: bool, hucre: float) -> void:
	tip = p_tip
	yon = p_yon
	sabit = p_sabit
	var olcek := hucre / 128.0
	_isik = Sprite2D.new()
	_isik.texture = load(G + "ray_%s_isik.svg" % tip)
	_isik.scale = Vector2.ONE * olcek * 128.0 / _isik.texture.get_width()
	_isik.modulate = Color(PARLAMA_RENGI, 0.0)
	_isik.rotation = yon * PI / 2.0
	add_child(_isik)
	_ray = Sprite2D.new()
	_ray.texture = load(G + "ray_%s.svg" % tip)
	_ray.scale = Vector2.ONE * olcek * 128.0 / _ray.texture.get_width()
	_ray.rotation = yon * PI / 2.0
	add_child(_ray)
	if sabit:
		_civata = Sprite2D.new()
		_civata.texture = load(G + "civata.svg")
		_civata.scale = Vector2.ONE * hucre * 0.24 / _civata.texture.get_width()
		_civata.position = Vector2(-hucre * 0.33, -hucre * 0.33)
		add_child(_civata)


# Dokunuş: sabit değilse döner ve true döner
func dokun() -> bool:
	if sabit:
		_salla(0.09)
		return false
	yon = (yon + 1) % 4
	if _donme and _donme.is_valid():
		_donme.kill()
	var hedef := yon * PI / 2.0
	# Açıyı hep ileri (saat yönünde) çevir: 270° → 360° gibi
	while hedef < _ray.rotation - 0.01:
		hedef += TAU
	_donme = create_tween().set_parallel()
	_donme.tween_property(_ray, "rotation", hedef, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_donme.tween_property(_isik, "rotation", hedef, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_donme.tween_property(self, "scale", Vector2(1.12, 1.12), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_donme.chain().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_donme.chain().tween_callback(func() -> void:
		_ray.rotation = fposmod(_ray.rotation, TAU)
		_isik.rotation = _ray.rotation)
	return true


func parla(deger: bool) -> void:
	if deger == bagli:
		return
	bagli = deger
	if _isik_tween and _isik_tween.is_valid():
		_isik_tween.kill()
	_isik_tween = create_tween()
	_isik_tween.tween_property(_isik, "modulate:a", 0.85 if deger else 0.0, 0.35 if deger else 0.2).set_trans(Tween.TRANS_SINE)


# İpucu: yanlış yöndeki parça hafifçe sallanır
func ipucu() -> void:
	_salla(0.14)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)


func _salla(aci: float) -> void:
	var tween := create_tween()
	for i in 3:
		var a := aci * (1.0 - i * 0.3)
		tween.tween_property(self, "rotation", a, 0.06).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "rotation", -a, 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", 0.0, 0.06)
