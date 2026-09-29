extends "res://oyunlar/muzik_kutusu/enstruman.gd"
# DrumKit: bas davul, trampet, iki tom, zil ve marakas. Her parmak ayrı vuruştur: iki elle aynı anda
# birden çok parçaya vurulabilir. Aynı parçaya hızlı art arda vurmak önceki sesi kesmez, üst üste çalar
# (havuzda 16 ses). Vurulan parça titreyip esner ve dokunulan yerden bir halka dalgası yayılır.

const G := "res://oyunlar/muzik_kutusu/gorseller/"
const S := "res://oyunlar/muzik_kutusu/sesler/"

# Parçalar: [ses, görsel, merkez, görsel genişliği, dokunma alanı, dokunma alanı kayması, renk]
# Sıra önemli: sonra eklenen üstte çizilir ve üst üste binen yerde önce o çalar (tomlar bas davulun üstünde).
const PARTS := [
	["bas", preload(G + "bas_davul.svg"), Vector2(520, 300), 300.0, Vector2(300, 300), Vector2.ZERO, Color("ff5b6e")],
	["trampet", preload(G + "trampet.svg"), Vector2(185, 290), 250.0, Vector2(250, 200), Vector2(0, -30), Color("ffc23d")],
	["tom_ince", preload(G + "tom_mavi.svg"), Vector2(388, 108), 190.0, Vector2(196, 150), Vector2(0, -8), Color("4aa3ff")],
	["tom_kalin", preload(G + "tom_yesil.svg"), Vector2(652, 108), 190.0, Vector2(196, 150), Vector2(0, -8), Color("5cc95c")],
	["zil", preload(G + "zil.svg"), Vector2(872, 130), 250.0, Vector2(262, 150), Vector2(0, -44), Color("ffd04a")],
	["marakas", preload(G + "marakas.svg"), Vector2(880, 358), 200.0, Vector2(210, 210), Vector2.ZERO, Color("ff6fb5")],
]


func _init() -> void:
	ring_effect = true


func sound_streams() -> Dictionary:
	return {
		"bas": preload(S + "bas.wav"),
		"trampet": preload(S + "trampet.wav"),
		"tom_ince": preload(S + "tom_ince.wav"),
		"tom_kalin": preload(S + "tom_kalin.wav"),
		"zil": preload(S + "zil.wav"),
		"marakas": preload(S + "marakas.wav"),
	}


func build() -> void:
	for part in PARTS:
		var pad := Pad.new()
		pad.sound = part[0]
		pad.color = part[6]
		pad.style = Pad.Style.WOBBLE
		pad.position = part[2]
		pad.setup(part[1], part[3], part[4], true, part[5])
		add_pad(pad)


# Hızlı art arda vuruşlar makineli tüfek gibi aynı duyulmasın: perde çok az değişir
func play_pad(pad: Pad, at: Vector2, pitch: float = 1.0) -> void:
	super.play_pad(pad, at, pitch * randf_range(0.97, 1.03))
