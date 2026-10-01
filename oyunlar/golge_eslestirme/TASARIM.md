# Gölge Eşleştirme — Tasarım

Eşyayı parmakla sürükleyip kendi gölgesine bırakma oyunu. Hedef yaş 1-3: **hiç yazı yok**, süre/puan/ceza yok.

## Ekran düzeni (dikey, `expand`)

```
┌──────────────────────────────┐
│ (←)      ● ● ● ○ · · · · · · │  geri (basılı tut) + 10 bölüm noktası
│                              │
│    ▲ gölge        ● gölge    │  üst bölge: gölgeler (2 sütun)
│    ★ gölge        ■ gölge    │
│ ╭──────────────────────────╮ │
│ │   ●             ▲        │ │  alt tepsi: eşyalar (2 sütun)
│ │   ■             ★        │ │
│ ╰──────────────────────────╯ │
└──────────────────────────────┘
```

Boyutlar `get_viewport_rect().size`'dan hesaplanır (telefon ve tablet oranında denendi).
Eşya boyutu ekranın kısa kenarının %20-27'si. Yerler her bölümde karışır; hiçbir eşya kendi
gölgesinin tam altındaki hücrede başlamaz, hücre içinde küçük rastgele kaydırma var.

## Oynanış

- Eşyaya dokununca "pop", eşya büyür, en üste çıkar ve parmağın biraz üstünde durur.
- Doğru gölgenin yakınına gelince gölge hafifçe aydınlanır.
- Bırakınca eşya kendi gölgesinin merkezine `drop_tolerance` x eşya boyutu kadar yakınsa: yerine oturur,
  büyüyüp küçülür, yıldızlar saçılır, "çın" sesi (her yerleşimde biraz daha tiz). Bir daha tutulamaz.
- Değilse yumuşakça yerine döner, hafif "boing"; başka bir gölgeye bırakıldıysa önce hafifçe sallanır.
- 4 eşya yerleşince: eşyalar zıplar, konfeti, kısa melodi, nokta altın rengine döner, sonraki bölüm.
- 10. bölümden sonra: büyük kutlama (konfeti yağmuru + konfeti topları + yıldız patlamaları + dev yıldız,
  uzun melodi), sonra 1. bölüm.
- ~9 sn hiçbir şey yapılmazsa bir el, yerleşmemiş bir eşyadan kendi gölgesine kayarak gösterir.
- Geri düğmesi 1 sn basılı tutulunca (çevresinde halka dolar) ana menüye döner; kazara dokunuş çıkarmaz.
  Android geri tuşu / Escape `SahneGecis` üzerinden hemen çalışır.

## Dokunma

Dokunmayı sahnedeki ortak `DragInput` düğümü (`ortak/surukleme_girdisi.gd`) okur; `golge_eslestirme.gd` onun
sinyallerini (`item_grabbed` / `item_moved` / `item_dropped` / `item_canceled` / `touched`) dinler. Aynı anda yalnız
bir parmak (`DragInput.active_touch`) bir şey tutabilir; diğer parmaklar, avuç içi dokunuşları ve onların kalkması yok sayılır. İptal edilen dokunuşta
veya uygulama arka plana giderse tutulan eşya sessizce yerine döner. Masaüstünde proje ayarındaki
"Emulate Touch From Mouse" ile fareyle oynanır.

## Dosyalar

```
golge_eslestirme/
  golge_eslestirme.tscn/.gd  ana sahne (ShadowMatchGame): akış, dokunma, yerleşim, ipucu, kayıt
                             sinyaller: level_completed(index), all_levels_completed
  esya.gd                    sürüklenen eşya: ortak/suruklenebilir.gd (DraggableItem) + gölgeye oturma
  golge_yuvasi.gd            gölge (ShadowSlot): eşyanın görseli + golge.gdshader; filled sinyali
  golge.gdshader             siluet: dokunun saydamlığı + tek düze yarı saydam lacivert renk
  (ipucu eli ortak: ortak/ipucu_eli.gd + ortak/gorseller/el.svg; Büyükten Küçüğe de kullanır)
  geri_dugmesi.gd            basılı tutunca dolan halkalı geri düğmesi
  ilerleme_noktalari.gd      üstteki 10 nokta
  kutlama.gd                 CPUParticles2D yıldız/konfeti efektleri, final
  sesler.gd                  küçük AudioStreamPlayer havuzu
  esya_verisi.gd             ShadowItemData (Resource): texture, group
  bolum_verisi.gd            ShadowLevelData (Resource): items, sky_top, sky_bottom
  esyalar/<kategori>/        her eşya için <ad>.svg + <ad>.tres
  bolumler/bolum_XX.tres     bölümler
  gorseller/                 el, tepeler, bulut, yıldız, ışıltı
  sesler/                    *.wav + ses_uret.py (sesleri yeniden üretir)
```

Ayarlar (`@export`, kök düğümün Inspector'ında): `drop_tolerance`, `grab_padding`, `hint_delay`,
`item_screen_ratio`, `min_item_ratio`, `hold_to_exit`, `drag_scale`, `drag_lift`, `return_time`,
`snap_time`, `celebration_time`, `finale_time`, `shadow_color`.
İlerleme `user://golge_eslestirme.cfg` (`ilerleme/bolum`: şu anki bölüm, 0'dan). Ana menü rozeti buradan okur.

## Bölümler

| Bölüm | Eşyalar |
|---|---|
| 1 | daire, kare, üçgen, yıldız |
| 2 | kalp, hilal, altıgen, dikdörtgen |
| 3 | roket, blok, oyuncak ayı, top |
| 4 | topaç, davul, uçurtma, çıngırak |
| 5 | kedi, balık, fil, zürafa |
| 6 | köpek, kuş, tavşan, kaplumbağa |
| 7 | otobüs, uçak, bisiklet, gemi |
| 8 | araba, helikopter, tren, traktör |
| 9 | oval, roket, tavşan, bisiklet |
| 10 | baklava, oyuncak ayı, fil, helikopter |

Siluet grupları (aynı bölümde birlikte olamaz): `yuvarlak` (daire, oval, top), `dortgen` (kare,
dikdörtgen, blok), `baklava` (baklava, uçurtma), `uzun_arac` (otobüs, tren). Oyun açılırken
`_check_data()` bunu ve boş/tekrarlı eşyaları denetler, sorun varsa Godot çıktısına hata yazar.

## Yeni eşya eklemek

1. `esyalar/<kategori>/yeni.svg` çiz: 256x256, kontur `#4A3B6B` 8 px, yuvarlak birleşimler, doygun renkler,
   **zemin gölgesi yok** (gölgeye dahil olur). Siluetten tanınabilir olsun.
2. Godot içe aktarınca `.import` ayarlarını 2x ölçek + mipmap yap (`svg/scale=2.0`, `mipmaps/generate=true`;
   en kolayı başka bir eşyanın `.svg.import` dosyasındaki `[params]` bölümünü kopyalamak).
3. Aynı klasörde `yeni.tres` oluştur (FileSystem > sağ tık > New Resource > ShadowItemData):
   Texture = yeni.svg, gerekirse Group (siluet başka bir eşyaya çok benziyorsa aynı grup adı).

## Yeni bölüm eklemek

1. `bolumler/bolum_11.tres` oluştur (New Resource > ShadowLevelData), Items dizisine eşyaların `.tres`
   dosyalarını sürükle (genelde 4), gökyüzü renklerini seç.
2. `golge_eslestirme.tscn` kök düğümünde Levels dizisine bu dosyayı ekle.
   Bölüm sayısı değişince ilerleme noktaları da kendiliğinden değişir.

## Sesler

Hepsi `sesler/ses_uret.py` ile (sadece Python standart kütüphanesi) sentezlendi, dış kaynak yok:
`pop` (yakalama), `ding` (doğru), `boing` (yanlış), `bolum_sonu`, `final`. Yeniden üretmek için
`python ses_uret.py`. Ses seviyeleri `sesler.gd` içinde (`VOLUMES`).
