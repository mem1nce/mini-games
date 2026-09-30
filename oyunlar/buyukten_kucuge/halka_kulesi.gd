extends SizeActivity
# Halka Kulesi (RingTower): sağda tabanlı direk, zeminde dağınık halkalar. Çocuk halkaları direğe sürükler;
# kule en büyük halka altta olacak şekilde kurulur. Doğru halka (kalanların en büyüğü) direğin tepesine
# gelip aşağı kayar, yerine oturur ve kendi notasını çalar (her halka bir öncekinden tiz: kule bitince
# notalar küçük bir melodi olur). Yanlış halka direğin tepesinde hafifçe sallanıp evine döner.
# Kule bitince tepesine yıldız konar, halkalar alttan üste kendi notalarıyla zıplar.

const TEX_STAR: Texture2D = preload("res://oyunlar/buyukten_kucuge/gorseller/yildiz.svg")

var next_rank: int = 0          # sıradaki doğru halka (kalanların en büyüğü)
var rod: Sprite2D
var star: Sprite2D
var _landed: int = 0


func build() -> void:
	rod = Sprite2D.new()
	rod.texture = SizeArt.texture("direk", plan.rod.size, plan.rod_color)
	rod.scale = Vector2.ONE / SizeArt.RASTER
	rod.position = plan.rod.get_center()
	add_child(rod)
	var tween := rod.create_tween()
	rod.scale = Vector2(1.0, 0.0) / SizeArt.RASTER
	rod.position.y = plan.rod.end.y
	tween.tween_property(rod, "scale", Vector2.ONE / SizeArt.RASTER, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(rod, "position:y", plan.rod.get_center().y, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spawn_items(Item, "halka")


# Direğin tepesinin biraz üstü: halka önce buraya gelir, sonra aşağı kayar
func rod_top(item: Item) -> Vector2:
	return Vector2(plan.rod.get_center().x, plan.rod.position.y - item.visual.y * 0.35)


# Bırakma alanı: direğin çevresi (en büyük halka genişliğinde) ve tepesinin biraz üstü
func drop_area() -> Rect2:
	var w := plan.sizes[0].x
	var top := plan.rod.position.y - plan.sizes[0].y * 1.2
	return drag_input.drop_area(Rect2(plan.rod.get_center().x - w / 2.0, top, w, plan.base_top - top))


func _on_dropped(item: Item, point: Vector2) -> void:
	if not drop_area().has_point(point):
		return_quietly(item)
	elif item.rank == next_rank:
		_place(item)
	else:
		refuse(item, rod_top(item))


func _place(ring: Item) -> void:
	next_rank += 1
	ring.placed = true
	ring.dragging = false
	ring.z_index = 2 + ring.rank
	var target: Vector2 = plan.targets[ring.rank]
	var top := rod_top(ring)
	var tween := ring._new_tween()
	tween.tween_property(ring, "position", top, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(ring, "rotation", 0.0, 0.2)
	tween.tween_callback(sounds.play.bind("kayma"))
	var fall := clampf((target.y - top.y) / 900.0, 0.22, 0.5)
	tween.tween_property(ring, "position", target, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_landed.bind(ring))
	ring._squash(tween)


func _on_landed(ring: Item) -> void:
	sounds.note(ring.rank)
	effects.sparkle(ring.position, ring.visual.x * 0.6)
	_landed += 1
	if _landed == plan.count:
		finish()


func hint_move() -> Array:
	for item: Item in items:
		if item.rank == next_rank and not item.placed:
			return [item, rod_top(item)]
	return []


func celebrate() -> void:
	# Tepeye yıldız konar, sonra halkalar alttan üste kendi notalarıyla zıplar
	var top_ring: Item = items[plan.count - 1]
	star = Sprite2D.new()
	star.texture = TEX_STAR
	var star_size := clampf(plan.sizes[0].x * 0.45, 70.0, 130.0)
	var star_scale := Vector2.ONE * star_size / TEX_STAR.get_width()
	star.position = Vector2(plan.rod.get_center().x, plan.rod.position.y - star_size * 0.2)
	star.scale = Vector2.ZERO
	star.z_index = 10
	add_child(star)
	var from := star.position - Vector2(0.0, star_size * 1.5)
	var landing := Vector2(star.position.x, top_ring.position.y - top_ring.visual.y / 2.0 - star_size * 0.42)
	star.position = from
	var tween := star.create_tween()
	tween.tween_property(star, "scale", star_scale, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "rotation", TAU, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(star, "position", landing, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	sounds.play("yildiz")
	await tween.finished
	effects.stars(landing, star_size * 1.4)
	await play_scale(items, 0.2)
