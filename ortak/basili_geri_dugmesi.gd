extends Control
# Basılı tutulunca çalışan geri düğmesi: parmak basılı kaldıkça çevresinde bir halka dolar,
# dolunca "completed" sinyali gelir. Erken bırakılırsa halka geri söner. Böylece küçük çocuklar
# kazara dokunarak oyundan çıkmaz. Dokunmayı ana sahne yönetir (press/release çağırır).

signal completed

const ICON: Texture2D = preload("res://ortak/gorseller/geri.svg")
const BG := Color(1, 1, 1, 0.95)
const BORDER := Color(0.23, 0.18, 0.42)
const RING := Color("ff7a9a")
const RING_BG := Color(0.23, 0.18, 0.42, 0.15)

var hold_time: float = 0.6
## Düğmenin dolgu rengi ve ikonu (oyun kendi renginde düğme isterse değiştirir)
var bg_color: Color = BG
var icon: Texture2D = ICON
var _progress: float = 0.0
var _holding: bool = false
var _done: bool = false
var _finger: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size / 2.0
	# Çentikli telefonlarda düğme çentiğin altında kalmasın: oyun yerini verdikten sonra güvenli alana alınır
	EkranYardimcisi.degisince(_guvenliye_al)
	_guvenliye_al.call_deferred()


## Düğmeyi güvenli alanın içine iter. Oyun düğmeyi sonradan başka bir yere taşırsa yeniden çağırabilir.
func _guvenliye_al() -> void:
	EkranYardimcisi.guvenliye_it(self)


## Sahnedeki hazır bir Panel'in yerine geçer (aynı konum ve boyut, aynı üst düğüm); Panel gizlenir.
static func replace(panel: Control, time: float = 0.6) -> Control:
	var button := new()
	button.position = panel.position
	button.size = panel.size
	button.hold_time = time
	panel.get_parent().add_child(button)
	panel.hide()
	return button


func contains(point: Vector2) -> bool:
	return is_visible_in_tree() and get_global_rect().grow(10.0).has_point(point)


## Dokunma olayını kendi parmağıyla takip eder; olayı kullandıysa true döner.
func handle_touch(touch: InputEventScreenTouch) -> bool:
	if touch.pressed:
		if _finger == -1 and contains(touch.position):
			_finger = touch.index
			press()
			return true
		return false
	if touch.index == _finger:
		_finger = -1
		release()
		return true
	return false


## Aynı sahnede tekrar kullanılacaksa (tamamlanınca ekran değişmiyorsa) düğmeyi sıfırlar.
func reset() -> void:
	_done = false
	_holding = false
	_finger = -1
	_progress = 0.0
	scale = Vector2.ONE
	queue_redraw()


func press() -> void:
	_holding = true
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.08)


func release() -> void:
	_holding = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if _done:
		return
	var before := _progress
	if _holding:
		_progress = minf(1.0, _progress + delta / hold_time)
		if _progress >= 1.0:
			_done = true
			completed.emit()
	else:
		_progress = maxf(0.0, _progress - delta * 3.0)
	if _progress != before:
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center + Vector2(0, 6), radius - 6.0, Color(0.2, 0.1, 0.3, 0.16))
	draw_circle(center, radius - 8.0, bg_color)
	draw_arc(center, radius - 8.0, 0.0, TAU, 48, BORDER, 5.0, true)
	var icon_size := radius * 1.0
	draw_texture_rect(icon, Rect2(center - Vector2(icon_size, icon_size) / 2.0, Vector2(icon_size, icon_size)), false)
	if _progress > 0.0:
		draw_arc(center, radius - 1.0, 0.0, TAU, 48, RING_BG, 10.0, true)
		draw_arc(center, radius - 1.0, -PI / 2.0, -PI / 2.0 + TAU * _progress, 48, RING, 10.0, true)
