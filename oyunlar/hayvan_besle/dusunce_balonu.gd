extends Node2D
# Düşünce balonu (ThoughtBubble): hayvanın başının üstünde, istediği yiyeceğin resmi. Hayvan birden fazla
# istiyorsa resmin altında o kadar boş daire (rakam yok); her yiyecek verildiğinde biri dolar.
# İlk aşamalarda her zaman görünür (always); sonra sadece ipucu olarak kısa süre belirir (flash).
# Balon görseli 240x212'lik tuvalde (gorseller/balon.svg); içerik bu tuvalin koordinatlarında çizilir.

const TEX_BUBBLE: Texture2D = preload("res://oyunlar/hayvan_besle/gorseller/balon.svg")
const CANVAS := Vector2(240, 212)
const FOOD_CENTER := Vector2(122, 78)
const FOOD_SIZE := 96.0
const DOTS_Y := 138.0
const DOT_STEP := 34.0
const DOT_RADIUS := 12.0
const OUT := Color("3b2f6b")
const DOT_ON := Color("ff6f91")
const DOT_OFF := Color("ffffff")

var count: int = 1
var filled: int = 0
var always: bool = true
var shown: bool = false

var _canvas: Node2D
var _food: Sprite2D
var _dots: Node2D
var _dot_pops: Array[float] = []
var _tween: Tween
var _hide_at: float = -1.0
var _time: float = 0.0


# width: balonun ekrandaki genişliği (piksel)
func setup(food: FeedFoodData, want_count: int, width: float, always_visible: bool) -> void:
	count = want_count
	always = always_visible
	_dot_pops.resize(count)
	_dot_pops.fill(0.0)
	_canvas = Node2D.new()
	_canvas.scale = Vector2.ONE * width / CANVAS.x
	_canvas.position = -CANVAS / 2.0 * _canvas.scale
	add_child(_canvas)
	var bubble := Sprite2D.new()
	bubble.texture = TEX_BUBBLE
	bubble.centered = false
	bubble.scale = Vector2.ONE * CANVAS.x / TEX_BUBBLE.get_width()
	_canvas.add_child(bubble)
	_food = Sprite2D.new()
	_food.texture = food.texture
	var food_size := FOOD_SIZE if count > 1 else FOOD_SIZE * 1.3
	_food.scale = Vector2.ONE * food_size / food.texture.get_width()
	_food.position = FOOD_CENTER if count > 1 else FOOD_CENTER + Vector2(0, 14)
	_canvas.add_child(_food)
	_dots = Node2D.new()   # noktalar balon resminin üstünde çizilsin diye ayrı düğüm
	_canvas.add_child(_dots)
	_dots.draw.connect(_draw_dots)
	scale = Vector2.ZERO
	visible = false


# Balonun alt ucunun (başa doğru kabarcıkların) balon merkezine göre yeri
func tail_offset() -> Vector2:
	return (Vector2(52, 200) - CANVAS / 2.0) * _canvas.scale


func show_bubble(delay: float = 0.0) -> void:
	_hide_at = -1.0
	if shown:
		return
	shown = true
	visible = true
	_new_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_bubble(delay: float = 0.0) -> void:
	_hide_at = -1.0
	if not shown:
		return
	shown = false
	var tween := _new_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: visible = false)


# Kısa süreliğine görünür (ipucu); her zaman görünen balonda bir şey yapmaz, sadece zıplar
func flash(seconds: float) -> void:
	if always:
		bounce()
		return
	show_bubble()
	_hide_at = _time + seconds


func bounce() -> void:
	if not shown:
		return
	var tween := _new_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Bir yiyecek verildi: sıradaki nokta dolar ve zıplar
func fill_dot() -> void:
	filled = mini(filled + 1, count)
	if count > 1:
		var index := filled - 1
		var tween := create_tween()
		tween.tween_method(_set_pop.bind(index), 0.0, 1.0, 0.1)
		tween.tween_method(_set_pop.bind(index), 1.0, 0.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	bounce()


func dot_center(index: int) -> Vector2:
	var left := FOOD_CENTER.x - DOT_STEP * (count - 1) / 2.0
	return Vector2(left + index * DOT_STEP, DOTS_Y)


func _set_pop(value: float, index: int) -> void:
	_dot_pops[index] = value
	_dots.queue_redraw()


func _draw_dots() -> void:
	if count <= 1:
		return
	for i in count:
		var c := dot_center(i)
		var r := DOT_RADIUS * (1.0 + 0.5 * _dot_pops[i])
		_dots.draw_circle(c, r + 3.5, OUT)
		_dots.draw_circle(c, r, DOT_ON if i < filled else DOT_OFF)
		if i < filled:
			_dots.draw_circle(c + Vector2(-r * 0.35, -r * 0.35), r * 0.3, Color(1, 1, 1, 0.7))


func _process(delta: float) -> void:
	_time += delta
	if _hide_at > 0.0 and _time >= _hide_at:
		hide_bubble()
	# Hafifçe süzülür
	if _canvas:
		_canvas.position.y = -CANVAS.y / 2.0 * _canvas.scale.y + sin(_time * 2.0) * 3.0


func _new_tween() -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	return _tween
