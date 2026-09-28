extends Node2D
# Üstte bölüm ilerlemesi: her bölüm için bir nokta (yazı yok). Biten bölümler altın sarısı,
# şu anki bölüm beyaz ve hafifçe nabız gibi atar, sıradakiler soluk.

const DONE := Color("ffcf3a")
const CURRENT := Color("ffffff")
const LATER := Color(1, 1, 1, 0.45)
const OUTLINE := Color(0.29, 0.23, 0.42, 0.55)

var count: int = 10
var current: int = 0
var spacing: float = 34.0
var radius: float = 10.0

var _pops: Array[float] = []      # her noktanın ek büyüme miktarı (animasyon)
var _time: float = 0.0


func setup(level_count: int) -> void:
	count = level_count
	_pops.resize(count)
	_pops.fill(0.0)
	queue_redraw()


func set_current(index: int) -> void:
	current = index
	queue_redraw()


# Bölüm bitince o nokta altın rengine döner ve zıplar
func complete(index: int) -> void:
	current = index + 1
	_pop(index, 0.0)


# Final: bütün noktalar sırayla zıplar
func celebrate_all() -> void:
	current = count
	for i in count:
		_pop(i, i * 0.06)


func _pop(index: int, delay: float) -> void:
	if index < 0 or index >= count:
		return
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_method(_set_pop.bind(index), 0.0, 1.0, 0.12)
	tween.tween_method(_set_pop.bind(index), 1.0, 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _set_pop(value: float, index: int) -> void:
	_pops[index] = value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if current < count:
		queue_redraw()


func _draw() -> void:
	var left := -spacing * (count - 1) / 2.0
	for i in count:
		var center := Vector2(left + i * spacing, 0.0)
		var r := radius * (1.0 + _pops[i] * 0.7)
		var color := LATER
		if i < current:
			color = DONE
		elif i == current:
			color = CURRENT
			r *= 1.25 + sin(_time * 4.0) * 0.08
		draw_circle(center, r + 3.0, OUTLINE)
		draw_circle(center, r, color)
