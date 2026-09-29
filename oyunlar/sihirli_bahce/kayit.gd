extends RefCounted
# Sihirli Bahçe kaydı: user://sihirli_bahce.cfg
#   [bahce] parsel_0..4 (her parselin sözlüğü: bitki, aşama, ihtiyaç, birikinti), gece
#   [album] <bitki id> = kaç kez toplandı
#   [ipucu] ekme = ilk ekme ipucu gösterildi mi (bir kez ekildiyse gerek yok)

const PATH := "user://sihirli_bahce.cfg"
const PLOT_COUNT := 5


static func load_state() -> Dictionary:
	var config := ConfigFile.new()
	var ok := config.load(PATH) == OK
	var plots := []
	for i in PLOT_COUNT:
		var value = config.get_value("bahce", "parsel_%d" % i, {}) if ok else {}
		plots.append(value if value is Dictionary else {})
	var album := {}
	if ok and config.has_section("album"):
		for id in config.get_section_keys("album"):
			album[id] = int(config.get_value("album", id, 0))
	return {
		"plots": plots,
		"night": bool(config.get_value("bahce", "gece", false)) if ok else false,
		"album": album,
		"hint_done": bool(config.get_value("ipucu", "ekme", false)) if ok else false,
	}


static func save_state(state: Dictionary) -> void:
	var config := ConfigFile.new()
	var plots: Array = state["plots"]
	for i in plots.size():
		config.set_value("bahce", "parsel_%d" % i, plots[i])
	config.set_value("bahce", "gece", state["night"])
	var album: Dictionary = state["album"]
	for id in album:
		config.set_value("album", id, album[id])
	config.set_value("ipucu", "ekme", state["hint_done"])
	config.save(PATH)
