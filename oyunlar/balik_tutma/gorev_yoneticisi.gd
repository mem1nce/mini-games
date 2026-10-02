extends Control
# Görev: ekranın üstündeki baloncukta yazısız, resimle. Her adet bir simge (istenen renk/desen/boyutta soluk
# balık ya da çöp). Görevdeki nesne toplanınca sıradaki simge renklenir, zıplar ve parlar. Bir nesne listedeki
# ilk uyan ve dolmamış gereksinime sayılır. Hepsi dolunca "tamamlandi" sinyali gelir.

signal tamamlandi

const Turler := preload("res://oyunlar/balik_tutma/balik_turleri.gd")
const G := "res://oyunlar/balik_tutma/gorseller/"
const COP_TURLERI := ["sise", "poset", "teneke"]
const SIMGE := 72.0
const BALON_Y := 60.0         # görev baloncuğunun üst kenarı (penguenin kafasının üstünde kalsın)
const SOLUK := """
shader_type canvas_item;
// Baloncuktaki henüz toplanmamış simge soluk ve yarı saydam; dolu = 1 olunca asıl renkleri.
uniform float dolu : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	// COLOR burada doku rengiyle çarpılmış olarak gelir
	vec4 c = COLOR;
	float gri = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 soluk = mix(mix(vec3(gri), c.rgb, 0.55), vec3(1.0), 0.35);
	COLOR = vec4(mix(soluk, c.rgb, dolu), c.a * mix(0.55, 1.0, dolu));
}
"""

var gereksinimler: Array = []     # {"g": gereksinim, "dolu": n, "simgeler": [TextureRect]}
var _golge := Shader.new()
var _balon: Control
var _zaman := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_golge.code = SOLUK


func kur(gorev: Array, ekran_x: float) -> void:
	for c in get_children():
		c.queue_free()
	gereksinimler.clear()
	# Simgelerin boyları ve toplam genişlik
	var satir: Array = []
	var genislik := 0.0
	for g in gorev:
		var boy := SIMGE * (1.25 if g.get("boyut", "") == "buyuk" else (0.78 if g.get("boyut", "") == "kucuk" else 1.0))
		satir.append(boy)
		genislik += boy * int(g["adet"]) + 6.0 * (int(g["adet"]) - 1)
	genislik += 26.0 * (gorev.size() - 1)
	var olcek := minf(1.0, (ekran_x - 220.0) / (genislik + 40.0))
	var balon_boyu := Vector2(genislik * olcek + 44.0, SIMGE * 1.25 * olcek + 30.0)
	_balon = Control.new()
	_balon.size = balon_boyu
	_balon.position = Vector2((ekran_x - balon_boyu.x) * 0.5, BALON_Y)
	_balon.pivot_offset = balon_boyu * 0.5
	_balon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balon.draw.connect(_balonu_ciz)
	add_child(_balon)
	var x := 22.0
	for i in gorev.size():
		var g: Dictionary = gorev[i]
		var boy: float = satir[i] * olcek
		var kayit := {"g": g, "dolu": 0, "simgeler": []}
		for k in int(g["adet"]):
			var simge := TextureRect.new()
			simge.texture = _simge_dokusu(g, k)
			simge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			simge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			simge.size = Vector2(boy, boy)
			simge.pivot_offset = simge.size * 0.5
			simge.position = Vector2(x, (balon_boyu.y - boy) * 0.5)
			simge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var mat := ShaderMaterial.new()
			mat.shader = _golge
			simge.material = mat
			_balon.add_child(simge)
			kayit["simgeler"].append(simge)
			x += boy + 6.0
		x += 20.0
		gereksinimler.append(kayit)
	_balon.scale = Vector2(0.6, 0.6)
	_balon.modulate.a = 0.0
	var tween := _balon.create_tween().set_parallel()
	tween.tween_property(_balon, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_balon, "modulate:a", 1.0, 0.25)


func _simge_dokusu(g: Dictionary, sira: int) -> Texture2D:
	if g.get("cop", false):
		return load(G + "cop_%s.svg" % COP_TURLERI[sira % COP_TURLERI.size()])
	return Turler.ikon(g)


func _balonu_ciz() -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(1, 1, 1, 0.94)
	stil.set_corner_radius_all(int(_balon.size.y * 0.5))
	stil.set_border_width_all(5)
	stil.border_color = Color("8fc9ef")
	stil.shadow_color = Color(0.1, 0.2, 0.35, 0.22)
	stil.shadow_size = 10
	stil.shadow_offset = Vector2(0, 6)
	_balon.draw_style_box(stil, Rect2(Vector2.ZERO, _balon.size))
	# Baloncuk kabarcıkları (düşünce balonu gibi)
	_balon.draw_circle(Vector2(_balon.size.x * 0.16, _balon.size.y + 16.0), 11.0, Color(1, 1, 1, 0.9))
	_balon.draw_circle(Vector2(_balon.size.x * 0.12, _balon.size.y + 36.0), 7.0, Color(1, 1, 1, 0.85))


func gerekli_mi(nesne: Dictionary) -> bool:
	return _sira(nesne) >= 0


func _sira(nesne: Dictionary) -> int:
	for i in gereksinimler.size():
		var k: Dictionary = gereksinimler[i]
		if k["dolu"] < int(k["g"]["adet"]) and Turler.eslesir(k["g"], nesne):
			return i
	return -1


# Nesneyi göreve sayar; dolan simgenin ekrandaki ortasını döner (sayılmazsa Vector2.INF)
func isle(nesne: Dictionary) -> Vector2:
	var i := _sira(nesne)
	if i < 0:
		return Vector2.INF
	var k: Dictionary = gereksinimler[i]
	var simge: TextureRect = k["simgeler"][k["dolu"]]
	k["dolu"] += 1
	var mat: ShaderMaterial = simge.material
	var tween := simge.create_tween().set_parallel()
	tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("dolu", v), 0.0, 1.0, 0.35)
	tween.tween_property(simge, "scale", Vector2(1.35, 1.35), 0.15).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property(simge, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if tamam():
		tamamlandi.emit()
	return simge.get_global_rect().get_center()


func tamam() -> bool:
	for k in gereksinimler:
		if k["dolu"] < int(k["g"]["adet"]):
			return false
	return not gereksinimler.is_empty()


func _process(delta: float) -> void:
	_zaman += delta
	if _balon:
		_balon.position.y = BALON_Y + sin(_zaman * 1.4) * 3.0
