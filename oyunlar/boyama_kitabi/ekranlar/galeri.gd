class_name ColoringGallery
extends Control
# Galeri: kaydedilen eserlerin küçük resimleri, en yeni en başta, kaydırılabilir ızgara.
# Esere dokununca boyama ekranında kaldığı yerden açılır. Silme kazara olmasın diye iki adım:
# esere uzun basınca köşesinde çöp kutusu belirir; ona dokununca büyük bir onay (✓ / ✗) çıkar.
# Galeri boşsa şövale ve gülen boya kalemi görseli ile yeni resim düğmesi görünür.

const BackButton := preload("res://ortak/basili_geri_dugmesi.gd")
const PageList := preload("res://oyunlar/boyama_kitabi/sayfalar/sayfa_listesi.gd")
const G := "res://oyunlar/boyama_kitabi/gorseller/"
const BG := Color("eef7ff")
const OUT := Color("3b2f6b")
const COLUMNS := 4
const TOP := 118.0
const GAP := 26.0
const LONG_PRESS := 0.6

var game: Node
var back: Control
var new_button: ColoringIconButton
var trash: ColoringIconButton
var _grid: Control
var _cards: Array[Control] = []
var _empty: TextureRect
var _scroller := ColoringScroller.new()
var _owners := {}
var _pressed_card: Control
var _press_time: float = 0.0
var _trash_card: Control              # çöp kutusu gösterilen eser
var _confirm: Control                 # onay katmanı
var _yes: ColoringIconButton
var _no: ColoringIconButton


func setup(owner_game: Node) -> void:
	game = owner_game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	back = BackButton.new()
	back.size = Vector2(96, 96)
	back.completed.connect(func() -> void: game.show_home())
	add_child(back)
	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.clip_contents = true
	add_child(_grid)
	trash = _button("cop", 84)
	trash.accent = Color("ff5b6e")
	trash.visible = false
	_grid.add_child(trash)
	_empty = TextureRect.new()
	_empty.texture = load(G + "bos_galeri.svg")
	_empty.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_empty.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_empty)
	new_button = _button("yeni_resim", 150)
	new_button.accent = Color("ff7a9a")
	add_child(new_button)
	_reload()
	resized.connect(_layout)
	_layout()


func _button(icon: String, side: float) -> ColoringIconButton:
	var button := ColoringIconButton.new()
	button.icon = load(G + icon + ".svg")
	button.size = Vector2(side, side)
	button.icon_scale = 0.72
	return button


func _reload() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	var known := {}
	for page in PageList.PAGES:
		known[page["id"]] = true
	for art in ColoringArtworks.list():
		if known.has(art["page"]):
			_cards.append(_make_card(art))
	_empty.visible = _cards.is_empty()
	new_button.visible = _cards.is_empty()
	_hide_trash()


func _make_card(art: Dictionary) -> Control:
	var card := Control.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_meta("art", art)
	var texture := ColoringArtworks.thumbnail(art["id"])
	card.draw.connect(func() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("ffd27a")
		box.set_corner_radius_all(18)
		box.border_color = OUT
		box.set_border_width_all(4)
		box.shadow_color = Color(0.23, 0.18, 0.42, 0.18)
		box.shadow_size = 8
		box.shadow_offset = Vector2(0, 5)
		card.draw_style_box(box, Rect2(Vector2.ZERO, card.size))
		var inner := Rect2(Vector2(14, 14), card.size - Vector2(28, 28))
		card.draw_rect(inner, Color.WHITE)
		if texture:
			card.draw_texture_rect(texture, inner, false)
		card.draw_rect(inner, OUT, false, 3.0))
	card.resized.connect(func() -> void: card.pivot_offset = card.size * 0.5)
	_grid.add_child(card)
	_grid.move_child(trash, -1)
	return card


func _layout() -> void:
	back.position = Vector2(40, 14)
	_grid.position = Vector2(40, TOP)
	_grid.size = Vector2(size.x - 80, size.y - TOP)
	var width := (_grid.size.x - GAP * (COLUMNS - 1)) / COLUMNS
	var card_size := Vector2(width, (width - 28.0) * 0.75 + 28.0)
	var rows := ceili(_cards.size() / float(COLUMNS))
	_scroller.max_offset = maxf(0.0, rows * (card_size.y + GAP) + 30.0 - _grid.size.y)
	_scroller.offset = minf(_scroller.offset, _scroller.max_offset)
	for i in _cards.size():
		_cards[i].size = card_size
		_cards[i].position = Vector2((i % COLUMNS) * (width + GAP), 18.0 + (i / COLUMNS) * (card_size.y + GAP) - _scroller.offset)
	if _trash_card:
		trash.position = _trash_card.position + Vector2(_trash_card.size.x - trash.size.x * 0.7, -trash.size.y * 0.3)
		trash.pivot_offset = trash.size * 0.5
	var empty_size := Vector2(480, 360)
	_empty.size = empty_size
	_empty.position = Vector2((size.x - empty_size.x) * 0.5 - 90.0, (size.y - empty_size.y) * 0.5 + 20.0)
	new_button.position = Vector2(_empty.position.x + empty_size.x + 30.0, size.y * 0.5 - new_button.size.y * 0.5 + 40.0)
	new_button.pivot_offset = new_button.size * 0.5
	if _confirm:
		_confirm.size = size
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)


func _process(delta: float) -> void:
	if _scroller.step(delta):
		_layout()
	if _pressed_card and not _scroller.scrolling:
		_press_time += delta
		if _press_time >= LONG_PRESS:
			_show_trash(_pressed_card)
			_release_card()


# --- Dokunma ---

func handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_down(event.index, event.position)
		else:
			_up(event.index, event.position)
	elif event is InputEventScreenDrag and _owners.get(event.index) is String:
		if _scroller.drag(event.position):
			_release_card()
			_layout()


func _buttons() -> Array[Control]:
	var result: Array[Control] = []
	if _confirm:
		result.append_array([_yes, _no])
		return result
	result.append(back)
	if trash.visible:
		result.append(trash)
	if new_button.visible:
		result.append(new_button)
	return result


func _down(index: int, pos: Vector2) -> void:
	for button in _buttons():
		if button.get_global_rect().grow(6.0).has_point(pos):
			_owners[index] = button
			button.press()
			return
	if _confirm:
		return
	if _grid.get_global_rect().has_point(pos) and not _owners.values().has("grid"):
		_owners[index] = "grid"
		_scroller.press(pos)
		if _trash_card:
			_hide_trash()
			return
		for card in _cards:
			if card.get_global_rect().has_point(pos):
				_pressed_card = card
				_press_time = 0.0
				var tween := card.create_tween()
				tween.tween_property(card, "scale", Vector2.ONE * 0.95, 0.08)


func _up(index: int, pos: Vector2) -> void:
	if not _owners.has(index):
		return
	var owner: Variant = _owners[index]
	_owners.erase(index)
	if owner is String:
		var was_scrolling := _scroller.scrolling
		_scroller.release()
		var card := _pressed_card
		_release_card()
		if not was_scrolling and card and card.get_global_rect().has_point(pos):
			var art: Dictionary = card.get_meta("art")
			game.sounds.play("sayfa")
			game.open_coloring(art["page"], art["id"], "gallery")
		return
	var button: Control = owner
	button.release()
	if button == back or not button.get_global_rect().grow(6.0).has_point(pos):
		return
	if button == new_button:
		game.sounds.play("tik")
		game.show_picker()
	elif button == trash:
		game.sounds.play("tik")
		_open_confirm()
	elif button == _yes:
		_delete_confirmed()
	elif button == _no:
		game.sounds.play("tik")
		_close_confirm()


func _release_card() -> void:
	if _pressed_card:
		var tween := _pressed_card.create_tween()
		tween.tween_property(_pressed_card, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pressed_card = null


# --- Silme: uzun bas → çöp kutusu → onay ---

func _show_trash(card: Control) -> void:
	_trash_card = card
	trash.visible = true
	_layout()
	trash.scale = Vector2.ONE * 0.2
	var tween := trash.create_tween()
	tween.tween_property(trash, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	game.sounds.play("tik")


func _hide_trash() -> void:
	_trash_card = null
	trash.visible = false


func _open_confirm() -> void:
	if _trash_card == null:
		return
	var art: Dictionary = _trash_card.get_meta("art")
	_confirm = Control.new()
	_confirm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm.size = size
	var picture := ColoringArtworks.thumbnail(art["id"])
	_confirm.draw.connect(func() -> void:
		_confirm.draw_rect(Rect2(Vector2.ZERO, _confirm.size), Color(0.18, 0.13, 0.3, 0.55))
		var frame := Rect2(_confirm.size * 0.5 - Vector2(230, 230), Vector2(460, 360))
		var box := StyleBoxFlat.new()
		box.bg_color = Color("ffd27a")
		box.set_corner_radius_all(24)
		box.border_color = OUT
		box.set_border_width_all(5)
		_confirm.draw_style_box(box, frame)
		var inner := frame.grow(-18)
		_confirm.draw_rect(inner, Color.WHITE)
		if picture:
			_confirm.draw_texture_rect(picture, inner, false))
	add_child(_confirm)
	_yes = _button("onay", 130)
	_no = _button("iptal", 130)
	_yes.icon_scale = 0.9
	_no.icon_scale = 0.9
	for button in [_no, _yes]:
		_confirm.add_child(button)
		button.pivot_offset = button.size * 0.5
	_yes.position = size * 0.5 + Vector2(40, 150)
	_no.position = size * 0.5 + Vector2(-170, 150)
	_confirm.modulate.a = 0.0
	var tween := _confirm.create_tween()
	tween.tween_property(_confirm, "modulate:a", 1.0, 0.15)


func _close_confirm() -> void:
	if _confirm:
		_confirm.queue_free()
	_confirm = null
	_hide_trash()


func _delete_confirmed() -> void:
	var card := _trash_card
	var art: Dictionary = card.get_meta("art")
	ColoringArtworks.delete_art(art["id"])
	game.sounds.play("sil")
	_close_confirm()
	var tween := card.create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ONE * 0.1, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "modulate:a", 0.0, 0.25)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		_reload()
		_layout())
