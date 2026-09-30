extends SizeActivity
# İç İçe Bebekler (NestingDolls): zeminde farklı boyda, aynı karakterde (renk tonları farklı) bebekler.
# Çocuk bir bebeği daha büyük bir bebeğin üstüne sürükler: büyük bebeğin üst yarısı açılır, küçük bebek
# içine girer, kapanır. Kural (bölüm ayarı strict):
#   - serbest: her daha büyük bebeğe girebilir (içindekilerle birlikte boyuna göre yerleşir, hiç tıkanmaz),
#   - boy atlama yok: ancak büyük bebeğin en içtekinden tam bir boy küçükse girer.
# Büyük bebeği küçüğe koymaya çalışınca ya da kural tutmayınca bebek kibarca evine döner.
# Hepsi tek bebekte toplanınca bebek sevinçle zıplar, sonra hepsi sırayla dışarı fırlar, yan yana
# (büyükten küçüğe) dizilir ve sırayla selam verir (her biri kendi notasıyla).

const Doll := preload("res://oyunlar/buyukten_kucuge/bebek.gd")


func build() -> void:
	spawn_items(Doll, plan.art)


# Görünen (başka bebeğin içinde olmayan) bebekler
func visible_dolls() -> Array:
	return items.filter(func(d: Doll) -> bool: return d.visible)


func can_nest(small: Doll, big: Doll) -> bool:
	if small.rank <= big.rank:
		return false
	if plan.level.strict:
		return small.rank == big.innermost_rank() + 1
	return true


# Bırakılan noktanın üstündeki (toleranslı) başka bebek
func doll_at(point: Vector2, exclude: Doll) -> Doll:
	var best: Doll = null
	var best_distance := INF
	for doll: Doll in visible_dolls():
		if doll == exclude or doll.placed:
			continue
		if drag_input.drop_area(doll.rect()).has_point(point):
			var distance := point.distance_to(doll.position)
			if distance < best_distance:
				best_distance = distance
				best = doll
	return best


func _on_dropped(item: Item, point: Vector2) -> void:
	var doll: Doll = item
	var big := doll_at(point, doll)
	if big == null:
		return_quietly(doll)
	elif can_nest(doll, big):
		_nest(doll, big)
	else:
		refuse(doll)


# Küçük bebek büyüğün içine girer: büyük açılır, küçük üstünden içine iner, büyük kapanır
func _nest(small: Doll, big: Doll) -> void:
	small.placed = true
	big.placed = true            # animasyon bitene kadar tutulamaz
	small.dragging = false
	big.z_index = 2
	small.z_index = 1            # büyüğün arkasında: içine iniyor gibi görünür
	big.open()
	sounds.play("tok")
	var above := big.position + Vector2(0.0, -big.visual.y * 0.55 - small.visual.y * 0.2)
	var tween := small._new_tween()
	tween.tween_property(small, "position", above, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(small, "scale", Vector2.ONE, 0.22)
	tween.parallel().tween_property(small, "rotation", 0.0, 0.22)
	tween.tween_property(small, "position", big.position + Vector2(0.0, big.visual.y * 0.1), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(small, "scale", Vector2.ONE * 0.8, 0.28)
	tween.tween_callback(_on_nested.bind(small, big))


func _on_nested(small: Doll, big: Doll) -> void:
	small.visible = false
	small.scale = Vector2.ONE
	small.position = big.position
	var inside := [small] + small.contents + big.contents
	inside.sort_custom(func(a: Doll, b: Doll) -> bool: return a.rank < b.rank)
	big.contents = inside
	small.contents = []
	big.close()
	later(0.18, func() -> void:
		sounds.play("tok", 1.25)
		sounds.note(small.rank)
		effects.sparkle(big.position, big.visual.x * 0.5)
		big.z_index = Doll.Z_IDLE
		big.placed = false
		big.hop(0.0)
		if visible_dolls().size() == 1:
			big.placed = true
			finish())


# Sıradaki doğru hamle: en büyük görünen bebeğe girebilecek (tercihen tam bir boy küçük) bebek
func hint_move() -> Array:
	var dolls := visible_dolls()
	dolls.sort_custom(func(a: Doll, b: Doll) -> bool: return a.rank < b.rank)
	for big: Doll in dolls:
		if big.placed:
			continue
		for small: Doll in dolls:
			if small != big and not small.placed and small.rank == big.innermost_rank() + 1:
				return [small, big.position]
	for big: Doll in dolls:
		for small: Doll in dolls:
			if small != big and not small.placed and not big.placed and can_nest(small, big):
				return [small, big.position]
	return []


func celebrate() -> void:
	var big: Doll = visible_dolls()[0]
	big.hop(0.0, 2)
	await get_tree().create_timer(1.0).timeout
	# Açılır, içindekiler sırayla fırlayıp yan yana dizilir
	big.open(0.3)
	sounds.play("tok")
	var move := big.create_tween()
	move.tween_property(big, "position", plan.targets[big.rank], 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var inside: Array = big.contents.duplicate()
	var start := big.position + Vector2(0.0, -big.visual.y * 0.3)
	for k in inside.size():
		var doll: Doll = inside[k]
		doll.position = start
		doll.scale = Vector2.ONE * 0.5
		doll.rotation = 0.0
		doll.visible = true
		doll.z_index = 3
		var target: Vector2 = plan.targets[doll.rank]
		var peak := Vector2((start.x + target.x) / 2.0, minf(start.y, target.y) - big.visual.y * 0.6)
		var tween := doll._new_tween()
		tween.tween_interval(0.15 + k * 0.35)
		tween.tween_callback(sounds.play.bind("firla"))
		tween.tween_property(doll, "position", peak, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(doll, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(doll, "rotation", TAU, 0.5)
		tween.tween_property(doll, "position", target, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func() -> void:
			doll.rotation = 0.0
			doll.z_index = 1
			sounds.note(doll.rank))
	await get_tree().create_timer(0.3 + inside.size() * 0.35 + 0.4).timeout
	big.close()
	big.contents = []
	# Büyükten küçüğe sırayla selam
	for k in items.size():
		var doll: Doll = items[k]
		doll.bow(k * 0.28)
		later(k * 0.28, sounds.note.bind(doll.rank))
	await get_tree().create_timer(items.size() * 0.28 + 0.6).timeout
