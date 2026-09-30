extends Node2D
# Olta ipi ve ağ kepçe (kanca yok). Parmak suya basılıyken ağ o noktaya yumuşakça iner ve parmağı izler;
# parmak kalkınca yukarı, oltanın ucunun altına çıkar. İp kavislidir: ortası sarkar, ağ hareket edince
# geriden gelir. Ağa bir şey girince ağ kendiliğinden yukarı çıkar ve "teslim" sinyali gelir.
# Derin denizde ağın üstünde küçük bir fener yanar.

signal teslim(icerik: Node2D)
signal suya_girdi(x: float)

const G := "res://oyunlar/balik_tutma/gorseller/"
const AG_ENI := 110.0
const INME_HIZI := 900.0
const CIKMA_HIZI := 620.0
const BEKLEME_ALTI := 22.0       # oltanın ucundan ağın beklediği yere uzaklık (torba suyun üstünde kalır)

var uc := Vector2.ZERO           # oltanın ucu (her kare kayıktan gelir)
var yuzey_y := 400.0
var dip_y := 1160.0
var takip := false               # parmak suda mı
var hedef := Vector2.ZERO
var icerik: Node2D = null
var kilitli := false             # teslimde ve gıdıklanırken dokunma alınmaz

var _ag: Node2D
var _ag_sprite: Sprite2D
var _fener: Sprite2D
var _hiz := Vector2.ZERO
var _onceki := Vector2.ZERO
var _zaman := 0.0


func kur(p_yuzey: float, p_dip: float, fenerli: bool, efekt_isik: Sprite2D) -> void:
	yuzey_y = p_yuzey
	dip_y = p_dip
	_ag = Node2D.new()
	add_child(_ag)
	_ag_sprite = Sprite2D.new()
	_ag_sprite.texture = load(G + ("ag_fener.svg" if fenerli else "ag.svg"))
	var k := AG_ENI / 120.0
	_ag_sprite.scale = Vector2.ONE * AG_ENI / _ag_sprite.texture.get_width()
	_ag_sprite.centered = false
	_ag_sprite.offset = -Vector2(60, 6) * _ag_sprite.texture.get_width() / 120.0
	_ag.add_child(_ag_sprite)
	if fenerli and efekt_isik:
		_fener = efekt_isik
		_fener.position = Vector2(0, 16.0 * k)
		_ag.add_child(_fener)
		_ag.move_child(_fener, 0)


func ag_konumu() -> Vector2:
	return _ag.global_position


# Ağ torbasının ortası (çarpışma ve içerik yeri)
func torba() -> Vector2:
	return _ag.global_position + Vector2(0, 76.0 * AG_ENI / 120.0)


func torba_yaricapi() -> float:
	return 48.0


func suda_mi() -> bool:
	return torba().y > yuzey_y + 10.0


func bekleme_yeri() -> Vector2:
	return uc + Vector2(0, BEKLEME_ALTI)


func yerlestir(p_uc: Vector2) -> void:
	uc = p_uc
	_ag.position = bekleme_yeri()
	_onceki = _ag.position


func parmak(nokta: Vector2) -> void:
	if kilitli or icerik:
		return
	takip = true
	hedef = Vector2(nokta.x, clampf(nokta.y, yuzey_y + 40.0, dip_y - 70.0)) - Vector2(0, 76.0 * AG_ENI / 120.0)


func birak() -> void:
	takip = false


func yakala(nesne: Node2D) -> void:
	icerik = nesne
	takip = false
	var yer := nesne.global_position
	nesne.reparent(_ag)
	nesne.global_position = yer
	var tween := nesne.create_tween()
	tween.tween_property(nesne, "position", Vector2(0, 80.0 * AG_ENI / 120.0), 0.18).set_trans(Tween.TRANS_SINE)


func icerigi_al() -> Node2D:
	var n := icerik
	icerik = null
	return n


# Denizanası: ağ gıdıklanmış gibi titrer
func gidikla() -> void:
	kilitli = true
	var tween := _ag.create_tween()
	for i in 6:
		tween.tween_property(_ag, "rotation", 0.22 if i % 2 == 0 else -0.22, 0.06).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_ag, "rotation", 0.0, 0.08)
	tween.tween_callback(func() -> void: kilitli = false)


func _process(delta: float) -> void:
	_zaman += delta
	var hedef_yer := hedef if takip else bekleme_yeri()
	var hiz := INME_HIZI if takip else CIKMA_HIZI
	var fark := hedef_yer - _ag.position
	# Yumuşak takip: uzaktayken hızlı, yaklaşınca yavaşlar
	var adim := fark * (1.0 - exp(-delta * 7.0))
	if adim.length() > hiz * delta:
		adim = adim.normalized() * hiz * delta
	_ag.position += adim
	_hiz = _hiz.lerp((_ag.position - _onceki) / maxf(delta, 0.001), 0.2)
	var onceki_suda := _onceki.y + 76.0 * AG_ENI / 120.0 > yuzey_y
	_onceki = _ag.position
	if suda_mi() != onceki_suda:
		suya_girdi.emit(torba().x)
	if not kilitli:
		_ag.rotation = clampf(-_hiz.x * 0.0006, -0.3, 0.3)
	if icerik and not takip and _ag.position.distance_to(bekleme_yeri()) < 12.0:
		kilitli = true
		teslim.emit(icerik)
	if _fener:
		_fener.modulate.a = 0.75 + sin(_zaman * 3.0) * 0.1
	queue_redraw()


func _draw() -> void:
	# Kavisli ip: ortası sarkar, ağ hareket ettikçe geriden gelir (esnek görünüm)
	var bas := uc
	var son := _ag.position
	var orta := (bas + son) * 0.5
	var sarkma := 18.0 + 10.0 * sin(_zaman * 1.4) + clampf(40.0 - bas.distance_to(son) * 0.05, 0.0, 30.0)
	var kontrol := orta + Vector2(0, sarkma) - _hiz * 0.06
	var noktalar := PackedVector2Array()
	for i in 21:
		var t := i / 20.0
		noktalar.append(bas.lerp(kontrol, t).lerp(kontrol.lerp(son, t), t))
	draw_polyline(noktalar, Color(0.18, 0.16, 0.3, 0.9), 3.4, true)
	draw_polyline(noktalar, Color(1, 1, 1, 0.55), 1.2, true)
