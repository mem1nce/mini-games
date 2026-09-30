extends Node2D
# Arka katman: gökyüzü (güneş ya da ay, süzülen bulutlar), derinleştikçe koyulaşan su (sığ, orta, derin),
# yavaşça sallanan ışık huzmeleri, dipte kum, taş, yosun ve mercanlar (hafifçe sallanır), dipten yükselen
# kabarcıklar. Berraklık (0-1) çöp bölümlerinde bitkilerin rengini açar.

const G := "res://oyunlar/balik_tutma/gorseller/"
const TEMALAR := {
	"gol": {"gok": [Color("a8dcff"), Color("e6f6ff")], "su": [Color("86dccb"), Color("3aa3a8"), Color("1f6f80")],
		"kum": [Color("d9c49a"), Color("b39a6a")], "huzme": 0.5, "gok_cismi": "gunes",
		"susler": ["sazlik", "taslar", "yosun", "sazlik", "istiridye", "yosun", "taslar", "sazlik"]},
	"deniz": {"gok": [Color("7cc6ff"), Color("d6efff")], "su": [Color("5cc6f2"), Color("2a82cc"), Color("163f8a")],
		"kum": [Color("f2dca6"), Color("d4b474")], "huzme": 0.55, "gok_cismi": "gunes",
		"susler": ["yosun", "taslar", "deniz_yildizi", "yosun", "istiridye", "taslar", "yosun", "mercan_turuncu"]},
	"mercan": {"gok": [Color("8fe0ff"), Color("e6fbff")], "su": [Color("6ae6e0"), Color("26a6c8"), Color("1a5ea8")],
		"kum": [Color("fbe8c0"), Color("e0c48a")], "huzme": 0.6, "gok_cismi": "gunes",
		"susler": ["mercan_pembe", "mercan_turuncu", "deniz_yildizi", "mercan_mor", "yosun", "mercan_pembe", "istiridye", "mercan_turuncu"]},
	"derin": {"gok": [Color("262c5a"), Color("6a5a96")], "su": [Color("1f4a8a"), Color("12265a"), Color("060a24")],
		"kum": [Color("2e3252"), Color("1a1d32")], "huzme": 0.18, "gok_cismi": "ay",
		"susler": ["isikli_bitki", "yosun_koyu", "taslar", "isikli_bitki", "yosun_koyu", "isikli_bitki", "taslar", "yosun_koyu"]},
}

var tema := "gol"
var ekran := Vector2(720, 1280)
var yuzey_y := 400.0
var dip_y := 1160.0
var berraklik := 1.0

var _susler: Array[Sprite2D] = []
var _huzmeler: Array[Sprite2D] = []
var _bulutlar: Array[Sprite2D] = []
var _zaman := 0.0
var _kum: PackedVector2Array


func kur(p_tema: String, p_ekran: Vector2, p_yuzey: float) -> void:
	tema = p_tema
	ekran = p_ekran
	yuzey_y = p_yuzey
	dip_y = ekran.y - 110.0
	for c in get_children():
		c.queue_free()
	_susler.clear()
	_huzmeler.clear()
	_bulutlar.clear()
	var t: Dictionary = TEMALAR[tema]
	# Gök cismi ve bulutlar
	var cisim := Sprite2D.new()
	cisim.texture = load(G + t["gok_cismi"] + ".svg")
	cisim.scale = Vector2.ONE * 104.0 / cisim.texture.get_width()
	cisim.position = Vector2(ekran.x - 76.0, yuzey_y - 180.0)
	add_child(cisim)
	for i in 3:
		var b := Sprite2D.new()
		b.texture = load(G + "bulut.svg")
		b.scale = Vector2.ONE * randf_range(150.0, 220.0) / b.texture.get_width()
		b.position = Vector2(randf_range(0.0, ekran.x), randf_range(yuzey_y - 260.0, yuzey_y - 90.0))
		b.modulate = Color(1, 1, 1, 0.85) if tema != "derin" else Color(0.55, 0.55, 0.8, 0.5)
		b.set_meta("hiz", randf_range(6.0, 12.0))
		add_child(b)
		_bulutlar.append(b)
	# Işık huzmeleri (eklemeli karışım)
	var ekle := CanvasItemMaterial.new()
	ekle.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in 4:
		var h := Sprite2D.new()
		h.texture = load(G + "huzme.svg")
		h.material = ekle
		h.centered = false
		h.offset = Vector2(-h.texture.get_width() * 0.5, 0)
		h.scale = Vector2(randf_range(1.2, 2.0), (dip_y - yuzey_y) / h.texture.get_height())
		h.position = Vector2(ekran.x * (0.15 + i * 0.24), yuzey_y)
		h.rotation = randf_range(-0.2, 0.05)
		h.modulate = Color(1, 1, 1, t["huzme"])
		h.set_meta("faz", randf() * TAU)
		add_child(h)
		_huzmeler.append(h)
	# Dip kumu (dalgalı üst kenar)
	_kum = PackedVector2Array()
	var adim := 24.0
	var x := 0.0
	while x <= ekran.x + adim:
		_kum.append(Vector2(x, dip_y + sin(x * 0.012) * 14.0 + sin(x * 0.037 + 1.0) * 6.0))
		x += adim
	# Dip süsleri: tabanlarından sallanır
	var adlar: Array = t["susler"]
	for i in adlar.size():
		var s := Sprite2D.new()
		s.texture = load(G + adlar[i] + ".svg")
		var boy := 170.0 if adlar[i] in ["yosun", "yosun_koyu", "sazlik", "isikli_bitki"] else 110.0
		if adlar[i] in ["deniz_yildizi", "istiridye"]:
			boy = 60.0
		var doku := s.texture.get_size()
		s.scale = Vector2.ONE * boy / doku.y
		s.centered = false
		s.offset = Vector2(-doku.x * 0.5, -doku.y)
		var sx := ekran.x * (i + 0.5) / adlar.size() + randf_range(-24.0, 24.0)
		s.position = Vector2(sx, dip_y + sin(sx * 0.012) * 14.0 + 18.0)
		s.set_meta("faz", randf() * TAU)
		s.set_meta("sallanir", adlar[i] in ["yosun", "yosun_koyu", "sazlik", "isikli_bitki", "mercan_pembe", "mercan_mor", "mercan_turuncu"])
		add_child(s)
		_susler.append(s)
	berraklik_ayarla(berraklik)
	queue_redraw()


# 0 = kirli (bitkiler soluk), 1 = temiz
func berraklik_ayarla(deger: float) -> void:
	berraklik = deger
	for s in _susler:
		var gri := Color(0.62, 0.6, 0.52)
		var hedef := gri.lerp(Color.WHITE, deger)
		s.create_tween().tween_property(s, "modulate", hedef, 0.8)


func _process(delta: float) -> void:
	_zaman += delta
	for s in _susler:
		if s.get_meta("sallanir"):
			s.rotation = sin(_zaman * 0.9 + s.get_meta("faz")) * 0.08
	for h in _huzmeler:
		var faz: float = h.get_meta("faz")
		h.rotation = -0.08 + sin(_zaman * 0.25 + faz) * 0.12
		h.self_modulate.a = 0.55 + sin(_zaman * 0.6 + faz) * 0.35
	for b in _bulutlar:
		b.position.x += float(b.get_meta("hiz")) * delta
		if b.position.x > ekran.x + 140.0:
			b.position.x = -140.0


func _draw() -> void:
	var t: Dictionary = TEMALAR[tema]
	var gok: Array = t["gok"]
	var bant := 16
	for i in bant:
		var y0 := yuzey_y * i / bant
		draw_rect(Rect2(0, y0, ekran.x, yuzey_y / bant + 1.0), gok[0].lerp(gok[1], float(i) / (bant - 1)))
	# Su: yüzeyden dibe üç ton (sığ, orta, derin)
	var su: Array = t["su"]
	bant = 40
	var yukseklik := ekran.y - yuzey_y
	for i in bant:
		var k := float(i) / (bant - 1)
		var renk: Color = su[0].lerp(su[1], k * 2.0) if k < 0.5 else su[1].lerp(su[2], (k - 0.5) * 2.0)
		draw_rect(Rect2(0, yuzey_y + yukseklik * i / bant, ekran.x, yukseklik / bant + 1.0), renk)
	# Kum
	var kum: Array = t["kum"]
	var cokgen := _kum.duplicate()
	cokgen.append(Vector2(ekran.x, ekran.y))
	cokgen.append(Vector2(0, ekran.y))
	draw_colored_polygon(cokgen, kum[0])
	var alt := PackedVector2Array()
	for p in _kum:
		alt.append(p + Vector2(0, 36))
	alt.append(Vector2(ekran.x, ekran.y))
	alt.append(Vector2(0, ekran.y))
	draw_colored_polygon(alt, kum[1])
	draw_polyline(_kum, kum[0].lightened(0.2), 4.0, true)
	for i in 26:
		var p := Vector2(fmod(i * 131.0, ekran.x), dip_y + 30.0 + fmod(i * 47.0, ekran.y - dip_y - 30.0))
		draw_circle(p, 3.0, kum[1].darkened(0.15))
