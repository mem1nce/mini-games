extends Control
# Akvaryum koleksiyonu: üstte büyük akvaryum (cam, su, kum, yosun, kabarcık); yakalanan türler içinde yüzer.
# Altında bütün türlerin ızgarası: yakalananlar renkli, yakalanmamışlar gri siluet. Dokunulan balık takla atar.
# Sol üstteki düğme kapatır.

signal kapandi

const Turler := preload("res://oyunlar/balik_tutma/balik_turleri.gd")
const G := "res://oyunlar/balik_tutma/gorseller/"
const SILUET := """
shader_type canvas_item;
// Yakalanmamış tür: sadece saydamlığı kullanılan gri siluet
void fragment() {
	// COLOR burada doku rengiyle çarpılmış olarak gelir; sadece saydamlığı kullanılır
	COLOR = vec4(vec3(0.42, 0.46, 0.58), COLOR.a * 0.75);
}
"""

var sesler: Node

var _acik := false
var _kapat: Control
var _tank := Rect2()
var _yuzenler: Array = []         # {"dugum", "hiz", "tur", "boy"}
var _hucreler: Array = []         # {"rect", "tur", "dugum", "yakalandi"}
var _zaman := 0.0
var _siluet := Shader.new()
var _icerik: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_siluet.code = SILUET
	visible = false


func acik_mi() -> bool:
	return _acik


func ac(akvaryum: Dictionary, ekran: Vector2) -> void:
	_acik = true
	visible = true
	size = ekran
	for c in get_children():
		c.queue_free()
	_yuzenler.clear()
	_hucreler.clear()
	var karart := ColorRect.new()
	karart.color = Color(0.05, 0.1, 0.2, 0.55)
	karart.size = ekran
	karart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(karart)
	_icerik = Control.new()
	_icerik.size = ekran
	_icerik.pivot_offset = ekran * 0.5
	_icerik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icerik.draw.connect(_ciz)
	add_child(_icerik)
	_tank = Rect2(46, 150, ekran.x - 92, minf(480.0, ekran.y * 0.37))
	# Yosunlar
	for i in 4:
		var y := Sprite2D.new()
		y.texture = load(G + ("yosun.svg" if i % 2 == 0 else "mercan_pembe.svg"))
		var boy := 130.0 if i % 2 == 0 else 90.0
		y.scale = Vector2.ONE * boy / y.texture.get_height()
		y.centered = false
		y.offset = Vector2(-y.texture.get_width() * 0.5, -y.texture.get_height())
		y.position = Vector2(_tank.position.x + _tank.size.x * (0.1 + i * 0.27), _tank.end.y - 18.0)
		y.set_meta("faz", randf() * TAU)
		_icerik.add_child(y)
	var kabarcik := CPUParticles2D.new()
	kabarcik.texture = load(G + "kabarcik.svg")
	kabarcik.amount = 14
	kabarcik.lifetime = (_tank.size.y - 60.0) / 70.0
	kabarcik.position = Vector2(_tank.get_center().x, _tank.end.y - 40.0)
	kabarcik.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	kabarcik.emission_rect_extents = Vector2(_tank.size.x * 0.4, 6)
	kabarcik.direction = Vector2(0, -1)
	kabarcik.spread = 6.0
	kabarcik.gravity = Vector2.ZERO
	kabarcik.initial_velocity_min = 55.0
	kabarcik.initial_velocity_max = 80.0
	kabarcik.scale_amount_min = 0.12
	kabarcik.scale_amount_max = 0.25
	_icerik.add_child(kabarcik)
	# Yakalanan türler akvaryumda yüzer
	var ic := _tank.grow(-40.0)
	ic.size.y -= 50.0
	for tur in Turler.SIRA:
		if not akvaryum.has(tur):
			continue
		var s := Sprite2D.new()
		s.texture = Turler.doku(tur)
		var boy := Turler.boy(tur) * 0.6
		s.scale = Vector2.ONE * boy / s.texture.get_width()
		s.position = Vector2(randf_range(ic.position.x, ic.end.x), randf_range(ic.position.y, ic.end.y))
		var hiz := Vector2(randf_range(30.0, 60.0) * (1.0 if randf() < 0.5 else -1.0), 0)
		s.scale.x *= signf(hiz.x)
		s.set_meta("faz", randf() * TAU)
		_icerik.add_child(s)
		_yuzenler.append({"dugum": s, "hiz": hiz, "tur": tur, "boy": boy, "y": s.position.y})
	# Bütün türlerin ızgarası
	var sutun := 5
	var satir := ceili(Turler.SIRA.size() / float(sutun))
	var ust := _tank.end.y + 26.0
	var hucre := minf((ekran.x - 92.0) / sutun, (ekran.y - 40.0 - ust) / satir)
	var sol := (ekran.x - hucre * sutun) * 0.5
	for i in Turler.SIRA.size():
		var tur: String = Turler.SIRA[i]
		var r := Rect2(sol + (i % sutun) * hucre, ust + floori(i / float(sutun)) * hucre, hucre, hucre).grow(-5.0)
		var simge := TextureRect.new()
		simge.texture = Turler.doku(tur)
		simge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		simge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		simge.position = r.position + Vector2(8, 8)
		simge.size = r.size - Vector2(16, 16)
		simge.pivot_offset = simge.size * 0.5
		simge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var yakalandi := akvaryum.has(tur)
		if not yakalandi:
			var mat := ShaderMaterial.new()
			mat.shader = _siluet
			simge.material = mat
		_icerik.add_child(simge)
		_hucreler.append({"rect": r, "tur": tur, "dugum": simge, "yakalandi": yakalandi})
	_kapat = _geri_dugmesi()
	add_child(_kapat)
	_icerik.scale = Vector2(0.9, 0.9)
	_icerik.modulate.a = 0.0
	var tween := _icerik.create_tween().set_parallel()
	tween.tween_property(_icerik, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_icerik, "modulate:a", 1.0, 0.2)


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


func kapat() -> void:
	if not _acik:
		return
	_acik = false
	var tween := _icerik.create_tween()
	tween.tween_property(_icerik, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func() -> void:
		if not _acik:
			visible = false
		kapandi.emit())


func dokun(nokta: Vector2) -> void:
	if _kapat.get_global_rect().grow(10.0).has_point(nokta):
		_ses("dokun")
		kapat()
		return
	for y in _yuzenler:
		var s: Sprite2D = y["dugum"]
		if s.position.distance_to(nokta) < y["boy"] * 0.55:
			_takla(y)
			return
	for h in _hucreler:
		if h["rect"].has_point(nokta):
			var simge: TextureRect = h["dugum"]
			var tween := simge.create_tween()
			if h["yakalandi"]:
				_ses("takla")
				tween.tween_property(simge, "rotation", TAU, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween.tween_callback(func() -> void: simge.rotation = 0.0)
				for y in _yuzenler:
					if y["tur"] == h["tur"]:
						_takla(y)
			else:
				_ses("dokun")
				tween.tween_property(simge, "rotation", 0.12, 0.07)
				tween.tween_property(simge, "rotation", -0.12, 0.09)
				tween.tween_property(simge, "rotation", 0.0, 0.07)
			return


func _takla(y: Dictionary) -> void:
	_ses("takla")
	var s: Sprite2D = y["dugum"]
	var tween := s.create_tween()
	tween.tween_property(s, "rotation", TAU * signf(y["hiz"].x), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: s.rotation = 0.0)


func _ses(ad: String) -> void:
	if sesler:
		sesler.play(ad)


func _process(delta: float) -> void:
	if not _acik:
		return
	_zaman += delta
	var ic := _tank.grow(-40.0)
	ic.size.y -= 50.0
	for y in _yuzenler:
		var s: Sprite2D = y["dugum"]
		var hiz: Vector2 = y["hiz"]
		s.position.x += hiz.x * delta
		s.position.y = y["y"] + sin(_zaman * 1.4 + s.get_meta("faz")) * 8.0
		if (s.position.x < ic.position.x and hiz.x < 0.0) or (s.position.x > ic.end.x and hiz.x > 0.0):
			y["hiz"] = -hiz
			s.scale.x = -s.scale.x
	for c in _icerik.get_children():
		if c is Sprite2D and c.has_meta("faz") and c.centered == false:
			c.rotation = sin(_zaman * 0.9 + c.get_meta("faz")) * 0.07
	_icerik.queue_redraw()


func _ciz() -> void:
	# Panel
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("f2f8ff")
	panel.set_corner_radius_all(36)
	panel.shadow_color = Color(0, 0, 0.2, 0.3)
	panel.shadow_size = 16
	_icerik.draw_style_box(panel, Rect2(22, 130, size.x - 44, size.y - 150))
	# Akvaryum: su, kum, cam
	var bant := 18
	for i in bant:
		var t := float(i) / (bant - 1)
		_icerik.draw_rect(Rect2(_tank.position.x, _tank.position.y + _tank.size.y * i / bant, _tank.size.x, _tank.size.y / bant + 1.0),
			Color("bff0ff").lerp(Color("3aa0e0"), t))
	_icerik.draw_rect(Rect2(_tank.position.x, _tank.end.y - 34.0, _tank.size.x, 34.0), Color("f2d9a0"))
	for i in 18:
		_icerik.draw_circle(Vector2(_tank.position.x + 20.0 + i * (_tank.size.x - 40.0) / 17.0, _tank.end.y - 16.0 + (i % 3) * 5.0), 4.0, Color("d4b474"))
	var cam := StyleBoxFlat.new()
	cam.bg_color = Color(1, 1, 1, 0.0)
	cam.set_corner_radius_all(26)
	cam.set_border_width_all(10)
	cam.border_color = Color("8fb0d8")
	_icerik.draw_style_box(cam, _tank.grow(6.0))
	_icerik.draw_rect(Rect2(_tank.position.x + 18.0, _tank.position.y + 20.0, 16.0, _tank.size.y * 0.5), Color(1, 1, 1, 0.3))
	# Izgara hücreleri
	for h in _hucreler:
		var hucre := StyleBoxFlat.new()
		hucre.bg_color = Color(1, 1, 1, 0.95) if h["yakalandi"] else Color("e3e9f3")
		hucre.set_corner_radius_all(18)
		hucre.set_border_width_all(3)
		hucre.border_color = Color("bcd0ea")
		_icerik.draw_style_box(hucre, h["rect"])
