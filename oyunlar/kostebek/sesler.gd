extends "res://ortak/ses_havuzu.gd"
# Köstebek Vurma sesleri (ortak ses havuzu: aynı ses art arda çalınca kesilmez).
# Sesler sesler/ses_uret.py ile sentezlendi.

const S := "res://oyunlar/kostebek/sesler/"
const STREAMS := {
	"pop": preload(S + "pop.wav"),
	"bonk": preload(S + "bonk.wav"),
	"cin": preload(S + "cin.wav"),
	"kask": preload(S + "kask.wav"),
	"puf": preload(S + "puf.wav"),
	"can": preload(S + "can.wav"),
	"seviye": preload(S + "seviye.wav"),
	"oyun_sonu": preload(S + "oyun_sonu.wav"),
	"bip": preload(S + "bip.wav"),
	"bip_son": preload(S + "bip_son.wav"),
}
# Ses seviyeleri (dB): hepsi yumuşak; bomba ve can kaybı en kısık, ani yüksek ses yok
const VOLUMES := {
	"pop": -14.0, "bonk": -7.0, "cin": -9.0, "kask": -8.0, "puf": -13.0, "can": -11.0,
	"seviye": -7.0, "oyun_sonu": -7.0, "bip": -9.0, "bip_son": -8.0,
}


func _init() -> void:
	streams = STREAMS
	volumes = VOLUMES
	player_count = 10
