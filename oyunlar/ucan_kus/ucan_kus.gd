extends Node2D
# Uçan Kuş: ekrana dokununca kuş zıplar, direklerin arasından geçmeye çalışır.

enum State { READY, PLAYING, GAME_OVER }

## Ekran yönü: SahneGecis bu oyuna geçerken ekranı buna göre döndürür.
@export_enum("dikey", "yatay") var ekran_yonu: String = "dikey"

# --- Zorluk ayarları (Inspector'dan da değiştirilebilir) ---
@export_group("Kuş")
## Yerçekimi (piksel/sn²). Küçük değer = kuş daha yavaş düşer.
@export var gravity: float = 900.0
## Zıplama gücü. Büyük değer = daha yükseğe zıplar.
@export var flap_strength: float = 430.0
## Kuşun ulaşabileceği en yüksek düşme hızı.
@export var max_fall_speed: float = 480.0
## Çarpışma yarıçapı. Kuşun görselinden küçük tutuldu, çocuklar için affedici olsun.
@export var bird_hit_radius: float = 30.0

@export_group("Direkler")
## Direklerin sola kayma hızı (piksel/sn).
@export var pipe_speed: float = 160.0
## Üst ve alt direk arasındaki boşluk.
@export var gap_size: float = 400.0
## İki direk çifti arasındaki yatay mesafe.
@export var pipe_spacing: float = 480.0
## Art arda gelen boşlukların yüksekliği en fazla bu kadar değişir.
@export var max_gap_shift: float = 260.0

@export_group("Hızlanma")
## Kaç puanda bir oyun bir kademe hızlanır.
@export var speed_step_points: int = 5
## Her kademede direk hızının artış oranı (0.08 = %8).
@export var speed_step_ratio: float = 0.08
## Hızın üst sınırı: başlangıç hızının en fazla bu katı.
@export var max_speed_factor: float = 1.8
## Kuşun yerçekimi ve zıplaması hıza ne kadar uyar (0 = hiç değişmez, 1 = hızla aynı oranda çabuklaşır).
## Zıplama yüksekliği hep aynı kalır, sadece zıplama daha çabuk olur.
@export_range(0.0, 1.0) var bird_speed_match: float = 0.5
## Boşluk bu kademeden sonra daralmaya başlar.
@export var gap_shrink_start_level: int = 2
## Daralma başlayınca her kademede boşluğun küçülme oranı (0.03 = %3).
@export var gap_shrink_per_level: float = 0.03
## Boşluk en fazla başlangıcın bu oranına kadar daralır.
@export_range(0.5, 1.0) var min_gap_ratio: float = 0.8
## Müziğin kademe başına hızlanma oranı (0 = müzik değişmez).
@export var music_speed_per_level: float = 0.008

@export_group("Hareketli direkler")
## Bu puandan sonra bazı direkler yavaşça yukarı aşağı hareket eder.
@export var moving_pipes_start_score: int = 15
## Kaç direkte bir hareketli direk gelir (en az ve en çok).
@export var moving_pipe_every_min: int = 3
@export var moving_pipe_every_max: int = 4
## Hareketin yüksekliği: orta noktadan yukarı ve aşağı (piksel).
@export var moving_pipe_range: float = 60.0
## Bir yukarı-aşağı turun süresi (sn). Büyük değer = daha yavaş.
@export var moving_pipe_period: float = 3.6

@export_group("Canlar")
@export var start_lives: int = 3
## Çarptıktan sonra kuşun yanıp söndüğü (dokunulmaz olduğu) süre.
@export var blink_duration: float = 1.5

const PIPE_TEXTURE: Texture2D = preload("res://oyunlar/ucan_kus/direk.svg")
const CLOUD_TEXTURE: Texture2D = preload("res://oyunlar/ucan_kus/bulut.svg")
const HEART_TEXTURE: Texture2D = preload("res://oyunlar/ucan_kus/kalp.svg")

# Direk beyaz çizildi, bu renklerle boyanıyor
const PIPE_COLORS := [
	Color("ff7a7a"), Color("ffb35c"), Color("ffd84d"), Color("b58cff"), Color("ff8fc7"),
]
const PIPE_HALF_WIDTH := 60.0
const GROUND_HEIGHT := 70.0
const GAP_TOP_LIMIT := 140.0     # boşluk ekranın üstüne bundan fazla yaklaşmaz
const GAP_BOTTOM_LIMIT := 80.0   # boşluk çimene bundan fazla yaklaşmaz
const CLOUD_COUNT := 5
# Hız kademesi arttıkça gökyüzü: sabah → öğle → gün batımı → gece
const SKY_COLORS := [Color(0.71, 0.88, 1.0), Color(0.47, 0.77, 1.0), Color(1.0, 0.74, 0.6), Color(0.29, 0.29, 0.58)]
const WIND_LINE_COUNT := 8
const SPARKLE_COUNT := 8

@onready var bird: AnimatedSprite2D = $Bird
@onready var pipes: Node2D = $Pipes
@onready var ground: ColorRect = $Ground
@onready var sky: ColorRect = $Background/Sky
@onready var clouds: Node2D = $Background/Clouds
@onready var score_label: Label = $HUD/ScoreLabel
@onready var hearts_box: HBoxContainer = $HUD/HeartsBox
@onready var start_screen: Control = $HUD/StartScreen
@onready var tap_label: Label = $HUD/StartScreen/TapLabel
@onready var game_over_screen: Control = $HUD/GameOverScreen
@onready var result_label: Label = $HUD/GameOverScreen/Box/ResultLabel
@onready var restart_button: Button = $HUD/GameOverScreen/Box/RestartButton
@onready var back_button: Panel = $HUD/BackButton

var state: State = State.READY
var bird_velocity: float = 0.0
var score: int = 0
var lives: int = 0
var blink_left: float = 0.0
var distance_since_spawn: float = 0.0
var last_gap_y: float = 0.0
var can_restart: bool = false
var time_passed: float = 0.0
var speed_level: int = 0             # hız kademesi: her speed_step_points puanda +1, can kaybında -1
var speed_factor: float = 1.0        # direk hızının çarpanı; kademenin hedefine yumuşakça yaklaşır
var pipes_until_moving: int = 0
var effects: Node2D
var sky_tween: Tween
var hop_tween: Tween
var score_base_y: float = 0.0


func _ready() -> void:
	SesYoneticisi.muzik("ucan_kus", self)
	lives = start_lives
	_create_hearts()
	_create_clouds()
	effects = Node2D.new()
	add_child(effects)
	score_base_y = score_label.position.y
	get_viewport().size_changed.connect(_layout)
	_layout()

	bird.position = _bird_start_position()
	bird.play("flap")
	last_gap_y = bird.position.y

	score_label.visible = false
	game_over_screen.visible = false
	start_screen.visible = true

	# "Başlamak için dokun" yazısı yavaşça yanıp sönsün
	var tween := tap_label.create_tween().set_loops()
	tween.tween_property(tap_label, "modulate:a", 0.35, 0.6)
	tween.tween_property(tap_label, "modulate:a", 1.0, 0.6)


func _input(event: InputEvent) -> void:
	# Sadece dokunma ile oynanır (bilgisayarda fare tıklaması dokunmaya çevrilir)
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return

	# Geri: başlangıç ekranındayken ana menüye, oyun sırasında başlangıç ekranına
	if back_button.get_global_rect().grow(16.0).has_point(touch.position):
		SesYoneticisi.efekt("geri")
		if state == State.READY:
			SahneGecis.ana_menuye_don()
		else:
			SahneGecis.sahneyi_yeniden_baslat()
		return

	match state:
		State.READY:
			_start_game()
		State.PLAYING:
			_flap()
		State.GAME_OVER:
			# Düğmenin biraz dışına basılsa da kabul et
			if can_restart and restart_button.get_global_rect().grow(30.0).has_point(touch.position):
				_restart()


func _process(delta: float) -> void:
	time_passed += delta
	_move_clouds(delta)

	match state:
		State.READY:
			# Başlamadan önce kuş havada hafifçe süzülür
			bird.position.y = _bird_start_position().y + sin(time_passed * 3.0) * 15.0
		State.PLAYING:
			speed_factor = move_toward(speed_factor, _target_speed_factor(), 0.3 * delta)
			_update_bird(delta)
			_update_pipes(delta)
			_update_blink(delta)
			_check_collisions()


# --- Oyun akışı ---

func _start_game() -> void:
	state = State.PLAYING
	start_screen.visible = false
	score_label.visible = true
	distance_since_spawn = 0.0
	SesYoneticisi.efekt("yukselis")
	_spawn_pipe_pair()
	_flap()


func _flap() -> void:
	bird_velocity = -flap_strength * _bird_pace()
	bird.frame = 0
	SesYoneticisi.efekt("kanat", -3.0)


func _take_hit() -> void:
	if blink_left > 0.0 or state != State.PLAYING:
		return
	lives -= 1
	_update_hearts()
	_change_speed_level(-1)  # çarpınca oyun bir kademe yavaşlar
	# Yumuşak "boing", ardından kısa, üzgün olmayan bir iniş sesi (can gitti)
	SesYoneticisi.efekt("boing", -2.0)
	get_tree().create_timer(0.25).timeout.connect(SesYoneticisi.efekt.bind("yumusak_dusus", -5.0))
	if lives <= 0:
		_game_over()
	else:
		blink_left = blink_duration


func _add_point() -> void:
	score += 1
	score_label.text = str(score)
	SesYoneticisi.efekt("ding", -3.0)
	# Puan yazısı kısa bir an büyüsün
	score_label.pivot_offset = score_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.12)
	if speed_step_points > 0 and score % speed_step_points == 0:
		_change_speed_level(1)


func _game_over() -> void:
	state = State.GAME_OVER
	blink_left = 0.0
	bird.modulate.a = 1.0
	bird.pause()
	score_label.visible = false
	result_label.text = "Puan: %d" % score
	SesYoneticisi.muzik_hizi(1.0)

	await get_tree().create_timer(0.6).timeout
	SesYoneticisi.ezgi("yildiz_kazanma")
	game_over_screen.modulate.a = 0.0
	game_over_screen.visible = true
	restart_button.pivot_offset = restart_button.size / 2.0
	create_tween().tween_property(game_over_screen, "modulate:a", 1.0, 0.3)

	# Çocuk yanlışlıkla hemen yeniden başlatmasın diye kısa bekleme
	await get_tree().create_timer(0.5).timeout
	can_restart = true


func _restart() -> void:
	can_restart = false
	SesYoneticisi.efekt("basari")
	var tween := create_tween()
	tween.tween_property(restart_button, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(restart_button, "scale", Vector2.ONE, 0.08)
	tween.tween_callback(get_tree().reload_current_scene)


# --- Hızlanma ---

# Üst sınıra ulaşılan kademe (%8 artış ve 1.8 kat sınırla 8)
func _max_speed_level() -> int:
	if speed_step_ratio <= 0.0 or max_speed_factor <= 1.0:
		return 0
	return ceili(log(max_speed_factor) / log(1.0 + speed_step_ratio) - 0.0001)


func _target_speed_factor() -> float:
	return minf(pow(1.0 + speed_step_ratio, speed_level), maxf(max_speed_factor, 1.0))


# Kuşun zaman ölçeği: hız çarpanını bird_speed_match kadar izler
func _bird_pace() -> float:
	return lerpf(1.0, speed_factor, bird_speed_match)


# Yeni direklerin boşluğu: belli kademeden sonra azar azar daralır, alt sınırın altına inmez
func _current_gap() -> float:
	var shrink := gap_shrink_per_level * maxi(speed_level - gap_shrink_start_level, 0)
	return gap_size * maxf(1.0 - shrink, min_gap_ratio)


func _change_speed_level(change: int) -> void:
	var new_level := clampi(speed_level + change, 0, _max_speed_level())
	if new_level == speed_level:
		return
	speed_level = new_level
	_update_sky()
	SesYoneticisi.muzik_hizi(1.0 + music_speed_per_level * speed_level)
	if change > 0:
		SesYoneticisi.efekt("vuus", -2.0)
		_spawn_wind_lines()
		_spawn_bird_sparkles()
		_hop_score()


# moving_pipes_start_score puandan sonra her 3-4 direkte bir hareketli direk
func _next_pipe_moves() -> bool:
	if score < moving_pipes_start_score:
		return false
	pipes_until_moving -= 1
	if pipes_until_moving > 0:
		return false
	pipes_until_moving = randi_range(moving_pipe_every_min, maxi(moving_pipe_every_max, moving_pipe_every_min))
	return true


func _sky_color() -> Color:
	var t := float(speed_level) / maxi(_max_speed_level(), 1) * (SKY_COLORS.size() - 1)
	var i := mini(floori(t), SKY_COLORS.size() - 2)
	return SKY_COLORS[i].lerp(SKY_COLORS[i + 1], t - i)


func _update_sky() -> void:
	if sky_tween and sky_tween.is_valid():
		sky_tween.kill()
	var color := _sky_color()
	sky_tween = create_tween().set_parallel()
	sky_tween.tween_property(sky, "color", color, 1.2).set_trans(Tween.TRANS_SINE)
	# Bulutlar da gökyüzünün rengini biraz alır
	sky_tween.tween_property(clouds, "modulate", Color.WHITE.lerp(color, 0.3), 1.2)


# Ekranın üst ve alt kenarından sağdan sola geçen kısa rüzgar çizgileri
func _spawn_wind_lines() -> void:
	var screen := _screen_size()
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.0)])
	for i in WIND_LINE_COUNT:
		var length := randf_range(150.0, 280.0)
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0.0)])
		line.width = randf_range(5.0, 9.0)
		line.gradient = fade
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		var band := randf_range(0.0, screen.y * 0.2)
		var y := 190.0 + band if i % 2 == 0 else screen.y - GROUND_HEIGHT - 50.0 - band
		line.position = Vector2(screen.x + 20.0, y)
		effects.add_child(line)
		var tween := line.create_tween()
		tween.tween_interval(i * 0.04 + randf() * 0.1)
		tween.tween_property(line, "position:x", -length - 20.0, randf_range(0.4, 0.6))
		tween.tween_callback(line.queue_free)


# Kuşun etrafında kısa süre parlayıp dağılan küçük yıldızlar
func _spawn_bird_sparkles() -> void:
	var shape := PackedVector2Array()
	for k in 8:
		shape.append(Vector2.from_angle(k * TAU / 8.0) * (13.0 if k % 2 == 0 else 4.5))
	for i in SPARKLE_COUNT:
		var sparkle := Polygon2D.new()
		sparkle.polygon = shape
		sparkle.color = Color(1.0, 0.96, 0.62)
		var direction := Vector2.from_angle(i * TAU / SPARKLE_COUNT + randf_range(-0.25, 0.25))
		sparkle.position = direction * 45.0
		sparkle.scale = Vector2.ZERO
		bird.add_child(sparkle)
		var tween := sparkle.create_tween().set_parallel()
		tween.tween_property(sparkle, "position", direction * randf_range(85.0, 110.0), 0.55) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sparkle, "scale", Vector2.ONE * randf_range(0.9, 1.4), 0.18)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.3).set_delay(0.25)
		tween.chain().tween_callback(sparkle.queue_free)


func _hop_score() -> void:
	if hop_tween and hop_tween.is_valid():
		hop_tween.kill()
	hop_tween = create_tween()
	hop_tween.tween_property(score_label, "position:y", score_base_y - 40.0, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop_tween.tween_property(score_label, "position:y", score_base_y, 0.32) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


# --- Kuş ---

func _update_bird(delta: float) -> void:
	# Oyun hızlandıkça kuş aynı yüksekliğe daha çabuk zıplayıp iner (yerçekimi pace², zıplama pace ile artar)
	var pace := _bird_pace()
	var fall_limit := max_fall_speed * pace
	bird_velocity = minf(bird_velocity + gravity * pace * pace * delta, fall_limit)
	bird.position.y += bird_velocity * delta

	# Yükselirken yukarı, düşerken aşağı doğru hafifçe eğil
	var target_rotation := clampf(bird_velocity / fall_limit * 0.5, -0.35, 0.5)
	bird.rotation = lerpf(bird.rotation, target_rotation, 8.0 * delta)

	# Tavana çarpınca can gitmez, sadece durur
	if bird.position.y - bird_hit_radius < 0.0:
		bird.position.y = bird_hit_radius
		bird_velocity = maxf(bird_velocity, 0.0)


func _update_blink(delta: float) -> void:
	if blink_left <= 0.0:
		return
	blink_left -= delta
	if blink_left <= 0.0:
		bird.modulate.a = 1.0
	else:
		bird.modulate.a = 0.3 if fmod(blink_left, 0.2) < 0.1 else 1.0


# --- Direkler ---

func _update_pipes(delta: float) -> void:
	# Direkler hep aynı sürede bir doğar (başlangıç hızıyla ölçülen mesafe), ama hız çarpanıyla kayar:
	# aralarındaki mesafe hızla orantılı açılır, yani sıklaşmazlar, sadece daha hızlı gelirler
	distance_since_spawn += pipe_speed * delta
	if distance_since_spawn >= pipe_spacing:
		distance_since_spawn -= pipe_spacing
		_spawn_pipe_pair()
	var speed := pipe_speed * speed_factor

	for pair: Node2D in pipes.get_children():
		pair.position.x -= speed * delta
		if pair.has_meta("travel"):
			# Hareketli direk: orta noktasının çevresinde yavaşça yukarı aşağı
			var age: float = pair.get_meta("age") + delta
			pair.set_meta("age", age)
			pair.position.y = pair.get_meta("base_y") + sin(age * TAU / moving_pipe_period) * pair.get_meta("travel")
		if not pair.get_meta("scored") and pair.position.x + PIPE_HALF_WIDTH < bird.position.x:
			pair.set_meta("scored", true)
			_add_point()
		if pair.position.x < -PIPE_HALF_WIDTH * 3.0:
			pair.queue_free()


func _spawn_pipe_pair() -> void:
	var screen := _screen_size()
	var gap := _current_gap()
	var min_y := GAP_TOP_LIMIT + gap / 2.0
	var max_y := screen.y - GROUND_HEIGHT - GAP_BOTTOM_LIMIT - gap / 2.0
	# Hareketli direğin orta noktası, hareket payı kadar içeride kalır
	var travel := 0.0
	if _next_pipe_moves():
		travel = clampf((max_y - min_y) / 2.0, 0.0, moving_pipe_range)
	var gap_y := randf_range(last_gap_y - max_gap_shift, last_gap_y + max_gap_shift)
	gap_y = clampf(gap_y, min_y + travel, max_y - travel)
	if max_y < min_y:
		gap_y = (screen.y - GROUND_HEIGHT) / 2.0  # boşluk çok büyük ayarlandıysa ortala
	last_gap_y = gap_y

	# Çiftin merkezi boşluğun ortası
	var pair := Node2D.new()
	pair.position = Vector2(screen.x + PIPE_HALF_WIDTH * 2.0, gap_y)
	pair.modulate = PIPE_COLORS.pick_random()
	pair.set_meta("scored", false)
	pair.set_meta("gap", gap)
	if travel > 0.0:
		pair.set_meta("travel", travel)
		pair.set_meta("base_y", gap_y)
		pair.set_meta("age", 0.0)

	var half_height := PIPE_TEXTURE.get_height() / 2.0
	var top := Sprite2D.new()
	top.texture = PIPE_TEXTURE
	top.flip_v = true
	top.position.y = -gap / 2.0 - half_height
	var bottom := Sprite2D.new()
	bottom.texture = PIPE_TEXTURE
	bottom.position.y = gap / 2.0 + half_height

	pair.add_child(top)
	pair.add_child(bottom)
	pipes.add_child(pair)


# --- Çarpışma ---

func _check_collisions() -> void:
	# Yere değince kuş geri sıçrar (ve bir can gider)
	var floor_y := _screen_size().y - GROUND_HEIGHT
	if bird.position.y + bird_hit_radius > floor_y:
		bird.position.y = floor_y - bird_hit_radius
		bird_velocity = -flap_strength * _bird_pace()
		_take_hit()

	if blink_left > 0.0 or state != State.PLAYING:
		return
	for pair: Node2D in pipes.get_children():
		if _bird_hits_pair(pair):
			_take_hit()
			return


func _bird_hits_pair(pair: Node2D) -> bool:
	var half_gap: float = pair.get_meta("gap") / 2.0
	var left := pair.position.x - PIPE_HALF_WIDTH
	var width := PIPE_HALF_WIDTH * 2.0
	var top_rect := Rect2(left, pair.position.y - half_gap - 2000.0, width, 2000.0)
	var bottom_rect := Rect2(left, pair.position.y + half_gap, width, 2000.0)
	return _circle_hits_rect(bird.position, bird_hit_radius, top_rect) \
		or _circle_hits_rect(bird.position, bird_hit_radius, bottom_rect)


func _circle_hits_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := center.clamp(rect.position, rect.end)
	return center.distance_to(closest) < radius


# --- Arayüz ve arka plan ---

func _create_hearts() -> void:
	for i in start_lives:
		var heart := TextureRect.new()
		heart.texture = HEART_TEXTURE
		heart.custom_minimum_size = Vector2(64, 64)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts_box.add_child(heart)


func _update_hearts() -> void:
	# Kaybedilen kalpler soluk görünür
	for i in hearts_box.get_child_count():
		var heart := hearts_box.get_child(i) as TextureRect
		heart.modulate = Color.WHITE if i < lives else Color(1, 1, 1, 0.2)


func _create_clouds() -> void:
	var screen := _screen_size()
	for i in CLOUD_COUNT:
		var cloud := Sprite2D.new()
		cloud.texture = CLOUD_TEXTURE
		var size_scale := randf_range(0.6, 1.1)
		cloud.scale = Vector2(size_scale, size_scale)
		cloud.position = Vector2(randf_range(0.0, screen.x), randf_range(120.0, screen.y * 0.7))
		cloud.set_meta("speed", 15.0 + 25.0 * size_scale)  # büyük bulutlar daha hızlı
		clouds.add_child(cloud)


func _move_clouds(delta: float) -> void:
	var screen := _screen_size()
	for cloud: Sprite2D in clouds.get_children():
		cloud.position.x -= cloud.get_meta("speed") * speed_factor * delta
		if cloud.position.x < -150.0:
			cloud.position = Vector2(screen.x + 150.0, randf_range(120.0, screen.y * 0.7))


func _layout() -> void:
	# Farklı telefon boylarında çimen hep en altta dursun
	var screen := _screen_size()
	ground.position = Vector2(0.0, screen.y - GROUND_HEIGHT)
	ground.size = Vector2(screen.x, GROUND_HEIGHT)


func _screen_size() -> Vector2:
	return get_viewport_rect().size


func _bird_start_position() -> Vector2:
	var screen := _screen_size()
	return Vector2(screen.x * 0.3, screen.y * 0.45)
