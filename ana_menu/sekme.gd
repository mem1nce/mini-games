extends Control
# Kategori sekmesi: büyük renkli simge ve altında küçük ad. Seçili sekme kendi renginin açık tonuyla dolar,
# kalın renkli çerçeve alır, simgesi büyür ve hafifçe öne çıkar; seçili olmayanlar beyazımsı ve sade durur.

var kategori: Dictionary = {}
var secili := false

var _ic: Control
var _simge: TextureRect
var _ad: Label
var _renk := Color.WHITE
var _dolgu := 0.0          # 0 = seçili değil, 1 = seçili (renk geçişi için)


func kur(p_kategori: Dictionary, boyut: Vector2) -> void:
	kategori = p_kategori
	_renk = kategori["renk"]
	size = boyut
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic = Control.new()
	_ic.size = boyut
	_ic.pivot_offset = boyut / 2.0
	_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic.draw.connect(_ciz)
	add_child(_ic)
	var simge_boyu := roundf(boyut.x * 0.6)
	_simge = TextureRect.new()
	_simge.texture = load(kategori["simge"])
	_simge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_simge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_simge.size = Vector2(simge_boyu, simge_boyu)
	_simge.position = Vector2((boyut.x - simge_boyu) / 2.0, boyut.y * 0.09)
	_simge.pivot_offset = _simge.size / 2.0
	_simge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic.add_child(_simge)
	_ad = Label.new()
	_ad.theme_type_variation = &"KartYazisi"
	_ad.text = kategori["ad"]
	var yazi_boyu := roundi(boyut.x * 0.155)
	_ad.add_theme_font_size_override("font_size", yazi_boyu)
	# Uzun ad sekmeye sığsın; etiket kendiliğinden büyüyüp ortadan kaymasın
	_ad.clip_text = true
	var yazi_yazi: Font = _ad.get_theme_font("font")
	while yazi_boyu > 10 and yazi_yazi.get_string_size(tr(_ad.text), HORIZONTAL_ALIGNMENT_LEFT, -1, yazi_boyu).x > boyut.x - 8.0:
		yazi_boyu -= 1
	_ad.add_theme_font_size_override("font_size", yazi_boyu)
	_ad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ad.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic.add_child(_ad)
	# Boyut ağaca eklendikten sonra verilir; önce verilirse etiket varsayılan yazı boyuyla yüksek kalır ve yazı aşağı kayar
	_ad.position = Vector2(0, boyut.y * 0.7)
	_ad.size = Vector2(boyut.x, boyut.y * 0.24)
	_guncelle()


func sec(deger: bool, animasyonlu: bool = true) -> void:
	secili = deger
	if not animasyonlu:
		_dolgu = 1.0 if deger else 0.0
		_simge.scale = Vector2.ONE * (1.08 if deger else 0.92)
		_guncelle()
		return
	var tween := create_tween().set_parallel()
	tween.tween_method(_dolgu_ayarla, _dolgu, 1.0 if deger else 0.0, 0.2)
	if deger:
		tween.tween_property(_simge, "scale", Vector2.ONE * 1.08, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var zipla := _ic.create_tween()
		zipla.tween_property(_ic, "scale", Vector2(1.06, 1.06), 0.1).set_trans(Tween.TRANS_SINE)
		zipla.tween_property(_ic, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(_simge, "scale", Vector2.ONE * 0.92, 0.2).set_trans(Tween.TRANS_SINE)


func bas() -> void:
	_ic.create_tween().tween_property(_ic, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_SINE)


func iptal() -> void:
	_ic.create_tween().tween_property(_ic, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)


func giris(gecikme: float) -> void:
	_ic.modulate.a = 0.0
	_ic.position.y = -16.0
	var tween := _ic.create_tween().set_parallel()
	tween.tween_property(_ic, "modulate:a", 1.0, 0.25).set_delay(gecikme)
	tween.tween_property(_ic, "position:y", 0.0, 0.45).set_delay(gecikme).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _dolgu_ayarla(deger: float) -> void:
	_dolgu = deger
	_guncelle()


func _guncelle() -> void:
	_ad.add_theme_color_override("font_color", Color("857e9e").lerp(_renk.darkened(0.38), _dolgu))
	_simge.modulate = Color(1, 1, 1, 0.8 + 0.2 * _dolgu)
	_ic.queue_redraw()


func _ciz() -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(1, 1, 1, 0.72).lerp(_renk.lightened(0.62), _dolgu)
	stil.set_corner_radius_all(roundi(size.x * 0.26))
	stil.set_border_width_all(roundi(3 + 2 * _dolgu))
	stil.border_color = _renk.lightened(0.8).lerp(_renk, _dolgu)
	stil.shadow_color = Color(_renk.darkened(0.4), 0.08 + 0.22 * _dolgu)
	stil.shadow_size = roundi(6 + 8 * _dolgu)
	stil.shadow_offset = Vector2(0, 3 + 4 * _dolgu)
	stil.anti_aliasing_size = 1.2
	_ic.draw_style_box(stil, Rect2(Vector2.ZERO, size))
