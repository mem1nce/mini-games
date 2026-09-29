extends Node
# SongPlayer: ksilofonun şarkı modu. Sıradaki notanın tuşu parlar; çocuk o tuşa dokununca şarkı bir nota
# ilerler. Yanlış tuş da ses çıkarır ama şarkıyı ilerletmez (ceza yok). Şarkı bitince `finished` gelir.
# replay(): biten şarkıyı kendi temposuyla (notaların süreleriyle) baştan çalar; her notada `replay_note`.

signal target_changed(bar: int)            # -1: parlayan tuş yok
signal finished(song: MusicSong)
signal replay_note(bar: int)
signal replay_ended

var song: MusicSong = null
var step: int = 0
var _replay_id: int = 0                    # yeni bir replay/stop eski beklemeleri geçersiz kılar
var _replaying: bool = false
var _timer: Timer                          # düğümle birlikte silinir: oyundan çıkınca bekleyen nota kalmaz


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)


func is_playing() -> bool:
	return song != null


func start(new_song: MusicSong) -> void:
	stop_replay()
	song = new_song
	step = 0
	target_changed.emit(target())


func stop() -> void:
	song = null
	step = 0
	target_changed.emit(-1)


## Sıradaki notanın tuşu (şarkı yoksa -1)
func target() -> int:
	if song == null or step >= song.size():
		return -1
	return song.bar(step)


## Tuş çalındı: sıradaki notaysa şarkı ilerler (true döner)
func on_bar(bar: int) -> bool:
	if song == null or bar != target():
		return false
	step += 1
	if step >= song.size():
		var done := song
		song = null
		step = 0
		target_changed.emit(-1)
		finished.emit(done)
	else:
		target_changed.emit(target())
	return true


func is_replaying() -> bool:
	return _replaying


func replay(played: MusicSong, delay: float = 0.0, speed: float = 1.0) -> void:
	_replay_id += 1
	var my_id := _replay_id
	_replaying = true
	if delay > 0.0:
		_timer.start(delay)
		await _timer.timeout
	for i in played.size():
		if my_id != _replay_id:
			return
		replay_note.emit(played.bar(i))
		_timer.start(played.seconds(i) / speed)
		await _timer.timeout
	if my_id == _replay_id:
		_replaying = false
		replay_ended.emit()


func stop_replay() -> void:
	if _replaying:
		_replay_id += 1
		_replaying = false
		replay_ended.emit()
