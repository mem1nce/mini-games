extends Control
# Varış kutlaması: istasyondaki hayvanlar zıplar, bacadan renkli duman halkaları çıkar, konfeti ve zıplayan
# harflerle "Harika!" / "Süper!" / "Tebrikler!". Bütün yolcular alındıysa istasyonun üstünde büyük ek yıldız.
# Arayüz katmanında durur (yazı ve yıldız); parçacıklar dünya katmanındaki efektlerde.

const G := "res://oyunlar/tren_rayi/gorseller/"
const SOZLER := ["Harika!", "Süper!", "Tebrikler!"]
const HARF_RENKLERI := [Color("ff5a6e"), Color("ff9f40"), Color("ffc93d"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var efektler: Node2D
var sesler: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func oyna(izgara: Node2D, tren: Node2D, ekran: Vector2, ek_yildiz: bool) -> void:
	_ses("varis")
	izgara.hayvanlar_sevinsin()
	efektler.halkalar(tren.baca_konumu(), izgara.hucre * 0.7, 9)
	await get_tree().create_timer(0.4).timeout
	_ses("kutlama")
	efektler.konfeti(Vector2(ekran.x * 0.5, ekran.y + 20.0), ekran.x * 0.85, 110 if ek_yildiz else 80)
	_soz(ekran)
	if ek_yildiz:
		await get_tree().create_timer(0.5).timeout
		_yildiz(izgara.istasyon_merkezi() + Vector2(0, -izgara.hucre * 0.9), izgara.hucre)


func _ses(ad: String) -> void:
	if sesler:
		sesler.play(ad)


# Ortada büyük, zıplayan tek kelime: harfler farklı renklerde
func _soz(ekran: Vector2) -> void:
	var soz: String = SOZLER.pick_random()
	var satir := HBoxContainer.new()
	satir.alignment = BoxContainer.ALIGNMENT_CENTER
	satir.add_theme_constant_override("separation", 2)
	satir.size = Vector2(ekran.x, 130)
	satir.position = Vector2(0, 60)
	satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(satir)
	for i in soz.length():
		var harf := Label.new()
		harf.text = soz[i]
		harf.theme_type_variation = &"Baslik"
		var ayar := LabelSettings.new()
		ayar.font = harf.get_theme_font("font", &"Baslik")
		ayar.font_size = 96
		ayar.font_color = HARF_RENKLERI[i % HARF_RENKLERI.size()]
		ayar.outline_size = 18
		ayar.outline_color = Color.WHITE
		ayar.shadow_size = 6
		ayar.shadow_color = Color(0.3, 0.15, 0.3, 0.35)
		ayar.shadow_offset = Vector2(0, 5)
		harf.label_settings = ayar
		harf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		satir.add_child(harf)
	satir.pivot_offset = satir.size * 0.5
	satir.scale = Vector2.ZERO
	var tween := satir.create_tween()
	tween.tween_property(satir, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.7)
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


func _yildiz(konum: Vector2, hucre: float) -> void:
	_ses("yildiz")
	var yildiz := TextureRect.new()
	yildiz.texture = load(G + "yildiz.svg")
	yildiz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	yildiz.size = Vector2(hucre, hucre) * 1.3
	yildiz.pivot_offset = yildiz.size * 0.5
	yildiz.position = konum - yildiz.size * 0.5
	yildiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	yildiz.scale = Vector2.ZERO
	add_child(yildiz)
	efektler.yildizlar(konum, 12)
	efektler.parilti(konum, Color("fff6b0"), 18, hucre * 0.6)
	var tween := yildiz.create_tween()
	tween.tween_property(yildiz, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(yildiz, "rotation", TAU, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.4)
	tween.tween_property(yildiz, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(yildiz.queue_free)
