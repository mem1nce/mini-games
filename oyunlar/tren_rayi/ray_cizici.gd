extends RefCounted
# Herhangi bir yol boyunca ray çizer (başlangıç ve istasyon uçları, giriş ekranındaki halka).
# Renkler ve ölçüler ray parçası SVG'leriyle aynı (128'lik karoda: traversler 21 px arayla, raylar eksenden 20 px).

const TRAVERS := Color("c07e4c")
const TRAVERS_KOYU := Color("6b4226")
const TRAVERS_ACIK := Color("d99a62")
const RAY := Color("b5bccc")
const RAY_KOYU := Color("454b63")
const RAY_ACIK := Color("ffffff")
const GOLGE := Color(0.16, 0.12, 0.23, 0.17)


# noktalar: yol; olcek = hücre / 128
static func ciz(tuval: CanvasItem, noktalar: PackedVector2Array, olcek: float) -> void:
	if noktalar.size() < 2:
		return
	var yol := _yeniden_ornekle(noktalar, 21.33 * olcek)
	# Traversler (gölge, gövde, damar)
	var yari := 31.0 * olcek
	var kalin := 6.0 * olcek
	for katman in 2:
		for i in yol.size() - 1:
			var orta := (yol[i] + yol[i + 1]) * 0.5
			var yon := (yol[i + 1] - yol[i]).normalized()
			var dik := Vector2(-yon.y, yon.x)
			var kayma := Vector2(2.5, 4.0) * olcek if katman == 0 else Vector2.ZERO
			var p := PackedVector2Array([
				orta + kayma - yon * kalin - dik * yari, orta + kayma + yon * kalin - dik * yari,
				orta + kayma + yon * kalin + dik * yari, orta + kayma - yon * kalin + dik * yari])
			if katman == 0:
				tuval.draw_colored_polygon(p, GOLGE)
			else:
				tuval.draw_colored_polygon(p, TRAVERS)
				var kapali := p.duplicate()
				kapali.append(p[0])
				tuval.draw_polyline(kapali, TRAVERS_KOYU, 2.2 * olcek, true)
				tuval.draw_line(orta - yon * 1.5 * olcek - dik * (yari - 7.0 * olcek), orta - yon * 1.5 * olcek + dik * (yari - 9.0 * olcek),
					Color(1, 1, 1, 0.28), 2.0 * olcek, true)
	# Raylar: gölge, koyu kenar, gövde, parlama
	for yan in [-1.0, 1.0]:
		var ray := _kaydir(noktalar, yan * 20.0 * olcek)
		tuval.draw_polyline(_tasi(ray, Vector2(2, 3) * olcek), GOLGE, 7.2 * olcek, true)
		tuval.draw_polyline(ray, RAY_KOYU, 9.6 * olcek, true)
		tuval.draw_polyline(ray, RAY, 5.4 * olcek, true)
		tuval.draw_polyline(_kaydir(ray, -1.0 * olcek), RAY_ACIK, 1.8 * olcek, true)


static func _tasi(noktalar: PackedVector2Array, kayma: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in noktalar:
		out.append(p + kayma)
	return out


# Yola paralel kaydırılmış çizgi
static func _kaydir(noktalar: PackedVector2Array, uzaklik: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := noktalar.size()
	for i in n:
		var onceki := noktalar[maxi(i - 1, 0)]
		var sonraki := noktalar[mini(i + 1, n - 1)]
		var yon := (sonraki - onceki).normalized()
		out.append(noktalar[i] + Vector2(-yon.y, yon.x) * uzaklik)
	return out


# Eşit aralıklı noktalar (traversler için)
static func _yeniden_ornekle(noktalar: PackedVector2Array, aralik: float) -> PackedVector2Array:
	var out := PackedVector2Array([noktalar[0]])
	var kalan := aralik
	for i in range(1, noktalar.size()):
		var a := noktalar[i - 1]
		var b := noktalar[i]
		var d := a.distance_to(b)
		while d >= kalan:
			a = a.lerp(b, kalan / d)
			out.append(a)
			d = a.distance_to(b)
			kalan = aralik
		kalan -= d
	return out
