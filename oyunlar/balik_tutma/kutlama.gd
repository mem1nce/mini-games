extends Control
# Kutlamalar (arayüz katmanında): zıplayan harflerle "Harika!" / "Süper!" / "Tebrikler!" ve yeni tür tanıtımı
# (ilk kez yakalanan balık büyüyerek ekranın ortasına gelir, parlar, sonra hedefine uçar).

const Turler := preload("res://oyunlar/balik_tutma/balik_turleri.gd")
const SOZLER := ["Harika!", "Süper!", "Tebrikler!"]
const HARF_RENKLERI := [Color("ff5a6e"), Color("ff9f40"), Color("ffc93d"), Color("5cc95c"), Color("4fa8ff"), Color("a66bff")]

var efektler: Node2D
var sesler: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func soz(ekran: Vector2) -> void:
	var soz: String = tr(SOZLER.pick_random())
	var satir := HBoxContainer.new()
	satir.alignment = BoxContainer.ALIGNMENT_CENTER
	satir.add_theme_constant_override("separation", 2)
	satir.size = Vector2(ekran.x, 130)
	satir.position = Vector2(0, ekran.y * 0.42)
	satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(satir)
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
	tween.tween_interval(1.8)
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


# Yeni tür: balığın kopyası baştan ortaya büyüyerek gelir, döner, parlar; sonra hedefe küçülerek uçar
func yeni_tur(tur: String, bas: Vector2, hedef: Vector2, ekran: Vector2) -> void:
	if sesler:
		sesler.play("yeni")
	var isik := TextureRect.new()
	isik.texture = load(Turler.G + "isik.svg")
	isik.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	isik.size = Vector2(420, 420)
	isik.position = ekran * 0.5 - isik.size * 0.5
	isik.modulate = Color(1.0, 0.95, 0.6, 0.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	isik.material = mat
	isik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(isik)
	var balik := TextureRect.new()
	balik.texture = Turler.doku(tur)
	balik.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	balik.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	balik.size = Vector2(300, 240)
	balik.pivot_offset = balik.size * 0.5
	balik.position = bas - balik.size * 0.5
	balik.scale = Vector2.ONE * 0.35
	balik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(balik)
	var orta := ekran * 0.5 - balik.size * 0.5
	var tween := create_tween().set_parallel()
	tween.tween_property(balik, "position", orta, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(balik, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(isik, "modulate:a", 0.55, 0.4)
	tween.chain().tween_property(balik, "rotation", TAU, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout
	if efektler:
		efektler.parilti(ekran * 0.5, Color("fff6b0"), 22, 110.0)
		efektler.yildizlar(ekran * 0.5, 8)
	await get_tree().create_timer(1.0).timeout
	var uc := create_tween().set_parallel()
	uc.tween_property(balik, "position", hedef - balik.size * 0.5, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	uc.tween_property(balik, "scale", Vector2.ONE * 0.2, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	uc.tween_property(isik, "modulate:a", 0.0, 0.4)
	await uc.finished
	balik.queue_free()
	isik.queue_free()


# Bölüm sonunda kovadaki balıklar sırayla akvaryum simgesine uçar
func akvaryuma_tasi(turler: Array, bas: Vector2, hedef: Vector2) -> void:
	for i in turler.size():
		var balik := TextureRect.new()
		balik.texture = Turler.doku(turler[i])
		balik.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		balik.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		balik.size = Vector2(90, 72)
		balik.pivot_offset = balik.size * 0.5
		balik.position = bas - balik.size * 0.5
		balik.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(balik)
		var tepe := (bas + hedef) * 0.5 + Vector2(0, -160) - balik.size * 0.5
		var son := hedef - balik.size * 0.5
		var ilk := balik.position
		var tween := balik.create_tween()
		tween.tween_interval(i * 0.18)
		tween.tween_method(func(t: float) -> void:
			balik.position = ilk.lerp(tepe, t).lerp(tepe.lerp(son, t), t)
			balik.scale = Vector2.ONE * lerpf(1.0, 0.4, t)
			balik.rotation = t * TAU * 0.5, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(balik.queue_free)
