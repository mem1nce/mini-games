extends Node2D
# Sürüklenebilir nesne (DraggableItem): yakalanma, parmağı izleme, yerine geri kayma, gelme/gitme
# ve kutlama zıplaması animasyonları. Dokunmayı ortak/surukleme_girdisi.gd (DragInput) yönetir;
# doğru yere bırakılıp bırakılmadığına oyun karar verir.
# Kullanım: bu script'i extends et, görselini (Sprite2D vb.) alt düğüm olarak ekle, setup_drag() çağır.
# Gölge Eşleştirme (esya.gd) ve Hayvanları Besle (yiyecek.gd) kullanır.

const Z_IDLE := 1
const Z_DRAGGED := 10

var home: Vector2                # başlangıç yeri; yanlış bırakılınca buraya döner
var size: float = 200.0          # görselin boyu (yakalama alanı ve animasyon mesafeleri buna göre)
var dragging: bool = false

var _target: Vector2             # sürüklerken parmağın biraz üstündeki hedef nokta
var _lift: float = 0.0
var _tween: Tween


func setup_drag(item_size: float, start: Vector2) -> void:
	size = item_size
	home = start
	position = start
	z_index = Z_IDLE


# Şu an tutulabilir mi? (alt sınıf değiştirir: yerleşmiş / yenmiş nesne tutulamaz)
func can_grab() -> bool:
	return true


# Parmak nesnenin yakalama alanında mı? Alan görselden biraz büyüktür (padding > 1).
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


func drag_to(point: Vector2) -> void:
	_target = point + Vector2(0.0, -_lift)


# Nesnenin gideceği nokta (bırakma kontrolü görünen konuma göre yapılır)
func drop_point() -> Vector2:
	return _target


func _process(delta: float) -> void:
	if dragging:
		# Parmağı yumuşakça izler (ani sıçrama olmasın)
		position = position.lerp(_target, 1.0 - exp(-28.0 * delta))


# Yumuşakça başlangıç yerine kayar; wiggle: önce hafifçe sallanır (yanlış yere bırakıldı)
func return_home(duration: float, wiggle: bool) -> void:
	dragging = false
	var tween := _new_tween()
	if wiggle:
		for angle in [0.14, -0.12, 0.08, 0.0]:
			tween.tween_property(self, "rotation", angle, 0.07)
	tween.tween_property(self, "position", home, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "rotation", 0.0, duration)
	tween.tween_callback(func() -> void: z_index = Z_IDLE)


# Aşağıdan zıplayarak gelir
func appear(delay: float) -> void:
	var start := position
	position = start + Vector2(0.0, size * 0.6)
	scale = Vector2.ZERO
	var tween := _new_tween().set_parallel()
	tween.tween_property(self, "position", start, 0.5).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear(delay: float) -> void:
	dragging = false
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
	if dragging or not can_grab():
		return
	var tween := _new_tween()
	for angle in [0.1, -0.1, 0.07, -0.05, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.09)


func _new_tween() -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	return _tween
