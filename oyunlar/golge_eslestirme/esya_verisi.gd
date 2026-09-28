class_name ShadowItemData
extends Resource
# Gölge Eşleştirme'de bir eşya. Her eşyanın yanında bir .tres dosyası vardır
# (ör. esyalar/hayvanlar/tavsan.tres). Gölgesi ayrıca çizilmez, bu görselden üretilir.

## Eşyanın görseli (256x256 SVG, zemin gölgesi olmadan).
@export var texture: Texture2D
## Siluetleri birbirine çok benzeyen eşyalar aynı grubu paylaşır (ör. daire, oval, top: "yuvarlak").
## Aynı bölümde aynı gruptan iki eşya olamaz. Boş bırakılırsa eşya kendine özgü sayılır.
@export var group: StringName = &""


func item_name() -> String:
	return resource_path.get_file().get_basename()
