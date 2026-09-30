extends Node2D
# Ön katman: dalgalı su yüzeyi (kayığın alt kısmını hafifçe örten yarı saydam şerit, ışık yansımaları),
# göl temasında yüzen nilüferler ve çöp bölümlerinde suyu bulandıran perde (çöp azaldıkça söner).

const G := "res://oyunlar/balik_tutma/gorseller/"
const BULANIK := Color(0.42, 0.45, 0.24, 0.5)

var ekran := Vector2(720, 1280)
var yuzey_y := 400.0
var su_rengi := Color("86dccb")
var bulaniklik := 0.0            # 0 = temiz, 1 = en bulanık

var _zaman := 0.0
var _niluferler: Array[Sprite2D] = []


func kur(p_ekran: Vector2, p_yuzey: float, p_su_rengi: Color, tema: String) -> void:
	ekran = p_ekran
	yuzey_y = p_yuzey
	su_rengi = p_su_rengi
	for c in get_children():
		c.queue_free()
	_niluferler.clear()
	if tema == "gol":
		for x in [ekran.x * 0.08, ekran.x * 0.93]:
			var n := Sprite2D.new()
			n.texture = load(G + "nilufer.svg")
			n.scale = Vector2.ONE * 110.0 / n.texture.get_width()
			n.position = Vector2(x, yuzey_y + 6.0)
			n.set_meta("x", x)
			add_child(n)
			_niluferler.append(n)


func dalga_y(x: float) -> float:
	return yuzey_y + sin(x * 0.02 + _zaman * 1.6) * 5.0 + sin(x * 0.047 - _zaman * 1.1) * 3.0


func bulaniklik_ayarla(deger: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "bulaniklik", deger, 0.9).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_zaman += delta
	for n in _niluferler:
		n.position = Vector2(float(n.get_meta("x")) + sin(_zaman * 0.4) * 6.0, dalga_y(n.position.x) + 4.0)
		n.rotation = sin(_zaman * 0.8 + n.position.x) * 0.04
	queue_redraw()


func _draw() -> void:
	# Bulanık su perdesi
	if bulaniklik > 0.01:
		draw_rect(Rect2(0, yuzey_y, ekran.x, ekran.y - yuzey_y), Color(BULANIK, BULANIK.a * bulaniklik))
	# Yüzey şeridi: dalga çizgisinin altında yarı saydam su
	var ust := PackedVector2Array()
	var x := 0.0
	while x <= ekran.x + 16.0:
		ust.append(Vector2(x, dalga_y(x)))
		x += 16.0
	var serit := ust.duplicate()
	for i in range(ust.size() - 1, -1, -1):
		serit.append(ust[i] + Vector2(0, 26))
	draw_colored_polygon(serit, Color(su_rengi, 0.45))
	draw_polyline(ust, Color(1, 1, 1, 0.85), 4.0, true)
	# Işık yansımaları
	for i in 9:
		var px := fmod(i * 97.0 + _zaman * 14.0, ekran.x)
		var py := dalga_y(px) + 14.0 + (i % 3) * 7.0
		draw_line(Vector2(px, py), Vector2(px + 22.0, py), Color(1, 1, 1, 0.4), 3.0, true)
