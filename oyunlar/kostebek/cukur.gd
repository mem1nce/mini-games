extends Node2D
# Hole: bir çukur. Katmanlar (arkadan öne): çukurun arkası (toprak tümseği + koyu ağız),
# maske (içindeki nesne sadece ağız çizgisinin üstünde ve ağzın içinde görünür),
# ön toprak dudağı (nesnenin alt kısmını örter). Böylece nesne çukurun içinden çıkıyormuş gibi görünür.
# Birimler: çukur SVG'lerinin 320x200 tuvali; düğümün merkezi ağzın merkezi (tuvalde 160,100).

signal emptied(hole: Node2D)

const TEX_BACK: Texture2D = preload("res://oyunlar/kostebek/gorseller/cukur_arka.svg")
const TEX_FRONT: Texture2D = preload("res://oyunlar/kostebek/gorseller/cukur_on.svg")
const WIDTH := 320.0
const MOUTH := Vector2(126.0, 40.0)    # ağız elipsinin yarıçapları (konturun biraz içi)
# Nesneler çukurun üstüne bu kadar taşar / ön dudak altta bu kadar yer kaplar (yerleşim için)
const TOP_EXTENT := 270.0
const BOTTOM_EXTENT := 70.0

var item: Node2D = null
var free_since: float = -100.0          # boşaldığı an (çıkış yöneticisinin saatine göre)
var _mask: Node2D
var _base_scale := Vector2.ONE


func _ready() -> void:
	var back := Sprite2D.new()
	back.texture = TEX_BACK
	back.scale = Vector2(0.5, 0.5)
	add_child(back)
	_mask = Node2D.new()
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_mask.draw.connect(_draw_mask)
	add_child(_mask)
	var front := Sprite2D.new()
	front.texture = TEX_FRONT
	front.scale = Vector2(0.5, 0.5)
	add_child(front)


# Maske: ağız çizgisinin üstündeki her yer + ağzın alt yarısı
func _draw_mask() -> void:
	var points := PackedVector2Array([Vector2(-170, -700), Vector2(170, -700), Vector2(170, 0), Vector2(MOUTH.x, 0)])
	for k in range(1, 24):
		var angle := PI * k / 24.0
		points.append(Vector2(cos(angle) * MOUTH.x, sin(angle) * MOUTH.y))
	points.append(Vector2(-MOUTH.x, 0))
	points.append(Vector2(-170, 0))
	_mask.draw_colored_polygon(points, Color.WHITE)


func place(center: Vector2, width: float) -> void:
	position = center
	_base_scale = Vector2.ONE * width / WIDTH
	scale = _base_scale


func is_free() -> bool:
	return item == null


func put(new_item: Node2D) -> void:
	item = new_item
	_mask.add_child(new_item)
	new_item.finished.connect(_on_item_finished)


func _on_item_finished(finished_item: Node2D) -> void:
	if finished_item == item:
		item = null
		emptied.emit(self)


# Dokunma alanı (ekran koordinatı): nesnenin görünen kısmı, biraz büyütülmüş, en az min_size
func touch_rect(padding: float, min_size: float) -> Rect2:
	if item == null:
		return Rect2()
	var local: Rect2 = item.visible_rect()
	var s := global_scale
	var rect := Rect2(global_transform * local.position, local.size * s)
	var grown := rect.size * padding
	grown = Vector2(maxf(grown.x, min_size), maxf(grown.y, min_size))
	return Rect2(rect.get_center() - grown / 2.0, grown)


func appear(delay: float) -> void:
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", _base_scale, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear(delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
