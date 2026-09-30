extends Node2D
# Aç hayvan (Animal). Düğümün merkezi hayvanın ayaklarının yere değdiği nokta.
# Parçalar: gövde (göbeği doyunca büyür, karnı guruldarken dalgalanır), boyundan dönen kafa (ret için
# iki yana sallanır) ve kafanın üstünde kodla çizilen yüz (hayvan_yuzu.gd), başın üstünde düşünce balonu.
# Durumlar (mood): HUNGRY (aç: üzgün yüz, ara sıra karnı guruldar, ağzını yalar), EATING (çiğniyor),
# FULL (doymuş: mutlu yüz, keyifle sallanır). Sürüklenen yiyeceği gözleriyle izler; yiyecek kendi
# yiyeceğiyse heyecanlanır (gözleri büyür, ağzını açar), değilse merakla bakar.

signal fed_one(animal: Node2D)
signal became_full(animal: Node2D)

enum Mood { HUNGRY, EATING, FULL }

const Face := preload("res://oyunlar/hayvan_besle/hayvan_yuzu.gd")
const Bubble := preload("res://oyunlar/hayvan_besle/dusunce_balonu.gd")
const Food := preload("res://oyunlar/hayvan_besle/yiyecek.gd")
const Sounds := preload("res://oyunlar/hayvan_besle/sesler.gd")
const Effects := preload("res://oyunlar/hayvan_besle/efektler.gd")

const CANVAS := 256.0
const FEET := Vector2(128, 246)       # tuvalde ayakların yere değdiği nokta
const NECK := Vector2(128, 192)       # kafanın döndüğü nokta
const DROP_CENTER := Vector2(128, 150)
## Düşünce balonunun kuyruğunun değdiği yer (başın üstü) ve balonun genişliği (hayvan boyuna oran)
const BUBBLE_TIP := Vector2(118, 62)
const BUBBLE_WIDTH := 0.72

var data: FeedAnimalData
var want: FeedFoodData
var want_count: int = 1
var eaten: int = 0
var mood: Mood = Mood.HUNGRY
var size: float = 240.0               # 256'lık tuvalin ekrandaki boyu
var bubble: Bubble

var sounds: Sounds
var effects: Effects

var _rig: Node2D                      # gövde + kafa (zıplama ve dans bunu hareket ettirir)
var _body: Node2D
var _head: Node2D
var _face: Face
var _queue: Array[Food] = []          # ağza giren / sırada bekleyen yiyecekler
var _time: float = 0.0
var _watching: bool = false
var _watch_point: Vector2
var _excite: float = 0.0              # hedef heyecan (0..1)
var _excite_now: float = 0.0
var _curious: float = 0.0             # başka yiyeceğe merakla bakış (baş eğme)
var _next_blink: float = 0.0
var _next_growl: float = 0.0
var _next_lick: float = 0.0
var _giggle_until: float = 0.0

# Tween ile değişen canlandırma değerleri (_process bunları parçalara uygular)
var hop_y: float = 0.0
var dance_rot: float = 0.0
var shake: float = 0.0
var belly: float = 1.0
var ripple: float = 0.0
var blink_amount: float = 0.0
var tongue_amount: float = 0.0
var eat_open: float = 0.0
var chew: float = 0.0
var refuse_amount: float = 0.0

var _move_tween: Tween
var _head_tween: Tween


func setup(animal: FeedAnimalData, food: FeedFoodData, count: int, animal_size: float, bubble_always: bool) -> void:
	data = animal
	want = food
	want_count = count
	size = animal_size
	_time = randf() * 10.0
	_next_blink = _time + randf_range(1.0, 3.0)
	_next_growl = _time + randf_range(3.0, 8.0)
	_next_lick = _time + randf_range(2.0, 5.0)
	var s := size / CANVAS
	_rig = Node2D.new()
	add_child(_rig)
	_body = Node2D.new()
	_rig.add_child(_body)
	_body.add_child(_canvas_sprite(animal.body_texture, -FEET * s, s))
	_head = Node2D.new()
	_head.position = (NECK - FEET) * s
	_rig.add_child(_head)
	var head_canvas := _canvas_sprite(animal.head_texture, -NECK * s, s)
	_head.add_child(head_canvas)
	_face = Face.new()
	_face.setup(animal)
	head_canvas.add_child(_face)
	_face.scale = Vector2.ONE * animal.head_texture.get_width() / CANVAS   # yüz tuval biriminde çizer
	# Düşünce balonu: kuyruğu başın üstüne değecek şekilde
	bubble = Bubble.new()
	bubble.z_index = 5
	add_child(bubble)
	bubble.setup(food, count, size * BUBBLE_WIDTH, bubble_always)
	bubble.position = (BUBBLE_TIP - FEET) * s - bubble.tail_offset()


# Tuvalin sol üstü offset'te, tuval birimi s piksel olacak şekilde bir sprite (256'lık tuval, 2x içe aktarılmış)
func _canvas_sprite(texture: Texture2D, offset: Vector2, s: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = offset
	sprite.scale = Vector2.ONE * s * CANVAS / texture.get_width()
	return sprite


# --- Sorgular ---

func accepts(food: FeedFoodData) -> bool:
	return data.accepts.has(food)


# Daha fazla yiyecek alabilir mi? (ağzındakiler ve sıradakiler de sayılır)
func wants_more() -> bool:
	return mood != Mood.FULL and eaten + _queue.size() < want_count


func is_full() -> bool:
	return mood == Mood.FULL


# Bırakma alanı: gövdeyi ve başı kapsayan elips, tolerance kadar büyütülmüş. İçindeyse 0..1 (merkeze
# göre uzaklık), dışındaysa INF.
func drop_distance(point: Vector2, tolerance: float) -> float:
	var center := to_global((DROP_CENTER - FEET) * size / CANVAS)
	var radius := Vector2(0.42, 0.5) * size * (1.0 + tolerance) * global_scale
	var d := point - center
	var n := sqrt(pow(d.x / radius.x, 2.0) + pow(d.y / radius.y, 2.0))
	return n if n <= 1.0 else INF


func mouth_global() -> Vector2:
	return _face.to_global(Vector2(128.0, data.mouth_y + 8.0))


func head_top_global() -> Vector2:
	return _face.to_global(Vector2(128.0, 70.0))


func face() -> Face:
	return _face


# --- Sürüklenen yiyeceği izleme ---

func watch(point: Vector2, food: FeedFoodData) -> void:
	_watching = true
	_watch_point = point
	if accepts(food) and wants_more():
		var distance := point.distance_to(to_global((DROP_CENTER - FEET) * size / CANVAS))
		_excite = clampf(1.3 - distance / (size * 2.5), 0.35, 1.0)
		_curious = 0.0
	else:
		_excite = 0.0
		_curious = 1.0


func unwatch() -> void:
	_watching = false
	_excite = 0.0
	_curious = 0.0


func is_excited() -> bool:
	return _excite_now > 0.3


# --- Yeme ---

# Doğru yiyecek bırakıldı: ağza uçar, çiğnenir, yutulur. Hayvan yerken gelen yiyecek sırada bekler.
func feed(food: Food) -> void:
	food.eaten = true
	_queue.append(food)
	if mood == Mood.EATING:
		var wait := food.create_tween()
		wait.tween_property(food, "global_position", mouth_global() + Vector2(size * 0.22, size * 0.12), 0.25).set_trans(Tween.TRANS_SINE)
		wait.parallel().tween_property(food, "scale", Vector2.ONE * 0.8, 0.25)
		return
	_eat_next()


func _eat_next() -> void:
	mood = Mood.EATING
	var food: Food = _queue[0]
	var tween := create_tween()
	tween.tween_property(self, "eat_open", 1.0, 0.15).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_callback(food.fly_into.bind(mouth_global(), 0.3))
	tween.tween_interval(0.3)
	tween.tween_property(self, "eat_open", 0.0, 0.1)
	for k in 3:
		if k != 1:
			tween.tween_callback(func() -> void: sounds.play("hapur", randf_range(0.92, 1.1)))
		tween.tween_property(self, "chew", 1.0, 0.14).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(self, "eat_open", 0.22, 0.14)
		tween.tween_property(self, "chew", 0.15, 0.14).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(self, "eat_open", 0.0, 0.14)
	tween.tween_property(self, "chew", 0.0, 0.08)
	tween.tween_callback(_swallow)


func _swallow() -> void:
	sounds.play("yutma", randf_range(0.95, 1.05))
	_queue.pop_front()
	eaten += 1
	bubble.fill_dot()
	effects.sparkle(mouth_global(), size * 0.6)
	var tween := create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(sounds.play.bind("nokta", pow(1.122, eaten - 1)))
	_nod()
	fed_one.emit(self)
	if eaten >= want_count:
		_become_full()
	elif not _queue.is_empty():
		_eat_next()
	else:
		mood = Mood.HUNGRY


func _become_full() -> void:
	mood = Mood.FULL
	_giggle_until = _time + 1.2
	create_tween().tween_property(self, "belly", 1.09, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	effects.hearts(head_top_global(), size)
	sounds.play(Sounds.voice_name(data), randf_range(0.98, 1.06))
	_hop(0.0, 1)
	bubble.hide_bubble(0.7)
	became_full.emit(self)


# --- Tepkiler ---

# Kibarca reddeder: başını iki yana sallar ("ıh-ıh"), gözlerini kapar
func refuse() -> void:
	sounds.play("ih_ih", randf_range(0.97, 1.05))
	if _head_tween:
		_head_tween.kill()
	_head_tween = create_tween()
	for angle in [0.22, -0.22, 0.18, -0.14, 0.0]:
		_head_tween.tween_property(self, "shake", angle, 0.1).set_trans(Tween.TRANS_SINE)
	refuse_amount = 1.0
	create_tween().tween_property(self, "refuse_amount", 0.0, 0.2).set_delay(0.4)


# Dokununca: kıkırdar, zıplar, sesini çıkarır; balon kısa süre görünür
func poke(show_bubble: bool, bubble_time: float) -> void:
	_giggle_until = _time + 0.9
	sounds.play("kikir", randf_range(0.95, 1.1))
	var voice := create_tween()
	voice.tween_interval(0.35)
	voice.tween_callback(sounds.play.bind(Sounds.voice_name(data), randf_range(0.97, 1.08)))
	_hop(0.0, 1)
	if show_bubble and mood != Mood.FULL:
		bubble.flash(bubble_time)


# İpucu: yerinde hafifçe zıplar
func nudge() -> void:
	_hop(0.0, 1, 0.07)


# Bölüm sonu dansı: sırayla zıplayıp sağa sola sallanır
func dance(delay: float, times: int) -> void:
	_giggle_until = _time + delay + times * 0.55
	_hop(delay, times, 0.16, true)


func _hop(delay: float, times: int, height: float = 0.12, swing: bool = false) -> void:
	if _move_tween:
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_interval(delay)
	for k in times:
		var side := 1.0 if k % 2 == 0 else -1.0
		_move_tween.tween_property(self, "hop_y", -size * height, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if swing:
			_move_tween.parallel().tween_property(self, "dance_rot", 0.16 * side, 0.2)
		_move_tween.tween_property(self, "hop_y", 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		if swing:
			_move_tween.parallel().tween_property(self, "dance_rot", 0.0, 0.25)
		_move_tween.tween_interval(0.1)


func _nod() -> void:
	var tween := create_tween()
	tween.tween_property(_head, "position:y", (NECK.y - FEET.y) * size / CANVAS + size * 0.03, 0.1)
	tween.tween_property(_head, "position:y", (NECK.y - FEET.y) * size / CANVAS, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Aşağıdan zıplayarak gelir
func appear(delay: float) -> void:
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func leave(delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


# --- Her kare: yüz ve beden ---

func _process(delta: float) -> void:
	_time += delta
	_idle_events()
	var k := 1.0 - exp(-10.0 * delta)
	_excite_now = lerpf(_excite_now, _excite if mood == Mood.HUNGRY else 0.0, k)

	var sad_t := 0.0
	var smile_t := 0.3
	var open_t := 0.0
	var eye_t := 1.0
	var happy_t := 0.0
	var blush_t := 0.0
	match mood:
		Mood.HUNGRY:
			sad_t = 0.8 * (1.0 - 0.4 * float(eaten) / want_count) * (1.0 - _excite_now)
			smile_t = 0.1 + 0.5 * _excite_now
			open_t = 0.75 * _excite_now
			eye_t = 1.0 + 0.35 * _excite_now
		Mood.EATING:
			smile_t = 0.6
			open_t = eat_open
			blush_t = 0.4
		Mood.FULL:
			smile_t = 1.0
			blush_t = 1.0
			happy_t = 1.0 if fmod(_time, 3.2) < 1.1 else 0.0
	if _time < _giggle_until:
		happy_t = 1.0
		smile_t = 1.0
		open_t = maxf(open_t, 0.35)
	if refuse_amount > 0.0:
		open_t = 0.0
		smile_t = 0.2
	_face.sad = lerpf(_face.sad, sad_t, k)
	_face.smile = lerpf(_face.smile, smile_t, k)
	_face.mouth_open = open_t if mood == Mood.EATING else lerpf(_face.mouth_open, open_t, k)
	_face.eye_scale = lerpf(_face.eye_scale, eye_t, k)
	_face.happy_eyes = happy_t
	_face.blush = lerpf(_face.blush, blush_t, k)
	_face.cheek_puff = chew
	_face.tongue = tongue_amount
	_face.blink = maxf(blink_amount, refuse_amount)
	_face.look = _face.look.lerp(_look_target(), 1.0 - exp(-8.0 * delta))
	_face.queue_redraw()

	# Beden: nefes, göbek, karın dalgalanması; doyunca keyifle sallanma; heyecanda kıpır kıpır
	var breathe := 1.0 + 0.012 * sin(_time * 2.4)
	var wobble := ripple * 0.05 * sin(_time * 28.0)
	_body.scale = Vector2(belly * (1.0 + wobble), belly * breathe * (1.0 - wobble * 0.5))
	var sway := sin(_time * 2.2) * 0.06 if mood == Mood.FULL else 0.0
	var jitter := -absf(sin(_time * 9.0)) * size * 0.025 * _excite_now
	_rig.rotation = sway + dance_rot
	_rig.position.y = hop_y + jitter
	var tilt := clampf((_watch_point.x - global_position.x) / (size * 3.0), -1.0, 1.0) * 0.12 * _curious if _watching else 0.0
	_head.rotation = lerpf(_head.rotation, tilt, k) if shake == 0.0 else shake


# Gözlerin bakacağı yön: sürüklenen yiyecek varsa ona, yoksa yavaşça etrafa
func _look_target() -> Vector2:
	if _watching:
		var eyes := _face.to_global(Vector2(128.0, data.eye_y))
		var dir := (_watch_point - eyes) / (size * 0.9)
		return dir.limit_length(1.0)
	return Vector2(sin(_time * 0.45) * 0.45, 0.2 + sin(_time * 0.31) * 0.2)


# Kendiliğinden olanlar: göz kırpma, açken karın guruldaması ve ağız yalama
func _idle_events() -> void:
	if _time >= _next_blink:
		_next_blink = _time + randf_range(2.0, 5.0)
		var blink := create_tween()
		blink.tween_property(self, "blink_amount", 1.0, 0.07)
		blink.tween_property(self, "blink_amount", 0.0, 0.09)
	if mood != Mood.HUNGRY or _watching or _excite_now > 0.1:
		return
	if _time >= _next_growl:
		_next_growl = _time + randf_range(7.0, 13.0)
		sounds.play("guruldama", randf_range(0.9, 1.1))
		var growl := create_tween()
		growl.tween_property(self, "ripple", 1.0, 0.15)
		growl.tween_interval(0.5)
		growl.tween_property(self, "ripple", 0.0, 0.3)
	elif _time >= _next_lick:
		_next_lick = _time + randf_range(4.0, 8.0)
		var lick := create_tween()
		lick.tween_property(self, "tongue_amount", 1.0, 0.18).set_trans(Tween.TRANS_SINE)
		lick.tween_interval(0.35)
		lick.tween_property(self, "tongue_amount", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
