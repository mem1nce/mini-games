class_name ColoringUndoStack
extends RefCounted
# Geri alma yığını. Her araç kullanımı tek bir kayıt (fırçada bir parmak darbesi = bir kayıt).
# Kayıtlar küçük tutulur: bölge boyamada sadece bölge numarası ve eski/yeni renk; fırça, damga ve
# temizlemede fırça katmanındaki düğüm (çizimin noktaları). Sınır aşılınca en eski kayıt düşer; tuval
# düşen kayıttaki düğümü kalıcı katmana işler (bkz. ColoringCanvas._bake).
#
# Kayıt biçimleri (Dictionary):
#   {"kind": "region", "region": int, "before": Color, "after": Color, "at": Vector2}
#   {"kind": "layer", "node": Node2D}
#   {"kind": "clear", "colors": PackedColorArray, "node": Node2D}
#   {"kind": "group", "items": Array}   (birlikte geri alınan kayıtlar, ör. silgiyle dokunma)

const LIMIT := 40

var _items: Array[Dictionary] = []


## Kaydı ekler; sınırı aşan en eski kayıtları döndürür (tuval onları kalıcı katmana işler)
func push(entry: Dictionary) -> Array[Dictionary]:
	_items.append(entry)
	var dropped: Array[Dictionary] = []
	while _items.size() > LIMIT:
		dropped.append(_items.pop_front())
	return dropped


func pop() -> Dictionary:
	return _items.pop_back() if not _items.is_empty() else {}


func size() -> int:
	return _items.size()


func clear() -> void:
	_items.clear()
