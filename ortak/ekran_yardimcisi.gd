extends Node
# Autoload "EkranYardimcisi": ekran boyutu ve güvenli alan bilgisi (bütün telefon / tablet oranları için).
#
# Ölçekleme canvas_items + expand: tasarım alanı (yatay 1280x720, dikey 720x1280) her cihazda aynı boyutta
# görünür; ekran daha geniş ya da daha uzunsa görünen alan büyür, artan yeri arka plan doldurur (siyah şerit yok).
#
#   EkranYardimcisi.gorunen_boyut()      görünen alanın gerçek boyutu (ör. 20:9 telefonda 1600x720, 4:3 tablette 1280x960)
#   EkranYardimcisi.tasarim_alani()      görünen alanın ortasındaki tasarım alanı (Rect2): oynanış bunun içinde kalmalı
#   EkranYardimcisi.guvenli_alan()       çentik, kamera deliği, yuvarlak köşe ve hareket çubuğu dışında kalan alan (Rect2)
#   EkranYardimcisi.guvenli_bosluklar()  aynı bilginin kenar boşlukları: {"sol", "ust", "sag", "alt"} (tasarım pikseli)
#   EkranYardimcisi.ekran_degisti        ekran boyutu ya da güvenli alan değişince (döndürme, pencere boyutu)
#   EkranYardimcisi.guvenliye_it(oge)    konumu kodla verilmiş bir düğmeyi / göstergeyi güvenli alanın içine iter
#   EkranYardimcisi.guvenliye_it_grup([a, b])  yan yana duran öğeleri aralarındaki düzeni bozmadan birlikte iter
#   EkranYardimcisi.kenar_payi(SIDE_LEFT, 40)  düzen hesaplarında kullanılacak kenar payı (boşluk büyükse o)
#   EkranYardimcisi.guvenli_nokta(p, r)  Node2D ile çizilen düğmeler için: merkezi güvenli alanın içine alınmış nokta
#
# Arka planlar gorunen_boyut()'u kaplar; düğmeler ve göstergeler guvenli_alan()'ın içinde durur (en kolayı:
# ortak/arayuz_koku.tscn içine koymak). Sabit 1280 / 720 yazma.

signal ekran_degisti

const YATAY_TASARIM := Vector2(1280, 720)
const DIKEY_TASARIM := Vector2(720, 1280)

## Deneme için elle verilen güvenli alan boşlukları (tasarım pikseli; sol, üst, sağ, alt). Bilgisayarda çentikli
## telefonu taklit etmek için: EkranYardimcisi.deneme_bosluklari = Vector4(90, 0, 0, 30). Vector4.ZERO = kapalı.
var deneme_bosluklari := Vector4.ZERO:
	set(deger):
		deneme_bosluklari = deger
		_degisti()

var _son_boyut := Vector2.ZERO
var _son_bosluklar := Vector4.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.size_changed.connect(_degisti)
	_son_boyut = gorunen_boyut()
	_son_bosluklar = _bosluklari_olc()


func gorunen_boyut() -> Vector2:
	return get_tree().root.get_visible_rect().size


func gorunen_alan() -> Rect2:
	return Rect2(Vector2.ZERO, gorunen_boyut())


## Tasarım çözünürlüğü: sahnenin yönüne göre 1280x720 ya da 720x1280
func tasarim_boyutu() -> Vector2:
	var boyut := Vector2(get_tree().root.content_scale_size)
	if boyut.x <= 0.0 or boyut.y <= 0.0:
		return YATAY_TASARIM
	return boyut


## Görünen alanın ortasındaki tasarım alanı. Oynanış için gereken her şey bunun içinde olmalı.
func tasarim_alani() -> Rect2:
	var tasarim := tasarim_boyutu()
	return Rect2(((gorunen_boyut() - tasarim) / 2.0).max(Vector2.ZERO), tasarim)


## Güvenli alan boşlukları (tasarım pikseli)
func guvenli_bosluklar() -> Dictionary:
	var b := _bosluklari_olc()
	return {"sol": b.x, "ust": b.y, "sag": b.z, "alt": b.w}


## Çentik, kamera deliği, yuvarlak köşeler ve alttaki hareket çubuğu dışında kalan alan
func guvenli_alan() -> Rect2:
	var b := _bosluklari_olc()
	var boyut := gorunen_boyut()
	return Rect2(b.x, b.y, maxf(boyut.x - b.x - b.z, 1.0), maxf(boyut.y - b.y - b.w, 1.0))


## Konumu kodla verilmiş arayüz öğesini güvenli alanın içine iter: çentiğin, yuvarlak köşenin ya da hareket
## çubuğunun altında kalıyorsa en az kaydırmayla içeri alır; zaten içerideyse (ya da cihazda boşluk yoksa) dokunmaz.
## Öğeyi yerleştirdikten sonra çağır; ekran değişince yeniden yerleştiriyorsan yine çağır. pay: boşluğun kenarından
## bırakılacak ek mesafe.
func guvenliye_it(oge: Control, pay := 8.0) -> void:
	guvenliye_it_grup([oge], pay)


## Yan yana duran öğeleri (ör. sağ üst köşedeki düğmeler, geri düğmesi + yanındaki sayaç) aralarındaki düzeni
## bozmadan birlikte güvenli alana iter: kayma hepsini saran kutuya göre hesaplanır ve hepsine aynen uygulanır.
func guvenliye_it_grup(ogeler: Array, pay := 8.0) -> void:
	var gecerli: Array[Control] = []
	var kutu := Rect2()
	for oge in ogeler:
		var c := oge as Control
		if c == null or not is_instance_valid(c) or not c.is_inside_tree():
			continue
		kutu = _kutu(c) if gecerli.is_empty() else kutu.merge(_kutu(c))
		gecerli.append(c)
	if gecerli.is_empty():
		return
	var kayma := _kayma(kutu, pay)
	if kayma == Vector2.ZERO:
		return
	for c in gecerli:
		c.position += _ust_donusum(c).affine_inverse().basis_xform(kayma)


## Kenarlardan "kenar" kadar içeride duran bir düzen için kenar payları: güvenli alan boşluğu daha büyükse o
## kullanılır. Ör. var sol := EkranYardimcisi.kenar_payi(SIDE_LEFT, 40.0)
func kenar_payi(kenar: Side, en_az := 0.0, pay := 8.0) -> float:
	var b := _bosluklari_olc()
	var bosluk: float = [b.x, b.y, b.z, b.w][kenar]
	return maxf(en_az, bosluk + pay) if bosluk > 0.0 else en_az


## Merkezi "nokta", yarıçapı "yaricap" olan bir şeklin (Node2D ile çizilen düğme) güvenli alana alınmış merkezi
func guvenli_nokta(nokta: Vector2, yaricap := 0.0, pay := 8.0) -> Vector2:
	var kutu := Rect2(nokta - Vector2(yaricap, yaricap), Vector2(yaricap, yaricap) * 2.0)
	return nokta + _kayma(kutu, pay)


# Öğenin ekrandaki kutusu. Kendi ölçeği (basma / belirme animasyonu) hesaba katılmaz.
func _kutu(oge: Control) -> Rect2:
	return _ust_donusum(oge) * Rect2(oge.position, oge.size)


func _ust_donusum(oge: Control) -> Transform2D:
	var ust := oge.get_parent() as CanvasItem
	return ust.get_global_transform() if ust else Transform2D.IDENTITY


# Bir dikdörtgeni güvenli alana sokmak için gereken en küçük kayma. Yalnızca boşluğu olan kenarlar sınır koyar.
func _kayma(kutu: Rect2, pay: float) -> Vector2:
	var b := _bosluklari_olc()
	if b == Vector4.ZERO:
		return Vector2.ZERO
	var boyut := gorunen_boyut()
	var kayma := Vector2.ZERO
	if b.x > 0.0 and kutu.position.x < b.x + pay:
		kayma.x = b.x + pay - kutu.position.x
	elif b.z > 0.0 and kutu.end.x > boyut.x - b.z - pay:
		kayma.x = boyut.x - b.z - pay - kutu.end.x
	if b.y > 0.0 and kutu.position.y < b.y + pay:
		kayma.y = b.y + pay - kutu.position.y
	elif b.w > 0.0 and kutu.end.y > boyut.y - b.w - pay:
		kayma.y = boyut.y - b.w - pay - kutu.end.y
	return kayma


# Boşluklar (sol, üst, sağ, alt). Cihaz pikselinden tasarım pikseline çevrilir.
func _bosluklari_olc() -> Vector4:
	if deneme_bosluklari != Vector4.ZERO:
		return deneme_bosluklari
	# Bilgisayarda get_display_safe_area görev çubuğu dışındaki masaüstünü verir; pencereli testte anlamı yok
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var pencere := get_tree().root
	var boyut := Vector2(pencere.size)
	if boyut.x <= 0.0 or boyut.y <= 0.0:
		return Vector4.ZERO
	var guvenli := Rect2(DisplayServer.get_display_safe_area())
	if guvenli.size.x <= 0.0 or guvenli.size.y <= 0.0:
		return Vector4.ZERO
	var konum := Vector2(pencere.position)
	var olcek := gorunen_boyut() / boyut           # cihaz pikseli → tasarım pikseli
	var sol := maxf(guvenli.position.x - konum.x, 0.0) * olcek.x
	var ust := maxf(guvenli.position.y - konum.y, 0.0) * olcek.y
	var sag := maxf(konum.x + boyut.x - guvenli.end.x, 0.0) * olcek.x
	var alt := maxf(konum.y + boyut.y - guvenli.end.y, 0.0) * olcek.y
	# Yatayda telefon iki yöne de çevrilebilir (çentik solda ya da sağda): iki yana aynı boşluk verilir, böylece
	# düzen ortada kalır ve telefon ters çevrilince hiçbir şey yer değiştirmez
	if boyut.x > boyut.y:
		sol = maxf(sol, sag)
		sag = sol
	# Akıl dışı değerlere karşı: boşluk ekranın çeyreğini geçmesin
	var b := gorunen_boyut()
	return Vector4(minf(sol, b.x * 0.25), minf(ust, b.y * 0.25), minf(sag, b.x * 0.25), minf(alt, b.y * 0.25))


func _degisti() -> void:
	if not is_inside_tree():
		return
	var boyut := gorunen_boyut()
	var bosluklar := _bosluklari_olc()
	if boyut == _son_boyut and bosluklar == _son_bosluklar:
		return
	_son_boyut = boyut
	_son_bosluklar = bosluklar
	ekran_degisti.emit()
