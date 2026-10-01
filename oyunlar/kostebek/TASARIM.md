# Köstebek Vurma — Tasarım

Çukurlardan çıkan köstebeklere ve meyvelere dokunma, bombalardan kaçınma oyunu. 4-8 yaş, okuma gerektirmez:
skor yıldız + sayı, can kalp, seviye yıldız içinde sayı olarak gösterilir.

## Ekran düzeni (dikey, `expand`)

```
┌──────────────────────────────┐
│ (←)     [★ 120]     ❤ ❤ ❤   │  geri (basılı tut), skor, kalpler
│            ★2                │  seviye rozeti
│   ╭─────╮      ╭─────╮       │
│   ╰─────╯      ╰─────╯       │  6 çukur (2x3) — ileri seviyede 9 çukur (3x3)
│   ╭─────╮      ╭─────╮       │
│   ╰─────╯      ╰─────╯       │
│   ╭─────╮      ╭─────╮       │
│   ╰─────╯      ╰─────╯       │
└──────────────────────────────┘
```

Çukur boyu `get_viewport_rect().size`'dan, nesnenin çukurdan taşan yüksekliği dahil hücreye sığacak şekilde
hesaplanır; ızgara alana ortalanır (telefon ve tablet oranında denendi). Arka plan çimenli bahçe.

## Oynanış

- Açılışta 3-2-1 geri sayım (bip sesleri), sonra oyun başlar.
- Köstebek **+30**, meyve/sebze **+10**, bomba **1 can**. Kaçan hiçbir şey için ceza yok.
- Puan alınca nesnenin üstünden "+30" / "+10" yazısı süzülür; köstebek sersemler (sarmal gözler,
  dönen yıldızlar) ve içeri kaçar, meyve zıplayıp parıltıyla kaybolur.
- Bomba: yumuşak "puf" duman bulutu, hafif ekran sarsıntısı, kalp büyüyüp söner. Korkutucu değil.
- **Kasklı köstebek** (3. seviyeden itibaren): ilk dokunuş kaskı kırar (çatlak, parçalar uçar, "tak" sesi,
  puan yok), köstebek şaşkın bakar ve `helmet_extra_time` kadar daha uzun kalır; ikinci ayrı dokunuş +30.
- Canlar bitince: her şey içeri girer, panel açılır: skor, kupa + rekor (yeni rekorsa ışıltı),
  küçük ev (ana menü) ve büyük "tekrar oyna" düğmesi. Tekrar oyna sahneyi yeniden yüklemeden sıfırlar.
- Seviye her `points_per_level` puanda bir artar. Bildirim oyunu durdurmaz: büyük yıldızda seviye numarası
  belirir ve küçük seviye rozetine uçar, kısa melodi. Yeni seviye farklı çukur sayısı isterse yeni çıkış
  durur, çıkanlar inince çukurlar yeni düzende belirir.
- Geri düğmesi 1 sn basılı tutulunca ana menüye döner (hızlı vururken kazara çıkılmasın diye).
  Android geri tuşu / Escape `SahneGecis` üzerinden hemen çalışır.

## Dokunma

Hepsi `kostebek.gd` içindeki `_input`'ta, `InputEventScreenTouch` basış anında. Her parmak ayrı sayılır
(farklı çukurlara aynı anda vurulabilir). Bir basış en fazla bir nesneyi etkiler: dokunulan yerdeki
vurulabilir nesnelerin içinden merkezi en yakın olan. Vurulan nesne hemen vurulamaz olur (inerken tekrar
sayılmaz); kasklı köstebekte kask kırma ve vurma iki ayrı basıştır. Dokunma alanı görünen kısmın
`touch_padding` katı, en az `min_touch_size` piksel. Masaüstünde "Emulate Touch From Mouse" ile fareyle oynanır.

## Katmanlar (çukur)

`cukur.gd`: çukurun arkası (`cukur_arka.svg`) → maske düğümü (`clip_children`; ağız çizgisinin üstü +
ağzın alt yarı elipsi) ve içinde nesne → ön toprak dudağı (`cukur_on.svg`). Nesne ağzın altından yükselir,
alt kısmı dudağın arkasında kalır. Kask parçaları ve duman maskenin dışında, `Effects` katmanında uçar.

## Dosyalar

```
kostebek/
  kostebek.tscn / .gd     ana sahne (MoleGame): durumlar COUNTDOWN / PLAYING / GAME_OVER,
                          dokunma, çukur yerleşimi; sinyal: state_changed
  oyun_durumu.gd          MoleGameState: skor, can, seviye, rekor; sinyaller score_changed, life_lost,
                          level_up, game_over
  denge.gd / denge.tres   MoleBalance: BÜTÜN denge ayarları + seviye dizisi
  seviye_verisi.gd        MoleLevelData: bir seviyenin değerleri
  cikis_yoneticisi.gd     Spawner: ne zaman / nereden / ne çıkacak; sinyal: item_spawned
  cukur.gd                Hole: katmanlar, maske, dokunma alanı; sinyal: emptied
  cikan_nesne.gd          PopUpItem: çıkma / bekleme / inme; sinyaller hit, escaped, finished
  kostebek_nesne.gd       Mole (kask, şaşkın ve sersem yüz, dönen yıldızlar)
  meyve_nesne.gd          Fruit (8 meyve/sebze)
  bomba_nesne.gd          Bomb (titreyen fitil kıvılcımı)
  efektler.gd             yıldız/ışıltı, duman bulutu, kask parçaları, ekran sarsıntısı
  arayuz.gd               skor, seviye rozeti, kalpler, geri sayım, "+30" yazıları, seviye bildirimi, oyun bitti
  arka_plan.gd            çimenli bahçe
  sesler.gd               ortak/ses_havuzu.gd üzerine seslerin listesi ve seviyeleri
  gorseller/              bütün SVG'ler (2x ölçek + mipmap ile içe aktarılır)
  sesler/                 *.wav + ses_uret.py
```

Kök düğümdeki `@export`'lar: `balance` (denge.tres), `hold_to_exit`, `countdown_step`, `bomb_shake`.
Rekor `user://kostebek.cfg` (`[rekor] skor`); ana menü rozeti rekoru gösterir.

## Denge ayarları (`denge.tres`)

Godot'ta `denge.tres`'e çift tıkla, Inspector'da değiştir. Genel değerler:
`mole_points` 30, `fruit_points` 10, `lives` 3, `points_per_level` 150, `helmet_extra_time` 0.8,
`rise_time` 0.22, `hide_time` 0.2, `min_stay_time` 0.85 (görünür kalma süresinin alt sınırı),
`hole_cooldown` 0.6 (boşalan çukurun dinlenmesi), `max_bombs_in_row` 2, `max_bombs_on_screen` 1,
`touch_padding` 1.25, `min_touch_size` 130.

Seviyeler (`levels` dizisi; son seviyeden sonrası son seviye). Kalan olasılık köstebek:

| Sv | stay | aralık (sn) | aynı anda | bomba | kask | meyve | çukur |
|---|---|---|---|---|---|---|---|
| 1 | 1.6 | 1.0–1.5 | 1 | 0.08 | 0 | 0.40 | 6 |
| 2 | 1.45 | 0.9–1.3 | 1 | 0.10 | 0 | 0.40 | 6 |
| 3 | 1.3 | 0.8–1.2 | 2 | 0.12 | 0.15 | 0.38 | 6 |
| 4 | 1.2 | 0.75–1.1 | 2 | 0.13 | 0.22 | 0.36 | 9 |
| 5 | 1.1 | 0.7–1.0 | 2 | 0.14 | 0.28 | 0.35 | 9 |
| 6 | 1.0 | 0.6–0.9 | 3 | 0.16 | 0.33 | 0.34 | 9 |
| 7 | 0.95 | 0.55–0.85 | 3 | 0.17 | 0.38 | 0.33 | 9 |
| 8+ | 0.9 | 0.5–0.8 | 3 | 0.18 | 0.42 | 0.32 | 9 |

Yeni seviye: `levels` dizisine bir öğe ekle (New MoleLevelData). Oyun açılırken `MoleBalance.problems()`
değerleri denetler (olasılık toplamı, aralıklar, çukur sayısı) ve sorun varsa Godot çıktısına hata yazar.

## Görseller

Hepsi elle çizilmiş SVG, diğer oyunlarla aynı stil (koyu kontur, radyal gradyan, beyaz parlama).
Köstebek katmanları (`kostebek`, `yuz_normal` / `yuz_saskin` / `yuz_sersem`, `kask`, `kask_catlak`,
`kask_parca_1..3`) aynı 256x300 tuvalde üst üste oturur; tuvalin y≈254 çizgisi çukurun ağız çizgisidir.
Çukur SVG'leri 320x200, ağız merkezi (160,100). Meyvelerin çoğu Meyve Topla'dan kopya; üzüm yeşile boyandı
(bombayla karışmasın diye koyu mor/siyah meyve yok), havuç ve domates yeni.

## Sesler

`sesler/ses_uret.py` (ortak `ortak/ses/sentez.py` yardımcılarıyla, sadece Python standart kütüphanesi):
`pop` (çıkış), `bonk` (köstebek), `cin` (meyve), `kask` (kırılma), `puf` (bomba, yumuşak), `can`,
`seviye`, `oyun_sonu`, `bip`, `bip_son`. Yeniden üretmek için `python ses_uret.py`.
Ses seviyeleri `sesler.gd` içinde (`VOLUMES`). Havuzda 10 oynatıcı var; aynı ses art arda çalınca kesilmez.
