extends "res://ortak/ses_havuzu.gd"
# Zıpla Zıpla sesleri (ortak ses havuzu: aynı ses art arda çalınca kesilmez).
# Sesler sesler/ses_uret.py ile sentezlendi.

const S := "res://oyunlar/zipla_zipla/sesler/"
const STREAMS := {
	"zipla": preload(S + "zipla.wav"),
	"kon": preload(S + "kon.wav"),
	"cin": preload(S + "cin.wav"),
	"titre": preload(S + "titre.wav"),
	"ufalan": preload(S + "ufalan.wav"),
	"dus": preload(S + "dus.wav"),
	"oyun_sonu": preload(S + "oyun_sonu.wav"),
	"rekor": preload(S + "rekor.wav"),
}
# Ses seviyeleri (dB): hepsi yumuşak; düşme ve ufalanma kısık, ani yüksek ses yok
const VOLUMES := {
	"zipla": -10.0, "kon": -9.0, "cin": -9.0, "titre": -14.0, "ufalan": -12.0,
	"dus": -13.0, "oyun_sonu": -7.0, "rekor": -7.0,
}


func _init() -> void:
	streams = STREAMS
	volumes = VOLUMES
	player_count = 8
