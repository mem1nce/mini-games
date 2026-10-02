# Gölge Eşleştirme

1-3 yaş, hiç yazı yok. Eşyayı sürükleyip kendi gölgesine bırakma, 10 bölüm, sonra büyük kutlama ve 1. bölüme dönüş.

- Veri odaklı:
  - Her eşya `esyalar/<kategori>/<ad>.svg` + `.tres` (`ShadowItemData`: görsel + siluet grubu).
  - Her bölüm `bolumler/bolum_XX.tres` (`ShadowLevelData`); bölüm listesi kök düğümün `levels` dizisinde.
  - `_check_data()` aynı siluet grubundan iki eşyanın aynı bölümde olmasını engeller.
- Gölge ayrı çizilmez, `golge.gdshader` ile eşyanın kendi görselinden üretilir.
- Ayarlar (bırakma toleransı, ipucu süresi, animasyon süreleri) `golge_eslestirme.gd` başında `@export`.
- Sürükle-bırak ortak bileşenle: `esya.gd` ortak `ortak/suruklenebilir.gd`'yi extends eder, dokunmayı sahnedeki `DragInput` (`ortak/surukleme_girdisi.gd`) okur (tek parmak kilidi, basılı geri düğmesi); oyun sinyallerini dinler.
- Test: `testler/oynanis_testi.gd` (`--fixed-fps 60 --resolution 1280x720`; 10 bölümü sürükleyerek oynar, boş/yanlış bırakma, ikinci parmak, 1. bölüme dönüş; kaydı yedekleyip geri yazar).
- Sesler `sesler/ses_uret.py` ile sentezlenmiş `.wav` (`sesler.gd` ortak ses havuzunu kullanır).
- Ayrıntılar ve yeni eşya/bölüm ekleme `TASARIM.md` içinde.
- İlerleme `user://golge_eslestirme.cfg`.
