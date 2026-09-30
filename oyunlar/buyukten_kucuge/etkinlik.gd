class_name SizeActivity
extends Node2D
# Etkinlik arayüzü: Halka Kulesi, Sıralama Dizisi ve İç İçe Bebekler bunu extends eder.
# Ana sahne (SizeOrderGame) bölüm başında etkinliğin sahnesini kurar ve şu sırayla çağırır:
#   setup(plan, services)  -> build()  -> ... oyun ...  -> completed sinyali
#   -> await celebrate()  -> await leave()  -> queue_free
# Oyun sırasında: dokunma ortak DragInput sinyalleriyle gelir (_on_grabbed / _on_dropped / _on_canceled),
# ana sahne boşta kalınca show_hint() çağırır (hint_move(): [nesne, hedef nokta]).
# Yeni etkinlik türü: bu script'i extends eden bir sahne yaz (build, _on_dropped, hint_move, celebrate),
# ana sahnede ACTIVITIES'e ekle, SizeLevelGenerator'a yerleşimini yaz.

## Etkinlik bitti (bütün nesneler yerinde); ana sahne kutlamayı başlatır
signal completed

const Item := preload("res://oyunlar/buyukten_kucuge/boyutlu_nesne.gd")
const Sounds := preload("res://oyunlar/buyukten_kucuge/sesler.gd")
const Effects := preload("res://oyunlar/buyukten_kucuge/efektler.gd")
const HintHand := preload("res://ortak/ipucu_eli.gd")
const DragInput := preload("res://ortak/surukleme_girdisi.gd")

## Yanlış / boş bırakmada nesnenin evine dönme süresi
const RETURN_TIME := 0.45

var plan: SizeLevelGenerator.Plan
var sounds: Sounds
var effects: Effects
var hand: HintHand
var drag_input: DragInput
var items: Array = []           # sürüklenebilir nesneler (Item); sıra numarasına göre (items[r].rank == r)
var done: bool = false


func setup(level_plan: SizeLevelGenerator.Plan, game_sounds: Sounds, game_effects: Effects, hint_hand: HintHand, input: DragInput) -> void:
	plan = level_plan
	sounds = game_sounds
	effects = game_effects
	hand = hint_hand
	drag_input = input
	drag_input.item_grabbed.connect(_on_grabbed)
	drag_input.item_dropped.connect(_on_dropped)
	drag_input.item_canceled.connect(_on_canceled)


func _exit_tree() -> void:
	if drag_input:
		drag_input.item_grabbed.disconnect(_on_grabbed)
		drag_input.item_dropped.disconnect(_on_dropped)
		drag_input.item_canceled.disconnect(_on_canceled)
		if drag_input.items == items:      # sonraki bölümün listesine dokunma
			drag_input.items = []


# --- Etkinliğin dolduracağı işlevler ---

## Nesneleri kurar ve gösterir (drag_input.items'ı doldurur)
func build() -> void:
	pass


## Sıradaki doğru hamle: [nesne, hedef nokta] ya da []
func hint_move() -> Array:
	return []


## Tamamlanma gösterisi (await edilir)
func celebrate() -> void:
	await get_tree().create_timer(0.1).timeout


func _on_dropped(_item: Item, _point: Vector2) -> void:
	pass


# --- Ortak davranışlar ---

func _on_grabbed(_item: Item) -> void:
	sounds.play("pop", randf_range(0.95, 1.1))


func _on_canceled(item: Item) -> void:
	item.return_home(RETURN_TIME, false)


# Boşluğa bırakıldı: sessizce evine döner
func return_quietly(item: Item) -> void:
	item.return_home(RETURN_TIME, false)


# Yanlış yere bırakıldı: yumuşak ses, hafif sallanma, evine dönüş (via: önce gideceği yer)
func refuse(item: Item, via: Vector2 = Vector2.INF) -> void:
	sounds.play("geri")
	item.bounce_back(via, via != Vector2.INF, RETURN_TIME)


func show_hint() -> void:
	var move := hint_move()
	if move.is_empty():
		return
	var item: Item = move[0]
	item.glow()
	hand.play(item.position, move[1])


# Sıra numarasına göre nesnelerin büyükten küçüğe zıplayıp kendi notasını çalması (kutlamalarda)
func play_scale(order: Array, step: float = 0.22) -> void:
	for k in order.size():
		var item: Item = order[k]
		later(k * step, func() -> void:
			item.hop(0.0)
			sounds.note(item.rank))
	await get_tree().create_timer(order.size() * step + 0.45).timeout


# delay saniye sonra callback (etkinliğe bağlı: etkinlik silinirse çalışmaz)
func later(delay: float, callback: Callable) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(callback)


func finish() -> void:
	if not done:
		done = true
		completed.emit()


## Bölüm sonunda her şey küçülerek kaybolur (await edilir)
func leave() -> void:
	for child in get_children():
		if child is Node2D and child.visible:
			var tween := (child as Node2D).create_tween()
			tween.tween_property(child, "scale", Vector2.ZERO, 0.3).set_delay(randf() * 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		elif child is Control:
			var fade := (child as Control).create_tween()
			fade.tween_property(child, "modulate:a", 0.0, 0.3)
	await get_tree().create_timer(0.55).timeout


# Nesneleri kurar (sıra numarasına göre), gelirken zıplar
func spawn_items(script: GDScript, art: String) -> void:
	items.clear()
	for r in plan.count:
		var item: Item = script.new()
		add_child(item)
		item.setup_item(art, r, plan.sizes[r], plan.colors[r], plan.starts[r], plan.touch)
		items.append(item)
	# Soldan sağa sırayla gelsinler
	var order := plan.start_order()
	for k in order.size():
		items[order[k]].appear(0.25 + k * 0.08)
	drag_input.items = items
