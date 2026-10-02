extends Control
# Ortak arayüz kökü: ekranı kaplayan, güvenli alan boşluklarını (çentik, kamera deliği, yuvarlak köşeler,
# alttaki hareket çubuğu) kendiliğinden uygulayan kapsayıcı. Oyunun düğmeleri ve göstergeleri bunun içine konur
# ve anchor'larla köşelere / kenarlara sabitlenir; böylece hiçbir cihazda çentiğin altında kalmazlar.
#
# Kullanım (bir CanvasLayer'ın altına):
#   const ArayuzKoku := preload("res://ortak/arayuz_koku.tscn")
#   var kok := ArayuzKoku.instantiate()
#   katman.add_child(kok)
#   kok.add_child(dugme)           # dugme anchor'ları köke göre çalışır (ör. PRESET_TOP_LEFT)
# Sahnede: arayuz_koku.tscn'i CanvasLayer'ın altına örnekle, öğeleri içine koy.
# Kökün boyutu = güvenli alan; "yerlesti" sinyali boyut her değiştiğinde gelir (kodla yerleşim yapanlar için).
# Dokunmayı engellemez (mouse_filter = IGNORE). Arka planlar buraya DEĞİL, ekranı kaplayacak şekilde ayrı konur.

signal yerlesti

## Güvenli alanın içinde ayrıca bırakılacak pay (tasarım pikseli): sol, üst, sağ, alt
@export var ek_bosluk := Vector4.ZERO:
	set(deger):
		ek_bosluk = deger
		_uygula()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	EkranYardimcisi.degisince(_uygula)
	_uygula()


func _uygula() -> void:
	if not is_inside_tree():
		return
	var b: Dictionary = EkranYardimcisi.guvenli_bosluklar()
	offset_left = float(b["sol"]) + ek_bosluk.x
	offset_top = float(b["ust"]) + ek_bosluk.y
	offset_right = -float(b["sag"]) - ek_bosluk.z
	offset_bottom = -float(b["alt"]) - ek_bosluk.w
	yerlesti.emit()
