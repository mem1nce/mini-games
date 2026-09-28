# Hafıza Kartları

İki tema (hayvanlar, meyveler), 4 bölüm (2x2 → 4x4).

- Temalar ve bölümler `veriler.gd` içinde. Yeni tema = `temalar/` altında yeni klasör + `THEMES`'e bir satır.
- Kart animasyonları `kart.gd`.
- İlerleme `user://hafiza.cfg`.
- SVG'ler 2x ölçek + mipmap ile içe aktarılır (`.import` içinde `svg/scale=2.0`, `mipmaps/generate=true`) ve kök düğümde `texture_filter = LINEAR_WITH_MIPMAPS` var. Yeni SVG eklenince aynı ayarları ver.
