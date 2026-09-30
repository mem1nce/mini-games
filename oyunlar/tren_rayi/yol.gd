extends RefCounted
# Trenin izlediği yol: sık aralıklı noktalar ve her noktaya kadarki uzunluk. konum(s) yol üzerindeki s
# mesafesindeki noktayı verir. Kapalı yolda (giriş ekranındaki halka) s, uzunluğa göre sarılır.

var noktalar := PackedVector2Array()
var mesafeler := PackedFloat32Array()
var kapali := false


func uzunluk() -> float:
	return mesafeler[mesafeler.size() - 1] if mesafeler.size() > 0 else 0.0


func ekle(nokta: Vector2) -> void:
	if noktalar.size() > 0:
		var son := noktalar[noktalar.size() - 1]
		if son.distance_to(nokta) < 0.01:
			return
		mesafeler.append(mesafeler[mesafeler.size() - 1] + son.distance_to(nokta))
	else:
		mesafeler.append(0.0)
	noktalar.append(nokta)


func duz_ekle(bitis: Vector2, adim: float = 8.0) -> void:
	var bas := noktalar[noktalar.size() - 1] if noktalar.size() > 0 else bitis
	var sayi := maxi(1, ceili(bas.distance_to(bitis) / adim))
	for i in range(1, sayi + 1):
		ekle(bas.lerp(bitis, float(i) / sayi))


# Merkez etrafında a0'dan a1'e yay (radyan); ilk nokta yolun son noktasıyla aynı olmalı
func yay_ekle(merkez: Vector2, yaricap: float, a0: float, a1: float, adim: float = 6.0) -> void:
	var sayi := maxi(2, ceili(absf(a1 - a0) * yaricap / adim))
	for i in range(0, sayi + 1):
		var a := lerpf(a0, a1, float(i) / sayi)
		ekle(merkez + Vector2(cos(a), sin(a)) * yaricap)


func _sar(s: float) -> float:
	if kapali:
		return fposmod(s, uzunluk())
	return clampf(s, 0.0, uzunluk())


func konum(s: float) -> Vector2:
	if noktalar.is_empty():
		return Vector2.ZERO
	s = _sar(s)
	var i := mesafeler.bsearch(s)
	if i <= 0:
		return noktalar[0]
	if i >= noktalar.size():
		return noktalar[noktalar.size() - 1]
	var d0 := mesafeler[i - 1]
	var d1 := mesafeler[i]
	return noktalar[i - 1].lerp(noktalar[i], (s - d0) / maxf(d1 - d0, 0.0001))


# Uzun bir araç için: ön ve arka dingil yol üstünde; ortası ve yönü
func arac(s: float, dingil: float) -> Array:
	var on := konum(s + dingil)
	var arka := konum(s - dingil)
	# Yolun başında/sonunda dingil taşarsa düz devam ediyormuş gibi uzat
	if not kapali:
		if s + dingil > uzunluk():
			on = konum(uzunluk()) + _son_yon() * (s + dingil - uzunluk())
		if s - dingil < 0.0:
			arka = konum(0.0) - _ilk_yon() * (dingil - s)
	return [(on + arka) * 0.5, (on - arka).angle()]


func _ilk_yon() -> Vector2:
	return (noktalar[1] - noktalar[0]).normalized() if noktalar.size() > 1 else Vector2.RIGHT


func _son_yon() -> Vector2:
	var n := noktalar.size()
	return (noktalar[n - 1] - noktalar[n - 2]).normalized() if n > 1 else Vector2.RIGHT
