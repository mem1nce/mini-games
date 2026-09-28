extends Node
# Gölge Eşleştirme sesleri. Projede ortak bir ses yöneticisi olmadığı için küçük bir
# AudioStreamPlayer havuzu: aynı anda birkaç ses çalabilir. Sesler sesler/ses_uret.py ile üretildi.

const STREAMS := {
	"pop": preload("res://oyunlar/golge_eslestirme/sesler/pop.wav"),
	"ding": preload("res://oyunlar/golge_eslestirme/sesler/ding.wav"),
	"boing": preload("res://oyunlar/golge_eslestirme/sesler/boing.wav"),
	"bolum_sonu": preload("res://oyunlar/golge_eslestirme/sesler/bolum_sonu.wav"),
	"final": preload("res://oyunlar/golge_eslestirme/sesler/final.wav"),
}
# Ses seviyeleri (dB): hepsi yumuşak, ani yüksek ses olmasın
const VOLUMES := {"pop": -10.0, "ding": -8.0, "boing": -9.0, "bolum_sonu": -7.0, "final": -6.0}
const PLAYER_COUNT := 6

var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: String, pitch: float = 1.0) -> void:
	if not STREAMS.has(sound):
		push_warning("Gölge Eşleştirme: '%s' diye bir ses yok" % sound)
		return
	var player := _players[0]
	for candidate in _players:
		if not candidate.playing:
			player = candidate
			break
	player.stream = STREAMS[sound]
	player.volume_db = VOLUMES.get(sound, -8.0)
	player.pitch_scale = pitch
	player.play()
