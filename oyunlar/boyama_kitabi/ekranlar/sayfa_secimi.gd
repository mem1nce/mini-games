class_name ColoringPagePicker
extends Control
# Sayfa seçimi: üstte büyük kategori simgeleri (Hayvanlar, Araçlar, Oyuncaklar, Doğa, Şekiller), altında
# kaydırılabilir küçük resim ızgarası. Sayfalar sayfalar/sayfa_listesi.gd'den gelir (basit olanlar önce).
# Bir sayfaya dokununca o sayfadan yeni bir eser açılır. Geri düğmesi giriş ekranına döner.

const Settings := preload("res://oyunlar/boyama_kitabi/ayarlar.gd")
const PageList := preload("res://oyunlar/boyama_kitabi/sayfalar/sayfa_listesi.gd")
const BackButton := preload("res://ortak/basili_geri_dugmesi.gd")
const G := "res://oyunlar/boyama_kitabi/gorseller/"
const PNG := "res://oyunlar/boyama_kitabi/sayfalar/png/"
const BG := Color("fff6ea")
const OUT := Color("3b2f6b")
const COLUMNS := 3
const TOP := 128.0
const GAP := 26.0
const GRID_TOP := 14.0
const GRID_BOTTOM := 20.0             # alt satırın gölgesine yer

var game: Node
var category: String = ""
var back: Control
var _tabs: Array[ColoringIconButton] = []
var _cards: Array[Control] = []
var _grid: Control
var _scroller := ColoringScroller.new()
var _owners := {}                     # index -> düğme ya da "grid"
var _pressed_card: Control


func setup(owner_game: Node, start_category: String) -> void:
	game = owner_game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	back = BackButton.new()
	back.size = Vector2(96, 96)
	back.completed.connect(func() -> void: game.show_home())
	add_child(back)
	for entry in Settings.CATEGORIES:
		var tab := ColoringIconButton.new()
		tab.icon = load(G + entry["icon"] + ".svg")
		tab.accent = entry["color"]
		tab.icon_scale = 0.74
		tab.size = Vector2(100, 100)
		tab.set_meta("id", entry["id"])
		add_child(tab)
		_tabs.append(tab)
	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.clip_contents = true
	add_child(_grid)
	resized.connect(_layout)
	select(start_category if start_category != "" else Settings.CATEGORIES[0]["id"])
	_layout()


func select(id: String) -> void:
	category = id
	for tab in _tabs:
		tab.selected = tab.get_meta("id") == id
	for card in _cards:
		card.queue_free()
	_cards.clear()
	for page in PageList.PAGES:
		if page["category"] == id:
			_cards.append(_make_card(page["id"]))
	_scroller.offset = 0.0
	_layout()


func _make_card(page: String) -> Control:
	var card := Control.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_meta("page", page)
	var texture: Texture2D = load(PNG + page + "_kucuk.png")
	card.draw.connect(func() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color.WHITE
		box.set_corner_radius_all(22)
		box.border_color = OUT
		box.set_border_width_all(4)
		box.shadow_color = Color(0.23, 0.18, 0.42, 0.18)
		box.shadow_size = 8
		box.shadow_offset = Vector2(0, 5)
		card.draw_style_box(box, Rect2(Vector2.ZERO, card.size))
		var inner := Rect2(Vector2(12, 12), card.size - Vector2(24, 24))
		card.draw_texture_rect(texture, inner, false))
	card.resized.connect(func() -> void: card.pivot_offset = card.size * 0.5)
	_grid.add_child(card)
	return card


func _layout() -> void:
	back.position = Vector2(40, 14)
	var tab_step := 124.0
	var tabs_width := tab_step * (_tabs.size() - 1) + 100.0
	var start := maxf(170.0, (size.x - tabs_width) * 0.5)
	for i in _tabs.size():
		_tabs[i].position = Vector2(start + i * tab_step, 12)
		_tabs[i].pivot_offset = _tabs[i].size * 0.5
	_grid.position = Vector2(40, TOP)
	_grid.size = Vector2(size.x - 80, size.y - TOP)
	# Kartlar iki satır ekrana tam sığacak kadar büyür (alttaki satır taşmasın), ızgara ortalanır
	var width := (_grid.size.x - GAP * (COLUMNS - 1)) / COLUMNS
	var fit_height := (_grid.size.y - GRID_TOP - GAP - GRID_BOTTOM) * 0.5
	width = minf(width, (fit_height - 24.0) / 0.75 + 24.0)
	var card_size := Vector2(width, (width - 24.0) * 0.75 + 24.0)
	var left := (_grid.size.x - (width * COLUMNS + GAP * (COLUMNS - 1))) * 0.5
	var rows := ceili(_cards.size() / float(COLUMNS))
	var content := GRID_TOP + rows * card_size.y + (rows - 1) * GAP + GRID_BOTTOM
	_scroller.max_offset = maxf(0.0, content - _grid.size.y)
	for i in _cards.size():
		_cards[i].size = card_size
		_cards[i].position = Vector2(left + (i % COLUMNS) * (width + GAP), GRID_TOP + (i / COLUMNS) * (card_size.y + GAP) - _scroller.offset)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)


func _process(delta: float) -> void:
	if _scroller.step(delta):
		_layout()


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


func _down(index: int, pos: Vector2) -> void:
	if back.get_global_rect().grow(6.0).has_point(pos):
		_owners[index] = back
		back.press()
		return
	for tab in _tabs:
		if tab.contains(pos):
			_owners[index] = tab
			tab.press()
			return
	if _grid.get_global_rect().has_point(pos) and not _owners.values().has("grid"):
		_owners[index] = "grid"
		_scroller.press(pos)
		for card in _cards:
			if card.get_global_rect().has_point(pos):
				_pressed_card = card
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
			game.sounds.play("sayfa")
			game.open_coloring(card.get_meta("page"), "", "picker")
		return
	var button: Control = owner
	button.release()
	if button == back or not button.get_global_rect().grow(6.0).has_point(pos):
		return
	if button in _tabs and button.get_meta("id") != category:
		game.sounds.play("tik")
		select(button.get_meta("id"))
		game.last_category = category


func _release_card() -> void:
	if _pressed_card:
		var tween := _pressed_card.create_tween()
		tween.tween_property(_pressed_card, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pressed_card = null
