extends "res://oyunlar/buyukten_kucuge/boyutlu_nesne.gd"
# İç içe bebek (NestingDoll): alt ve üst yarı ayrı çizilir (bebek_<karakter>_alt / _ust şablonları, aynı tuval).
# Üst yarı açılma çizgisinden menteşe gibi kalkıp yana eğilir. contents: içindeki bebekler (büyükten küçüğe).
# art burada karakter adıdır (tavsan / ayi / penguen).

var contents: Array = []

var _lid: Node2D
var _lid_home: Vector2


func _build() -> void:
	add_child(_make_sprite("bebek_%s_alt" % art))
	var info := SizeArt.info("bebek_%s_ust" % art)
	# Menteşe: açılma çizgisinin ortası (tuvaldeki split, görünen boya ölçeklenir)
	_lid_home = Vector2(0.0, (float(info["split"]) / float(info["h"]) - 0.5) * visual.y)
	_lid = Node2D.new()
	_lid.position = _lid_home
	add_child(_lid)
	var top := _make_sprite("bebek_%s_ust" % art)
	top.position = -_lid_home
	_lid.add_child(top)
	sprite = top


# En içteki bebeğin sırası (içi boşsa kendisi)
func innermost_rank() -> int:
	return contents.back().rank if not contents.is_empty() else rank


func open(duration: float = 0.25) -> void:
	var tween := _lid.create_tween().set_parallel()
	tween.tween_property(_lid, "position", _lid_home + Vector2(visual.x * 0.12, -visual.y * 0.3), duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_lid, "rotation", 0.4, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close(duration: float = 0.2) -> void:
	var tween := _lid.create_tween().set_parallel()
	tween.tween_property(_lid, "position", _lid_home, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_lid, "rotation", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
