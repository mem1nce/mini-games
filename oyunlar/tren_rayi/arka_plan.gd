extends Node2D
# Izgaranın dışındaki tema zemini: renk geçişi, yumuşak lekeler ve serpiştirilmiş süsler (temanın ağaç ve kaya
# türleri, çiçek/çakıl/kar tanesi/deniz kabuğu/ışık noktaları). Süsler ızgaranın, istasyonun, trenin ve
# düğmelerin üstüne gelmez (yasak alanlar).

const G := "res://oyunlar/tren_rayi/gorseller/"
const RENKLER := {
	# üst, alt, leke
	"ciftlik": [Color("c4ec9f"), Color("9fd87a"), Color("b3e48c")],
	"orman": [Color("a8c67a"), Color("7fa25a"), Color("94b56a")],
	"kar": [Color("f4f9ff"), Color("d6e6f7"), Color("ffffff")],
	"sahil": [Color("fff1c9"), Color("f4d99c"), Color("bfeaf2")],
	"gece": [Color("3a3d5e"), Color("24263e"), Color("4a4d74")],
}
const NOKTA_RENKLERI := {
	"ciftlik": [Color("ffffff"), Color("ffe066"), Color("ff9cc2")],
	"orman": [Color("e8d37a"), Color("c96a4a"), Color("f2f2e0")],
	"kar": [Color("ffffff"), Color("cfe6ff")],
	"sahil": [Color("ffffff"), Color("f7b7a3"), Color("e8c27a")],
	"gece": [Color("ffe27a"), Color("7fd4ff"), Color("ff9cc2")],
}

var tema := "ciftlik"
var _ekran := Vector2(1280, 720)
var _noktalar: Array = []        # [konum, yarıçap, renk]
var _lekeler: Array = []


func kur(p_tema: String, ekran: Vector2, yasak: Array) -> void:
	tema = p_tema
	_ekran = ekran
	for c in get_children():
		c.queue_free()
	_noktalar.clear()
	_lekeler.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(tema + str(yasak.size()))
	for i in 7:
		_lekeler.append([Vector2(rng.randf_range(0, ekran.x), rng.randf_range(0, ekran.y)), rng.randf_range(90, 200)])
	# Süs sprite'ları: temanın ağaç ve kaya türleri, küçük boyda
	var konulan: Array = []
	for deneme in 400:
		if konulan.size() >= 9:
			break
		var boy := rng.randf_range(54.0, 84.0)
		var p := Vector2(rng.randf_range(20, ekran.x - 20), rng.randf_range(20, ekran.y - 20))
		var kutu := Rect2(p - Vector2(boy, boy) * 0.5, Vector2(boy, boy))
		if _cakisiyor(kutu.grow(6), yasak) or konulan.any(func(r: Rect2) -> bool: return r.grow(10).intersects(kutu)):
			continue
		konulan.append(kutu)
		var sprite := Sprite2D.new()
		sprite.texture = load(G + "engel_%s_%s.svg" % [tema, "A" if rng.randf() < 0.65 else "K"])
		sprite.scale = Vector2.ONE * boy / sprite.texture.get_width()
		sprite.position = p
		if tema != "gece":
			sprite.rotation = rng.randf_range(-0.4, 0.4)
		add_child(sprite)
	for i in 70:
		var p := Vector2(rng.randf_range(0, ekran.x), rng.randf_range(0, ekran.y))
		if _cakisiyor(Rect2(p - Vector2(6, 6), Vector2(12, 12)), yasak):
			continue
		var r: Array = NOKTA_RENKLERI[tema]
		_noktalar.append([p, rng.randf_range(2.0, 4.2), r[rng.randi() % r.size()]])
	queue_redraw()


func _cakisiyor(kutu: Rect2, yasak: Array) -> bool:
	for r in yasak:
		if r.intersects(kutu):
			return true
	return false


func _draw() -> void:
	var renkler: Array = RENKLER[tema]
	var bant := 24
	for i in bant:
		var t := float(i) / (bant - 1)
		draw_rect(Rect2(0, _ekran.y * i / bant, _ekran.x, _ekran.y / bant + 1.0), renkler[0].lerp(renkler[1], t))
	for leke in _lekeler:
		draw_circle(leke[0], leke[1], Color(renkler[2], 0.35))
	for nokta in _noktalar:
		var renk: Color = nokta[2]
		if tema == "gece":
			draw_circle(nokta[0], nokta[1] * 2.6, Color(renk, 0.18))
		draw_circle(nokta[0], nokta[1], renk)
