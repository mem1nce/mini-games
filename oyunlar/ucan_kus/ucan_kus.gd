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

@export_group("Canlar")
@export var start_lives: int = 3
## Çarptıktan sonra kuşun yanıp söndüğü (dokunulmaz olduğu) süre.
@export var blink_duration: float = 1.5

const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")
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

@onready var bird: AnimatedSprite2D = $Bird
@onready var pipes: Node2D = $Pipes
@onready var ground: ColorRect = $Ground
@onready var clouds: Node2D = $Background/Clouds
@onready var score_label: Label = $HUD/ScoreLabel
@onready var hearts_box: HBoxContainer = $HUD/HeartsBox
@onready var start_screen: Control = $HUD/StartScreen
@onready var tap_label: Label = $HUD/StartScreen/TapLabel
@onready var game_over_screen: Control = $HUD/GameOverScreen
@onready var result_label: Label = $HUD/GameOverScreen/Box/ResultLabel
@onready var restart_button: Button = $HUD/GameOverScreen/Box/RestartButton
@onready var back_panel: Panel = $HUD/BackButton
var back_button: Control

var state: State = State.READY
var bird_velocity: float = 0.0
var score: int = 0
var lives: int = 0
var blink_left: float = 0.0
var distance_since_spawn: float = 0.0
var last_gap_y: float = 0.0
var can_restart: bool = false
var time_passed: float = 0.0


func _ready() -> void:
	SesYoneticisi.muzik("ucan_kus", self)
	back_button = HoldButton.replace(back_panel)
	back_button.completed.connect(_on_back_completed)
	lives = start_lives
	_create_hearts()
	_create_clouds()
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
	if touch == null:
		return

	# Geri (basılı tutulur): başlangıç ekranındayken ana menüye, oyun sırasında başlangıç ekranına
	if back_button.handle_touch(touch) or not touch.pressed:
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


func _on_back_completed() -> void:
	SesYoneticisi.efekt("geri")
	if state == State.READY:
		SahneGecis.ana_menuye_don()
	else:
		SahneGecis.sahneyi_yeniden_baslat()


func _process(delta: float) -> void:
	time_passed += delta
	_move_clouds(delta)

	match state:
		State.READY:
			# Başlamadan önce kuş havada hafifçe süzülür
			bird.position.y = _bird_start_position().y + sin(time_passed * 3.0) * 15.0
		State.PLAYING:
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
	bird_velocity = -flap_strength
	bird.frame = 0
	SesYoneticisi.efekt("kanat", -3.0)


func _take_hit() -> void:
	if blink_left > 0.0 or state != State.PLAYING:
		return
	lives -= 1
	_update_hearts()
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


func _game_over() -> void:
	state = State.GAME_OVER
	blink_left = 0.0
	bird.modulate.a = 1.0
	bird.pause()
	score_label.visible = false
	result_label.text = "Puan: %d" % score

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


# --- Kuş ---

func _update_bird(delta: float) -> void:
	bird_velocity = minf(bird_velocity + gravity * delta, max_fall_speed)
	bird.position.y += bird_velocity * delta

	# Yükselirken yukarı, düşerken aşağı doğru hafifçe eğil
	var target_rotation := clampf(bird_velocity / max_fall_speed * 0.5, -0.35, 0.5)
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
	distance_since_spawn += pipe_speed * delta
	if distance_since_spawn >= pipe_spacing:
		distance_since_spawn -= pipe_spacing
		_spawn_pipe_pair()

	for pair: Node2D in pipes.get_children():
		pair.position.x -= pipe_speed * delta
		if not pair.get_meta("scored") and pair.position.x + PIPE_HALF_WIDTH < bird.position.x:
			pair.set_meta("scored", true)
			_add_point()
		if pair.position.x < -PIPE_HALF_WIDTH * 3.0:
			pair.queue_free()


func _spawn_pipe_pair() -> void:
	var screen := _screen_size()
	var min_y := GAP_TOP_LIMIT + gap_size / 2.0
	var max_y := screen.y - GROUND_HEIGHT - GAP_BOTTOM_LIMIT - gap_size / 2.0
	var gap_y := randf_range(last_gap_y - max_gap_shift, last_gap_y + max_gap_shift)
	gap_y = clampf(gap_y, min_y, max_y)
	if max_y < min_y:
		gap_y = (screen.y - GROUND_HEIGHT) / 2.0  # boşluk çok büyük ayarlandıysa ortala
	last_gap_y = gap_y

	# Çiftin merkezi boşluğun ortası
	var pair := Node2D.new()
	pair.position = Vector2(screen.x + PIPE_HALF_WIDTH * 2.0, gap_y)
	pair.modulate = PIPE_COLORS.pick_random()
	pair.set_meta("scored", false)

	var half_height := PIPE_TEXTURE.get_height() / 2.0
	var top := Sprite2D.new()
	top.texture = PIPE_TEXTURE
	top.flip_v = true
	top.position.y = -gap_size / 2.0 - half_height
	var bottom := Sprite2D.new()
	bottom.texture = PIPE_TEXTURE
	bottom.position.y = gap_size / 2.0 + half_height

	pair.add_child(top)
	pair.add_child(bottom)
	pipes.add_child(pair)


# --- Çarpışma ---

func _check_collisions() -> void:
	# Yere değince kuş geri sıçrar (ve bir can gider)
	var floor_y := _screen_size().y - GROUND_HEIGHT
	if bird.position.y + bird_hit_radius > floor_y:
		bird.position.y = floor_y - bird_hit_radius
		bird_velocity = -flap_strength
		_take_hit()

	if blink_left > 0.0 or state != State.PLAYING:
		return
	for pair: Node2D in pipes.get_children():
		if _bird_hits_pair(pair):
			_take_hit()
			return


func _bird_hits_pair(pair: Node2D) -> bool:
	var half_gap := gap_size / 2.0
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
		cloud.position.x -= cloud.get_meta("speed") * delta
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
