extends Control
# Minik Oyunlar ana menüsü: altı oyunun kartı. Karta dokununca oyun açılır.
# Kartlardaki çizimler oyunların kendi SVG'leridir (net görünsünler diye ana_menu/gorseller/
# içine kopyalanıp 2x ölçekle içe aktarıldı). Yazı tipi ve stiller ortak/tema.tres'ten gelir.

const G := "res://ana_menu/gorseller/"
const YolBolumleri := preload("res://oyunlar/yol_yap/bolumler.gd")
const HafizaVerileri := preload("res://oyunlar/hafiza/veriler.gd")
const GolgeShader := preload("res://oyunlar/golge_eslestirme/golge.gdshader")

# Yeni oyun eklemek için: buraya bir satır ve _ciz() içine çizimini ekle
const OYUNLAR := [
	{"ad": "Uçan Kuş", "sahne": "res://oyunlar/ucan_kus/ucan_kus.tscn", "renk": Color("cfe9ff"), "cizim": "kus", "kayit": ""},
	{"ad": "Dondurmacı", "sahne": "res://oyunlar/dondurmaci/dondurmaci.tscn", "renk": Color("ffdbe7"), "cizim": "dondurma", "kayit": ""},
	{"ad": "Yol Yap", "sahne": "res://oyunlar/yol_yap/yol_yap.tscn", "renk": Color("d3f4e2"), "cizim": "yol", "kayit": "yol_yap"},
	{"ad": "Hafıza", "sahne": "res://oyunlar/hafiza/hafiza.tscn", "renk": Color("e6ddff"), "cizim": "hafiza", "kayit": "hafiza"},
	{"ad": "Meyve Topla", "sahne": "res://oyunlar/meyve_topla/meyve_topla.tscn", "renk": Color("ffe7cc"), "cizim": "kirpi", "kayit": "meyve_topla"},
	{"ad": "Gölge Eşleştirme", "sahne": "res://oyunlar/golge_eslestirme/golge_eslestirme.tscn", "renk": Color("dff1ff"), "cizim": "golge", "kayit": "golge_eslestirme"},
]

const KART := Vector2(300, 292)
const ARALIK := 28.0
const CIZIM_MERKEZI := Vector2(150, 116)   # kart içinde çizimin merkezi
const LEKE_RENKLERI := [Color("ffb3cf"), Color("c9b6ff"), Color("a8efd0"), Color("ffd2a8"), Color("aedbff"), Color("fff1a8")]

var _kartlar: Array[Panel] = []
var _cizimler: Array[Node2D] = []
var _lekeler: Array[Sprite2D] = []
var _bulutlar: Array[Sprite2D] = []
var _baslik: HBoxContainer
var _secildi := false
var _zaman := 0.0
var _ekran := Vector2(720, 1280)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ekran = get_viewport_rect().size
	_arka_plan_olustur()
	_baslik_olustur()
	for i in OYUNLAR.size():
		var kart := _kart_olustur(OYUNLAR[i])
		add_child(kart)
		_kartlar.append(kart)
	_yerlestir()
	_acilis_animasyonu()


# --- Arka plan: yumuşak renk geçişi, çok yavaş süzülen renkli lekeler ve bulutlar ---

func _arka_plan_olustur() -> void:
	var gecis := Gradient.new()
	gecis.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gecis.colors = PackedColorArray([Color("ffeaf3"), Color("eef0ff"), Color("e2f8ef")])
	var doku := GradientTexture2D.new()
	doku.gradient = gecis
	doku.fill_from = Vector2(0.2, 0.0)
	doku.fill_to = Vector2(0.5, 1.0)
	doku.width = 64
	doku.height = 256
	var zemin := TextureRect.new()
	zemin.texture = doku
	zemin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	zemin.stretch_mode = TextureRect.STRETCH_SCALE
	zemin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zemin)
	zemin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var daire: Texture2D = load(G + "yumusak_daire.svg")
	for i in LEKE_RENKLERI.size():
		var leke := Sprite2D.new()
		leke.texture = daire
		var boyut := randf_range(300.0, 480.0)
		leke.scale = Vector2.ONE * boyut / daire.get_width()
		leke.modulate = Color(LEKE_RENKLERI[i], 0.45)
		leke.set_meta("ev", Vector2(randf_range(0.0, _ekran.x), randf_range(0.0, _ekran.y)))
		leke.set_meta("faz", randf() * TAU)
		add_child(leke)
		_lekeler.append(leke)

	var bulut: Texture2D = load(G + "bulut.svg")
	for i in 3:
		var b := Sprite2D.new()
		b.texture = bulut
		b.scale = Vector2.ONE * randf_range(150.0, 230.0) / bulut.get_width()
		b.modulate.a = 0.7
		b.position = Vector2(randf_range(0.0, _ekran.x), randf_range(120.0, _ekran.y - 120.0))
		b.set_meta("hiz", randf_range(5.0, 9.0))
		add_child(b)
		_bulutlar.append(b)


func _baslik_olustur() -> void:
	_baslik = HBoxContainer.new()
	_baslik.alignment = BoxContainer.ALIGNMENT_CENTER
	_baslik.add_theme_constant_override("separation", 20)
	_baslik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_baslik)
	_baslik.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_baslik.offset_top = 70.0
	_baslik.offset_bottom = 190.0
	for parca in [["Minik", Color("ff7a9a")], ["Oyunlar", Color("7b6cf6")]]:
		var etiket := Label.new()
		etiket.theme_type_variation = &"Baslik"
		etiket.text = parca[0]
		etiket.add_theme_color_override("font_color", parca[1])
		etiket.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_baslik.add_child(etiket)


# --- Kartlar ---

func _kart_olustur(oyun: Dictionary) -> Panel:
	var kart := Panel.new()
	kart.size = KART
	kart.pivot_offset = KART / 2.0
	kart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stil := StyleBoxFlat.new()
	stil.bg_color = oyun["renk"]
	stil.set_corner_radius_all(48)
	stil.set_border_width_all(5)
	stil.border_color = Color(1, 1, 1, 0.75)
	stil.shadow_color = Color(0.35, 0.25, 0.55, 0.16)
	stil.shadow_size = 18
	stil.shadow_offset = Vector2(0, 10)
	kart.add_theme_stylebox_override("panel", stil)

	# Çizimin arkasında hafif beyaz bir ışık
	var isik := Sprite2D.new()
	isik.texture = load(G + "yumusak_daire.svg")
	isik.scale = Vector2.ONE * 250.0 / isik.texture.get_width()
	isik.modulate.a = 0.75
	isik.position = CIZIM_MERKEZI
	kart.add_child(isik)

	var cizim := Node2D.new()
	cizim.position = CIZIM_MERKEZI
	kart.add_child(cizim)
	_ciz(cizim, oyun["cizim"])
	cizim.set_meta("olcek", cizim.scale)
	_cizimler.append(cizim)

	var ad := Label.new()
	ad.theme_type_variation = &"KartYazisi"
	ad.text = oyun["ad"]
	ad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad.position = Vector2(0, KART.y - 78.0)
	ad.size = Vector2(KART.x, 60)
	kart.add_child(ad)
	ad.ready.connect(_yaziyi_sigdir.bind(ad))

	var bolum := _ulasilan_bolum(oyun["kayit"])
	if bolum > 0:
		kart.add_child(_rozet_olustur(bolum))
	return kart


# Uzun adlar (ör. "Gölge Eşleştirme") karta sığsın diye yazı biraz küçülür.
# Tema değerleri ancak düğüm ağaca eklenince doğru okunduğu için ready'de çalışır.
func _yaziyi_sigdir(ad: Label) -> void:
	var yazi_tipi := ad.get_theme_font("font")
	var yazi_boyu := ad.get_theme_font_size("font_size")
	while yazi_boyu > 24 and yazi_tipi.get_string_size(ad.text, HORIZONTAL_ALIGNMENT_LEFT, -1, yazi_boyu).x > KART.x - 32.0:
		yazi_boyu -= 2
	ad.add_theme_font_size_override("font_size", yazi_boyu)


# Sağ üst köşede küçük ilerleme rozeti: yıldız ve ulaşılan bölüm
func _rozet_olustur(bolum: int) -> PanelContainer:
	var rozet := PanelContainer.new()
	rozet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(1, 1, 1, 0.92)
	stil.set_corner_radius_all(22)
	stil.content_margin_left = 12
	stil.content_margin_right = 16
	stil.content_margin_top = 4
	stil.content_margin_bottom = 4
	stil.shadow_color = Color(0.35, 0.25, 0.55, 0.14)
	stil.shadow_size = 6
	stil.shadow_offset = Vector2(0, 3)
	rozet.add_theme_stylebox_override("panel", stil)
	var satir := HBoxContainer.new()
	satir.add_theme_constant_override("separation", 6)
	satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rozet.add_child(satir)
	var yildiz := TextureRect.new()
	yildiz.texture = load(G + "yildiz.svg")
	yildiz.custom_minimum_size = Vector2(28, 28)
	yildiz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	yildiz.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	yildiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	satir.add_child(yildiz)
	var sayi := Label.new()
	sayi.theme_type_variation = &"Rozet"
	sayi.text = str(bolum)
	sayi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sayi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	satir.add_child(sayi)
	# Sağ üst köşeye çapalı; içeriğine göre sola doğru büyür
	rozet.anchor_left = 1.0
	rozet.anchor_right = 1.0
	rozet.offset_right = -16.0
	rozet.offset_left = -16.0
	rozet.offset_top = 16.0
	rozet.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	return rozet


# Oyunların kendi kayıt dosyalarından ulaşılan bölümü okur; kayıt yoksa 0 döner (rozet gösterilmez)
func _ulasilan_bolum(kayit: String) -> int:
	if kayit == "":
		return 0
	var ayar := ConfigFile.new()
	if ayar.load("user://%s.cfg" % kayit) != OK:
		return 0
	match kayit:
		"yol_yap":
			var bitirilen := int(ayar.get_value("ilerleme", "tamamlanan", 0))
			return mini(bitirilen + 1, YolBolumleri.LIST.size())
		"hafiza":
			# Temalardan en ilerideki
			var en_iyi := 1
			if ayar.has_section("ilerleme"):
				for tema in ayar.get_section_keys("ilerleme"):
					en_iyi = maxi(en_iyi, mini(int(ayar.get_value("ilerleme", tema, 0)) + 1, HafizaVerileri.LEVELS.size()))
			return en_iyi
		"meyve_topla":
			return int(ayar.get_value("ilerleme", "bolum", 0)) + 1
		"golge_eslestirme":
			return int(ayar.get_value("ilerleme", "bolum", 0)) + 1
	return 0


func _yerlestir() -> void:
	var genislik := KART.x * 2.0 + ARALIK
	var sol := (_ekran.x - genislik) / 2.0
	var ust_sinir := 230.0
	var yukseklik := KART.y * 3.0 + ARALIK * 2.0
	var ust := ust_sinir + maxf(0.0, (_ekran.y - 50.0 - ust_sinir - yukseklik) / 2.0)
	for i in _kartlar.size():
		var satir := floori(i / 2.0)
		var sutun := i % 2
		var x := sol + sutun * (KART.x + ARALIK)
		if i == _kartlar.size() - 1 and _kartlar.size() % 2 == 1:
			x = (_ekran.x - KART.x) / 2.0  # tek kalan kart ortada
		_kartlar[i].position = Vector2(x, ust + satir * (KART.y + ARALIK))
		_kartlar[i].set_meta("yer", _kartlar[i].position)


# Başlık yukarıdan süzülür, kartlar sırayla hafifçe zıplayarak gelir
func _acilis_animasyonu() -> void:
	_baslik.modulate.a = 0.0
	var baslik_y := _baslik.position.y
	_baslik.position.y = baslik_y - 30.0
	var tween := _baslik.create_tween().set_parallel()
	tween.tween_property(_baslik, "modulate:a", 1.0, 0.5).set_delay(0.1)
	tween.tween_property(_baslik, "position:y", baslik_y, 0.6).set_delay(0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in _kartlar.size():
		var kart := _kartlar[i]
		var yer: Vector2 = kart.get_meta("yer")
		kart.position = yer + Vector2(0, 50)
		kart.scale = Vector2(0.8, 0.8)
		kart.modulate.a = 0.0
		var gecikme := 0.25 + i * 0.09
		var kart_tween := kart.create_tween().set_parallel()
		kart_tween.tween_property(kart, "modulate:a", 1.0, 0.25).set_delay(gecikme)
		kart_tween.tween_property(kart, "position", yer, 0.6).set_delay(gecikme).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		kart_tween.tween_property(kart, "scale", Vector2.ONE, 0.6).set_delay(gecikme).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_zaman += delta
	# Kart çizimleri yavaşça nefes alır
	for i in _cizimler.size():
		var cizim := _cizimler[i]
		var taban: Vector2 = cizim.get_meta("olcek")
		cizim.scale = taban * (1.0 + sin(_zaman * 1.7 + i * 1.3) * 0.035)
		cizim.rotation = sin(_zaman * 1.1 + i * 0.9) * 0.025
	# Lekeler ve bulutlar çok yavaş süzülür
	for leke in _lekeler:
		var ev: Vector2 = leke.get_meta("ev")
		var faz: float = leke.get_meta("faz")
		leke.position = ev + Vector2(sin(_zaman * 0.07 + faz) * 60.0, cos(_zaman * 0.05 + faz) * 45.0)
	for bulut in _bulutlar:
		bulut.position.x += float(bulut.get_meta("hiz")) * delta
		var yarim := bulut.texture.get_width() * bulut.scale.x / 2.0
		if bulut.position.x > _ekran.x + yarim:
			bulut.position = Vector2(-yarim, randf_range(120.0, _ekran.y - 120.0))


# --- Dokunma ---

func _input(event: InputEvent) -> void:
	var dokunma := event as InputEventScreenTouch
	if dokunma == null or not dokunma.pressed or _secildi or SahneGecis.gecis_suruyor:
		return
	for i in _kartlar.size():
		if _kartlar[i].get_global_rect().has_point(dokunma.position):
			_karta_dokun(i)
			return


# Kart hafifçe küçülüp geri büyür, sonra oyun açılır
func _karta_dokun(index: int) -> void:
	_secildi = true
	var kart := _kartlar[index]
	var tween := kart.create_tween()
	tween.tween_property(kart, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(kart, "scale", Vector2(1.04, 1.04), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(kart, "scale", Vector2.ONE, 0.1)
	tween.tween_callback(SahneGecis.sahne_degistir.bind(OYUNLAR[index]["sahne"]))


# --- Kart çizimleri (oyunların kendi görselleriyle) ---

func _sprite(parent: Node2D, dosya: String, genislik: float, konum: Vector2, aci: float = 0.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(G + dosya)
	sprite.scale = Vector2.ONE * genislik / sprite.texture.get_width()
	sprite.position = konum
	sprite.rotation = aci
	parent.add_child(sprite)
	return sprite


func _ciz(cizim: Node2D, tur: String) -> void:
	match tur:
		"kus":
			var bulut := _sprite(cizim, "bulut.svg", 130.0, Vector2(-58, 52))
			bulut.modulate.a = 0.95
			_sprite(cizim, "kus.svg", 185.0, Vector2(10, -8), -0.08)
		"dondurma":
			cizim.scale = Vector2.ONE * 0.84
			_sprite(cizim, "kulah.svg", 100.0, Vector2(0, 58))
			_sprite(cizim, "top_yaban_mersini.svg", 118.0, Vector2(0, -12))
			_sprite(cizim, "top_cilek.svg", 118.0, Vector2(0, -64))
		"yol":
			_sprite(cizim, "hediye_kutu.svg", 124.0, Vector2(40, 36))
			_sprite(cizim, "hediye_kapak.svg", 144.0, Vector2(50, -28), 0.28)
			_sprite(cizim, "bilye.svg", 98.0, Vector2(-58, 44))
			_sprite(cizim, "yildiz.svg", 34.0, Vector2(-30, -40), 0.2)
		"hafiza":
			_sprite(cizim, "kart_arka.svg", 126.0, Vector2(-40, 4), -0.22)
			var on := Node2D.new()
			on.position = Vector2(34, 8)
			on.rotation = 0.14
			cizim.add_child(on)
			_sprite(on, "kart_on.svg", 136.0, Vector2.ZERO)
			_sprite(on, "aslan.svg", 108.0, Vector2(0, -3))
		"kirpi":
			# Meyve Topla'daki kirpinin aynısı: ayaklar, gövde, sepet ve içinde meyveler
			cizim.scale = Vector2.ONE * 0.72
			var kok := Node2D.new()
			kok.position = Vector2(0, 118)
			cizim.add_child(kok)
			_sprite(kok, "kirpi_ayak.svg", 50.0, Vector2(-34, -12))
			_sprite(kok, "kirpi.svg", 190.0, Vector2(0, -90))
			_sprite(kok, "kirpi_ayak.svg", 50.0, Vector2(24, -10))
			_sprite(kok, "sepet_arka.svg", 200.0, Vector2(0, -200))
			_sprite(kok, "elma.svg", 56.0, Vector2(-42, -228), -0.2)
			_sprite(kok, "portakal.svg", 56.0, Vector2(40, -228), 0.2)
			_sprite(kok, "cilek.svg", 58.0, Vector2(0, -250))
			_sprite(kok, "sepet_on.svg", 200.0, Vector2(0, -200))
		"golge":
			# Gölge Eşleştirme: tavşanın gölgesi (oyundaki siluet shader'ıyla) ve önünde tavşan
			var golge := _sprite(cizim, "tavsan.svg", 150.0, Vector2(-38, 6), -0.06)
			var malzeme := ShaderMaterial.new()
			malzeme.shader = GolgeShader
			golge.material = malzeme
			_sprite(cizim, "tavsan.svg", 150.0, Vector2(40, 0), 0.1)
