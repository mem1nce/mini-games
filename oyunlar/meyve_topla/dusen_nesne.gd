extends Node2D
# Ağaçtan düşen tek bir nesne: meyve, kötü nesne ya da güçlendirme baloncuğu.
# Dalın ucunda küçükten büyüyerek belirir, uyarı süresince sallanır, sonra düşer.
# Yerde nereye ineceğini, yaklaştıkça koyulaşan bir gölge gösterir.

signal warning_started(item: Node2D)

enum Phase { HANGING, FALLING, BOUNCING, DONE }

const GRAVITY := 900.0
const BOUNCE_GRAVITY := 1500.0
const WIND_AMPLITUDE := 38.0
const WIND_SPEED := 1.8

var kind: String = ""
var category: String = ""        # "meyve", "kotu", "guc"
var picture: Texture2D           # sepete eklenirken kullanılır
var color := Color.WHITE         # parçacık rengi
var branch_index: int = -1
var phase: Phase = Phase.HANGING
var radius: float = 42.0
var base_x: float = 0.0          # rüzgarsız yatay konum (mıknatıs bunu kaydırır)
var prev_y: float = 0.0          # bir önceki karedeki y (sepet çizgisini geçti mi diye)

var _max_speed := 200.0
var _ground_y := 1170.0
var _windy := false
var _wind_dir := 1.0
var _velocity := Vector2.ZERO
var _spin := 0.0
var _time := 0.0
var _fall_time := 0.0
var _fall_start_y := 0.0
var _hang_left := 1.0
var _warning_time := 0.7
var _warned := false
var _anchor: Node2D
var _anchor_offset := Vector2.ZERO
var _body: Node2D                # görsel kısım; dönme ve sallanma buna uygulanır
var _shadow: Sprite2D
var _shadow_scale := Vector2.ONE
var _fly: Sprite2D
var _glow: Sprite2D


func setup(p_kind: String, p_category: String, texture: Texture2D, size: float, anchor: Node2D,
		anchor_offset: Vector2, hang_time: float, warning_time: float, max_speed: float,
		ground_y: float, windy: bool, shadow_layer: Node2D, shadow_texture: Texture2D) -> void:
	kind = p_kind
	category = p_category
	picture = texture
	radius = size * 0.5
	_anchor = anchor
	_anchor_offset = anchor_offset
	_hang_left = hang_time
	_warning_time = warning_time
	_max_speed = max_speed
	_ground_y = ground_y
	_windy = windy
	_wind_dir = 1.0 if randf() < 0.5 else -1.0
	_spin = randf_range(0.8, 1.8) * (1.0 if randf() < 0.5 else -1.0)

	_body = Node2D.new()
	add_child(_body)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * size / texture.get_width()
	_body.add_child(sprite)
	_follow_anchor()

	_shadow = Sprite2D.new()
	_shadow.texture = shadow_texture
	_shadow_scale = Vector2.ONE * size * 1.0 / shadow_texture.get_width()
	_shadow.scale = _shadow_scale * 0.4
	_shadow.modulate.a = 0.0
	_shadow.position = Vector2(position.x, _ground_y)
	shadow_layer.add_child(_shadow)

	# Dalda küçükten büyüyerek belirir
	_body.scale = Vector2.ZERO
	create_tween().tween_property(_body, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Çürük elmanın etrafında uçuşan sinek
func add_fly(texture: Texture2D) -> void:
	_fly = Sprite2D.new()
	_fly.texture = texture
	_fly.scale = Vector2.ONE * 34.0 / texture.get_width()
	add_child(_fly)


# Güçlendirme: baloncuğun içinde simge ve arkasında parıltı
func add_power_icon(icon: Texture2D, glow: Texture2D) -> void:
	var icon_sprite := Sprite2D.new()
	icon_sprite.texture = icon
	icon_sprite.scale = Vector2.ONE * radius * 1.25 / icon.get_width()
	_body.add_child(icon_sprite)
	_glow = Sprite2D.new()
	_glow.texture = glow
	_glow.scale = Vector2.ONE * radius * 3.4 / glow.get_width()
	_glow.modulate.a = 0.7
	add_child(_glow)
	move_child(_glow, 0)
	_spin = 0.0


func _exit_tree() -> void:
	if is_instance_valid(_shadow):
		_shadow.queue_free()


func _follow_anchor() -> void:
	if is_instance_valid(_anchor):
		position = get_parent().to_local(_anchor.to_global(_anchor_offset)) + Vector2(0, radius * 0.85)


# Her karede ana script çağırır. "landed" (yere indi) ya da "" döner.
func step(delta: float) -> String:
	_time += delta
	_update_extras()
	match phase:
		Phase.HANGING:
			_follow_anchor()
			_hang_left -= delta
			if not _warned and _hang_left <= _warning_time:
				_warned = true
				warning_started.emit(self)
			if _warned:
				_body.rotation = sin(_time * 28.0) * 0.13
				_shadow.position = Vector2(position.x, _ground_y)
				_shadow.modulate.a = move_toward(_shadow.modulate.a, 0.18, delta)
			else:
				_body.rotation = sin(_time * 2.2) * 0.05
			if _hang_left <= 0.0:
				_start_fall()
		Phase.FALLING:
			prev_y = position.y
			_fall_time += delta
			_velocity.y = minf(_velocity.y + GRAVITY * delta, _max_speed)
			position.y += _velocity.y * delta
			var wind := 0.0
			if _windy:
				# Rüzgar yavaşça başlar ki meyve birden kaymasın
				wind = sin(_fall_time * WIND_SPEED) * WIND_AMPLITUDE * _wind_dir * minf(_fall_time / 0.5, 1.0)
			position.x = base_x + wind
			_body.rotation += _spin * delta * (1.8 if _windy else 1.0)
			_update_shadow()
			if position.y >= _ground_y - radius * 0.75:
				position.y = _ground_y - radius * 0.75
				return "landed"
		Phase.BOUNCING:
			_velocity.y += BOUNCE_GRAVITY * delta
			position += _velocity * delta
			_body.rotation += _spin * delta
			if position.y > _ground_y + 300.0:
				queue_free()
	return ""


func _start_fall() -> void:
	phase = Phase.FALLING
	base_x = position.x
	prev_y = position.y
	_fall_start_y = position.y
	_velocity = Vector2.ZERO


func _update_shadow() -> void:
	var t := clampf((position.y - _fall_start_y) / maxf(_ground_y - _fall_start_y, 1.0), 0.0, 1.0)
	_shadow.position = Vector2(position.x, _ground_y)
	_shadow.scale = _shadow_scale * lerpf(0.45, 1.0, t)
	_shadow.modulate.a = lerpf(0.18, 0.6, t)


func _update_extras() -> void:
	if _fly:
		# Sinek elmanın etrafında sekiz çizer, kanatları titrer
		var x := cos(_time * 4.2) * radius * 1.15
		_fly.position = Vector2(x, sin(_time * 8.4) * radius * 0.35 - radius * 0.95)
		_fly.flip_h = sin(_time * 4.2) > 0.0
		_fly.scale.y = absf(_fly.scale.x) * (1.0 + sin(_time * 55.0) * 0.08)
	if _glow:
		# Baloncuk hafifçe nefes alır, arkasındaki parıltı nabız gibi atar
		var pulse := 1.0 + sin(_time * 5.0) * 0.08
		_glow.scale = Vector2.ONE * radius * 3.4 / _glow.texture.get_width() * pulse
		if _time > 0.4 and phase != Phase.DONE:
			_body.scale = Vector2.ONE * (1.0 + sin(_time * 3.0) * 0.04)


# Hedef olmayan meyve sepetten seker (ceza yok)
func bounce_off(direction: float) -> void:
	phase = Phase.BOUNCING
	_velocity = Vector2(direction * randf_range(240.0, 340.0), -560.0)
	_spin = direction * 9.0
	_fade_shadow()
	create_tween().tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.5)


# Kötü nesne kirpiye çarpıp savrulur
func knock_away(direction: float) -> void:
	phase = Phase.BOUNCING
	_velocity = Vector2(direction * randf_range(320.0, 420.0), -620.0)
	_spin = direction * 12.0
	_fade_shadow()
	create_tween().tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.45)


# Yere düştü: hafifçe ezilip söner
func land() -> void:
	phase = Phase.DONE
	_body.rotation = 0.0
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector2(1.25, 0.75), 0.08)
	tween.tween_property(_body, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.3)
	tween.tween_callback(queue_free)
	_fade_shadow()


# Bölüm bitince ya da baştan başlarken nazikçe kaybolur
func vanish() -> void:
	phase = Phase.DONE
	var tween := create_tween().set_parallel()
	tween.tween_property(_body, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
	_fade_shadow()


# Güçlendirme baloncuğu patlar
func pop() -> void:
	phase = Phase.DONE
	var tween := create_tween().set_parallel()
	tween.tween_property(_body, "scale", Vector2(1.5, 1.5), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)
	_fade_shadow()


func _fade_shadow() -> void:
	if is_instance_valid(_shadow):
		create_tween().tween_property(_shadow, "modulate:a", 0.0, 0.2)
