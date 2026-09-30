extends "res://ortak/suruklenebilir.gd"
# Boyutlu nesne (SizedItem): boyut sırasını (rank; 0 = en büyük) bilen sürüklenebilir nesne. Yakalanma,
# parmağı izleme, yerine dönme, gelme/gitme ve zıplama ortak DraggableItem'dan (ortak/suruklenebilir.gd),
# dokunma ortak DragInput'tan gelir. Görseli SizeArt ile tam kendi boyutunda çizilir.
# Dokunma alanı görselden küçük olmaz ama en az touch x touch'tır (küçük nesne de rahat tutulsun).

var rank: int = 0
var art: String = ""
var visual: Vector2 = Vector2(100, 100)   # görünen boyut (px)
var color: Color = Color.WHITE
var touch: float = 86.0
## Yerine oturdu (ya da kutlamada): artık tutulamaz
var placed: bool = false

var sprite: Sprite2D
var _glow: Tween


func setup_item(item_art: String, item_rank: int, item_visual: Vector2, item_color: Color, start: Vector2, min_touch: float) -> void:
	art = item_art
	rank = item_rank
	visual = item_visual
	color = item_color
	touch = min_touch
	setup_drag(maxf(visual.x, visual.y), start)
	_build()


func _build() -> void:
	sprite = _make_sprite(art)
	add_child(sprite)


func _make_sprite(template: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = SizeArt.texture(template, visual, color)
	s.scale = Vector2.ONE / SizeArt.RASTER
	return s


func can_grab() -> bool:
	return not placed and visible


# Dokunma alanı: görselin padding katı, ama her kenarı en az touch
func grab_distance(point: Vector2, padding: float) -> float:
	var half := Vector2(maxf(visual.x * 0.5 * padding, touch * 0.5), maxf(visual.y * 0.5 * padding, touch * 0.5))
	var d := point - position
	if absf(d.x) <= half.x and absf(d.y) <= half.y:
		return d.length()
	return INF


func rect() -> Rect2:
	return Rect2(position - visual / 2.0, visual)


# Yerine yumuşakça kayar ve oturur (on_landed: oturunca çağrılır)
func seat(target: Vector2, duration: float, on_landed: Callable = Callable()) -> void:
	placed = true
	dragging = false
	var tween := _new_tween()
	tween.tween_property(self, "position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "rotation", 0.0, duration)
	_squash(tween)
	if on_landed.is_valid():
		tween.tween_callback(on_landed)


# Oturunca hafifçe basılıp esner
func _squash(tween: Tween) -> void:
	tween.tween_property(self, "scale", Vector2(1.08, 0.9), 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Yanlış yere bırakıldı: (varsa via noktasına gidip) hafifçe sallanır ve yumuşakça evine döner
func bounce_back(via: Vector2, go_via: bool, duration: float) -> void:
	dragging = false
	var tween := _new_tween()
	if go_via:
		tween.tween_property(self, "position", via, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for angle in [0.14, -0.12, 0.08, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.07)
	tween.tween_property(self, "position", home, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: z_index = Z_IDLE)


# İpucu: birkaç kez parlar ve kıpırdar
func glow() -> void:
	if _glow:
		_glow.kill()
	_glow = create_tween()
	for k in 3:
		_glow.tween_property(self, "modulate", Color(1.45, 1.45, 1.3), 0.22).set_trans(Tween.TRANS_SINE)
		_glow.tween_property(self, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_SINE)
	wiggle()


# Kutlamada selam: öne eğilip doğrulur
func bow(delay: float) -> void:
	var tween := _new_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2(1.06, 0.86), 0.16).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "rotation", 0.12, 0.16)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.3)
