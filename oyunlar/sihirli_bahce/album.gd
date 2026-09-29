extends Control
# Bitki albümü ve ilk keşif kutlaması.
# Albüm: kitap sayfasında 12 kart; keşfedilen bitki renkli (sağ altta kaç kez toplandığı, nadirse köşede
# yıldızlar), keşfedilmeyen gri siluet. Karta dokununca kart zıplar. Tamam düğmesi ya da kitabın dışı kapatır.
# Kutlama: yeni bitki parselden büyüyerek ekranın ortasına gelir, arkasında dönen ışınlar, yıldız ve
# parıltılar; sonra küçülerek albüm simgesine uçar (celebration_finished).

signal closed
signal celebration_finished

const Bitkiler := preload("res://oyunlar/sihirli_bahce/bitkiler.gd")
const Efektler := preload("res://oyunlar/sihirli_bahce/efektler.gd")
const G := "res://oyunlar/sihirli_bahce/gorseller/"
const INK := Color("5a3e8e")
const COLS := 4
const CARD := Vector2(148, 158)
const GAP := 16.0
const SILHOUETTE := "shader_type canvas_item;\nuniform vec4 tint : source_color = vec4(0.55, 0.52, 0.66, 0.5);\nvoid fragment() {\n\tCOLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a);\n}\n"


# Albüm kartı
class Card extends Control:
	var texture: Texture2D
	var found := false
	var rare := false
	var count := 0
	var silhouette: Material
	var star: Texture2D

	func _draw() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("fffdf6") if found else Color("efeaf6")
		style.set_corner_radius_all(22)
		style.set_border_width_all(5)
		style.border_color = Color("f2b632") if found and rare else Color("5a3e8e", 0.45)
		style.shadow_color = Color(0.2, 0.1, 0.35, 0.18)
		style.shadow_size = 5
		style.shadow_offset = Vector2(0, 4)
		draw_style_box(style, Rect2(Vector2.ZERO, size))
		if found and rare:
			for k in 2:
				draw_texture_rect(star, Rect2(Vector2(10 + k * 22, 8), Vector2(24, 24)), false)


var sounds: Node
var _dim: ColorRect
var _book: Control
var _cards: Array[Card] = []
var _ok: Control
var _party: Control
var _rays: Node2D
var _hero: Sprite2D
var _fx: Node2D
var _silhouette := ShaderMaterial.new()
var _open := false
var _celebrating := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = SILHOUETTE
	_silhouette.shader = shader
	_dim = ColorRect.new()
	_dim.color = Color(0.12, 0.08, 0.25, 0.5)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	_book = Control.new()
	_book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_book.draw.connect(_draw_book)
	add_child(_book)
	var star: Texture2D = load(G + "yildiz.svg")
	for id in Bitkiler.ALBUM_ORDER:
		var card := Card.new()
		card.texture = Bitkiler.texture(id, 4)
		card.rare = Bitkiler.PLANTS[id]["rarity"] == Bitkiler.RARE
		card.star = star
		card.size = CARD
		card.pivot_offset = CARD / 2.0
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pic := TextureRect.new()
		pic.name = "Resim"
		pic.texture = card.texture
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.position = Vector2(10, 8)
		pic.size = CARD - Vector2(20, 18)
		card.add_child(pic)
		var badge := Label.new()
		badge.name = "Sayi"
		var settings := LabelSettings.new()
		settings.font_size = 26
		settings.font_color = Color.WHITE
		settings.outline_size = 8
		settings.outline_color = INK
		badge.label_settings = settings
		badge.theme_type_variation = &"Baslik"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.position = Vector2(CARD.x - 70, CARD.y - 40)
		badge.size = Vector2(60, 34)
		card.add_child(badge)
		_book.add_child(card)
		_cards.append(card)
	_ok = _round_button(load(G + "tamam.svg"), 104.0)
	_book.add_child(_ok)
	_party = Control.new()
	_party.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var party_dim := ColorRect.new()
	party_dim.color = Color(0.12, 0.08, 0.25, 0.45)
	party_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	party_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_party.add_child(party_dim)
	_rays = Node2D.new()
	_rays.draw.connect(_draw_rays)
	_party.add_child(_rays)
	_hero = Sprite2D.new()
	_party.add_child(_hero)
	add_child(_party)
	_fx = Efektler.new()
	add_child(_fx)
	visible = false
	_party.visible = false


func _round_button(icon: Texture2D, diameter: float) -> Control:
	var button := Control.new()
	button.size = Vector2(diameter, diameter)
	button.pivot_offset = button.size / 2.0
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.draw.connect(func() -> void:
		var c := button.size / 2.0
		var r := diameter / 2.0 - 4.0
		button.draw_circle(c + Vector2(0, 5), r, Color(0.2, 0.1, 0.3, 0.2))
		button.draw_circle(c, r, Color.WHITE)
		button.draw_arc(c, r, 0.0, TAU, 48, INK, 5.0, true)
		button.draw_texture_rect(icon, Rect2(c - Vector2(r, r) * 0.62, Vector2(r, r) * 1.24), false))
	return button


func is_busy() -> bool:
	return _open or _celebrating


# --- Albüm ---

func open_album(album: Dictionary) -> void:
	_open = true
	visible = true
	_dim.visible = true
	_book.visible = true
	_party.visible = false
	var w := size.x
	var h := size.y
	var grid := Vector2(COLS * CARD.x + (COLS - 1) * GAP, 3 * CARD.y + 2 * GAP)
	var book_size := grid + Vector2(96, 110)
	_book.size = book_size
	_book.position = Vector2((w - book_size.x) * 0.5, (h - book_size.y) * 0.5 + 6.0)
	_book.pivot_offset = book_size / 2.0
	for i in _cards.size():
		var card := _cards[i]
		var id: String = Bitkiler.ALBUM_ORDER[i]
		card.count = int(album.get(id, 0))
		card.found = card.count > 0
		var pic: TextureRect = card.get_node("Resim")
		pic.material = null if card.found else _silhouette
		var badge: Label = card.get_node("Sayi")
		badge.text = "×%d" % card.count if card.count > 1 else ""
		var col := i % COLS
		var row := i / COLS
		card.position = Vector2(48 + col * (CARD.x + GAP), 70 + row * (CARD.y + GAP))
		card.queue_redraw()
	_ok.position = Vector2(book_size.x - 70, -34)
	_book.queue_redraw()
	_book.scale = Vector2(0.7, 0.7)
	_book.modulate.a = 0.0
	_dim.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_book, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_book, "modulate:a", 1.0, 0.2)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.25)


func close_album() -> void:
	if not _open:
		return
	_open = false
	var tween := create_tween().set_parallel()
	tween.tween_property(_book, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_book, "modulate:a", 0.0, 0.2)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(func() -> void:
		if not _open and not _celebrating:
			visible = false
		closed.emit())


func _draw_book() -> void:
	var s := _book.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("8f68d6")
	style.set_corner_radius_all(36)
	style.shadow_color = Color(0.1, 0.05, 0.2, 0.35)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 10)
	_book.draw_style_box(style, Rect2(Vector2(-14, -10), s + Vector2(28, 24)))
	var page := StyleBoxFlat.new()
	page.bg_color = Color("fff8ec")
	page.set_corner_radius_all(26)
	page.set_border_width_all(4)
	page.border_color = Color("d8c8ec")
	_book.draw_style_box(page, Rect2(Vector2(10, 12), s - Vector2(20, 20)))
	_book.draw_line(Vector2(s.x * 0.5, 30), Vector2(s.x * 0.5, s.y - 26), Color("d8c8ec"), 5.0, true)
	# Üstte küçük çiçek süsü
	var tex: Texture2D = load(G + "kitap.svg")
	_book.draw_texture_rect(tex, Rect2(Vector2(s.x * 0.5 - 30, 8), Vector2(60, 60)), false)


# Dokunma albüme gittiyse true
func touch(point: Vector2) -> bool:
	if _celebrating:
		return true
	if not _open:
		return false
	if _ok.get_global_rect().grow(10.0).has_point(point) or not _book.get_global_rect().grow(20.0).has_point(point):
		_pop(_ok)
		_sound("tik")
		close_album()
		return true
	for card in _cards:
		if card.get_global_rect().has_point(point):
			_pop(card)
			if card.found:
				_fx.sparkles(card.get_global_rect().get_center(), Color("fff6b0"), 10, 40.0)
				_sound("pirilti")
			else:
				_sound("kipir")
			return true
	return true


func _pop(control: Control) -> void:
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(0.9, 0.9), 0.07)
	tween.tween_property(control, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# --- İlk keşif kutlaması ---

func celebrate(id: String, from: Vector2, to: Vector2) -> void:
	_celebrating = true
	visible = true
	_dim.visible = false
	_book.visible = false
	_party.visible = true
	_party.modulate.a = 0.0
	var center := size * 0.5 + Vector2(0, 30)
	_rays.position = center
	_rays.scale = Vector2.ZERO
	var tex := Bitkiler.texture(id, 4)
	_hero.texture = tex
	# Çizimin dolu kısmı ortaya gelsin (kısa bitkilerde tuvalin üstü boş)
	var used := Bitkiler.content_rect(id, 4)
	var px := tex.get_width() / 240.0
	_hero.offset = (Vector2(120, 150) - used.get_center()) * px
	var big := minf(360.0 / used.size.y, 460.0 / used.size.x) / px
	var small := 150.0 / used.size.y / px
	_hero.position = from
	_hero.scale = Vector2.ONE * small
	_hero.modulate.a = 1.0
	_sound("kesif")
	var tween := create_tween()
	tween.tween_property(_party, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(_hero, "position", center, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_hero, "scale", Vector2.ONE * big, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_rays, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_fx.stars(center + Vector2(0, -60), 14)
		_fx.sparkles(center, Bitkiler.PLANTS[id]["color"], 24, 150.0))
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void: _fx.sparkles(center + Vector2(0, -120), Color.WHITE, 14, 120.0))
	tween.tween_interval(1.1)
	tween.tween_property(_hero, "position", to, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_hero, "scale", Vector2.ONE * small * 0.4, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_rays, "scale", Vector2.ZERO, 0.4)
	tween.parallel().tween_property(_party, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.tween_callback(func() -> void:
		_celebrating = false
		_party.visible = false
		if not _open:
			visible = false
		celebration_finished.emit())


func _draw_rays() -> void:
	for k in 12:
		var a := TAU * k / 12.0
		var p1 := Vector2(cos(a - 0.12), sin(a - 0.12)) * 420.0
		var p2 := Vector2(cos(a + 0.12), sin(a + 0.12)) * 420.0
		_rays.draw_polygon(PackedVector2Array([Vector2.ZERO, p1, p2]),
				PackedColorArray([Color(1, 0.95, 0.65, 0.3), Color(1, 0.9, 0.5, 0.0), Color(1, 0.9, 0.5, 0.0)]))
	_rays.draw_circle(Vector2.ZERO, 150.0, Color(1, 0.97, 0.8, 0.12))


func _process(delta: float) -> void:
	if _party.visible:
		_rays.rotation += delta * 0.4


func _sound(sound: String) -> void:
	if sounds:
		sounds.play(sound)
