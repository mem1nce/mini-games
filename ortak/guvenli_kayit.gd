class_name GuvenliKayit
extends RefCounted

const SCHEMA_VERSION := 1

static func save_config(config: ConfigFile, path: String) -> Error:
	if not path.begins_with("user://"):
		push_error("Kayıt yolu user:// dışında: %s" % path)
		return ERR_UNAUTHORIZED
	config.set_value("meta", "schema_version", SCHEMA_VERSION)
	var temporary := path + ".tmp"
	var result := config.save(temporary)
	if result != OK:
		push_error("Kayıt geçici dosyaya yazılamadı: %s (%s)" % [temporary, result])
		return result
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("Kayıt klasörü açılamadı")
		return ERR_CANT_OPEN
	var temporary_name := temporary.trim_prefix("user://")
	var target_name := path.trim_prefix("user://")
	if dir.file_exists(target_name):
		dir.remove(target_name + ".bak")
		dir.rename(target_name, target_name + ".bak")
	var rename_result := dir.rename(temporary_name, target_name)
	if rename_result != OK:
		push_error("Kayıt yerine taşınamadı: %s (%s)" % [path, rename_result])
		return rename_result
	return OK
