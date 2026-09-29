extends Node2D
# Üstte yazısız bölüm ilerlemesi: yuvarlak bir çubuk, biten bölümler kadar dolar; sonunda bir yıldız.
# Çubuk düğüm konumunu merkez alır. Bölümler arası ince çentikler bölüm sayısını gösterir.

const TEX_STAR: Texture2D = preload("res://oyunlar/toplama/gorseller/yildiz.svg")
const TRACK := Color(1, 1, 1, 0.75)
const FILL := Color("ffb23f")
const FILL_LIGHT := Color("ffd873")
const OUTLINE := Color(0.29, 0.23, 0.42, 0.7)

var width: float = 600.0
var height: float = 30.0
var count: int = 20

var _shown: float = 0.0         # dolu bölüm sayısı (animasyonlu, kesirli olabilir)
var _star_scale: float = 1.0


func setup(level_count: int, completed: int) -> void:
	count = maxi(level_count, 1)
	_shown = completed
	queue_redraw()


# Bir bölüm bitti: çubuk o bölümün sonuna kadar dolar
func complete(index: int) -> void:
	var tween := create_tween()
	tween.tween_method(_set_shown, _shown, float(index + 1), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if index + 1 >= count:
		tween.tween_method(_set_star, 1.0, 1.8, 0.2)
		tween.tween_method(_set_star, 1.8, 1.0, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Final sonrası baştan: çubuk boşalır
func reset() -> void:
	create_tween().tween_method(_set_shown, _shown, 0.0, 0.5).set_trans(Tween.TRANS_SINE)


func _set_shown(value: float) -> void:
	_shown = value
	queue_redraw()


func _set_star(value: float) -> void:
	_star_scale = value
	queue_redraw()


func _draw() -> void:
	var bar_width := width - height * 1.6    # sağda yıldıza yer
	var left := -width / 2.0
	var track := Rect2(left, -height / 2.0, bar_width, height)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(int(height / 2.0))
	style.bg_color = TRACK
	style.set_border_width_all(4)
	style.border_color = OUTLINE
	draw_style_box(style, track)
	# Dolu kısım
	var ratio := clampf(_shown / count, 0.0, 1.0)
	if ratio > 0.0:
		var inner := track.grow(-4.0)
		var fill := StyleBoxFlat.new()
		fill.set_corner_radius_all(int(inner.size.y / 2.0))
		fill.bg_color = FILL
		var fill_width := maxf(inner.size.y, inner.size.x * ratio)
		draw_style_box(fill, Rect2(inner.position, Vector2(fill_width, inner.size.y)))
		draw_line(inner.position + Vector2(inner.size.y / 2.0, 5.0), inner.position + Vector2(fill_width - inner.size.y / 2.0, 5.0), FILL_LIGHT, 4.0, true)
	# Bölüm çentikleri
	for i in range(1, count):
		var x := left + bar_width * i / count
		draw_line(Vector2(x, -height / 2.0 + 8.0), Vector2(x, height / 2.0 - 8.0), Color(OUTLINE, 0.25), 2.0, true)
	# Sondaki yıldız: bitince renkli, yoksa soluk
	var star_size := height * 1.7 * _star_scale
	var center := Vector2(width / 2.0 - height * 0.8, 0.0)
	var color := Color.WHITE if _shown >= count - 0.01 else Color(1, 1, 1, 0.45)
	draw_texture_rect(TEX_STAR, Rect2(center - Vector2(star_size, star_size) / 2.0, Vector2(star_size, star_size)), false, color)
