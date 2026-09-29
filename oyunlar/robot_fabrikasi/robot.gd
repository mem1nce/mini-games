extends Node2D
# Robot görünümü: şablona (bacak tipi, tepe, boyun, kanat, uzun kol) ve renklere göre parçalardan kurulur;
# canlanma (gözler yanar, göğüs ışıkları sırayla yanıp söner), dans, el sallama ve hafif boşta hareket.
# Montaj, galeri ve ana menü bunu kullanır. Düğümün (0, 0) noktası robotun yere bastığı yerin ortası.
#
# look: {"body": {"color", "shape"}, "head": {"color", "shape"}, "arm": renk, "antenna": renk, "wheel": renk}

const G := "res://oyunlar/robot_fabrikasi/gorseller/"
const P := G + "parcalar/"
const BODY := 130.0
const HEAD := 112.0
const ARM := 108.0
const SILHOUETTE := "shader_type canvas_item;\nuniform vec4 tint : source_color = vec4(0.36, 0.33, 0.48, 0.45);\nvoid fragment() {\n\tCOLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a);\n}\n"

# Şablonlar: legs (tekerlek, yay, palet, jet, tek_teker, orumcek, pogo, roket, ahtapot), top (anten, pervane,
# cift_pervane), neck (boyun halkası sayısı), wings, long_arms, size
const ROBOTS := {
	"tekerlekli": {"legs": "tekerlek", "top": "anten"},
	"yayli": {"legs": "yay", "top": "anten"},
	"pervaneli": {"legs": "tekerlek", "top": "pervane"},
	"uzun_boyunlu": {"legs": "tekerlek", "top": "anten", "neck": 2},
	"paletli": {"legs": "palet", "top": "anten"},
	"ucan": {"legs": "jet", "top": "anten", "size": 0.9},
	"tek_tekerlekli": {"legs": "tek_teker", "top": "anten"},
	"orumcek": {"legs": "orumcek", "top": "anten"},
	"ziplayan": {"legs": "pogo", "top": "anten"},
	"roketli": {"legs": "roket", "top": "anten"},
	"kanatli": {"legs": "tekerlek", "top": "anten", "wings": true},
	"uzun_kollu": {"legs": "palet", "top": "anten", "long_arms": true},
	"ahtapot": {"legs": "ahtapot", "top": "pervane"},
	"cift_pervaneli": {"legs": "jet", "top": "cift_pervane"},
	"dev": {"legs": "palet", "top": "pervane", "neck": 1, "long_arms": true, "wings": true, "size": 1.12},
}
const ORDER := ["tekerlekli", "yayli", "pervaneli", "uzun_boyunlu", "paletli", "ucan", "tek_tekerlekli", "orumcek",
	"ziplayan", "roketli", "kanatli", "uzun_kollu", "ahtapot", "cift_pervaneli", "dev"]
const LEG_HEIGHT := {"tekerlek": 62.0, "yay": 92.0, "palet": 70.0, "jet": 84.0, "tek_teker": 78.0, "orumcek": 96.0,
	"pogo": 118.0, "roket": 84.0, "ahtapot": 92.0}
const DEFAULT_LOOK := {"body": {"color": "mavi", "shape": "kare"}, "head": {"color": "sari", "shape": "daire"},
	"arm": "kirmizi", "antenna": "yesil", "wheel": "kirmizi"}

var template := "tekerlekli"
var look: Dictionary = DEFAULT_LOOK
var awake := false
var slots: Array[Node2D] = []          # montajda sırayla yerine oturan parçalar

var _root: Node2D                      # zıplayan/sallanan kısım
var _body: Sprite2D
var _head: Node2D
var _arms: Array[Node2D] = []
var _spinners: Array[Sprite2D] = []    # pervaneler
var _flames: Array[Sprite2D] = []
var _lights: Node2D
var _time := 0.0
var _phase := 0.0
var _eye_amount := 0.0
var _hover := false


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_phase = randf() * TAU


func build(p_template: String, p_look: Dictionary) -> void:
	template = p_template if ROBOTS.has(p_template) else "tekerlekli"
	look = p_look if not p_look.is_empty() else DEFAULT_LOOK
	for child in get_children():
		child.queue_free()
	slots.clear()
	_arms.clear()
	_spinners.clear()
	_flames.clear()
	var t: Dictionary = ROBOTS[template]
	scale = Vector2.ONE * float(t.get("size", 1.0))
	_root = Node2D.new()
	add_child(_root)
	var legs: String = t["legs"]
	_hover = legs in ["jet", "roket"]
	var leg_h: float = LEG_HEIGHT[legs]
	var body_y := -leg_h - BODY * 0.4
	_build_legs(legs, body_y)
	# Kanatlar gövdenin arkasında
	if t.get("wings", false):
		for side in [-1, 1]:
			var wing := _sprite(G + "kanat.svg", 128.0, Vector2(side * 88.0, body_y - 20.0))
			wing.flip_h = side > 0
			slots.append(wing)
	# Kollar gövdenin arkasında, omuzdan sarkar
	for side in [-1, 1]:
		var arm := Node2D.new()
		arm.position = Vector2(side * BODY * 0.42, body_y - 14.0)
		arm.rotation = side * -0.28
		_root.add_child(arm)
		var sprite := _sprite(P + "kol_%s.svg" % look["arm"], ARM, Vector2.ZERO, arm)
		sprite.centered = false
		sprite.offset = -Vector2(80, 26) * sprite.texture.get_width() / 160.0
		if t.get("long_arms", false):
			sprite.scale.y *= 1.45
		arm.set_meta("rest", arm.rotation)
		arm.set_meta("side", side)
		_arms.append(arm)
		slots.append(arm)
	var body: Dictionary = look["body"]
	_body = _sprite(P + "govde_%s_%s.svg" % [body["shape"], body["color"]], BODY, Vector2(0, body_y))
	slots.append(_body)
	var top_of_body := body_y - BODY * 0.36
	var neck: int = t.get("neck", 0)
	if neck == 0:
		# Kısa boyun halkası: kafa gövdeye bağlı görünsün
		slots.append(_sprite(G + "boyun.svg", 44.0, Vector2(0, top_of_body - 4.0)))
		slots.back().scale.y *= 0.35
	for i in neck:
		var ring := _sprite(G + "boyun.svg", 58.0, Vector2(0, top_of_body - 34.0 - i * 64.0))
		slots.append(ring)
	var head_y := top_of_body - neck * 64.0 - HEAD * 0.4
	_head = Node2D.new()
	_head.position = Vector2(0, head_y)
	_root.add_child(_head)
	var head: Dictionary = look["head"]
	_sprite(P + "kafa_%s_%s.svg" % [head["shape"], head["color"]], HEAD, Vector2.ZERO, _head)
	slots.append(_head)
	_build_top(t["top"], head_y - HEAD * 0.42)
	_lights = Node2D.new()
	_lights.draw.connect(_draw_lights)
	_root.add_child(_lights)


func _sprite(path: String, width: float, pos: Vector2, parent: Node2D = null) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.scale = Vector2.ONE * width / sprite.texture.get_width()
	sprite.position = pos
	(parent if parent else _root).add_child(sprite)
	return sprite


func _build_legs(legs: String, body_y: float) -> void:
	var wheel := P + "tekerlek_%s.svg" % look.get("wheel", "kirmizi")
	match legs:
		"tekerlek":
			for side in [-1, 1]:
				slots.append(_sprite(wheel, 70.0, Vector2(side * 42.0, -35.0)))
		"tek_teker":
			var fork := _sprite(G + "bacak.svg", 44.0, Vector2(0, -62.0))
			slots.append(fork)
			slots.append(_sprite(wheel, 80.0, Vector2(0, -40.0)))
		"yay":
			for side in [-1, 1]:
				slots.append(_sprite(G + "yay.svg", 58.0, Vector2(side * 30.0, -52.0)))
		"palet":
			slots.append(_sprite(G + "palet.svg", 190.0, Vector2(0, -38.0)))
		"orumcek":
			for i in 4:
				var x: float = [-1.0, -0.35, 0.35, 1.0][i]
				var leg := _sprite(G + "bacak.svg", 38.0, Vector2(x * 58.0, -48.0))
				leg.rotation = x * 0.35
				slots.append(leg)
		"pogo":
			slots.append(_sprite(G + "pogo.svg", 62.0, Vector2(0, -64.0)))
		"ahtapot":
			for i in 4:
				var x: float = [-1.0, -0.35, 0.35, 1.0][i]
				var arm := _sprite(G + "dokunac.svg", 42.0, Vector2(x * 44.0, -48.0))
				arm.flip_h = x > 0.0
				slots.append(arm)
		"jet", "roket":
			for side in ([-1, 1] if legs == "jet" else [0]):
				var flame := _sprite(G + "alev.svg", 40.0 if legs == "jet" else 56.0, Vector2(side * 30.0, body_y + BODY * 0.52))
				_flames.append(flame)
				slots.append(flame)
			if legs == "roket":
				for side in [-1, 1]:
					var fin := _sprite(G + "kanatcik.svg", 54.0, Vector2(side * 64.0, body_y + 36.0))
					fin.flip_h = side < 0
					slots.append(fin)


func _build_top(top: String, head_top: float) -> void:
	match top:
		"anten":
			var antenna := _sprite(P + "anten_%s.svg" % look.get("antenna", "yesil"), 76.0, Vector2(0, head_top - 30.0), _head)
			antenna.position = Vector2(0, head_top - _head.position.y - 30.0)
		"pervane", "cift_pervane":
			var xs := [0.0] if top == "pervane" else [-40.0, 40.0]
			for x in xs:
				var prop := _sprite(G + "pervane.svg", 150.0 if top == "pervane" else 104.0, Vector2(x, head_top - _head.position.y - 18.0), _head)
				_spinners.append(prop)


# Montaj: önce hepsi gizli, sonra parça parça görünür
func hide_parts() -> void:
	for slot in slots:
		slot.visible = false
	_lights.visible = false


func show_slot(node: Node2D) -> void:
	node.visible = true
	var full := node.scale
	node.scale = full * 0.6
	node.create_tween().tween_property(node, "scale", full, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Parçanın dokusu (montajda uçan kopya için): düğüm sprite ise kendisi, değilse ilk sprite çocuğu
static func slot_sprite(node: Node2D) -> Sprite2D:
	if node is Sprite2D:
		return node
	for child in node.get_children():
		if child is Sprite2D:
			return child
	return null


func set_silhouette(value: bool) -> void:
	var material: ShaderMaterial = null
	if value:
		var shader := Shader.new()
		shader.code = SILHOUETTE
		material = ShaderMaterial.new()
		material.shader = shader
	_apply_material(self, material)
	if _lights:
		_lights.visible = not value


func _apply_material(node: Node, material: Material) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			child.material = material
		_apply_material(child, material)


# --- Animasyonlar ---

func wake() -> void:
	awake = true
	_lights.visible = true
	var tween := create_tween()
	for k in 2:
		tween.tween_method(func(v: float) -> void: _eye_amount = v, 0.0, 1.0, 0.12)
		tween.tween_method(func(v: float) -> void: _eye_amount = v, 1.0, 0.2, 0.1)
	tween.tween_method(func(v: float) -> void: _eye_amount = v, 0.2, 1.0, 0.2)
	var hop := create_tween()
	hop.tween_property(_root, "position:y", -24.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hop.tween_property(_root, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func dance() -> void:
	var tween := create_tween()
	for k in 2:
		tween.tween_property(_root, "rotation", 0.14, 0.18).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(_root, "position:y", -30.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_root, "rotation", -0.14, 0.18).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(_root, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_root, "rotation", 0.0, 0.2)
	tween.tween_property(_root, "scale", Vector2(-1, 1), 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_root, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_SINE)
	for arm in _arms:
		var side: float = arm.get_meta("side")
		var rest: float = arm.get_meta("rest")
		var arms := create_tween()
		for k in 3:
			arms.tween_property(arm, "rotation", side * -2.4, 0.2).set_trans(Tween.TRANS_SINE)
			arms.tween_property(arm, "rotation", rest, 0.2).set_trans(Tween.TRANS_SINE)


func wave() -> void:
	if _arms.size() < 2:
		return
	var arm := _arms[1]
	var rest: float = arm.get_meta("rest")
	var tween := create_tween()
	tween.tween_property(arm, "rotation", -2.6, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for k in 3:
		tween.tween_property(arm, "rotation", -2.2, 0.14).set_trans(Tween.TRANS_SINE)
		tween.tween_property(arm, "rotation", -2.8, 0.14).set_trans(Tween.TRANS_SINE)
	tween.tween_property(arm, "rotation", rest, 0.3).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_time += delta
	for prop in _spinners:
		prop.scale.x = absf(prop.scale.y) * (0.25 + 0.75 * absf(cos(_time * 14.0)))
	for flame in _flames:
		flame.scale.y = absf(flame.scale.x) * (0.85 + 0.2 * sin(_time * 30.0 + flame.position.x))
	if _hover:
		_root.position.y = sin(_time * 2.6 + _phase) * 8.0 - 10.0
	if awake:
		_lights.queue_redraw()


# Gözler (kafanın ekranında) ve göğüs ışıkları
func _draw_lights() -> void:
	if not awake:
		return
	var head: Dictionary = look["head"]
	var k := HEAD / 160.0
	var visor := {"daire": [Vector2(0, 9), 15.8, 7.6], "kare": [Vector2(0, 9), 15.8, 7.6],
		"ucgen": [Vector2(0, 23), 12.3, 6.0], "yildiz": [Vector2(0, 10), 10.6, 5.6]}
	var v: Array = visor.get(head["shape"], visor["daire"])
	for side in [-1, 1]:
		var p: Vector2 = _head.position + (v[0] + Vector2(side * v[1], 0)) * k
		var r: float = v[2] * k * 1.25
		_lights.draw_circle(p, r * 2.4, Color(0.5, 1.0, 1.0, 0.22 * _eye_amount))
		_lights.draw_circle(p, r, Color(0.6, 1.0, 1.0, _eye_amount))
		_lights.draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(1, 1, 1, _eye_amount))
	var body: Dictionary = look["body"]
	var chest := Vector2(0, 20 if body["shape"] == "ucgen" else 6) * BODY / 160.0
	var colors := [Color("ff5a6e"), Color("ffe066"), Color("5ef0b0")]
	for i in 3:
		var on := int(_time * 5.0) % 3 == i
		var p: Vector2 = _body.position + chest + Vector2((i - 1) * 13.0 * BODY / 160.0, 0)
		if on:
			_lights.draw_circle(p, 9.0, Color(colors[i], 0.35))
		_lights.draw_circle(p, 3.6, colors[i].lightened(0.3) if on else colors[i].darkened(0.3))
