extends Node
# Narrator: Godot'nun metinden sese özelliğiyle (DisplayServer.tts_*) Türkçe sesli sayma.
# Proje ayarı audio/general/text_to_speech açık, platform TTS destekliyor ve cihazda Türkçe bir ses
# varsa available = true olur. Yoksa her şey sessizce devre dışı kalır, oyun normal çalışır.
# Windows'ta OneCore sesleri de görünür (Türkçe dil paketiyle "Microsoft Tolga"); Android'de cihazın TTS'i.

const WORDS := ["sıfır", "bir", "iki", "üç", "dört", "beş", "altı", "yedi", "sekiz", "dokuz", "on",
	"on bir", "on iki", "on üç", "on dört", "on beş", "on altı", "on yedi", "on sekiz", "on dokuz", "yirmi"]

var available: bool = false
var enabled: bool = true
var _voice: String = ""


func _ready() -> void:
	_voice = _find_turkish_voice()
	available = _voice != ""


func _exit_tree() -> void:
	stop()


func _find_turkish_voice() -> String:
	if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
		return ""
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return ""
	for voice in DisplayServer.tts_get_voices():
		var language := str(voice.get("language", "")).to_lower()
		if language.begins_with("tr"):
			return str(voice.get("id", ""))
	return ""


func is_active() -> bool:
	return available and enabled


static func number_word(n: int) -> String:
	return WORDS[n] if n >= 0 and n < WORDS.size() else str(n)


func say(text: String, interrupt: bool = true) -> void:
	if not is_active():
		return
	DisplayServer.tts_speak(text, _voice, 80, 1.0, 0.95, 0, interrupt)


func say_number(n: int) -> void:
	say(number_word(n))


func say_problem(a: int, b: int) -> void:
	say("%s artı %s" % [number_word(a), number_word(b)])


# interrupt false: sayma sesleri bitince sıraya girer
func say_result(a: int, b: int, interrupt: bool = true) -> void:
	say("%s artı %s eder %s" % [number_word(a), number_word(b), number_word(a + b)], interrupt)


func stop() -> void:
	if available:
		DisplayServer.tts_stop()
