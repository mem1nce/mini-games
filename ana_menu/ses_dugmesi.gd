extends Control
# Ana menüdeki küçük ses düğmesi (sağ üst): her dokunuşta hepsi açık → sadece efektler → sessiz.
# Mod SesYoneticisi'nde tutulur ve user://ses_ayari.cfg'ye kaydedilir. Dokunmayı ana_menu.gd yönetir.

const SIMGELER: Array[Texture2D] = [
	preload("res://ana_menu/gorseller/ses_hepsi.svg"),
	preload("res://ana_menu/gorseller/ses_efekt.svg"),
	preload("res://ana_menu/gorseller/ses_kapali.svg"),
]
const DOKUNMA_PAYI := 18.0      # görünenden geniş dokunma alanı (84 + 2x18 = 120 px)

var _ic: Control
var _simge: TextureRect


func kur(boyut: float) -> void:
	size = Vector2(boyut, boyut)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic = Control.new()
	_ic.size = size
	_ic.pivot_offset = size / 2.0
	_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic.draw.connect(_ciz)
	add_child(_ic)
	_simge = TextureRect.new()
	_simge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_simge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_simge.size = size * 0.72
	_simge.position = size * 0.14
	_simge.pivot_offset = _simge.size / 2.0
	_simge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic.add_child(_simge)
	_simge.texture = SIMGELER[SesYoneticisi.mod]


func icinde_mi(nokta: Vector2) -> bool:
	return get_global_rect().grow(DOKUNMA_PAYI).has_point(nokta)


func bas() -> void:
	_ic.create_tween().tween_property(_ic, "scale", Vector2(0.88, 0.88), 0.08).set_trans(Tween.TRANS_SINE)


func iptal() -> void:
	_ic.create_tween().tween_property(_ic, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)


# Sonraki moda geçer; simge küçülüp yenisiyle büyür
func degistir() -> void:
	var mod := SesYoneticisi.sonraki_mod()
	SesYoneticisi.efekt("dugme_tik")
	var tween := _ic.create_tween()
	tween.tween_property(_simge, "scale", Vector2(0.6, 0.6), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: _simge.texture = SIMGELER[mod])
	tween.tween_property(_simge, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_ic, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ciz() -> void:
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(1, 1, 1, 0.8)
	stil.set_corner_radius_all(roundi(size.x / 2.0))
	stil.set_border_width_all(3)
	stil.border_color = Color("e4ddff")
	stil.shadow_color = Color(0.35, 0.25, 0.55, 0.1)
	stil.shadow_size = 6
	stil.shadow_offset = Vector2(0, 3)
	stil.anti_aliasing_size = 1.2
	_ic.draw_style_box(stil, Rect2(Vector2.ZERO, size))
