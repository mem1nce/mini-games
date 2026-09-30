extends Node2D
# Oyun ızgarası: zemin karoları, ray parçaları, engeller, yolcu peronları, başlangıç ucu ve istasyon.
# Dokunulan parçayı döndürür, başlangıca bağlı rayları parlatır, yol tamamsa istasyon ışığını yakar,
# ipucunda yanlış yöndeki bir parçayı sallar ve trenin izleyeceği yolu (yol.gd) kurar.

const Baglanti := preload("res://oyunlar/tren_rayi/baglanti.gd")
const RayParcasi := preload("res://oyunlar/tren_rayi/ray_parcasi.gd")
const RayCizici := preload("res://oyunlar/tren_rayi/ray_cizici.gd")
const Yol := preload("res://oyunlar/tren_rayi/yol.gd")
const G := "res://oyunlar/tren_rayi/gorseller/"
const ISTASYON_BOY := 2.0        # istasyonun ray boyunca uzunluğu (hücre)
const ISTASYON_DURAK := 1.72     # lokomotifin burnunun durduğu yer (istasyon başından, hücre)
const BASLANGIC_UZUNLUK := 12.0  # başlangıç ucunun ekran dışına uzanan boyu (hücre)
const TAHTA_KENAR := 10.0

var bolum: Dictionary = {}
var tema := "ciftlik"
var hucre := 100.0
var koken := Vector2.ZERO
var parcalar := {}                # Vector2i → ray_parcasi
var yolcular := {}                # Vector2i → hayvan düğümü (henüz alınmamışlar)
var istasyon_hayvanlari: Array[Node2D] = []
var efektler: Node2D
var tamam := false

var _cozum_sirasi: Array = []     # çözüm rotasındaki hücreler, sırayla (ipucu için)
var _uclar: Array[PackedVector2Array] = []
var _istasyon_isigi: Sprite2D
var _zaman := 0.0


# Ekran alanına göre hücre boyu ve ızgaranın sol üstü. Solda tren ve düğme, istasyon tarafında istasyon için yer ayrılır.
static func yerlesim(boyut: Vector2i, cikis_yonu: int, ekran: Vector2) -> Dictionary:
	var sol := 290.0
	var sag := 60.0
	var ust := 116.0
	var alt := 34.0
	var ek_x := ISTASYON_BOY + 0.1 if cikis_yonu == 1 else 0.0
	var ek_y := ISTASYON_BOY + 0.1 if cikis_yonu in [0, 2] else 0.0
	var hucre_boyu := minf(142.0, minf((ekran.x - sol - sag) / (boyut.x + ek_x), (ekran.y - ust - alt) / (boyut.y + ek_y)))
	hucre_boyu = floorf(hucre_boyu)
	var genislik := hucre_boyu * (boyut.x + ek_x)
	var yukseklik := hucre_boyu * (boyut.y + ek_y)
	var x := sol + (ekran.x - sol - sag - genislik) * 0.5
	var y := ust + (ekran.y - ust - alt - yukseklik) * 0.5
	if cikis_yonu == 0:
		y += hucre_boyu * ek_y
	return {"hucre": hucre_boyu, "koken": Vector2(x, y)}


func kur(p_bolum: Dictionary, p_tema: String, ekran: Vector2) -> void:
	bolum = p_bolum
	tema = p_tema
	var yer := yerlesim(bolum["boyut"], bolum["cikis_yonu"], ekran)
	hucre = yer["hucre"]
	koken = yer["koken"]
	var boyut: Vector2i = bolum["boyut"]
	var zemin: Texture2D = load(G + "zemin_%s.svg" % tema)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(bolum["boyut"]) + tema)
	for y in boyut.y:
		for x in boyut.x:
			# Karolar tekrar etmesin diye döndürülür/çevrilir; satranç tahtası gibi hafif ton farkı hücreleri ayırır
			var karo := Sprite2D.new()
			karo.texture = zemin
			karo.scale = Vector2.ONE * hucre / zemin.get_width()
			karo.position = merkez(Vector2i(x, y))
			karo.rotation = rng.randi_range(0, 3) * PI / 2.0
			karo.flip_h = rng.randf() < 0.5
			if (x + y) % 2 == 1:
				karo.modulate = Color(0.96, 0.96, 0.96)
			add_child(karo)
	for h in bolum["engeller"]:
		var engel := Sprite2D.new()
		engel.texture = load(G + "engel_%s_%s.svg" % [tema, bolum["engeller"][h]])
		engel.scale = Vector2.ONE * hucre * 0.96 / engel.texture.get_width()
		engel.position = merkez(h)
		if bolum["engeller"][h] != "K" or tema != "gece":
			engel.rotation = rng.randf_range(-0.25, 0.25)
		add_child(engel)
	for h in bolum["parcalar"]:
		var p: Dictionary = bolum["parcalar"][h]
		var parca: Node2D = RayParcasi.new()
		parca.position = merkez(h)
		add_child(parca)
		parca.kur(p["tip"], p["yon"], p["sabit"], hucre)
		parcalar[h] = parca
	for y in bolum["yolcular"]:
		_peron_kur(y["hucre"], y["hayvan"])
	_uclari_kur()
	_istasyon_kur()
	var yolcu_hucreleri := yolcular.keys()
	var cozum_rotasi := Baglanti.rota(bolum["cozum"], bolum["giris"], bolum["cikis"], bolum["cikis_yonu"], yolcu_hucreleri)
	_cozum_sirasi = cozum_rotasi["adimlar"].map(func(a: Dictionary) -> Vector2i: return a["hucre"])
	parlama_guncelle()
	queue_redraw()


func merkez(h: Vector2i) -> Vector2:
	return koken + (Vector2(h) + Vector2(0.5, 0.5)) * hucre


func alan() -> Rect2:
	return Rect2(koken, Vector2(bolum["boyut"]) * hucre)


func hucre_bul(nokta: Vector2) -> Vector2i:
	var h := Vector2i(((nokta - koken) / hucre).floor())
	var boyut: Vector2i = bolum["boyut"]
	if h.x < 0 or h.y < 0 or h.x >= boyut.x or h.y >= boyut.y:
		return Vector2i(-1, -1)
	return h


# Başlangıç ucu: batı kenarında trenin girdiği nokta
func giris_noktasi() -> Vector2:
	return merkez(bolum["giris"]) - Vector2(hucre * 0.5, 0)


func istasyon_noktasi() -> Vector2:
	return merkez(bolum["cikis"]) + Vector2(Baglanti.ADIM[bolum["cikis_yonu"]]) * hucre * 0.5


func _yon() -> Vector2:
	return Vector2(Baglanti.ADIM[bolum["cikis_yonu"]])


# --- Kurulum ayrıntıları ---

func _peron_kur(h: Vector2i, hayvan: String) -> void:
	var peron := Sprite2D.new()
	peron.texture = load(G + "peron.svg")
	peron.scale = Vector2.ONE * hucre * 0.9 / peron.texture.get_width()
	peron.position = merkez(h)
	add_child(peron)
	var dugum := _hayvan(hayvan, hucre * 0.62)
	dugum.position = merkez(h) + Vector2(-hucre * 0.04, -hucre * 0.02)
	add_child(dugum)
	yolcular[h] = dugum


func _hayvan(ad: String, boy: float) -> Node2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(G + "hayvanlar/%s.svg" % ad)
	sprite.scale = Vector2.ONE * boy / sprite.texture.get_width()
	sprite.set_meta("faz", randf() * TAU)
	sprite.set_meta("ad", ad)
	return sprite


func _uclari_kur() -> void:
	_uclar.clear()
	var bas := giris_noktasi()
	_uclar.append(PackedVector2Array([bas - Vector2(hucre * BASLANGIC_UZUNLUK, 0), bas]))
	var ist := istasyon_noktasi()
	_uclar.append(PackedVector2Array([ist, ist + _yon() * hucre * (ISTASYON_BOY - 0.12)]))


func _istasyon_kur() -> void:
	var ist := istasyon_noktasi()
	var istasyon := Sprite2D.new()
	istasyon.texture = load(G + "istasyon.svg")
	var k := ISTASYON_BOY * hucre / 256.0
	istasyon.scale = Vector2.ONE * k * 256.0 / istasyon.texture.get_width()
	istasyon.centered = false
	istasyon.offset = -Vector2(0, 128) * istasyon.texture.get_width() / 256.0
	istasyon.position = ist
	istasyon.rotation = _yon().angle()
	add_child(istasyon)
	_istasyon_isigi = Sprite2D.new()
	_istasyon_isigi.texture = load(G + "isik.svg")
	var isik_mat := CanvasItemMaterial.new()
	isik_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_istasyon_isigi.material = isik_mat
	_istasyon_isigi.scale = Vector2.ONE * hucre * 2.4 / _istasyon_isigi.texture.get_width()
	_istasyon_isigi.position = _istasyon_yeri(istasyon, Vector2(128, 70))
	_istasyon_isigi.modulate = Color(1.0, 0.85, 0.35, 0.0)
	add_child(_istasyon_isigi)
	# Perondaki iki hayvan (bölüme göre değişir)
	var adlar := ["tavsan", "panda", "penguen", "fil", "zurafa", "aslan", "baykus", "kaplumbaga"]
	var bas := posmod(hash(tema + str(bolum["boyut"])), adlar.size())
	for i in 2:
		var dugum := _hayvan(adlar[(bas + i * 3) % adlar.size()], hucre * 0.56)
		dugum.position = _istasyon_yeri(istasyon, Vector2(84 + i * 70, 84))
		add_child(dugum)
		istasyon_hayvanlari.append(dugum)


# İstasyon görselinin (256x192 tuval, ray y=128'de) bir noktasının dünyadaki yeri
func _istasyon_yeri(istasyon: Sprite2D, tuval: Vector2) -> Vector2:
	return istasyon.to_global((tuval - Vector2(0, 128)) * istasyon.texture.get_width() / 256.0)


func _draw() -> void:
	# Tahta: ızgaranın altında hafif yükseltilmiş, gölgeli zemin
	var r := alan().grow(TAHTA_KENAR)
	var stil := StyleBoxFlat.new()
	stil.bg_color = _tahta_rengi()
	stil.set_corner_radius_all(22)
	stil.shadow_color = Color(0.15, 0.1, 0.2, 0.28)
	stil.shadow_size = 14
	stil.shadow_offset = Vector2(0, 8)
	stil.border_color = _tahta_rengi().darkened(0.25)
	stil.set_border_width_all(3)
	draw_style_box(stil, r)
	for uc in _uclar:
		RayCizici.ciz(self, uc, hucre / 128.0)


func _tahta_rengi() -> Color:
	match tema:
		"orman": return Color("7a5c3a")
		"kar": return Color("b8cbe3")
		"sahil": return Color("d9b46a")
		"gece": return Color("2e3048")
	return Color("5fa843")


# --- Oyun ---

# Dokunuş: 1 = parça döndü, 0 = sabit parçaya dokunuldu, -1 = parça yok
func dokun(nokta: Vector2) -> int:
	var h := hucre_bul(nokta)
	if not parcalar.has(h):
		return -1
	return 1 if parcalar[h].dokun() else 0


func durum() -> Dictionary:
	var out := {}
	for h in parcalar:
		out[h] = {"tip": parcalar[h].tip, "yon": parcalar[h].yon}
	return out


# Başlangıca bağlı raylar parlar; yol istasyona varıyorsa istasyon ışığı yanar. Döner: yol tamam mı
func parlama_guncelle() -> bool:
	var d := durum()
	var bagli := Baglanti.bagli_hucreler(d, bolum["giris"])
	for h in parcalar:
		parcalar[h].parla(bagli.has(h))
	var onceki := tamam
	tamam = Baglanti.rota(d, bolum["giris"], bolum["cikis"], bolum["cikis_yonu"], yolcular.keys())["tamam"]
	if tamam != onceki:
		var tween := _istasyon_isigi.create_tween()
		tween.tween_property(_istasyon_isigi, "modulate:a", 0.75 if tamam else 0.0, 0.4)
		if tamam and efektler:
			efektler.parilti(_istasyon_isigi.position, Color("fff6b0"), 14, hucre * 0.6)
	return tamam


# İpucu: çözüm yolunda, başlangıca en yakın yanlış yöndeki (sabit olmayan) parça sallanır
func ipucu() -> bool:
	for h in _cozum_sirasi:
		var parca: Node2D = parcalar[h]
		var cozum: Dictionary = bolum["cozum"][h]
		if parca.sabit:
			continue
		if Baglanti.acikliklar(parca.tip, parca.yon) != Baglanti.acikliklar(cozum["tip"], cozum["yon"]):
			parca.ipucu()
			return true
	return false


# Trenin yolu: başlangıç ucundan rota boyunca (tamamsa istasyona kadar).
# Döner: {"yol", "tamam", "duraklar": [{"s", "hucre"}], "son": rotanın bittiği mesafe, "giris_s"}
func tren_yolu() -> Dictionary:
	var rota := Baglanti.rota(durum(), bolum["giris"], bolum["cikis"], bolum["cikis_yonu"], yolcular.keys())
	var yol: RefCounted = Yol.new()
	var bas := giris_noktasi()
	yol.ekle(bas - Vector2(hucre * BASLANGIC_UZUNLUK, 0))
	yol.duz_ekle(bas)
	var giris_s: float = yol.uzunluk()
	var adim_ortalari := {}
	for adim in rota["adimlar"]:
		var h: Vector2i = adim["hucre"]
		var c := merkez(h)
		var e := c + Vector2(Baglanti.ADIM[adim["giris"]]) * hucre * 0.5
		var x := c + Vector2(Baglanti.ADIM[adim["cikis"]]) * hucre * 0.5
		var s0: float = yol.uzunluk()
		if adim["giris"] == Baglanti.ters(adim["cikis"]):
			yol.duz_ekle(x)
		else:
			var kose := c + (Vector2(Baglanti.ADIM[adim["giris"]]) + Vector2(Baglanti.ADIM[adim["cikis"]])) * hucre * 0.5
			var a0 := (e - kose).angle()
			var a1 := (x - kose).angle()
			while a1 - a0 > PI:
				a1 -= TAU
			while a1 - a0 < -PI:
				a1 += TAU
			yol.yay_ekle(kose, hucre * 0.5, a0, a1)
		if not adim_ortalari.has(h):
			adim_ortalari[h] = (s0 + yol.uzunluk()) * 0.5
	var son: float = yol.uzunluk()
	if rota["tamam"]:
		yol.duz_ekle(istasyon_noktasi() + _yon() * hucre * ISTASYON_DURAK)
	# Yolcu durakları: yolcunun yanındaki ilk rota hücresinin ortası
	var duraklar: Array = []
	for yolcu in rota["yolcular"]:
		for adim in rota["adimlar"]:
			if (yolcu - adim["hucre"]).length_squared() == 1:
				duraklar.append({"s": adim_ortalari[adim["hucre"]], "hucre": yolcu})
				break
	duraklar.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["s"] < b["s"])
	return {"yol": yol, "tamam": rota["tamam"], "duraklar": duraklar, "son": son, "giris_s": giris_s,
		"yolcu_sayisi": yolcular.size()}


# Tren yolcuyu alınca yolcu düğümü ızgaradan çıkar (tren kendine bağlar)
func yolcu_al(h: Vector2i) -> Node2D:
	var dugum: Node2D = yolcular.get(h)
	yolcular.erase(h)
	return dugum


# Kutlama: istasyondaki hayvanlar zıplar
func hayvanlar_sevinsin() -> void:
	for i in istasyon_hayvanlari.size():
		var hayvan := istasyon_hayvanlari[i]
		var y := hayvan.position.y
		var tween := hayvan.create_tween()
		tween.tween_interval(i * 0.15)
		for k in 3:
			tween.tween_property(hayvan, "position:y", y - hucre * 0.28, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(hayvan, "position:y", y, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func istasyon_merkezi() -> Vector2:
	return _istasyon_isigi.position


func _process(delta: float) -> void:
	_zaman += delta
	# Bekleyen yolcular ve perondaki hayvanlar hafifçe kıpırdar
	for dugum in yolcular.values():
		dugum.rotation = sin(_zaman * 2.2 + dugum.get_meta("faz")) * 0.06
	for dugum in istasyon_hayvanlari:
		dugum.rotation = sin(_zaman * 1.8 + dugum.get_meta("faz")) * 0.05
