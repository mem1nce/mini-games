extends "res://ortak/ses_havuzu.gd"
# Tren Rayı sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile sentezlendi.

const S := "res://oyunlar/tren_rayi/sesler/"
const NAMES := ["tik", "civata", "tamam", "duduk", "cuf", "hareket", "fren", "soru", "yolcu", "varis",
	"kutlama", "vagon", "yildiz", "dokun"]
const VOLUMES := {
	"tik": -10.0, "civata": -10.0, "tamam": -9.0, "duduk": -9.0, "cuf": -16.0, "hareket": -9.0, "fren": -14.0,
	"soru": -9.0, "yolcu": -9.0, "varis": -8.0, "kutlama": -7.0, "vagon": -8.0, "yildiz": -8.0, "dokun": -12.0,
}


func _init() -> void:
	for sound in NAMES:
		streams[sound] = load(S + sound + ".wav")
	volumes = VOLUMES
	player_count = 10
