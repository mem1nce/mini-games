extends Node2D
# Tek balık: doğal, hafif dalgalı yüzme (yavaş dalga + kuyruk kıpırtısı), ara sıra geri dönme.
# Ağdayken sevinçle kıpırdar; görevle ilgisizse yüzgecini sallayıp suya geri atlar; denizanası ağı
# gıdıklayınca hızla yüzüp gider. Işıklı türlerin çevresinde yumuşak bir ışık var.

const Turler := preload("res://oyunlar/balik_tutma/balik_turleri.gd")

enum Durum { YUZUYOR, AGDA, UCUYOR, KACIYOR }

var tur := ""
var durum := Durum.YUZUYOR
var yon := 1.0                  # 1 = sağa, -1 = sola
var hiz := 80.0
var taban_y := 0.0              # dalganın ortası
var sinir := Rect2()            # yüzebileceği su alanı (ekran dışı kenarlar dahil)

var _sprite: Sprite2D
var _isik: Sprite2D
var _zaman := 0.0
var _dalga := 1.0
var _donus := 0.0               # bir sonraki olası geri dönüşe kalan süre


func kur(p_tur: String, p_yon: float, y: float, p_hiz: float, alan: Rect2) -> void:
	tur = p_tur
	yon = p_yon
	hiz = p_hiz
	taban_y = y
	sinir = alan
	_zaman = randf() * TAU
	_dalga = randf_range(0.6, 1.3)
	_donus = randf_range(5.0, 12.0)
	_sprite = Sprite2D.new()
	_sprite.texture = Turler.doku(tur)
	_sprite.scale = Vector2.ONE * Turler.boy(tur) / _sprite.texture.get_width()
	var t := Turler.tur(tur)
	if t.has("isik"):
		_isik = Sprite2D.new()
		_isik.texture = load(Turler.G + "isik.svg")
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_isik.material = mat
		_isik.scale = Vector2.ONE * Turler.boy(tur) * 1.5 / _isik.texture.get_width()
		_isik.modulate = Color(t["isik"], 0.45)
		add_child(_isik)
	add_child(_sprite)
	_yone_bak(false)


func yaricap() -> float:
	return Turler.boy(tur) * 0.36 + 14.0


func bilgi() -> Dictionary:
	return {"tur": tur}


func _yone_bak(animasyonlu: bool) -> void:
	var hedef := Vector2(yon, 1.0)
	if animasyonlu:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(0.0, 1.0), 0.18).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "scale", hedef, 0.18).set_trans(Tween.TRANS_SINE)
	else:
		scale = hedef


func _process(delta: float) -> void:
	_zaman += delta
	match durum:
		Durum.YUZUYOR:
			position.x += yon * hiz * delta
			position.y = taban_y + sin(_zaman * 1.3 * _dalga) * 12.0
			rotation = cos(_zaman * 1.3 * _dalga) * 0.08 * yon
			# Kuyruk kıpırtısı: hafif sıkışıp esneme
			_sprite.scale.x = absf(_sprite.scale.y) * (1.0 + sin(_zaman * 9.0) * 0.035)
			_donus -= delta
			if _donus <= 0.0:
				_donus = randf_range(6.0, 12.0)
				if randf() < 0.35 and position.x > sinir.position.x + 120.0 and position.x < sinir.end.x - 120.0:
					yon = -yon
					_yone_bak(true)
		Durum.AGDA:
			rotation = sin(_zaman * 16.0) * 0.22
		Durum.KACIYOR:
			position.x += yon * hiz * 3.0 * delta
			position.y = move_toward(position.y, taban_y, 120.0 * delta)
			rotation = sin(_zaman * 12.0) * 0.06


func disarida_mi() -> bool:
	return position.x < sinir.position.x - 60.0 or position.x > sinir.end.x + 60.0


# Ağa girdi
func aga_gir() -> void:
	durum = Durum.AGDA
	scale = Vector2(yon, 1.0)


# Denizanası gıdıkladı: ağdan çıkar, hızla uzaklaşır
func kac(dunya: Node2D) -> void:
	var yer := global_position
	reparent(dunya)
	global_position = yer
	durum = Durum.KACIYOR
	taban_y = clampf(yer.y + 60.0, sinir.position.y + 40.0, sinir.end.y - 40.0)
	rotation = 0.0


# Suya geri atlama: yüzgeç sallar, yay çizip suya dalar, sonra yüzmeye devam eder
func suya_don(dunya: Node2D, hedef: Vector2) -> void:
	durum = Durum.UCUYOR
	var yer := global_position
	reparent(dunya)
	global_position = yer
	rotation = 0.0
	var tween := create_tween()
	# yüzgeç sallama: sağa sola hızlı küçük dönüşler
	for i in 3:
		tween.tween_property(self, "rotation", 0.3, 0.09).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "rotation", -0.3, 0.09).set_trans(Tween.TRANS_SINE)
	var tepe := (yer + hedef) * 0.5 + Vector2(0, -140)
	tween.tween_method(func(t: float) -> void:
		global_position = yer.lerp(tepe, t).lerp(tepe.lerp(hedef, t), t)
		rotation = lerpf(-0.8, 1.2, t) * yon, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	rotation = 0.0
	taban_y = clampf(hedef.y + 80.0, sinir.position.y + 40.0, sinir.end.y - 40.0)
	durum = Durum.KACIYOR


# Akvaryumda dokununca takla
func takla() -> void:
	var tween := create_tween()
	tween.tween_property(self, "rotation", rotation + TAU * yon, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
