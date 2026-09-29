extends Node2D
# Efektler (ekran koordinatında, enstrümanların üstünde):
# - notes(): dokunulan yerden parçanın renginde küçük ♪ / ♫ işaretleri süzülüp solar (havuzlu sprite'lar)
# - ring(): davulda dokunulan yerden yayılan halka dalgası (_draw ile)
# - confetti(): şarkı bitince yukarıdan dökülen renkli konfeti ve yıldızlar (_draw ile)

const G := "res://oyunlar/muzik_kutusu/gorseller/"
const TEX_NOTES: Array[Texture2D] = [preload(G + "nota.svg"), preload(G + "nota_cift.svg")]
const TEX_STAR: Texture2D = preload(G + "yildiz.svg")
const CONFETTI_COLORS: Array[Color] = [
	Color("ff5b5b"), Color("ff9a3d"), Color("ffd23f"), Color("7bd85a"), Color("36cfc9"), Color("4aa3ff"), Color("8b6cf6"), Color("ff6fb5"),
]
const MAX_NOTES := 40

var _notes: Array[Sprite2D] = []
var _rings: Array[Dictionary] = []      # {pos, age, radius, color}
var _confetti: Array[Dictionary] = []   # {pos, vel, rot, spin, color, size, star}


func notes(at: Vector2, color: Color, count: int = 2) -> void:
	for k in count:
		var sprite := _free_note()
		sprite.texture = TEX_NOTES[randi() % TEX_NOTES.size()]
		var size := randf_range(42.0, 58.0)
		sprite.scale = Vector2.ONE * size / sprite.texture.get_width() * 0.4
		# Renk: beyaz dolgu parçanın renginde görünsün diye çarpılır; koyu hat koyulaşır ama okunur kalır
		sprite.modulate = Color(color.lightened(0.15), 1.0)
		sprite.position = at + Vector2(randf_range(-20.0, 20.0), -10.0)
		sprite.rotation = randf_range(-0.3, 0.3)
		sprite.show()
		var drift := Vector2(randf_range(-70.0, 70.0), -randf_range(120.0, 190.0))
		var time := randf_range(0.8, 1.1)
		var full := Vector2.ONE * size / sprite.texture.get_width()
		var tween := sprite.create_tween().set_parallel()
		tween.tween_property(sprite, "scale", full, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "position", sprite.position + drift, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "rotation", sprite.rotation + randf_range(-0.6, 0.6), time)
		tween.tween_property(sprite, "modulate:a", 0.0, time * 0.6).set_delay(time * 0.4)
		tween.chain().tween_callback(sprite.hide)


# Boşta bir nota sprite'ı; hepsi doluysa en eskisi yeniden kullanılır
func _free_note() -> Sprite2D:
	for sprite in _notes:
		if not sprite.visible:
			_notes.erase(sprite)
			_notes.append(sprite)
			return sprite
	if _notes.size() < MAX_NOTES:
		var sprite := Sprite2D.new()
		add_child(sprite)
		_notes.append(sprite)
		return sprite
	var oldest: Sprite2D = _notes.pop_front()
	_notes.append(oldest)
	return oldest


func ring(at: Vector2, radius: float, color: Color) -> void:
	_rings.append({"pos": at, "age": 0.0, "radius": radius, "color": color})
	if _rings.size() > 24:
		_rings.pop_front()


func confetti(area: Vector2) -> void:
	for k in 90:
		var star := k % 6 == 0
		_confetti.append({
			"pos": Vector2(randf_range(0.0, area.x), randf_range(-260.0, -20.0)),
			"vel": Vector2(randf_range(-60.0, 60.0), randf_range(180.0, 320.0)),
			"rot": randf() * TAU,
			"spin": randf_range(-6.0, 6.0),
			"color": CONFETTI_COLORS.pick_random(),
			"size": randf_range(30.0, 44.0) if star else randf_range(12.0, 20.0),
			"star": star,
			"limit": area.y + 60.0,
		})


func _process(delta: float) -> void:
	if _rings.is_empty() and _confetti.is_empty():
		return
	for r in _rings:
		r["age"] += delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r["age"] < 0.55)
	for c in _confetti:
		c["vel"].y += 60.0 * delta
		c["pos"] += c["vel"] * delta + Vector2(sin(c["rot"]) * 40.0 * delta, 0.0)
		c["rot"] += c["spin"] * delta
	_confetti = _confetti.filter(func(c: Dictionary) -> bool: return c["pos"].y < c["limit"])
	queue_redraw()


func _draw() -> void:
	for r in _rings:
		var t: float = r["age"] / 0.55
		var radius: float = r["radius"] * (0.35 + 0.9 * t)
		var color: Color = r["color"]
		draw_arc(r["pos"], radius, 0.0, TAU, 48, Color(color.lightened(0.3), 0.85 * (1.0 - t)), 12.0 * (1.0 - t) + 3.0, true)
		draw_arc(r["pos"], radius * 0.72, 0.0, TAU, 40, Color(1, 1, 1, 0.6 * (1.0 - t)), 5.0 * (1.0 - t) + 1.0, true)
	for c in _confetti:
		var size: float = c["size"]
		draw_set_transform(c["pos"], c["rot"], Vector2.ONE)
		if c["star"]:
			draw_texture_rect(TEX_STAR, Rect2(-size / 2.0, -size / 2.0, size, size), false)
		else:
			draw_rect(Rect2(-size / 2.0, -size * 0.3, size, size * 0.6), c["color"])
	draw_set_transform(Vector2.ZERO)


func is_celebrating() -> bool:
	return not _confetti.is_empty()
