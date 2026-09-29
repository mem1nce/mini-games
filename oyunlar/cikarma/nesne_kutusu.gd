extends Node2D
# ObjectBox: içindeki nesneleri kolay sayılır şekilde dizen kutu. Üstünde büyük bir rakam kartı var.
# Dizilim (layout): 1-5 zar yüzü (3x3 ızgara), 6 ve fazlası beşli sıralar (7 = üstte 5, altta 2).
# Kutu, düğüm konumunu merkez alarak çizilir. Sonuç kutusunda sağ altta bir sayaç balonu da olur.
# Çıkarma'da ikinci kutudaki nesneler soluk (ghost) gelir: ilk kutudan alınan nesneler bunların
# yerine uçar ve nesne canlanır (solidify).

const CARD_TEXTURE: Texture2D = preload("res://oyunlar/cikarma/gorseller/kart.svg")
const FONT: FontVariation = preload("res://oyunlar/cikarma/rakam_yazisi.tres")
const PATCH_MARGIN := 120       # kutu SVG'sinin köşe payı (2x içe aktarılmış dokuda piksel)
const PADDING := 28.0           # kutu kenarından nesne alanına
const CARD_SIZE := 124.0
const OBJECT_RATIO := 0.92      # nesne görselinin boyu / hücre boyu (SVG'lerin kendi kenar boşluğu var)
const COUNTER_RADIUS := 40.0
const COUNTER_COLOR := Color("ffb23f")
const OUTLINE := Color("4a3b6b")
const GHOST_ALPHA := 0.35       # soluk nesnelerin saydamlığı

## Kutunun görseli (kutu_a / kutu_b / kutu_sonuc).
@export var box_texture: Texture2D
## Karttaki rakamın rengi.
@export var number_color: Color = OUTLINE
## Sağ altta sayaç balonu gösterilsin mi (sonuç kutusu).
@export var has_counter: bool = false

var box_size := Vector2(320, 280)
var cell: float = 60.0
var objects: Array[Sprite2D] = []

var _bg: NinePatchRect
var _objects_layer: Node2D
var _card: Node2D
var _label: Label
var _counter: Node2D
var _counter_label: Label


func _ready() -> void:
	_bg = NinePatchRect.new()
	_bg.texture = box_texture
	_bg.patch_margin_left = PATCH_MARGIN
	_bg.patch_margin_top = PATCH_MARGIN
	_bg.patch_margin_right = PATCH_MARGIN
	_bg.patch_margin_bottom = PATCH_MARGIN
	_bg.scale = Vector2(0.5, 0.5)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_objects_layer = Node2D.new()
	add_child(_objects_layer)

	_card = Node2D.new()
	add_child(_card)
	var card_sprite := Sprite2D.new()
	card_sprite.texture = CARD_TEXTURE
	card_sprite.scale = Vector2.ONE * CARD_SIZE / CARD_TEXTURE.get_width()
	_card.add_child(card_sprite)
	_label = _make_label(104, number_color, 0)
	_label.position = Vector2(-CARD_SIZE / 2.0, -CARD_SIZE / 2.0 - 6.0)
	_label.size = Vector2(CARD_SIZE, CARD_SIZE)
	_card.add_child(_label)

	if has_counter:
		_counter = Node2D.new()
		_counter.draw.connect(_draw_counter)
		_counter.visible = false
		add_child(_counter)
		_counter_label = _make_label(52, Color.WHITE, 12)
		_counter_label.position = Vector2(-COUNTER_RADIUS, -COUNTER_RADIUS - 3.0)
		_counter_label.size = Vector2(COUNTER_RADIUS, COUNTER_RADIUS) * 2.0
		_counter.add_child(_counter_label)
	set_box_size(box_size)


func _make_label(font_size: int, color: Color, outline: int) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_outline_color", OUTLINE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func set_box_size(new_size: Vector2) -> void:
	box_size = new_size
	_bg.size = box_size * 2.0
	_bg.position = -box_size / 2.0
	# Kart kutunun üstünde, alt kenarı kutunun çerçevesine biraz biner
	_card.position = Vector2(0.0, -box_size.y / 2.0 - CARD_SIZE / 2.0 + 14.0)
	if _counter:
		# Sağ alt köşede, kutunun sınırından taşmadan (ekran kenarına yaklaşmasın)
		_counter.position = box_size / 2.0 - Vector2(COUNTER_RADIUS - 4.0, 30.0)


# --- Dizilim (saf hesap: testler/uretici_testi.gd de sınar) ---

# Izgara boyutu (sütun, satır)
static func grid(count: int) -> Vector2i:
	if count <= 5:
		return Vector2i(3, 3)
	return Vector2i(5, ceili(count / 5.0))


# Hücre biriminde, merkeze göre konumlar. Sıra satır satır, soldan sağa (sayılırken düzenli dolsun).
static func layout(count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	match count:
		0:
			pass
		1:
			result = [Vector2(0, 0)]
		2:
			result = [Vector2(-1, -1), Vector2(1, 1)]
		3:
			result = [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)]
		4:
			result = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
		5:
			result = [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)]
		_:
			var rows := ceili(count / 5.0)
			for k in count:
				result.append(Vector2(k % 5 - 2.0, floori(k / 5.0) - (rows - 1) / 2.0))
	return result


# count nesnenin bu kutuya sığacağı en büyük hücre boyu
func fit_cell(count: int) -> float:
	var g := grid(count)
	var inner := box_size - Vector2(PADDING, PADDING) * 2.0
	return minf(inner.x / g.x, inner.y / g.y)


# --- Nesneler ---

# Eski nesneleri siler, count tane yenisini sırayla belirterek dizer. Bitiş süresini döndürür.
# ghost: nesneler soluk olur (çıkan sayı; alınan nesneler bunların yerine gelir).
func fill(count: int, texture: Texture2D, cell_size: float, delay: float, step: float, ghost: bool = false) -> float:
	clear(false)
	cell = cell_size
	var positions := layout(count)
	for k in count:
		var sprite := _make_object(texture)
		sprite.position = positions[k] * cell
		sprite.set_meta("home", sprite.position)
		sprite.set_meta("busy", true)
		var full := sprite.scale
		sprite.scale = Vector2.ZERO
		if ghost:
			sprite.modulate.a = GHOST_ALPHA
		_objects_layer.add_child(sprite)
		objects.append(sprite)
		var tween := sprite.create_tween()
		tween.tween_interval(delay + k * step)
		tween.tween_property(sprite, "scale", full, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_callback(sprite.set_meta.bind("busy", false))
	return delay + count * step + 0.35


func _make_object(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * object_scale(texture)
	return sprite


func object_scale(texture: Texture2D) -> float:
	return cell * OBJECT_RATIO / maxf(texture.get_width(), texture.get_height())


# Sonuç kutusunda k. nesnenin varacağı yer (genel koordinat)
func slot_global(k: int, count: int) -> Vector2:
	return _objects_layer.to_global(layout(count)[k] * cell)


# Uçarak gelen nesneyi kutuya alır
func adopt(sprite: Sprite2D, count: int) -> void:
	sprite.reparent(_objects_layer, true)
	sprite.position = layout(count)[objects.size()] * cell
	sprite.rotation = 0.0
	sprite.set_meta("home", sprite.position)
	sprite.set_meta("busy", false)
	objects.append(sprite)
	var full := Vector2.ONE * object_scale(sprite.texture)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", full * 1.25, 0.08)
	tween.tween_property(sprite, "scale", full, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Nesneler uçmak için kutudan alındı (kutu artık onları tutmuyor)
func release_objects() -> Array[Sprite2D]:
	var result := objects.duplicate()
	objects.clear()
	return result


# Sondaki count nesne uçmak için kutudan alınır (çıkarılan nesneler)
func release_last(count: int) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = objects.slice(objects.size() - count)
	objects.resize(objects.size() - count)
	return result


# k. soluk nesne canlanır (alınan nesne onun yerine vardı)
func solidify(k: int) -> void:
	var sprite := objects[k]
	sprite.modulate.a = 1.0
	var full := Vector2.ONE * object_scale(sprite.texture)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", full * 1.25, 0.08)
	tween.tween_property(sprite, "scale", full, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Dokunulan nesne varsa zıplatır; nesneye dokunulduysa true
func hop_at(global_point: Vector2) -> bool:
	var point := _objects_layer.to_local(global_point)
	for sprite in objects:
		if point.distance_to(sprite.get_meta("home")) <= maxf(cell * 0.6, 40.0):
			hop(sprite, 0.0)
			return true
	return false


func hop(sprite: Sprite2D, delay: float, times: int = 1) -> void:
	if sprite.get_meta("busy", false):
		return
	sprite.set_meta("busy", true)
	var home: Vector2 = sprite.get_meta("home")
	var tween := sprite.create_tween()
	tween.tween_interval(delay)
	for i in times:
		tween.tween_property(sprite, "position", home - Vector2(0.0, cell * 0.35), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "position", home, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(sprite.set_meta.bind("busy", false))


# Kutlamada nesneler dalga gibi zıplar
func celebrate() -> void:
	for k in objects.size():
		hop(objects[k], k * 0.05, 2)


func clear(animated: bool) -> void:
	for sprite in objects:
		if not animated:
			sprite.queue_free()
			continue
		var tween := sprite.create_tween()
		tween.tween_property(sprite, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(sprite.queue_free)
	objects.clear()


# --- Kart ve sayaç ---

func set_number(text: String, color: Color = number_color, pop: bool = true) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	# İki basamaklı sayılar karta sığsın
	_label.add_theme_font_size_override("font_size", 104 if text.length() < 2 else 80)
	if pop:
		_pop(_card, 1.2)


func card_global() -> Vector2:
	return _card.global_position


func card_global_size() -> float:
	return CARD_SIZE * global_scale.x


func set_counter(value: int) -> void:
	if _counter == null:
		return
	_counter.visible = value > 0
	_counter_label.text = str(value)
	_pop(_counter, 1.3)


func _draw_counter() -> void:
	_counter.draw_circle(Vector2(0, 4), COUNTER_RADIUS, Color(OUTLINE, 0.2))
	_counter.draw_circle(Vector2.ZERO, COUNTER_RADIUS, COUNTER_COLOR)
	_counter.draw_arc(Vector2.ZERO, COUNTER_RADIUS, 0.0, TAU, 48, OUTLINE, 6.0, true)


func celebrate_card() -> void:
	_pop(_card, 1.3)
	if _counter and _counter.visible:
		_pop(_counter, 1.4)


func _pop(node: Node2D, amount: float) -> void:
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * amount, 0.09)
	tween.tween_property(node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
