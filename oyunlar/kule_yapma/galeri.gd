extends Control
# "Apartmanlarım" galerisi: kaydedilmiş kuleler küçük resimler halinde (en yenisi önde), 3 sütun, dikey kaydırılır.
# Karta dokununca "sec" sinyali (apartman görünümü açılır). Sol üstteki düğme kapatır.

signal sec(index: int)
signal kapandi

const Blok := preload("res://oyunlar/kule_yapma/blok.gd")
const G := "res://oyunlar/kule_yapma/gorseller/"
const SUTUN := 3
const KAYMA_ESIGI := 14.0

var sesler: Node

var _acik := false
var _ekran := Vector2(720, 1280)
var _icerik: Control
var _kartlar: Array = []          # {"rect", "index", "dugum"}
var _kapat: Control
var _kaydirma := 0.0
var _en_fazla := 0.0
var _bas := Vector2.ZERO
var _son_y := 0.0
var _basili := false
var _kayiyor := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func acik_mi() -> bool:
	return _acik


func ac(apartmanlar: Array, ekran: Vector2) -> void:
	_acik = true
	visible = true
	_ekran = ekran
	size = ekran
	for c in get_children():
		c.queue_free()
	_kartlar.clear()
	var zemin := ColorRect.new()
	zemin.size = ekran
	zemin.color = Color("dff1ff")
	zemin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zemin)
	var alan := Control.new()
	alan.position = Vector2(0, 150)
	alan.size = Vector2(ekran.x, ekran.y - 150)
	alan.clip_contents = true
	alan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(alan)
	_icerik = Control.new()
	_icerik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icerik.draw.connect(_ciz)
	alan.add_child(_icerik)
	var kenar := 30.0
	var aralik := 20.0
	var gen := (ekran.x - 2 * kenar - aralik * (SUTUN - 1)) / SUTUN
	var boy := gen * 1.45
	for sira in apartmanlar.size():
		var index := apartmanlar.size() - 1 - sira
		var r := Rect2(kenar + (sira % SUTUN) * (gen + aralik), 10.0 + floori(sira / float(SUTUN)) * (boy + aralik), gen, boy)
		var kule := _mini_kule(apartmanlar[index], r)
		_icerik.add_child(kule)
		_kartlar.append({"rect": r, "index": index, "dugum": kule})
	var satir := ceili(apartmanlar.size() / float(SUTUN))
	_en_fazla = maxf(0.0, 20.0 + satir * (boy + aralik) - alan.size.y)
	_kaydirma = 0.0
	if apartmanlar.is_empty():
		var bos := Sprite2D.new()
		bos.texture = load(G + "apartman.svg")
		bos.scale = Vector2.ONE * 220.0 / bos.texture.get_width()
		bos.position = Vector2(ekran.x * 0.5, ekran.y * 0.4)
		bos.modulate = Color(1, 1, 1, 0.4)
		add_child(bos)
	_kapat = _geri_dugmesi()
	add_child(_kapat)
	var baslik := Sprite2D.new()
	baslik.texture = load(G + "apartman.svg")
	baslik.scale = Vector2.ONE * 96.0 / baslik.texture.get_width()
	baslik.position = Vector2(ekran.x * 0.5, 76.0)
	add_child(baslik)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	_konumla()


# Kartın içine sığan küçük kule
func _mini_kule(apartman: Dictionary, r: Rect2) -> Node2D:
	var kok := Node2D.new()
	var katlar: Array = apartman["katlar"]
	var hayvanlar: Array = apartman["hayvanlar"]
	var toplam := 0.0
	for k in katlar:
		toplam += Blok.boyut(k).y
	var kaymalar: Array = apartman.get("x", [])
	var genislik := 270.0
	for x in kaymalar:
		genislik = maxf(genislik, 270.0 + absf(float(x)) * 2.0)
	var olcek := minf((r.size.x - 20.0) / genislik, (r.size.y - 30.0) / toplam)
	kok.scale = Vector2.ONE * olcek
	kok.position = Vector2(r.get_center().x, r.end.y - 14.0)
	var y := 0.0
	for i in katlar.size():
		var b: Node2D = Blok.new()
		kok.add_child(b)
		b.kur(katlar[i], hayvanlar[i] if i < hayvanlar.size() else "panda")
		b.position = Vector2(float(kaymalar[i]) if i < kaymalar.size() else 0.0, y - b.yukseklik() * 0.5)
		b.hemen_goster()
		b.set_process(false)
		y -= b.yukseklik()
	return kok


func _geri_dugmesi() -> Control:
	var d := Control.new()
	d.size = Vector2(104, 104)
	d.position = Vector2(36, 24)
	d.pivot_offset = d.size * 0.5
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var simge: Texture2D = load("res://ortak/gorseller/geri.svg")
	d.draw.connect(func() -> void:
		d.draw_circle(Vector2(52, 58), 46, Color(0.1, 0.1, 0.25, 0.2))
		d.draw_circle(Vector2(52, 52), 46, Color.WHITE)
		d.draw_arc(Vector2(52, 52), 46, 0.0, TAU, 48, Color(0.23, 0.18, 0.42), 5.0, true)
		d.draw_texture_rect(simge, Rect2(Vector2(26, 26), Vector2(52, 52)), false))
	return d


# sinyal = false: apartman görünümüne geçerken (galeriye geri dönülecek) giriş ekranına dönülmesin
func kapat(sinyal: bool = true) -> void:
	if not _acik:
		return
	_acik = false
	visible = false
	for c in get_children():
		c.queue_free()
	if sinyal:
		kapandi.emit()


func dokun(p: Vector2) -> void:
	if _kapat.get_global_rect().grow(10.0).has_point(p):
		if sesler:
			sesler.play("dokun")
		kapat()
		return
	_basili = true
	_kayiyor = false
	_bas = p
	_son_y = p.y


func surukle(p: Vector2) -> void:
	if not _basili:
		return
	if not _kayiyor and p.distance_to(_bas) > KAYMA_ESIGI:
		_kayiyor = true
	if _kayiyor:
		_kaydirma = clampf(_kaydirma - (p.y - _son_y), 0.0, _en_fazla)
		_son_y = p.y
		_konumla()


func birak(p: Vector2) -> void:
	if not _basili:
		return
	_basili = false
	if _kayiyor:
		return
	var yerel := p - Vector2(0, 150) + Vector2(0, _kaydirma)
	for k in _kartlar:
		if k["rect"].has_point(yerel):
			if sesler:
				sesler.play("dokun")
			sec.emit(k["index"])
			return


func _konumla() -> void:
	_icerik.position.y = -_kaydirma
	# Görünmeyen kartlar çizilmesin
	for k in _kartlar:
		var r: Rect2 = k["rect"]
		k["dugum"].visible = r.end.y - _kaydirma > -20.0 and r.position.y - _kaydirma < _ekran.y
	_icerik.queue_redraw()


func _ciz() -> void:
	for k in _kartlar:
		var stil := StyleBoxFlat.new()
		stil.bg_color = Color("bfe6ff")
		stil.set_corner_radius_all(24)
		stil.set_border_width_all(5)
		stil.border_color = Color.WHITE
		stil.shadow_color = Color(0.1, 0.2, 0.4, 0.2)
		stil.shadow_size = 8
		stil.shadow_offset = Vector2(0, 4)
		_icerik.draw_style_box(stil, k["rect"])
		var r: Rect2 = k["rect"]
		_icerik.draw_rect(Rect2(r.position.x + 5, r.end.y - 22, r.size.x - 10, 17), Color("8fd46a"))
