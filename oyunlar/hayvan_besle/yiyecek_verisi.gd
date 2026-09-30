class_name FeedFoodData
extends Resource
# Hayvanları Besle: bir yiyecek türü (yiyecekler/<ad>.tres). Hangi hayvanın yediği hayvanın
# kendi verisindedir (FeedAnimalData.accepts).

## Kısa ad (dosya adıyla aynı; testlerde ve hata mesajlarında görünür)
@export var id: StringName = &""
## Görsel (256'lık tuval, gorseller/yiyecekler/)
@export var texture: Texture2D
