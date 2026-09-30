extends Node2D
# Lokomotif + vagonlar. Hepsi aynı yol (yol.gd) üzerinde: lokomotifin ortası "mesafe"de, vagonlar arkasında
# sabit aralıklarla. Her araç ön ve arka dingil noktası yolun üstünde olacak şekilde yerleşir; böylece virajlarda
# vagonlar lokomotifi doğal şekilde izler. Bacadan puf puf duman çıkar (hareket ederken sık, dururken seyrek).
# Alınan yolcular vagonların pencerelerinden (tavan pencereleri) el sallar.

const G := "res://oyunlar/tren_rayi/gorseller/"
const TASARIMLAR := ["yolcu", "acik", "kargo", "tanker", "odun", "cicek"]
const RENKLER := ["kirmizi", "mavi", "sari", "yesil", "mor"]
# Vagon tuvalinde (160x110) yolcu yerleri
const KOLTUKLAR := {
	"yolcu": [Vector2(52, 55), Vector2(108, 55)],
	"acik": [Vector2(46, 52), Vector2(112, 56)],
	"tanker": [Vector2(80, 55)],
	"kargo": [Vector2(80, 55)],
	"cicek": [Vector2(80, 55)],
	"odun": [],
}
const LOKO_BOY := 1.3            # hücre cinsinden
const VAGON_BOY := 0.98
const ARALIK := 0.07

var yol: RefCounted
var mesafe := 0.0
var hucre := 100.0
var efektler: Node2D             # duman ve uçan yolcular buraya eklenir (her şeyin üstünde)
var sesler: Node
var dongu_hizi := 0.0            # giriş ekranında sürekli döner (px/sn)
var hareket_ediyor := false

var _araclar: Array = []         # {"dugum", "ofset", "dingil", "tasarim", "koltuklar", "yolcular"}
var _duman_sayac := 0.0
var _zaman := 0.0


# i. kazanılan vagonun adı ("tasarim_renk"): tasarım ve renk sırayla değişir
static func vagon_adi(i: int) -> String:
	return "%s_%s" % [TASARIMLAR[i % TASARIMLAR.size()], RENKLER[(i * 3) % RENKLER.size()]]


func kur(vagonlar: Array, p_hucre: float) -> void:
	hucre = p_hucre
	for arac in _araclar:
		arac["dugum"].queue_free()
	_araclar.clear()
	var loko_boy := LOKO_BOY * hucre
	_arac_ekle(G + "lokomotif.svg", loko_boy, 0.0, "")
	var ofset := -loko_boy * 0.5
	for ad in vagonlar:
		var boy := VAGON_BOY * hucre
		ofset -= ARALIK * hucre + boy * 0.5
		_arac_ekle(G + "vagon_%s.svg" % ad, boy, ofset, str(ad).get_slice("_", 0))
		ofset -= boy * 0.5
	yerlestir()


func _arac_ekle(dosya: String, boy: float, ofset: float, tasarim: String) -> void:
	var dugum := Node2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = load(dosya)
	sprite.scale = Vector2.ONE * boy / sprite.texture.get_width()
	dugum.add_child(sprite)
	# Araçlar arka arkaya: öndeki üstte görünsün (sonra eklenen en alta çizilir)
	add_child(dugum)
	move_child(dugum, 0)
	var koltuklar: Array = []
	for k in KOLTUKLAR.get(tasarim, []):
		koltuklar.append((k - Vector2(80, 55)) * boy / 160.0)
	_araclar.append({"dugum": dugum, "ofset": ofset, "dingil": boy * 0.32, "tasarim": tasarim,
		"koltuklar": koltuklar, "yolcular": []})


func uzunluk() -> float:
	if _araclar.is_empty():
		return 0.0
	var son: Dictionary = _araclar.back()
	return -son["ofset"] + VAGON_BOY * hucre * 0.5 + LOKO_BOY * hucre * 0.5


func on_ucu() -> float:
	return LOKO_BOY * hucre * 0.5


func yerlestir() -> void:
	if yol == null:
		return
	for arac in _araclar:
		var yer: Array = yol.arac(mesafe + arac["ofset"], arac["dingil"])
		arac["dugum"].position = yer[0]
		arac["dugum"].rotation = yer[1]


func baca_konumu() -> Vector2:
	if _araclar.is_empty():
		return global_position
	var loko: Node2D = _araclar[0]["dugum"]
	return loko.to_global(Vector2(LOKO_BOY * hucre * (60.0 / 220.0), 0.0))


func loko_konumu() -> Vector2:
	return _araclar[0]["dugum"].global_position if not _araclar.is_empty() else global_position


# Yumuşak hızlanıp yavaşlayarak hedef mesafeye gider
func git(hedef: float, hiz: float, egri: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	var sure := maxf(0.25, absf(hedef - mesafe) / hiz)
	hareket_ediyor = true
	var tween := create_tween()
	tween.tween_property(self, "mesafe", hedef, sure).set_trans(egri).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	hareket_ediyor = false


func _process(delta: float) -> void:
	_zaman += delta
	if dongu_hizi != 0.0:
		mesafe += dongu_hizi * delta
		hareket_ediyor = true
	yerlestir()
	_yolcular_el_sallar()
	_duman_sayac -= delta
	if _duman_sayac <= 0.0 and efektler and not _araclar.is_empty():
		_duman_sayac = 0.3 if hareket_ediyor else 1.1
		efektler.duman(baca_konumu(), hucre * (0.3 if hareket_ediyor else 0.24))


# --- Yolcular ---

func bos_koltuk_var() -> bool:
	return _bos_koltuk()[0] >= 0


func _bos_koltuk() -> Array:
	for i in _araclar.size():
		var arac: Dictionary = _araclar[i]
		if arac["yolcular"].size() < arac["koltuklar"].size():
			return [i, arac["yolcular"].size()]
	# Yer kalmadıysa son vagona sığdırılır
	for i in range(_araclar.size() - 1, 0, -1):
		if not _araclar[i]["koltuklar"].is_empty():
			return [i, 0]
	return [0, -1]


# Yolcu (dünyadaki bir düğüm) zıplayıp trene biner
func yolcu_bindir(yolcu: Node2D) -> void:
	var yer := _bos_koltuk()
	var arac: Dictionary = _araclar[yer[0]]
	var koltuk: Vector2 = arac["koltuklar"][yer[1]] if yer[1] >= 0 else Vector2(-hucre * 0.35, 0)
	var dugum: Node2D = arac["dugum"]
	var bas := yolcu.global_position
	var hedef := dugum.to_global(koltuk)
	var tepe := (bas + hedef) * 0.5 + Vector2(0, -hucre * 0.9)
	var olcek := yolcu.scale
	var tween := yolcu.create_tween()
	tween.tween_method(func(t: float) -> void:
		yolcu.global_position = bas.lerp(tepe, t).lerp(tepe.lerp(hedef, t), t)
		yolcu.scale = olcek * lerpf(1.0, 0.72, t), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	yolcu.reparent(dugum)
	yolcu.position = koltuk
	yolcu.rotation = 0.0
	yolcu.set_meta("koltuk", koltuk)
	yolcu.set_meta("faz", randf() * TAU)
	arac["yolcular"].append(yolcu)


func _yolcular_el_sallar() -> void:
	for arac in _araclar:
		for yolcu in arac["yolcular"]:
			var faz: float = yolcu.get_meta("faz")
			yolcu.rotation = -arac["dugum"].rotation + sin(_zaman * 5.0 + faz) * 0.18
			yolcu.position = yolcu.get_meta("koltuk") + Vector2(0, -absf(sin(_zaman * 5.0 + faz)) * hucre * 0.04).rotated(-arac["dugum"].rotation)


func yolcu_sayisi() -> int:
	var n := 0
	for arac in _araclar:
		n += arac["yolcular"].size()
	return n


func yolculari_indir() -> void:
	for arac in _araclar:
		for yolcu in arac["yolcular"]:
			yolcu.queue_free()
		arac["yolcular"].clear()


# Kutlamada trenin sonuna yeni vagon parıltıyla eklenir
func vagon_ekle(ad: String) -> Node2D:
	var boy := VAGON_BOY * hucre
	var son: Dictionary = _araclar.back()
	var son_boy := LOKO_BOY * hucre if _araclar.size() == 1 else VAGON_BOY * hucre
	var ofset: float = son["ofset"] - son_boy * 0.5 - ARALIK * hucre - boy * 0.5
	_arac_ekle(G + "vagon_%s.svg" % ad, boy, ofset, str(ad).get_slice("_", 0))
	yerlestir()
	var dugum: Node2D = _araclar.back()["dugum"]
	dugum.scale = Vector2.ZERO
	var tween := dugum.create_tween()
	tween.tween_property(dugum, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return dugum


# Dokunma denetimi (giriş ekranında trene dokununca düdük)
func iceriyor_mu(nokta: Vector2) -> bool:
	for arac in _araclar:
		if arac["dugum"].global_position.distance_to(nokta) < hucre * 0.7:
			return true
	return false
