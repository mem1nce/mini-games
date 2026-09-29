extends Node2D
# Yarıştaki araba: pistin eğrisi üzerinde ilerler (fizik motoru yok).
# Durum yol boyunca uzaklık (s) ve hızdır. Arka ve ön tekerleğin temas noktaları eğriden okunur;
# araba ikisinin ortasına oturur, açısı ikisini birleştiren çizgidir (tepelerde kendiliğinden eğilir).
# Rampa ucunda zıplar: yatay hız sabit, yükseklik iki parçalı parabol (inişte daha hafif yerçekimi =
# süzülme); konum zıplamanın başından geçen süreyle hesaplanır. Su birikintisi kısa süre yavaşlatır,
# kasiste araba küçük bir hoplar. Çizim araba_gorunum.gd'de; çocuğun ve rakiplerin arabası aynı script.

signal jumped(car: Node2D)
signal landed(car: Node2D)
signal splashed(car: Node2D)
signal bumped(car: Node2D)
signal crossed_finish(car: Node2D)

const Gorunum := preload("res://oyunlar/araba_yarisi/araba_gorunum.gd")

const MAX_SPEED := 680.0
const ACCEL := 340.0             # gaza basınca (px/sn²)
const COAST := 190.0             # bırakınca yumuşak yavaşlama
const SLOPE_EFFECT := 0.7        # yokuş yukarı yavaşlatır, aşağı hızlandırır
# Şeritler: 0 çocuğun arabası (önde), 1-2 rakipler (arkada, biraz küçük). Değer: yakın kenardan yukarı px
const LANES := [26.0, 56.0, 84.0]
const SCALES := [0.78, 0.71, 0.65]
const WHEEL_BASE := 164.0        # tuvalde iki tekerlek arası
const BODY_CENTER := 92.0        # tuvalde gövde ortasının yerden yüksekliği (yıldız toplamak için)
# Zıplama
const JUMP_G_UP := 900.0
const JUMP_G_DOWN := 560.0
const JUMP_VY := [470.0, 600.0]  # küçük / büyük rampada en yüksek dikey hız
const JUMP_MIN_RATIO := 0.45     # yavaş gelen araba da biraz zıplar
const JUMP_MIN_VX := 0.45        # havada en az bu oranda yatay hız
# Engeller
const PUDDLE_SLOW := 0.62
const PUDDLE_TIME := 0.7
const BUMP_SLOW := 0.8
const BUMP_HOP := 30.0
const BUMP_TIME := 0.36

var track: Node2D                # pist.gd
var lane := 0
var lane_offset := 26.0
var car_scale := 0.78
var half_wb := 64.0
var s := 0.0
var speed := 0.0
var target_speed := 0.0
var throttle := false            # egzoz dumanı için (gaz veriliyor mu)
var airborne := false
var finished := false
var view: Gorunum
var exhaust: CPUParticles2D

var _next_ramp := 0
var _next_obstacle := 0
var _launch_pos := Vector2.ZERO
var _air_t := 0.0
var _vx := 0.0
var _vy := 0.0
var _slow_t := 0.0
var _hop_t := -1.0
var _prev_speed := 0.0
var _prev_y := 0.0
var _vert_vel := 0.0
var _pose_offset := Vector2.ZERO  # inişte konum sıçramasın diye yavaşça sönen fark
var _rot_offset := 0.0


static func half_wheel_base(p_scale: float) -> float:
	return WHEEL_BASE * 0.5 * p_scale


# Rampadan çıkış dikey hızı: hıza bağlı, en az JUMP_MIN_RATIO
static func jump_vy(size: int, ratio: float) -> float:
	return JUMP_VY[clampi(size, 1, 2) - 1] * lerpf(JUMP_MIN_RATIO, 1.0, clampf(ratio, 0.0, 1.0))


# Zıplamanın başından t sn sonra çıkış noktasına göre yükseklik (px, + yukarı)
static func jump_height(t: float, vy: float) -> float:
	var t_up := vy / JUMP_G_UP
	if t <= t_up:
		return vy * t - 0.5 * JUMP_G_UP * t * t
	var d := t - t_up
	return vy * vy / (2.0 * JUMP_G_UP) - 0.5 * JUMP_G_DOWN * d * d


# Havadaki dikey hız (+ yukarı)
static func jump_velocity(t: float, vy: float) -> float:
	var t_up := vy / JUMP_G_UP
	return vy - JUMP_G_UP * t if t <= t_up else -JUMP_G_DOWN * (t - t_up)


func setup(p_track: Node2D, p_lane: int, color: String, driver: int, start_s: float) -> void:
	track = p_track
	lane = p_lane
	lane_offset = LANES[lane]
	car_scale = SCALES[lane]
	half_wb = half_wheel_base(car_scale)
	scale = Vector2.ONE * car_scale
	view = Gorunum.new()
	add_child(view)
	view.set_color(color)
	view.set_driver(driver)
	s = start_s
	while _next_ramp < track.ramps.size() and track.ramps[_next_ramp]["s1"] <= s + half_wb:
		_next_ramp += 1
	while _next_obstacle < track.obstacles.size() and track.obstacles[_next_obstacle]["s"] <= s:
		_next_obstacle += 1
	_update_pose(0.0, true)
	_prev_y = position.y


# Gövde ortası (dünyada): yıldız toplama ve efektler için
func body_center() -> Vector2:
	return position + Vector2(0, -BODY_CENTER * car_scale).rotated(rotation)


func speed_ratio() -> float:
	return clampf(speed / MAX_SPEED, 0.0, 1.2)


func step(delta: float) -> void:
	if airborne:
		_air_step(delta)
	else:
		_road_step(delta)
	# Hızlanınca burun kalkar, yavaşlayınca hafifçe iner
	var accel := (speed - _prev_speed) / maxf(delta, 0.001)
	_prev_speed = speed
	view.set_lean(clampf(-accel / ACCEL * 0.05, -0.06, 0.05) if not airborne else 0.0)
	if exhaust:
		exhaust.position = view.exhaust_position()
		# Duman sadece hızlanırken (tam hızda ve havada yok)
		exhaust.emitting = throttle and not finished and not airborne and speed < MAX_SPEED * 0.8


func _road_step(delta: float) -> void:
	var slope: float = track.slope_at(s)
	var factor := clampf(1.0 + slope * SLOPE_EFFECT, 0.85, 1.12)
	var goal := target_speed * factor
	if _slow_t > 0.0:
		_slow_t -= delta
		goal = minf(goal, MAX_SPEED * 0.5)
	if speed < goal:
		speed = minf(goal, speed + ACCEL * delta)
	else:
		speed = maxf(goal, speed - COAST * delta)
	var prev := s
	s = minf(s + speed * delta, track.length - half_wb - 1.0)
	# Ön tekerlek rampa ucunu geçtiyse zıpla
	if _next_ramp < track.ramps.size():
		var ramp: Dictionary = track.ramps[_next_ramp]
		if s + half_wb >= ramp["s1"]:
			_next_ramp += 1
			s = ramp["s1"] - half_wb
			_update_pose(delta, false)
			view.spin_wheels((s - prev) / car_scale)
			_launch(ramp)
			return
	while _next_obstacle < track.obstacles.size() and track.obstacles[_next_obstacle]["s"] <= s:
		_hit(track.obstacles[_next_obstacle])
		_next_obstacle += 1
	_update_pose(delta, false)
	view.spin_wheels((s - prev) / car_scale)
	_check_finish()


func _contact(at: float) -> Vector2:
	return track.lane_point(at, lane_offset) - Vector2(0, track.ramp_height(at))


func _update_pose(delta: float, snap: bool) -> void:
	var rear := _contact(s - half_wb)
	var front := _contact(s + half_wb)
	var mid := (rear + front) * 0.5
	var hop := 0.0
	if _hop_t >= 0.0:
		_hop_t += delta
		if _hop_t >= BUMP_TIME:
			_hop_t = -1.0
		else:
			hop = sin(PI * _hop_t / BUMP_TIME) * BUMP_HOP * car_scale
	var angle := (front - rear).angle()
	if snap or delta <= 0.0:
		rotation = angle
	else:
		# Yolun dikey hızındaki ani değişim (tepe, çukur, rampa başı) gövdeyi yaylandırır
		var vy := (mid.y - _prev_y) / delta
		view.bump(-(vy - _vert_vel) * 0.22)
		_vert_vel = vy
		var k := 1.0 - exp(-14.0 * delta)
		_pose_offset = _pose_offset.lerp(Vector2.ZERO, k)
		_rot_offset = lerpf(_rot_offset, 0.0, k)
		rotation = angle + _rot_offset
	_prev_y = mid.y
	position = mid - Vector2(0, hop) + _pose_offset


func _launch(ramp: Dictionary) -> void:
	airborne = true
	_air_t = 0.0
	_launch_pos = position
	_vy = jump_vy(ramp["size"], speed / MAX_SPEED)
	_vx = maxf(speed, MAX_SPEED * JUMP_MIN_VX)
	speed = _vx
	_pose_offset = Vector2.ZERO
	_rot_offset = 0.0
	view.bump(140.0)
	view.set_airborne(1.0)
	jumped.emit(self)


func _air_step(delta: float) -> void:
	_air_t += delta
	var x := _launch_pos.x + _vx * _air_t
	position = Vector2(x, _launch_pos.y - jump_height(_air_t, _vy))
	var v_up := jump_velocity(_air_t, _vy)
	# Havada burun hareket yönüne biraz döner, inişe doğru düzelir
	var target := atan2(-v_up, _vx) * 0.4
	rotation = lerp_angle(rotation, target, 1.0 - exp(-4.0 * delta))
	view.spin_wheels(_vx * 0.7 * delta / car_scale)
	var ground: float = track.lane_y_at_x(x, lane_offset)
	var height: float = ground - position.y
	view.place_shadow(Vector2(x, ground), clampf(1.0 - height / 420.0, 0.25, 1.0))
	# En alçaktaki tekerlek yere değince iner
	var lowest := position.y + absf(sin(rotation)) * half_wb
	if v_up < 0.0 and lowest >= ground:
		_land(x)
	_check_finish()


func _land(x: float) -> void:
	var fall := -jump_velocity(_air_t, _vy)
	var before := position
	var before_rot := rotation
	airborne = false
	s = track.s_at_x(x)
	_update_pose(0.0, true)
	_pose_offset = before - position
	_rot_offset = wrapf(before_rot - rotation, -PI, PI)
	position = before
	rotation = before_rot
	_prev_y = position.y - _pose_offset.y
	_vert_vel = 0.0
	view.set_airborne(0.0)
	view.reset_shadow()
	view.bump(120.0 + fall * 0.35)
	# Üstünden uçulan engeller atlanır
	while _next_obstacle < track.obstacles.size() and track.obstacles[_next_obstacle]["s"] <= s:
		_next_obstacle += 1
	while _next_ramp < track.ramps.size() and track.ramps[_next_ramp]["s1"] <= s + half_wb:
		_next_ramp += 1
	landed.emit(self)


func _hit(obstacle: Dictionary) -> void:
	match obstacle["type"]:
		"puddle":
			speed *= PUDDLE_SLOW
			_slow_t = PUDDLE_TIME
			view.kick_tilt(0.9)
			view.bump(90.0)
			splashed.emit(self)
		"bump":
			speed *= BUMP_SLOW
			_hop_t = 0.0
			view.bump(-260.0)
			view.kick_tilt(-0.7)
			bumped.emit(self)


func _check_finish() -> void:
	if finished:
		return
	var at: float = s if not airborne else track.s_at_x(position.x)
	if at >= track.finish_s:
		finished = true
		crossed_finish.emit(self)
