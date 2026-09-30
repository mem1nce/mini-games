# Meyve Topla

Başında sepet taşıyan kirpiyle ağaçtan düşen meyveleri toplama, 12 bölüm + sonsuz mod, güçlendirmeler.

- Tasarım ve dosya yapısı `TASARIM.md` içinde.
- Bölüm verileri `bolumler.gd`, akış `meyve_topla.gd`. Oyuncu, düşen nesne, bölüm yöneticisi, ağaç, arka plan, efektler ve arayüz ayrı script'lerde.
- Parçacıklar `CPUParticles2D`.
- Meyve SVG'leri hafıza oyunundan kopyalandı (zemin gölgesi çıkarılarak).
- İlerleme `user://meyve_topla.cfg`.
- Sesler (`SesYoneticisi`, `meyve_topla.gd` ve düğmeler `arayuz.gd`): müzik `meyve_topla`; meyve `pop` (kombo arttıkça ince), kombo `basari_parlak`, kötü nesne `bonk` + `sersem` + `yumusak_dusus`, güç `guc_al` / `guc_bitti`, bölüm başı `bolum_gecisi`, bölüm sonu `kutlama`.
