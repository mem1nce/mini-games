extends "res://oyunlar/muzik_kutusu/enstruman.gd"
# AnimalOrchestra: iki sıra, sekiz hayvan. Dokununca hayvan ağzını açıp sesini çıkarır ve ses süresince
# neşeyle zıplayıp sallanır; tekrar dokunulursa ses yeniden çalar ve süre uzar.
# Sesler sesler/<ad>.wav: gerçek bir kayıtla değiştirmek için aynı adla dosyayı değiştirmek yeter.

const G := "res://oyunlar/muzik_kutusu/gorseller/"
const S := "res://oyunlar/muzik_kutusu/sesler/"

const ANIMALS := ["kedi", "kopek", "inek", "ordek", "koyun", "horoz", "kurbaga", "aslan"]
const COLORS: Array[Color] = [
	Color("ffa84d"), Color("e8a45c"), Color("ff9ec0"), Color("ffd93d"),
	Color("c9b6ff"), Color("ff4f5e"), Color("6fd35a"), Color("f28a2e"),
]
const COLUMNS := 4
const CELL := Vector2(260, 232)
const TOP_ROW_Y := 118.0
const ANIMAL_WIDTH := 212.0


func sound_streams() -> Dictionary:
	var streams := {}
	for animal in ANIMALS:
		streams[animal] = load(S + animal + ".wav")
	return streams


func build() -> void:
	for k in ANIMALS.size():
		var animal: String = ANIMALS[k]
		var pad := Pad.new()
		pad.sound = animal
		pad.color = COLORS[k]
		pad.style = Pad.Style.SING
		pad.open_texture = load(G + animal + "_ses.svg")
		pad.position = Vector2(CELL.x * (k % COLUMNS + 0.5), TOP_ROW_Y + CELL.y * floori(k / float(COLUMNS)))
		pad.setup(load(G + animal + ".svg"), ANIMAL_WIDTH, Vector2(CELL.x - 16.0, CELL.y - 8.0), false, Vector2(0, 4))
		add_pad(pad)
