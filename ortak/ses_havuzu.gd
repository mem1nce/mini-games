extends Node
# Oyunlar için küçük ses havuzu: birkaç AudioStreamPlayer aynı anda çalabilir, böylece aynı ses
# art arda hızlıca çalınınca birbirini kesmez. Boş oyuncu yoksa en eski başlayan ses susturulur.
# Kullanım: bu script'i extends eden bir sesler.gd yazıp _init içinde streams / volumes ver.

## Ses adı -> AudioStream
var streams: Dictionary = {}
## Ses adı -> ses seviyesi (dB). Listede olmayan ses -8 dB çalar.
var volumes: Dictionary = {}
var player_count: int = 8

var _players: Array[AudioStreamPlayer] = []
var _started: Array[int] = []   # her oyuncunun başladığı an (ms), en eskisini bulmak için


func _ready() -> void:
	for i in player_count:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
		_started.append(0)


func play(sound: String, pitch: float = 1.0) -> void:
	if not streams.has(sound):
		push_warning("Ses havuzu: '%s' diye bir ses yok" % sound)
		return
	var index := 0
	for i in _players.size():
		if not _players[i].playing:
			index = i
			break
		if _started[i] < _started[index]:
			index = i
	var player := _players[index]
	player.stream = streams[sound]
	player.volume_db = volumes.get(sound, -8.0)
	player.pitch_scale = pitch
	player.play()
	_started[index] = Time.get_ticks_msec()
