extends "res://ortak/ses_havuzu.gd"
# Robot Fabrikası sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile sentezlendi.

const S := "res://oyunlar/robot_fabrikasi/sesler/"
const NAMES := ["al", "dogru", "boing", "dolu", "boru", "dus", "kol", "montaj", "uyan", "dans", "kutlama", "yardimci", "tik", "ucus"]
const VOLUMES := {
	"al": -13.0, "dogru": -9.0, "boing": -9.0, "dolu": -9.0, "boru": -15.0, "dus": -15.0, "kol": -9.0,
	"montaj": -11.0, "uyan": -9.0, "dans": -9.0, "kutlama": -7.0, "yardimci": -12.0, "tik": -12.0, "ucus": -12.0,
}


func _init() -> void:
	for sound in NAMES:
		streams[sound] = load(S + sound + ".wav")
	volumes = VOLUMES
	player_count = 10
