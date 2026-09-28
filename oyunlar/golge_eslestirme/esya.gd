extends Node2D
# Sürüklenebilir eşya (DraggableItem). Dokunmayı ana sahne yönetir; eşya sadece
# yakalanma, parmağı izleme, geri kayma ve gölgesine oturma animasyonlarını yapar.
# Bırakılınca "dropped" sinyali gönderir, doğru yere bırakılıp bırakılmadığına ana sahne karar verir.

signal picked(item: Node2D)
signal dropped(item: Node2D, at: Vector2)

const Slot := preload("res://oyunlar/golge_eslestirme/golge_yuvasi.gd")

const Z_IDLE := 1
const Z_PLACED := 0
const Z_DRAGGED := 10

var data: ShadowItemData
var slot: Slot                   # bu eşyanın kendi gölgesi
var home: Vector2                # başlangıç yeri; yanlış bırakılınca buraya döner
var size: float = 200.0
var placed: bool = false
var dragging: bool = false

var _sprite: Sprite2D
var _target: Vector2             # sürüklerken parmağın biraz üstündeki hedef nokta
var _lift: float = 0.0
var _tween: Tween


func setup(item_data: ShadowItemData, item_size: float, start: Vector2) -> void:
	data = item_data
	size = item_size
	home = start
	position = start
	z_index = Z_IDLE
	_sprite = Sprite2D.new()
	_sprite.texture = item_data.texture
	_sprite.scale = Vector2.ONE * item_size / item_data.texture.get_width()
	add_child(_sprite)


# Parmak eşyanın yakalama alanında mı? Alan görselden biraz büyüktür (padding > 1).
func grab_distance(point: Vector2, padding: float) -> float:
	var distance := point.distance_to(position)
	return distance if distance <= size * 0.5 * padding else INF


func grab(point: Vector2, lift: float, drag_scale: float) -> void:
	dragging = true
	_lift = lift
	_target = point + Vector2(0.0, -lift)
	z_index = Z_DRAGGED
	_new_tween().tween_property(self, "scale", Vector2.ONE * drag_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "rotation", 0.0, 0.15)
	picked.emit(self)


func drag_to(point: Vector2) -> void:
	_target = point + Vector2(0.0, -_lift)


# Eşyanın gideceği nokta (bırakma kontrolü görünen konuma göre yapılır)
func drop_point() -> Vector2:
	return _target


func release() -> void:
	if not dragging:
		return
	dragging = false
	dropped.emit(self, _target)


func _process(delta: float) -> void:
	if dragging:
		# Parmağı yumuşakça izler (ani sıçrama olmasın)
		position = position.lerp(_target, 1.0 - exp(-28.0 * delta))


# Yumuşakça başlangıç yerine kayar; yanlış gölgeye bırakıldıysa önce hafifçe sallanır
func return_home(duration: float, wiggle: bool) -> void:
	dragging = false
	var tween := _new_tween()
	if wiggle:
		for angle in [0.14, -0.12, 0.08, 0.0]:
			tween.tween_property(self, "rotation", angle, 0.07)
	tween.tween_property(self, "position", home, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: z_index = Z_IDLE)


# Gölgenin üstüne oturur: küçük bir büyüme-küçülme ile
func snap_to(point: Vector2, duration: float) -> void:
	dragging = false
	placed = true
	z_index = Z_PLACED
	var tween := _new_tween()
	tween.tween_property(self, "position", point, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", 0.0, duration)
	tween.tween_property(self, "scale", Vector2.ONE * 1.22, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Bölüm başında aşağıdan zıplayarak gelir
func appear(delay: float) -> void:
	var start := position
	position = start + Vector2(0.0, size * 0.6)
	scale = Vector2.ZERO
	var tween := _new_tween().set_parallel()
	tween.tween_property(self, "position", start, 0.5).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear(delay: float) -> void:
	var tween := _new_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.35).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", randf_range(-0.6, 0.6), 0.35).set_delay(delay)
	tween.chain().tween_callback(queue_free)


# Kutlamada yerinde zıplar
func hop(delay: float, times: int = 1) -> void:
	var base := position
	var tween := _new_tween()
	tween.tween_interval(delay)
	for k in times:
		tween.tween_property(self, "position", base + Vector2(0.0, -size * 0.2), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "rotation", 0.12 if k % 2 == 0 else -0.12, 0.2)
		tween.tween_property(self, "position", base, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "rotation", 0.0, 0.25)
		tween.tween_interval(0.08)


# İpucu sırasında dikkat çekmek için hafifçe kıpırdar
func wiggle() -> void:
	if dragging or placed:
		return
	var tween := _new_tween()
	for angle in [0.1, -0.1, 0.07, -0.05, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.09)


func _new_tween() -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	return _tween
