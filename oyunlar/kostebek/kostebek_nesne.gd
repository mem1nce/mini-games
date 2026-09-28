extends "res://oyunlar/kostebek/cikan_nesne.gd"
# Mole: sevimli köstebek. Kasklıysa ilk dokunuş kaskı kırar (puan yok, şaşkın yüz, süre uzar),
# sonraki ayrı dokunuş köstebeği vurur: sersemler (sarmal gözler, başının üstünde dönen yıldızlar)
# ve hızla içeri kaçar. Bütün katmanlar aynı 256x300 tuvalde; düğümün merkezi tuvalin merkezi.

const G := "res://oyunlar/kostebek/gorseller/"
const TEX_BODY: Texture2D = preload(G + "kostebek.svg")
const TEX_FACE_NORMAL: Texture2D = preload(G + "yuz_normal.svg")
const TEX_FACE_DIZZY: Texture2D = preload(G + "yuz_sersem.svg")
const TEX_FACE_SURPRISED: Texture2D = preload(G + "yuz_saskin.svg")
const TEX_HELMET: Texture2D = preload(G + "kask.svg")
const TEX_CRACK: Texture2D = preload(G + "kask_catlak.svg")
const TEX_STAR: Texture2D = preload(G + "yildiz.svg")

const DIZZY_TIME := 0.45       # vurulunca içeri kaçmadan önce sersem bekleme
const ESCAPE_TIME := 0.16      # vurulunca içeri kaçış süresi

var has_helmet: bool = false
var helmet: Sprite2D
var _crack: Sprite2D
var _face: Sprite2D
var _body_root: Node2D
var _stars: Array[Sprite2D] = []


func _init() -> void:
	kind = Kind.MOLE
	up_y = -104.0      # tuvalin y=254 çizgisi çukurun ağız çizgisine gelir, gövdenin altı dudağın arkasında kalır
	rise_trans = Tween.TRANS_CUBIC   # fırlamasın: gövdenin düz alt kenarı hiç görünmesin
	down_y = 200.0
	visual_rect = Rect2(-96, -144, 192, 260)


func setup(with_helmet: bool) -> void:
	has_helmet = with_helmet
	# Gövde kökü tuvalin alt kenarında: ezilip esnerken alt kenar yerinde kalır (dudağın arkasında)
	_body_root = Node2D.new()
	_body_root.position.y = 150.0
	add_child(_body_root)
	_add(TEX_BODY)
	_face = _add(TEX_FACE_NORMAL)
	if has_helmet:
		helmet = _add(TEX_HELMET)
		_crack = _add(TEX_CRACK)
		_crack.visible = false


func _add(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(0.5, 0.5)
	sprite.position.y = -150.0
	_body_root.add_child(sprite)
	return sprite


func _on_hit() -> void:
	if has_helmet:
		_break_helmet()
		hit.emit(self, HitResult.HELMET)
		return
	was_hit = true
	hittable = false
	_face.texture = TEX_FACE_DIZZY
	_show_stars()
	# Ezilip geri esner, biraz sersem bekler, sonra hızla içeri kaçar
	if _tween:
		_tween.kill()
	_body_root.scale = Vector2(1.15, 0.8)
	var squash := _body_root.create_tween()
	squash.tween_property(_body_root, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween = create_tween()
	_tween.tween_interval(DIZZY_TIME)
	_tween.tween_callback(go_down.bind(ESCAPE_TIME))
	hit.emit(self, HitResult.MOLE)


# Kask kırılır: kısa çatlak, sonra kask görünmez olur (parçaları efekt katmanı uçurur).
# Köstebek şaşkın bakar ve ikinci dokunuş için biraz daha uzun kalır.
func _break_helmet() -> void:
	has_helmet = false
	_crack.visible = true
	helmet.rotation = 0.0
	var crack := create_tween()
	crack.tween_property(helmet, "position:x", 4.0, 0.03)
	crack.tween_property(helmet, "position:x", -4.0, 0.03)
	crack.tween_callback(helmet.hide)
	crack.tween_callback(_crack.hide)
	_face.texture = TEX_FACE_SURPRISED
	_body_root.scale = Vector2(1.08, 0.9)
	var bounce := _body_root.create_tween()
	bounce.tween_property(_body_root, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Başın üstünde dönen üç yıldız
func _show_stars() -> void:
	for k in 3:
		var star := Sprite2D.new()
		star.texture = TEX_STAR
		star.scale = Vector2.ONE * 0.2
		add_child(star)
		_stars.append(star)


func _process(delta: float) -> void:
	super(delta)
	for k in _stars.size():
		var angle := _time * 6.0 + k * TAU / _stars.size()
		var star := _stars[k]
		star.position = Vector2(cos(angle) * 70.0, -150.0 + sin(angle) * 16.0)
		star.rotation = _time * 4.0


# Kask parçalarının uçması için: kask sprite'ının dünyadaki dönüşümü
func helmet_transform() -> Transform2D:
	return helmet.global_transform if helmet else global_transform
