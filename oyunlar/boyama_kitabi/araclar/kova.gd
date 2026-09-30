extends ColoringTool
# Boya kovası: dokunulan bölge seçili renkle, dokunulan noktadan dışa yayılan bir daireyle dolar.
# Bölge zaten o renkteyse sadece küçük bir ışıltı çıkar (her dokunuş görünür bir sonuç verir).

var _entry: Dictionary = {}


func begin(pos: Vector2) -> void:
	var region := canvas.region_at(pos)
	_entry = {}
	if canvas.colors[region] == color:
		canvas.sparkle(pos)
		canvas.play_sound("tik")
		return
	_entry = {"kind": "region", "region": region, "before": canvas.colors[region], "after": color, "at": pos}
	canvas.set_region_color(region, color, pos, true)
	canvas.play_sound("kova")


func end() -> void:
	if not _entry.is_empty():
		canvas.commit(_entry)
	_entry = {}


func cancel() -> void:
	if not _entry.is_empty():
		canvas.set_region_color(_entry["region"], _entry["before"], _entry["at"], false)
	_entry = {}
