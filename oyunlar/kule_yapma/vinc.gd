extends Node2D
# Ekranın üstüne sabit vinç (düğüm her kare kameranın sol üstüne taşınır). Kolun ortasındaki makaradan inen iki
# halatta kat sarkaç gibi sallanır; ileriki bölümlerde makara hafifçe yukarı aşağı da oynar. Dokununca kat bırakılır.

const G := "res://oyunlar/kule_yapma/gorseller/"
const HALAT := 170.0

var hiz := 1.5                   # sarkaç açısal hızı (radyan/sn)
var aci := 0.42                  # en büyük sallanma açısı
var dikey := 0.0                 # makaranın yukarı aşağı oynaması (px)
var asili: Node2D = null         # halattaki kat
var hazir := false               # bırakılabilir mi

var _makara: Sprite2D
var _zaman := 0.0
var _halat_boyu := HALAT
var _ekran_x := 720.0


func kur(ekran_x: float) -> void:
	_ekran_x = ekran_x
	var govde := Sprite2D.new()
	govde.texture = load(G + "vinc.svg")
	govde.centered = false
	govde.scale = Vector2.ONE * 760.0 / govde.texture.get_width()
	govde.position = Vector2(ekran_x * 0.5 - 380.0, 40.0)
	add_child(govde)
	_makara = Sprite2D.new()
	_makara.texture = load(G + "makara.svg")
	_makara.scale = Vector2.ONE * 100.0 / _makara.texture.get_width()
	add_child(_makara)


# Makaradaki kancanın ucu (yerel)
func kanca() -> Vector2:
	return Vector2(_ekran_x * 0.5, 302.0 + sin(_zaman * 1.3) * dikey)


func _sallanma_acisi() -> float:
	return sin(_zaman * hiz) * aci


# Yeni kat makaradan halatla iner, sonra sallanır
func kat_as(blok: Node2D) -> void:
	asili = blok
	hazir = false
	add_child(blok)
	_halat_boyu = 20.0
	blok.scale = Vector2(0.6, 0.6)
	_yerlestir()
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "_halat_boyu", HALAT, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(blok, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void: hazir = true)


# Katı bırakır: kat dünyaya geçer (aynı yerde kalır) ve döndürülür
func birak(dunya: Node2D) -> Node2D:
	if not hazir or asili == null:
		return null
	var blok := asili
	asili = null
	hazir = false
	blok.reparent(dunya)
	return blok


func _yerlestir() -> void:
	var k := kanca()
	_makara.position = k + Vector2(0, -52.0)
	if asili:
		var a := _sallanma_acisi()
		var yon := Vector2(sin(a), cos(a))
		var ust := k + yon * _halat_boyu
		asili.rotation = -a * 0.6
		asili.position = ust + Vector2(0, asili.yukseklik() * 0.5).rotated(asili.rotation)


func _process(delta: float) -> void:
	_zaman += delta
	_yerlestir()
	queue_redraw()


func _draw() -> void:
	# Direğin ekranın tepesine uzanan parçası (vinç görseli 40 px aşağıda başlar)
	var direk := Rect2(_ekran_x * 0.5 - 380.0 + 70.0, -20.0, 40.0, 72.0)
	draw_rect(direk, Color("ffc23a"))
	draw_rect(direk, Color("3a2e52"), false, 4.0)
	for y in [0.0, 24.0]:
		draw_line(direk.position + Vector2(4, y + 4), direk.position + Vector2(36, y + 20), Color("c9780e"), 3.0, true)
	if asili == null:
		return
	# İki halat: kancadan katın üst köşelerine
	var k := kanca()
	var yarim: float = asili.genislik() * 0.36
	var ust_sol: Vector2 = asili.position + Vector2(-yarim, -asili.yukseklik() * 0.5).rotated(asili.rotation)
	var ust_sag: Vector2 = asili.position + Vector2(yarim, -asili.yukseklik() * 0.5).rotated(asili.rotation)
	for uc in [ust_sol, ust_sag]:
		draw_line(k, uc, Color(0.23, 0.18, 0.32), 5.0, true)
		draw_line(k, uc, Color(0.72, 0.68, 0.8), 2.2, true)
