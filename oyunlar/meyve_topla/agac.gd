extends Node2D
# Ağaç: gövde, büyük yapraklı taç ve meyvelerin düştüğü, ayrı ayrı sallanabilen dallar.
# Dallar taçtan önce çizilir; üst uçları tacın içinde kalır, yapraklı alt kısımları sarkar.

const TEX_TRUNK: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/agac_govde.svg")
const TEX_CROWN: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/agac_tac.svg")
const TEX_BRANCH: Texture2D = preload("res://oyunlar/meyve_topla/gorseller/dal.svg")

const BRANCH_X := [0.1, 0.265, 0.425, 0.585, 0.745, 0.905]      # ekran genişliğine oranla
const CROWN_EDGE := [463.0, 476.0, 473.0, 494.0, 483.0, 450.0]  # o noktada tacın alt kenarı (SVG'de)
const CROWN_TOP := -70.0
const BRANCH_SCALE := 0.9
const BRANCH_SVG_WIDTH := 180.0
const BRANCH_PIVOT := Vector2(90, 0)     # SVG'de dalın taca bağlandığı nokta
const BRANCH_TIP := Vector2(92, 128)     # SVG'de meyvenin asıldığı uç

var branches: Array[Node2D] = []
var _shake_left: Array[float] = []
var _shake_total: Array[float] = []
var _crown: Sprite2D
var _crown_scale := Vector2.ONE
var _time := 0.0


func build(screen: Vector2, ground_y: float) -> void:
	# Gövde: alt ucu zeminde, üst ucu tacın içinde
	var trunk := Sprite2D.new()
	trunk.texture = TEX_TRUNK
	var trunk_height := float(TEX_TRUNK.get_height())
	var scale_y := maxf(0.8, (ground_y + 10.0 - 120.0) / trunk_height)
	trunk.scale = Vector2(0.8, scale_y)
	trunk.position = Vector2(screen.x / 2.0, ground_y + 10.0 - trunk_height * scale_y / 2.0)
	add_child(trunk)

	var crown_scale := maxf(1.0, screen.x * 1.25 / TEX_CROWN.get_width())

	# Dallar
	var pixel_scale := BRANCH_SVG_WIDTH / TEX_BRANCH.get_width()   # doku pikseli -> SVG birimi
	for i in BRANCH_X.size():
		var branch := Node2D.new()
		branch.position = Vector2(screen.x * BRANCH_X[i], CROWN_TOP + (CROWN_EDGE[i] - 30.0) * crown_scale)
		var sprite := Sprite2D.new()
		sprite.texture = TEX_BRANCH
		sprite.centered = false
		sprite.offset = -BRANCH_PIVOT / pixel_scale
		sprite.scale = Vector2.ONE * BRANCH_SCALE * pixel_scale
		# Bazı dallar ayna görüntüsü olsun, hepsi aynı görünmesin
		if i % 2 == 1:
			sprite.scale.x *= -1.0
		branch.add_child(sprite)
		add_child(branch)
		branches.append(branch)
		_shake_left.append(0.0)
		_shake_total.append(1.0)

	# Taç en üstte
	_crown = Sprite2D.new()
	_crown.texture = TEX_CROWN
	_crown.scale = Vector2.ONE * crown_scale
	_crown_scale = _crown.scale
	_crown.position = Vector2(screen.x / 2.0, CROWN_TOP + TEX_CROWN.get_height() * crown_scale / 2.0)
	add_child(_crown)


# Meyvenin asıldığı noktanın dala göre konumu
func tip_offset(index: int) -> Vector2:
	var tip := (BRANCH_TIP - BRANCH_PIVOT) * BRANCH_SCALE
	if index % 2 == 1:
		tip.x = -tip.x
	return tip


func tip_position(index: int) -> Vector2:
	return branches[index].to_global(tip_offset(index))


# Meyve düşmeden önce dal sallanır
func shake(index: int, duration: float) -> void:
	_shake_left[index] = duration
	_shake_total[index] = duration


func _process(delta: float) -> void:
	_time += delta
	for i in branches.size():
		# Rüzgarda hafif salınma
		var rotation_target := sin(_time * 1.3 + i * 1.7) * 0.03
		if _shake_left[i] > 0.0:
			_shake_left[i] -= delta
			var strength := clampf(_shake_left[i] / _shake_total[i], 0.0, 1.0)
			rotation_target += sin(_time * 34.0) * 0.13 * sqrt(strength)
		branches[i].rotation = rotation_target
	# Taç çok hafifçe nefes alır
	if _crown:
		_crown.scale = _crown_scale * (1.0 + sin(_time * 0.9) * 0.004)
