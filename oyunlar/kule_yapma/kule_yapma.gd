extends Node2D
# Kule Yapma (Hayvan Apartmanı) ana sahnesi (dikey). Ekranlar: giriş (oynat, apartmanlarım), oyun, galeri, apartman.
# Oyunda: dokununca vinçteki kat bırakılır, tween'le düşer; kulenin üstüne denk gelirse mıknatısla ortaya kayıp oturur,
# ıskalarsa yere düşüp zıplar ve kaybolur. Fizik motoru yok. Tasarım TASARIM.md'de, notlar CLAUDE.md'de.

## Ekran yönü: SahneGecis bu oyuna geçerken ekranı buna göre döndürür.
@export_enum("dikey", "yatay") var ekran_yonu: String = "dikey"
## Düşme ivmesi (px/sn²); büyük = daha hızlı düşer
@export var yercekimi: float = 2600.0
## Bölüm sonu panelinde dokunulmazsa kendiliğinden devam etme süresi (sn)
@export var devam_suresi: float = 8.0

const Bolumler := preload("res://oyunlar/kule_yapma/bolumler.gd")
const Kayit := preload("res://oyunlar/kule_yapma/kayit.gd")
const Blok := preload("res://oyunlar/kule_yapma/blok.gd")
const Kule := preload("res://oyunlar/kule_yapma/kule.gd")
const Vinc := preload("res://oyunlar/kule_yapma/vinc.gd")
const Kamera := preload("res://oyunlar/kule_yapma/kamera.gd")
const Manzara := preload("res://oyunlar/kule_yapma/manzara.gd")
const Apartman := preload("res://oyunlar/kule_yapma/apartman.gd")
const Galeri := preload("res://oyunlar/kule_yapma/galeri.gd")
const Efektler := preload("res://oyunlar/kule_yapma/efektler.gd")
const Sesler := preload("res://oyunlar/kule_yapma/sesler.gd")
const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")
const G := "res://oyunlar/kule_yapma/gorseller/"
const SOZLER := ["Harika!", "Süper!", "Tebrikler!"]
const HARF_RENKLERI := [Color("ff5a6e"), Color("ff9f40"), Color("ffc93d"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

enum Durum { GIRIS, OYUN, KUTLAMA, SONU, GALERI, APARTMAN }

var kayit := Kayit.new()
var durum := Durum.GIRIS
var level: Dictionary = {}
var kule: Node2D
var vinc: Node2D
var kamera: Camera2D
var manzara: Node2D
var efektler: Node2D

var _ekran := Vector2(720, 1280)
var _zemin_y := 1180.0
var _sesler: Node
var _dunya: Node2D
var _dusenler: Node2D
var _zemin: Sprite2D
var _ui: Control
var _geri: Control
var _geri_parmak := -1
var _duraklat: Control
var _perde: Control
var _devam: Control
var _cubuk: Control
var _cubuk_ikon: TextureRect
var _tac: TextureRect
var _giris: Control
var _oynat: Control
var _galeri_dugme: Control
var _sonu: Control
var _sonu_apartman: Control
var _sonu_devam: Control
var _galeri: Control
var _apartman: Control
var _apartman_donus := Durum.GIRIS
var _son_apartman: Dictionary = {}
var _duraklatildi := false
var _kombo := 0
var _son_tasarim := ""
var _son_hayvan := ""
var _rekor_asildi := false
var _oturum := 0
var _sonu_sayac := 0.0
var _parmak := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_ekran = get_viewport_rect().size
	_zemin_y = _ekran.y - 100.0
	for hata in Bolumler.validate():
		push_error("Kule Yapma: " + hata)
	kayit.yukle()
	_sesler = Sesler.new()
	add_child(_sesler)
	var arka := CanvasLayer.new()
	arka.layer = -10
	add_child(arka)
	manzara = Manzara.new()
	manzara.process_mode = Node.PROCESS_MODE_PAUSABLE
	arka.add_child(manzara)
	manzara.kur(_ekran, _zemin_y)
	_dunya = Node2D.new()
	_dunya.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_dunya)
	_zemin = Sprite2D.new()
	_zemin.centered = false
	_dunya.add_child(_zemin)
	kule = Kule.new()
	kule.position = Vector2(_ekran.x * 0.5, _zemin_y)
	_dunya.add_child(kule)
	_dusenler = Node2D.new()
	_dunya.add_child(_dusenler)
	efektler = Efektler.new()
	_dunya.add_child(efektler)
	vinc = Vinc.new()
	_dunya.add_child(vinc)
	vinc.kur(_ekran.x)
	kamera = Kamera.new()
	_dunya.add_child(kamera)
	kamera.kur(_ekran)
	kamera.make_current()
	_arayuzu_kur()
	_bolumu_hazirla()
	_giris_ekrani()


# --- Arayüz ---

func _arayuzu_kur() -> void:
	var katman := CanvasLayer.new()
	katman.layer = 5
	add_child(katman)
	_ui = Control.new()
	_ui.size = _ekran
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	katman.add_child(_ui)
	_cubuk = Control.new()
	_cubuk.position = Vector2(_ekran.x - 66.0, 300.0)
	_cubuk.size = Vector2(40.0, 520.0)
	_cubuk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cubuk.draw.connect(_cubugu_ciz)
	_ui.add_child(_cubuk)
	_cubuk_ikon = _doku_dugmesi(G + "kule_ikon.svg", Rect2(-14, -86, 68, 85))
	_cubuk.add_child(_cubuk_ikon)
	_tac = _doku_dugmesi(G + "tac.svg", Rect2(-22, 0, 44, 35))
	_cubuk.add_child(_tac)
	_duraklat = _yuvarlak_dugme(load(G + "duraklat.svg"), 104.0)
	_duraklat.position = Vector2(_ekran.x - 140.0, 24.0)
	_ui.add_child(_duraklat)
	# Giriş: büyük oynat ve apartmanlarım
	_giris = Control.new()
	_giris.size = _ekran
	_giris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_giris)
	_oynat = _yuvarlak_dugme(load(G + "oynat.svg"), 200.0)
	_oynat.position = Vector2(_ekran.x * 0.5 - 100.0, _ekran.y * 0.36)
	_giris.add_child(_oynat)
	_galeri_dugme = _yuvarlak_dugme(load(G + "apartman.svg"), 140.0)
	_galeri_dugme.position = Vector2(_ekran.x * 0.5 - 70.0, _ekran.y * 0.36 + 230.0)
	_giris.add_child(_galeri_dugme)
	# Bölüm sonu: apartmanım ya da devam
	_sonu = Control.new()
	_sonu.size = _ekran
	_sonu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sonu.visible = false
	_ui.add_child(_sonu)
	_sonu_apartman = _yuvarlak_dugme(load(G + "apartman.svg"), 150.0)
	_sonu_apartman.position = Vector2(_ekran.x * 0.5 - 180.0, _ekran.y * 0.3)
	_sonu.add_child(_sonu_apartman)
	_sonu_devam = _yuvarlak_dugme(load(G + "oynat.svg"), 150.0)
	_sonu_devam.position = Vector2(_ekran.x * 0.5 + 30.0, _ekran.y * 0.3)
	_sonu.add_child(_sonu_devam)
	# Duraklatma perdesi
	_perde = Control.new()
	_perde.size = _ekran
	_perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var karart := ColorRect.new()
	karart.color = Color(0.1, 0.1, 0.25, 0.45)
	karart.size = _ekran
	karart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_perde.add_child(karart)
	_devam = _yuvarlak_dugme(load(G + "oynat.svg"), 190.0)
	_devam.position = _ekran * 0.5 - _devam.size * 0.5
	_perde.add_child(_devam)
	_perde.visible = false
	_ui.add_child(_perde)
	var ust := CanvasLayer.new()
	ust.layer = 10
	add_child(ust)
	_galeri = Galeri.new()
	_galeri.sesler = _sesler
	_galeri.sec.connect(_galeriden_sec)
	_galeri.kapandi.connect(_giris_ekrani)
	ust.add_child(_galeri)
	_apartman = Apartman.new()
	_apartman.sesler = _sesler
	_apartman.kapandi.connect(_apartmandan_don)
	ust.add_child(_apartman)


func _doku_dugmesi(dosya: String, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(dosya)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _yuvarlak_dugme(simge: Texture2D, cap: float) -> Control:
	var dugme := Control.new()
	dugme.size = Vector2(cap, cap)
	dugme.pivot_offset = dugme.size / 2.0
	dugme.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dugme.draw.connect(func() -> void:
		var c := dugme.size / 2.0
		var r := cap / 2.0 - 5.0
		dugme.draw_circle(c + Vector2(0, 6), r, Color(0.1, 0.1, 0.3, 0.2))
		dugme.draw_circle(c, r, Color(1, 1, 1, 0.96))
		dugme.draw_arc(c, r, 0.0, TAU, 48, Color(0.23, 0.18, 0.42), 5.0, true)
		dugme.draw_texture_rect(simge, Rect2(c - Vector2(r, r) * 0.7, Vector2(r, r) * 1.4), false))
	return dugme


func _geri_dugmesi_kur() -> void:
	if _geri:
		_geri.queue_free()
	_geri = HoldButton.new()
	_geri.size = Vector2(104, 104)
	_geri.position = Vector2(36, 24)
	_geri.hold_time = 0.8
	_geri.completed.connect(_geri_basildi)
	_ui.add_child(_geri)
	_geri_parmak = -1


# Sağ kenardaki hedef çubuğu: tepede kule simgesi, dolan çubuk; sonsuz modda taç rekoru gösterir
func _cubugu_ciz() -> void:
	var r := Rect2(Vector2.ZERO, _cubuk.size)
	var zemin := StyleBoxFlat.new()
	zemin.bg_color = Color(1, 1, 1, 0.7)
	zemin.set_corner_radius_all(20)
	zemin.set_border_width_all(4)
	zemin.border_color = Color(0.23, 0.18, 0.42)
	_cubuk.draw_style_box(zemin, r)
	var sayi: int = kule.sayi() if kule else 0
	var hedef := int(level.get("hedef", 0))
	var ust := float(hedef) if hedef > 0 else float(maxi(maxi(kayit.rekor, sayi), 4)) + 2.0
	var oran := clampf(sayi / ust, 0.0, 1.0)
	if oran > 0.0:
		var dolgu := StyleBoxFlat.new()
		dolgu.bg_color = Color("ffb347")
		dolgu.set_corner_radius_all(14)
		var yuk := (r.size.y - 12.0) * oran
		_cubuk.draw_style_box(dolgu, Rect2(6, r.size.y - 6.0 - yuk, r.size.x - 12.0, yuk))
	_tac.visible = hedef == 0 and kayit.rekor > 0
	if _tac.visible:
		_tac.position.y = r.size.y - 6.0 - (r.size.y - 12.0) * clampf(kayit.rekor / ust, 0.0, 1.0) - 17.0


# --- Ekranlar ---

func _giris_ekrani() -> void:
	_oturum += 1
	durum = Durum.GIRIS
	_giris.visible = true
	_sonu.visible = false
	_duraklat.visible = false
	_cubuk.visible = false
	_bolumu_hazirla()
	_geri_dugmesi_kur()
	_oynat.scale = Vector2(0.6, 0.6)
	_oynat.create_tween().tween_property(_oynat, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Bölümün sahnesi (zemin, zemin kat, kamera) oyun başlamadan kurulur; giriş ekranı arkasında görünür
func _bolumu_hazirla() -> void:
	level = Bolumler.level(kayit.bolum)
	for c in _dusenler.get_children():
		c.queue_free()
	if vinc.asili:
		vinc.asili.queue_free()
		vinc.asili = null
		vinc.hazir = false
	_zemin.texture = load(G + "manzara/zemin_%s.svg" % level["tema"])
	_zemin.scale = Vector2.ONE * 900.0 / _zemin.texture.get_width()
	_zemin.position = Vector2(_ekran.x * 0.5 - 450.0, _zemin_y - 20.0)
	kule.kur(_hayvan_sec())
	kamera.sifirla()
	vinc.hiz = level["hiz"]
	vinc.aci = level["aci"]
	vinc.dikey = level["dikey"]
	_kombo = 0
	_rekor_asildi = false
	_cubuk.queue_redraw()


func _oyunu_baslat() -> void:
	_oturum += 1
	durum = Durum.OYUN
	_giris.visible = false
	_sonu.visible = false
	_duraklat.visible = true
	_cubuk.visible = true
	_geri_dugmesi_kur()
	_yeni_kat()


func _geri_basildi() -> void:
	match durum:
		Durum.GIRIS:
			SahneGecis.ana_menuye_don()
		_:
			_sonsuzu_kaydet()
			get_tree().paused = false
			_duraklatildi = false
			_perde.visible = false
			_giris_ekrani()


# Sonsuz modda çıkarken kule apartmanlara eklenir
func _sonsuzu_kaydet() -> void:
	if Bolumler.sonsuz_mu(kayit.bolum) and durum == Durum.OYUN and kule.sayi() >= 3:
		kayit.apartman_ekle(kule.veri(level["tema"]))
		kayit.kaydet()


func _galeriden_sec(index: int) -> void:
	_apartman_donus = Durum.GALERI
	durum = Durum.APARTMAN
	_galeri.kapat(false)
	_apartman.ac(kayit.apartmanlar[index], _ekran)


func _apartmandan_don() -> void:
	if _apartman_donus == Durum.GALERI:
		durum = Durum.GALERI
		_galeri.ac(kayit.apartmanlar, _ekran)
	else:
		durum = Durum.SONU
		_sonu.visible = true
		_sonu_sayac = devam_suresi


# --- Dokunma ---

func _input(event: InputEvent) -> void:
	var dokunma := event as InputEventScreenTouch
	var surukleme := event as InputEventScreenDrag
	if surukleme:
		if surukleme.index == _parmak:
			if durum == Durum.GALERI:
				_galeri.surukle(surukleme.position)
			elif durum == Durum.APARTMAN:
				_apartman.surukle(surukleme.position)
		return
	if dokunma == null:
		return
	if not dokunma.pressed:
		if dokunma.index == _geri_parmak:
			_geri.release()
			_geri_parmak = -1
		if dokunma.index == _parmak:
			_parmak = -1
			if durum == Durum.GALERI:
				_galeri.birak(dokunma.position)
			elif durum == Durum.APARTMAN:
				_apartman.birak(dokunma.position)
		return
	if SahneGecis.gecis_suruyor:
		return
	var p := dokunma.position
	match durum:
		Durum.GALERI:
			_parmak = dokunma.index
			_galeri.dokun(p)
			return
		Durum.APARTMAN:
			_parmak = dokunma.index
			_apartman.dokun(p)
			return
	if _geri.contains(p):
		_geri_parmak = dokunma.index
		_geri.press()
		return
	match durum:
		Durum.GIRIS:
			if _oynat.get_global_rect().has_point(p):
				_sicrat(_oynat)
				_sesler.play("dokun")
				_oyunu_baslat()
			elif _galeri_dugme.get_global_rect().has_point(p):
				_sicrat(_galeri_dugme)
				_sesler.play("dokun")
				durum = Durum.GALERI
				_giris.visible = false
				_galeri.ac(kayit.apartmanlar, _ekran)
		Durum.SONU:
			if _sonu_apartman.get_global_rect().has_point(p):
				_sicrat(_sonu_apartman)
				_sesler.play("dokun")
				_apartman_donus = Durum.SONU
				durum = Durum.APARTMAN
				_sonu.visible = false
				_apartman.ac(_son_apartman, _ekran)
			elif _sonu_devam.get_global_rect().has_point(p):
				_sicrat(_sonu_devam)
				_sesler.play("dokun")
				_sonraki_bolum()
		Durum.OYUN:
			if _duraklatildi:
				if _devam.get_global_rect().has_point(p):
					_duraklat_ayarla(false)
				return
			if _duraklat.get_global_rect().grow(8.0).has_point(p):
				_sicrat(_duraklat)
				_sesler.play("dokun")
				_duraklat_ayarla(true)
				return
			_birak()


func _sicrat(kontrol: Control) -> void:
	var tween := kontrol.create_tween()
	tween.tween_property(kontrol, "scale", Vector2(0.9, 0.9), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(kontrol, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _duraklat_ayarla(deger: bool) -> void:
	_duraklatildi = deger
	get_tree().paused = deger
	_perde.visible = deger
	_duraklat.visible = not deger


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _perde and durum == Durum.OYUN and not _duraklatildi:
		_duraklat_ayarla(true)


# --- Katlar ---

func _hayvan_sec() -> String:
	var secenek := Blok.HAYVANLAR.filter(func(h: String) -> bool: return h != _son_hayvan)
	_son_hayvan = secenek[randi() % secenek.size()]
	return _son_hayvan


func _tasarim_sec() -> String:
	var hedef := int(level["hedef"])
	if hedef > 0 and kule.sayi() == hedef - 1:
		return "cati"
	var secenek := Blok.TASARIMLAR.filter(func(t: String) -> bool:
		return t != _son_tasarim and (t != "yildizli" or kule.sayi() >= 12))
	_son_tasarim = secenek[randi() % secenek.size()]
	return _son_tasarim


func _yeni_kat() -> void:
	var blok: Node2D = Blok.new()
	blok.kur(_tasarim_sec(), _hayvan_sec())
	vinc.kat_as(blok)


func _birak() -> void:
	var blok: Node2D = vinc.birak(_dusenler)
	if blok == null:
		return
	var oturum := _oturum
	_sesler.play("birak")
	var ust: Vector2 = kule.tepe()
	var hedef_y: float = ust.y - blok.yukseklik() * 0.5
	var mesafe := maxf(10.0, hedef_y - blok.global_position.y)
	var sure := sqrt(2.0 * mesafe / yercekimi)
	var tween := blok.create_tween().set_parallel()
	tween.tween_property(blok, "global_position:y", hedef_y, sure).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(blok, "rotation", 0.0, sure).set_trans(Tween.TRANS_SINE)
	await tween.finished
	if oturum != _oturum:
		return
	var karar: String = kule.karar(blok.global_position.x, level["tolerans"], blok.genislik())
	if karar == "iska":
		_iska(blok)
		_kombo = 0
		await get_tree().create_timer(0.55, false).timeout
		if oturum == _oturum and durum == Durum.OYUN:
			_yeni_kat()
		return
	await _otur(blok, karar == "mukemmel")
	if oturum != _oturum:
		return
	var hedef := int(level["hedef"])
	if hedef > 0 and kule.sayi() >= hedef:
		_bolum_bitti()
		return
	if hedef == 0 and kule.sayi() > kayit.rekor:
		_rekor_kir()
	await get_tree().create_timer(0.3, false).timeout
	if oturum == _oturum and durum == Durum.OYUN:
		_yeni_kat()


# Mıknatıs: kat yumuşakça ortaya kayar, oturur, esner; hayvanlar taşınır
func _otur(blok: Node2D, mukemmel: bool) -> void:
	var tepe: Vector2 = kule.tepe()
	var hedef := tepe + Vector2(0, -blok.yukseklik() * 0.5)
	var tween := blok.create_tween()
	tween.tween_property(blok, "global_position", hedef, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	kule.yerlestir(blok)
	_sesler.play("otur")
	efektler.toz(tepe, blok.genislik())
	blok.tasin()
	get_tree().create_timer(0.2, false).timeout.connect(func() -> void: _sesler.play("tasin"))
	_cubuk.queue_redraw()
	if mukemmel:
		_kombo += 1
		_mukemmel(tepe + Vector2(0, -blok.yukseklik() * 0.5))
	else:
		_kombo = 0


# Mükemmel: parıltı, ışık halkası ve yazı; art arda mükemmellerde kombo (daha çok yıldız, daha büyük halka)
func _mukemmel(yer: Vector2) -> void:
	_sesler.play("kombo" if _kombo >= 2 else "mukemmel", 1.0 + minf(_kombo - 1, 5) * 0.06)
	efektler.parilti(yer, Color("fff6b0"), 12 + _kombo * 4, 70.0)
	efektler.halka(yer, 300.0 + minf(_kombo, 5) * 60.0)
	if _kombo >= 2:
		efektler.yildizlar(yer, mini(3 + _kombo * 2, 14))
		efektler.halka(yer, 420.0 + minf(_kombo, 5) * 60.0, Color("ffc2e0"))
	var ekran_yeri: Vector2 = yer - kamera.sol_ust()
	var yazi := Label.new()
	yazi.text = "Mükemmel!"
	yazi.theme_type_variation = &"Baslik"
	var ayar := LabelSettings.new()
	ayar.font = yazi.get_theme_font("font", &"Baslik")
	ayar.font_size = 58 + mini(_kombo, 5) * 6
	ayar.font_color = Color("ffb020") if _kombo < 2 else Color("ff6fa8")
	ayar.outline_size = 14
	ayar.outline_color = Color.WHITE
	yazi.label_settings = ayar
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yazi.size = Vector2(_ekran.x, 90)
	yazi.position = Vector2(0, ekran_yeri.y - 150.0)
	yazi.pivot_offset = yazi.size * 0.5
	yazi.scale = Vector2.ZERO
	yazi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(yazi)
	var tween := yazi.create_tween()
	tween.tween_property(yazi, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(yazi, "position:y", yazi.position.y - 50.0, 0.7).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(yazi, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(yazi.queue_free)


# Iska: kulenin yanından düşer; yer yakınsa sevimlice zıplar, "puf" diye kaybolur
func _iska(blok: Node2D) -> void:
	_sesler.play("iska")
	var tepe: Vector2 = kule.tepe()
	var yon := signf(blok.global_position.x - tepe.x)
	if yon == 0.0:
		yon = 1.0
	var yan: float = tepe.x + yon * (blok.genislik() + 30.0)
	var yer_y: float = _zemin_y - blok.yukseklik() * 0.5 + 10.0
	var uzak: bool = yer_y - blok.global_position.y > 900.0
	var hedef_y: float = blok.global_position.y + 700.0 if uzak else yer_y
	var sure: float = sqrt(2.0 * maxf(20.0, hedef_y - blok.global_position.y) / yercekimi)
	var tween := blok.create_tween()
	tween.tween_property(blok, "global_position:x", yan, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(blok, "global_position:y", hedef_y, sure).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(blok, "rotation", yon * 0.5, sure)
	if uzak:
		tween.parallel().tween_property(blok, "modulate:a", 0.0, sure)
	else:
		tween.tween_property(blok, "global_position:y", hedef_y - 60.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(blok, "rotation", yon * 0.2, 0.18)
		tween.tween_property(blok, "global_position:y", hedef_y, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void:
			efektler.puf(blok.global_position)
			_sesler.play("puf"))
		tween.tween_property(blok, "scale", Vector2(1.2, 0.2), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(blok, "modulate:a", 0.0, 0.18)
	tween.tween_callback(blok.queue_free)


func _rekor_kir() -> void:
	kayit.rekor = kule.sayi()
	kayit.kaydet()
	_cubuk.queue_redraw()
	if not _rekor_asildi:
		_rekor_asildi = true
		_sesler.play("rekor")
		efektler.yildizlar(kule.tepe(), 10)
		_sicrat(_cubuk)


# --- Bölüm sonu ---

func _bolum_bitti() -> void:
	durum = Durum.KUTLAMA
	var oturum := _oturum
	kule.kutla()
	_sesler.play("kutlama")
	efektler.konfeti(kamera.sol_ust() + Vector2(_ekran.x * 0.5, _ekran.y + 20.0), _ekran.x * 0.9)
	_soz()
	_son_apartman = kule.veri(level["tema"])
	kayit.apartman_ekle(_son_apartman)
	kayit.bolum += 1
	kayit.kaydet()
	await get_tree().create_timer(3.0, false).timeout
	if oturum != _oturum:
		return
	durum = Durum.SONU
	_sonu.visible = true
	_sonu_sayac = devam_suresi
	for d in [_sonu_apartman, _sonu_devam]:
		d.scale = Vector2(0.5, 0.5)
		d.create_tween().tween_property(d, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _sonraki_bolum() -> void:
	if durum != Durum.SONU:
		return
	durum = Durum.KUTLAMA
	_sonu.visible = false
	var tween := create_tween()
	tween.tween_property(_dunya, "modulate:a", 0.0, 0.3)
	await tween.finished
	_bolumu_hazirla()
	create_tween().tween_property(_dunya, "modulate:a", 1.0, 0.3)
	_oyunu_baslat()


func _soz() -> void:
	var soz: String = SOZLER.pick_random()
	var satir := HBoxContainer.new()
	satir.alignment = BoxContainer.ALIGNMENT_CENTER
	satir.add_theme_constant_override("separation", 2)
	satir.size = Vector2(_ekran.x, 130)
	satir.position = Vector2(0, _ekran.y * 0.32)
	satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(satir)
	for i in soz.length():
		var harf := Label.new()
		harf.text = soz[i]
		harf.theme_type_variation = &"Baslik"
		var ayar := LabelSettings.new()
		ayar.font = harf.get_theme_font("font", &"Baslik")
		ayar.font_size = 92
		ayar.font_color = HARF_RENKLERI[i % HARF_RENKLERI.size()]
		ayar.outline_size = 18
		ayar.outline_color = Color.WHITE
		ayar.shadow_size = 6
		ayar.shadow_color = Color(0.1, 0.15, 0.3, 0.35)
		ayar.shadow_offset = Vector2(0, 5)
		harf.label_settings = ayar
		harf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		satir.add_child(harf)
	satir.pivot_offset = satir.size * 0.5
	satir.scale = Vector2.ZERO
	var tween := satir.create_tween()
	tween.tween_property(satir, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.9)
	tween.tween_property(satir, "modulate:a", 0.0, 0.4)
	tween.tween_callback(satir.queue_free)
	await get_tree().process_frame
	for i in satir.get_child_count():
		var harf: Label = satir.get_child(i)
		var y := harf.position.y
		var zipla := harf.create_tween()
		zipla.tween_interval(0.35 + i * 0.06)
		zipla.tween_property(harf, "position:y", y - 26.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		zipla.tween_property(harf, "position:y", y, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


# --- Her kare ---

func _process(delta: float) -> void:
	if _duraklatildi:
		return
	kamera.tepeyi_izle(kule.tepe().y)
	vinc.position = kamera.sol_ust()
	manzara.guncelle(kamera.position.y)
	if durum == Durum.SONU:
		_sonu_sayac -= delta
		if _sonu_sayac <= 0.0:
			_sonraki_bolum()
