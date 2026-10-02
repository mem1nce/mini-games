extends Node2D
# Uçan Kuş arka planı: gökyüzü geçişi, güneş / ay, süzülen bulutlar ve üç katmanlı kayan (parallax) manzara.
# Uzak katman yavaş, yakın katman hızlı akar. Bölge değişince gökyüzü renkleri yumuşakça geçer, eski katmanlar
# solarken yenileri belirir. Katman karoları yatayda dikişsizdir; ekran ne kadar geniş olursa olsun yan yana dizilir.

const Bolgeler := preload("res://oyunlar/ucan_kus/bolgeler.gd")
const BULUT: Texture2D = preload("res://oyunlar/ucan_kus/bulut.svg")
const TURLER := ["uzak", "orta", "yakin"]
const HIZ_ORANLARI := {"uzak": 0.06, "orta": 0.16, "yakin": 0.34}   # direk hızının bu kadarıyla kayar
const BULUT_SAYISI := 5
const CISIM_BOYU := 240.0          # güneş / ayın ekrandaki boyu (cisim_boy = 1 iken)


# Tek bir kayan katman: dokusunu yan yana döşer, alt kenarı zemin çizgisindedir
class Katman extends Node2D:
	var doku: Texture2D
	var kayma := 0.0
	var genislik := 1280.0

	func _draw() -> void:
		if doku == null:
			return
		var w := float(doku.get_width())
		var x := -fposmod(kayma, w)
		while x < genislik:
			draw_texture(doku, Vector2(x, -doku.get_height()))
			x += w


var bolge_sirasi := 0

var _ekran := Vector2(1280, 720)
var _zemin_y := 650.0
var _gok: TextureRect
var _gecis := Gradient.new()
var _cisim: Sprite2D
var _yuvalar := {}                 # tür → Node2D (içinde eski ve yeni Katman)
var _bulutlar: Node2D
var _kaymalar := {"uzak": 0.0, "orta": 0.0, "yakin": 0.0}
var _tween: Tween


func kur(ekran: Vector2, zemin_y: float, sira: int) -> void:
	_gecis.offsets = PackedFloat32Array([0.0, 1.0])
	var doku := GradientTexture2D.new()
	doku.gradient = _gecis
	doku.fill_from = Vector2(0, 0)
	doku.fill_to = Vector2(0, 1)
	doku.width = 8
	doku.height = 256
	_gok = TextureRect.new()
	_gok.texture = doku
	_gok.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gok.stretch_mode = TextureRect.STRETCH_SCALE
	_gok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gok)
	_cisim = Sprite2D.new()
	add_child(_cisim)
	_yuva_ekle("uzak")
	_bulutlar = Node2D.new()
	add_child(_bulutlar)
	_yuva_ekle("orta")
	_yuva_ekle("yakin")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in BULUT_SAYISI:
		var bulut := Sprite2D.new()
		bulut.texture = BULUT
		var boy := rng.randf_range(0.5, 0.95)
		bulut.scale = Vector2(boy, boy)
		bulut.set_meta("hiz", 10.0 + 22.0 * boy)
		bulut.set_meta("oran", rng.randf())          # yüksekliği: gökyüzünün üst kısmında
		bulut.position.x = rng.randf_range(0.0, ekran.x)
		_bulutlar.add_child(bulut)
	bolge_sirasi = sira
	yerlestir(ekran, zemin_y)
	_bolgeyi_uygula(sira)


func _yuva_ekle(tur: String) -> void:
	var yuva := Node2D.new()
	add_child(yuva)
	_yuvalar[tur] = yuva


## Ekran boyutu değişince (farklı telefon oranları) her şeyi yeniden yerleştirir
func yerlestir(ekran: Vector2, zemin_y: float) -> void:
	_ekran = ekran
	_zemin_y = zemin_y
	_gok.size = ekran
	for tur: String in TURLER:
		var yuva: Node2D = _yuvalar[tur]
		yuva.position = Vector2(0, zemin_y + 2.0)
		for katman: Katman in yuva.get_children():
			katman.genislik = ekran.x
			katman.queue_redraw()
	for bulut: Sprite2D in _bulutlar.get_children():
		bulut.position.y = lerpf(70.0, zemin_y * 0.5, bulut.get_meta("oran"))
	_cismi_yerlestir(Bolgeler.bolge(bolge_sirasi))


func _cismi_yerlestir(veri: Dictionary) -> void:
	var yer: Vector2 = veri["cisim_yer"]
	_cisim.position = Vector2(_ekran.x * yer.x, _zemin_y * yer.y)


# Geçişsiz, doğrudan kurar (oyunun başında)
func _bolgeyi_uygula(sira: int) -> void:
	var veri := Bolgeler.bolge(sira)
	_gecis.colors = PackedColorArray(veri["gok"])
	_cisim.texture = load(Bolgeler.G + veri["cisim"] + ".svg")
	_cisim.modulate = veri["cisim_renk"]
	_cisim.scale = Vector2.ONE * float(veri["cisim_boy"]) * CISIM_BOYU / _cisim.texture.get_width()
	_cismi_yerlestir(veri)
	_bulutlar.modulate = veri["bulut"]
	for tur: String in TURLER:
		for eski in _yuvalar[tur].get_children():
			eski.queue_free()
		_katman_ekle(tur, veri["ad"], 1.0)


func _katman_ekle(tur: String, ad: String, alfa: float) -> Katman:
	var katman := Katman.new()
	katman.doku = load(Bolgeler.katman_yolu(ad, tur))
	katman.kayma = _kaymalar[tur]
	katman.genislik = _ekran.x
	katman.modulate.a = alfa
	_yuvalar[tur].add_child(katman)
	return katman


## Yeni bölgeye yumuşak geçiş: gökyüzü renkleri kayar, eski katmanlar solar, yenileri belirir
func bolge_ayarla(sira: int, sure: float) -> void:
	if posmod(sira, Bolgeler.BOLGELER.size()) == posmod(bolge_sirasi, Bolgeler.BOLGELER.size()):
		bolge_sirasi = sira
		return
	var eski := Bolgeler.bolge(bolge_sirasi)
	var yeni := Bolgeler.bolge(sira)
	bolge_sirasi = sira
	if _tween and _tween.is_valid():
		_tween.kill()
		_bolgeyi_uygula(sira)       # önceki geçiş yarım kaldıysa temiz başla
		return
	_tween = create_tween().set_parallel()
	_tween.tween_method(_gok_karistir.bind(eski["gok"], yeni["gok"]), 0.0, 1.0, sure).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_bulutlar, "modulate", yeni["bulut"], sure)
	for tur: String in TURLER:
		for katman in _yuvalar[tur].get_children():
			_tween.tween_property(katman, "modulate:a", 0.0, sure)
			_tween.tween_callback(katman.queue_free).set_delay(sure)
		_tween.tween_property(_katman_ekle(tur, yeni["ad"], 0.0), "modulate:a", 1.0, sure)
	# Güneş / ay: eskisi sönüp yenisi yeni yerinde belirir
	var yarim := sure / 2.0
	_tween.tween_property(_cisim, "modulate:a", 0.0, yarim)
	_tween.tween_callback(_cismi_degistir.bind(yeni)).set_delay(yarim)
	_tween.tween_property(_cisim, "modulate", yeni["cisim_renk"], yarim).set_delay(yarim)


func _cismi_degistir(veri: Dictionary) -> void:
	_cisim.texture = load(Bolgeler.G + veri["cisim"] + ".svg")
	_cisim.scale = Vector2.ONE * float(veri["cisim_boy"]) * CISIM_BOYU / _cisim.texture.get_width()
	var renk: Color = veri["cisim_renk"]
	_cisim.modulate = Color(renk.r, renk.g, renk.b, 0.0)
	_cismi_yerlestir(veri)


func _gok_karistir(t: float, eski: Array, yeni: Array) -> void:
	_gecis.colors = PackedColorArray([(eski[0] as Color).lerp(yeni[0], t), (eski[1] as Color).lerp(yeni[1], t)])


## Direklerin kaydığı mesafe kadar (px) katmanları kendi oranlarıyla kaydırır; bulutlar ayrıca kendi hızıyla süzülür
func kaydir(mesafe: float, delta: float) -> void:
	for tur: String in TURLER:
		_kaymalar[tur] += mesafe * float(HIZ_ORANLARI[tur])
		for katman: Katman in _yuvalar[tur].get_children():
			katman.kayma = _kaymalar[tur]
			katman.queue_redraw()
	for bulut: Sprite2D in _bulutlar.get_children():
		bulut.position.x -= float(bulut.get_meta("hiz")) * delta + mesafe * 0.04
		if bulut.position.x < -160.0:
			bulut.position.x = _ekran.x + 160.0
			bulut.set_meta("oran", randf())
			bulut.position.y = lerpf(70.0, _zemin_y * 0.5, bulut.get_meta("oran"))
