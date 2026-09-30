extends ColoringTool
# Damga: dokunulan yere seçili damga "pıt" diye büyüyerek yerleşir; hafif rastgele açı ve boy.
# Rengi seçili renktir; yüz, parıltı gibi ayrıntılar kendi renginde kalır.

const StampLayer := preload("res://oyunlar/boyama_kitabi/tuval/damga_katmani.gd")
const G := "res://oyunlar/boyama_kitabi/gorseller/"
const KINDS := ["yildiz", "kalp", "cicek", "parilti", "gulen_yuz", "balon"]
const POP_TIME := 0.3

var kind: int = 0
var size: float = 170.0

var _node: Node2D


static func fill_texture(index: int) -> Texture2D:
	return load(G + "damga_%s_renk.svg" % KINDS[index])


static func top_texture(index: int) -> Texture2D:
	return load(G + "damga_%s_ust.svg" % KINDS[index])


func begin(pos: Vector2) -> void:
	_node = StampLayer.new()
	_node.fill = fill_texture(kind)
	_node.top = top_texture(kind)
	_node.color = color
	_node.size = size * randf_range(0.9, 1.1)
	_node.position = pos
	_node.rotation = randf_range(-0.25, 0.25)
	canvas.add_layer_node(_node)
	_node.pop_in(POP_TIME)
	canvas.keep_redrawing(POP_TIME + 0.05)
	canvas.play_sound("damga", randf_range(0.92, 1.1))


func end() -> void:
	if _node != null:
		canvas.commit({"kind": "layer", "node": _node})
	_node = null


func cancel() -> void:
	if _node != null:
		canvas.remove_layer_node(_node)
	_node = null
