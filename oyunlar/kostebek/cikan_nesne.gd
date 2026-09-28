extends Node2D
# PopUpItem: çukurdan çıkan her şeyin ortak temeli (köstebek, meyve, bomba).
# Çukurun maske düğümünün çocuğudur; birimler çukur birimidir (çukurun ağız merkezi = 0,0).
# Akış: pop_up() -> çıkar (RISING) -> bekler (UP) -> iner (HIDING) -> finished sinyali ve silinir.
# Vurulunca alt sınıf kendi animasyonunu oynar ve hit sinyalini verir.

signal hit(item: Node2D, result: int)
signal escaped(item: Node2D)          # vurulmadan içeri girdi (ceza yok)
signal finished(item: Node2D)         # tamamen içeri girdi, çukur boşaldı

enum Kind { MOLE, FRUIT, BOMB }
enum HitResult { HELMET, MOLE, FRUIT, BOMB }
enum Phase { RISING, UP, HIDING, DONE }

var kind: Kind = Kind.MOLE
var phase: Phase = Phase.RISING
var hittable: bool = true
var was_hit: bool = false
var stay_left: float = 1.0
var hide_time: float = 0.2

# Alt sınıfların ayarladığı değerler (çukur birimi)
var up_y: float = -100.0                # tamamen çıkınca konum
var down_y: float = 200.0               # tamamen içerideyken konum (maskenin altında, görünmez)
var visual_rect := Rect2(-100, -100, 200, 200)   # görselin kendi içindeki dikdörtgeni
var rise_trans: Tween.TransitionType = Tween.TRANS_BACK   # çıkış eğrisi (BACK: hafifçe fırlar)

var _tween: Tween
var _time: float = 0.0


func pop_up(stay: float, rise_time: float, hide: float) -> void:
	stay_left = stay
	hide_time = hide
	position.y = down_y
	phase = Phase.RISING
	_tween = create_tween()
	_tween.tween_property(self, "position:y", up_y, rise_time).set_trans(rise_trans).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_on_risen)


func _on_risen() -> void:
	if phase == Phase.RISING:
		phase = Phase.UP


func _process(delta: float) -> void:
	_time += delta
	if phase == Phase.UP and not was_hit:
		stay_left -= delta
		if stay_left <= 0.0:
			go_down()


func extend_stay(seconds: float) -> void:
	stay_left += seconds


# İçeri gir. Vurulmadan giriyorsa "kaçtı" sayılır (ceza yok).
func go_down(time: float = -1.0) -> void:
	if phase == Phase.HIDING or phase == Phase.DONE:
		return
	phase = Phase.HIDING
	hittable = false
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:y", down_y, hide_time if time < 0.0 else time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish)


func _finish() -> void:
	if phase == Phase.DONE:
		return
	phase = Phase.DONE
	hittable = false
	if not was_hit:
		escaped.emit(self)
	finished.emit(self)
	queue_free()


# Oyun bittiğinde: ne durumda olursa olsun hemen içeri
func force_hide() -> void:
	hittable = false
	was_hit = true   # oyun sonu: kaçtı sayılmasın
	go_down(0.18)


# Bir dokunuş bu nesneye geldi. Alt sınıflar _on_hit'i yazar.
func receive_hit() -> void:
	if not hittable:
		return
	_on_hit()


func _on_hit() -> void:
	pass


# Görselin şu an görünen kısmı (çukur biriminde): ağzın biraz altından yukarısı
func visible_rect() -> Rect2:
	var rect := Rect2(visual_rect.position + position, visual_rect.size)
	var bottom := minf(rect.end.y, 30.0)
	rect.size.y = maxf(0.0, bottom - rect.position.y)
	return rect


# 2x içe aktarılmış SVG için sprite: scale 0.5 ile tuval birimine iner
func _sprite(texture: Texture2D, units_scale: float = 1.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * 0.5 * units_scale
	add_child(sprite)
	return sprite
