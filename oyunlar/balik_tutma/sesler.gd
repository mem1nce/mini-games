extends "res://ortak/ses_havuzu.gd"
# Balık Tutma sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile sentezlendi.

const S := "res://oyunlar/balik_tutma/sesler/"
const NAMES := ["dalis", "yakala", "kova", "geri", "gidik", "cop", "gorev", "yeni", "kutlama", "dokun", "takla", "temiz"]
const VOLUMES := {
	"dalis": -14.0, "yakala": -9.0, "kova": -10.0, "geri": -11.0, "gidik": -10.0, "cop": -9.0, "gorev": -9.0,
	"yeni": -8.0, "kutlama": -7.0, "dokun": -12.0, "takla": -11.0, "temiz": -10.0,
}


func _init() -> void:
	for sound in NAMES:
		streams[sound] = load(S + sound + ".wav")
	volumes = VOLUMES
	player_count = 10
