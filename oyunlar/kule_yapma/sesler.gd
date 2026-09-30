extends "res://ortak/ses_havuzu.gd"
# Kule Yapma sesleri (ortak ses havuzu). Sesler sesler/ses_uret.py ile sentezlendi.

const S := "res://oyunlar/kule_yapma/sesler/"
const NAMES := ["birak", "otur", "mukemmel", "kombo", "iska", "puf", "tasin", "kutlama", "dokun", "rekor", "kuslar", "isler"]
const VOLUMES := {
	"birak": -13.0, "otur": -9.0, "mukemmel": -8.0, "kombo": -8.0, "iska": -10.0, "puf": -13.0, "tasin": -11.0,
	"kutlama": -7.0, "dokun": -12.0, "rekor": -8.0, "kuslar": -14.0, "isler": -10.0,
}


func _init() -> void:
	for sound in NAMES:
		streams[sound] = load(S + sound + ".wav")
	volumes = VOLUMES
	player_count = 10
