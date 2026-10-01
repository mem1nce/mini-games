# Uçan Kuş

Dokununca zıplayan kuşla direklerin arasından geçme.

- Zorluk ayarları `ucan_kus.gd` başında `@export`.
- Görseller SVG: kuş 3 kare, direk beyaz çizilip `modulate` ile boyanıyor. Direk bilerek başlıksız, ucu yuvarlak düz bir sütun (genişliği çarpışma alanıyla aynı, 120 px): bilinen oyunlardaki boru gibi "geniş dudaklı başlık" çizme (nedeni kökteki `LISANSLAR.md`'de).
- Sesler (`SesYoneticisi`, `ucan_kus.gd`): müzik `ucan_kus`; kanat, puan `ding`, çarpma `boing` + `yumusak_dusus`, başlama `yukselis`, oyun sonu `yildiz_kazanma`, tekrar `basari`, hızlanma `vuus`.
- **Kademeli hızlanma** (ayarlar `@export` "Hızlanma" ve "Hareketli direkler" grupları): `speed_level` her `speed_step_points` puanda +1, can kaybında -1; `speed_factor` hedefe (`(1 + speed_step_ratio)^kademe`, en fazla `max_speed_factor`) yumuşakça yaklaşır. Direkler hep aynı sürede bir doğar, hızla kaydıkları için aralarındaki mesafe hızla orantılı açılır. Kuş `_bird_pace()` ile uyar (yerçekimi pace², zıplama pace: yükseklik aynı kalır). Boşluk `_current_gap()` ile daralır (her direk çifti kendi `gap` meta'sını taşır). `moving_pipes_start_score`'dan sonra 3-4 direkte bir direk sinüsle yukarı aşağı gider (`travel` / `base_y` / `age` meta). Hızlanınca: rüzgar çizgileri, kuş parıltısı, puan zıplaması, gökyüzü rengi (`SKY_COLORS`), `SesYoneticisi.muzik_hizi`. Yeni oyun sahneyi yeniden yüklediği için her şey baştan başlar.
- Test: `testler/hizlanma_testi.gd` (headless; otomatik pilot en üst kademeye kadar oynar).
