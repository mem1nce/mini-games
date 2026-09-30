extends SizeActivity
# Sıralama Dizisi (SortRow): ortada yan yana yuvalar, altta (zeminde) karışık nesneler. Nesneler yuvalara
# soldan sağa büyükten küçüğe (ters bölümlerde küçükten büyüğe) yerleşir. Her yuva bir sıraya aittir;
# yuvalar istenen sırayla doldurulabilir. Doğru yuvaya bırakılan nesne oturur ve kendi notasını çalar;
# yanlış yuvadaki nesne yumuşakça evine döner.
# Yuvaların üstünde metinsiz yön ipucu: soldan sağa küçülen (ters bölümde büyüyen) üç nokta. Yön değişen
# bölümün başında noktalar sırayla büyüyüp parlar. İlk bölümlerde yuvalarda kesik çizgili siluet vardır.

const Silhouette := preload("res://oyunlar/buyukten_kucuge/siluet.gd")
const TEX_SLOT: Texture2D = preload("res://oyunlar/buyukten_kucuge/gorseller/yuva.svg")
const TEX_DOT: Texture2D = preload("res://oyunlar/buyukten_kucuge/gorseller/nokta.svg")
const SLOT_MARGIN := 30.0        # yuva.svg köşe payı (SVG biriminde)
const DOT_SIZES := [38.0, 29.0, 21.0]

var slots: Array[Node2D] = []
var silhouettes: Array = []     # yuva -> Silhouette ya da null
var filled: Array[bool] = []
var dots: Array[Sprite2D] = []
var _placed: int = 0


func build() -> void:
	var tex_scale := TEX_SLOT.get_width() / 96.0
	for s in plan.count:
		var rect: Rect2 = plan.slots[s]
		# Yuva: ortasında duran bir düğüm ve içinde NinePatch (doku 2x çizildiği için yarı ölçekte)
		var slot := Node2D.new()
		slot.position = rect.get_center()
		var panel := NinePatchRect.new()
		panel.texture = TEX_SLOT
		panel.patch_margin_left = int(SLOT_MARGIN * tex_scale)
		panel.patch_margin_right = int(SLOT_MARGIN * tex_scale)
		panel.patch_margin_top = int(SLOT_MARGIN * tex_scale)
		panel.patch_margin_bottom = int(SLOT_MARGIN * tex_scale)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.scale = Vector2.ONE / tex_scale
		panel.size = rect.size * tex_scale
		panel.position = -rect.size / 2.0
		slot.add_child(panel)
		add_child(slot)
		slots.append(slot)
		filled.append(false)
		_pop_in(slot, 0.05 + s * 0.06)
		var silhouette: Silhouette = null
		if plan.level.silhouettes:
			var rank := plan.slot_rank[s]
			silhouette = Silhouette.new()
			add_child(silhouette)
			silhouette.position = plan.targets[rank]
			silhouette.setup(plan.art, plan.sizes[rank], plan.colors[rank])
			_pop_in(silhouette, 0.15 + s * 0.06)
		silhouettes.append(silhouette)
	_build_dots()
	spawn_items(Item, plan.art)
	if plan.direction_changed:
		later(0.9, _announce_direction)


# Yön ipucu: soldan sağa küçülen (ters yönde büyüyen) üç nokta
func _build_dots() -> void:
	var sizes: Array = DOT_SIZES.duplicate()
	if plan.level.ascending:
		sizes.reverse()
	var spacing := 58.0
	for k in 3:
		var dot := Sprite2D.new()
		dot.texture = TEX_DOT
		dot.position = plan.hint_center + Vector2((k - 1) * spacing, 0.0)
		dot.scale = Vector2.ONE * sizes[k] / TEX_DOT.get_width()
		dot.set_meta("size", sizes[k])
		add_child(dot)
		dots.append(dot)
		_pop_in(dot, 0.1 + k * 0.08)


# Yön değişti (ya da ilk kez): noktalar soldan sağa sırayla büyüyüp parlar, büyük nokta pes çalar
func _announce_direction() -> void:
	for k in dots.size():
		var dot := dots[k]
		var base := Vector2.ONE * float(dot.get_meta("size")) / TEX_DOT.get_width()
		var tween := dot.create_tween()
		tween.tween_interval(k * 0.3)
		tween.tween_callback(func() -> void:
			sounds.note(DOT_SIZES.find(float(dot.get_meta("size"))) * 2)
			effects.sparkle(dot.position, 60.0))
		tween.tween_property(dot, "scale", base * 1.7, 0.16).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(dot, "modulate", Color(1.5, 1.5, 1.4), 0.16)
		tween.tween_property(dot, "scale", base, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(dot, "modulate", Color.WHITE, 0.35)


func _pop_in(node: CanvasItem, delay: float) -> void:
	var target: Vector2 = node.scale
	node.scale = Vector2.ZERO
	var tween := node.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(node, "scale", target, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Bırakılan noktayı içeren (toleranslı) yuvalardan merkezi en yakın olanı
func slot_at(point: Vector2) -> int:
	var best := -1
	var best_distance := INF
	for s in plan.count:
		var rect: Rect2 = plan.slots[s]
		if drag_input.drop_area(rect).has_point(point):
			var distance := point.distance_to(rect.get_center())
			if distance < best_distance:
				best_distance = distance
				best = s
	return best


func _on_dropped(item: Item, point: Vector2) -> void:
	var s := slot_at(point)
	if s < 0:
		return_quietly(item)
	elif not filled[s] and plan.slot_rank[s] == item.rank:
		_place(item, s)
	else:
		refuse(item)


func _place(item: Item, s: int) -> void:
	filled[s] = true
	item.z_index = 2
	item.seat(plan.targets[item.rank], 0.22, _on_landed.bind(item, s))


func _on_landed(item: Item, s: int) -> void:
	sounds.note(item.rank)
	effects.sparkle(item.position, item.visual.y * 0.5)
	if silhouettes[s]:
		var fade := (silhouettes[s] as Node2D).create_tween()
		fade.tween_property(silhouettes[s], "modulate:a", 0.0, 0.25)
	var glow := slots[s].create_tween()
	glow.tween_property(slots[s], "modulate", Color(1.3, 1.25, 1.0), 0.12)
	glow.tween_property(slots[s], "modulate", Color.WHITE, 0.4)
	_placed += 1
	if _placed == plan.count:
		finish()


# Soldaki ilk boş yuvanın nesnesi
func hint_move() -> Array:
	for s in plan.count:
		if not filled[s]:
			var item: Item = items[plan.slot_rank[s]]
			if not item.placed:
				return [item, plan.targets[item.rank]]
	return []


func celebrate() -> void:
	# Büyükten küçüğe sırayla zıplar, her biri kendi notasını çalar; sonra yön noktaları zıplar
	await play_scale(items, 0.24)
	for k in dots.size():
		var dot := dots[k]
		var base := dot.position
		var tween := dot.create_tween()
		tween.tween_interval(k * 0.08)
		tween.tween_property(dot, "position", base + Vector2(0.0, -16.0), 0.15).set_trans(Tween.TRANS_SINE)
		tween.tween_property(dot, "position", base, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
