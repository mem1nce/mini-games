# Gölge Eşleştirme

1-3 yaş, hiç yazı yok. Eşyayı sürükleyip kendi gölgesine bırakma, 10 bölüm, sonra büyük kutlama ve 1. bölüme dönüş.

- Veri odaklı:
  - Her eşya `esyalar/<kategori>/<ad>.svg` + `.tres` (`ShadowItemData`: görsel + siluet grubu).
  - Her bölüm `bolumler/bolum_XX.tres` (`ShadowLevelData`); bölüm listesi kök düğümün `levels` dizisinde.
  - `_check_data()` aynı siluet grubundan iki eşyanın aynı bölümde olmasını engeller.
- Gölge ayrı çizilmez, `golge.gdshader` ile eşyanın kendi görselinden üretilir.
- Ayarlar (bırakma toleransı, ipucu süresi, animasyon süreleri) `golge_eslestirme.gd` başında `@export`.
- Tek parmak kilidi (`active_touch`), geri düğmesi basılı tutunca çalışır.
- Sesler `sesler/ses_uret.py` ile sentezlenmiş `.wav` (`sesler.gd` ortak ses havuzunu kullanır).
- Ayrıntılar ve yeni eşya/bölüm ekleme `TASARIM.md` içinde.
- İlerleme `user://golge_eslestirme.cfg`.
