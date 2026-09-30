# Kule Yapma (Hayvan Apartmanı) — Tasarım

Tek dokunuşla apartman katı bırakıp kule yapma. 4-8 yaş, **dikey** ekran (720x1280, `expand`), yazı yok
(sadece "Mükemmel!" ve kutlamada tek kelime). Can, süre, ceza yok; kule asla yıkılmaz.
**Fizik motoru yok**: düşme, oturma, mıknatıs, sallanma hep Tween ve basit hesapla (her seferinde aynı sonuç).

## Ekran

```
┌──────────────────────────┐
│ [←]                 [⏸] │
│ ═══════╤═════════════════│  vinç kolu (ekrana sabit), ortada makara
│        │                 │
│      ┌─┴─┐   ←→ sallanır │  halatta asılı kat (sarkaç)
│      └───┘               │
│                     ┃▓┃  │  sağ kenar: kule simgesi + dolan çubuk (hedef)
│      ╔═══╗   🐼          │
│      ║▢ ▢║   (katlar)    │
│      ╚═══╝               │
│ ~~~~ zemin kat, çimen ~~ │
└──────────────────────────┘
```

## Oynanış

- Kat, vincin halatında sarkaç gibi sallanır (ileride biraz da yukarı aşağı). Ekranın herhangi bir yerine dokununca
  bırakılır ve dimdik aşağı düşer (yerçekimi gibi hızlanan tween).
- Kulenin üstüne kısmen denk gelirse (**mıknatıs**: |kayma| ≤ tolerans × genişlik) yumuşakça ortaya kayar, oturur,
  esner-zıplar, toz çıkar; kuleye bir hayvan ailesi taşınır (pencerede belirir, el sallar).
- Tam ortaysa (küçük bir pay) "Mükemmel!", parıltı ve ışık halkası; art arda mükemmeller kombo (daha çok yıldız,
  daha büyük halka).
- Iskalarsa kulenin yanından yere düşer, sevimlice zıplar ve "puf" diye kaybolur; yenisi gelir.
- Kule yükseldikçe tabanından hafifçe sallanır (görsel). Kamera kulenin tepesini yumuşakça izler.
- Son kat hep çatı katıdır; hedefe varınca kutlama: kule aşağıdan yukarı ışıklarla yanar, bütün hayvanlar el sallar,
  konfeti, "Harika!" / "Süper!" / "Tebrikler!". Sonra "apartmanım" ya da "devam" (bir süre sonra kendiliğinden devam).

## Katlar ve hayvanlar

11 kat tasarımı (tuğla, ahşap, pembe sıva, mavi sıva, çiçekli balkon, yuvarlak pencereli, tenteli, taş, sarmaşık,
çizgili, yıldızlı) + özel zemin kat ve çatı katı. Katın iki katmanı var: pencere içleri (arka) ve delikli duvar +
çerçeveler (ön); hayvan ikisinin arasında durur, pencereden görünür. Hayvanlar hafıza oyunundan kopya.

## Manzara (yüksekliğe göre)

Köy ve tepeler → şehir çatıları → bulutlar ve kuşlar → sıcak hava balonları → gün batımı → yıldızlar, ay, uzay.
Gökyüzü rengi kule yüksekliğine göre yumuşakça değişir; süsler kendi yüksekliklerinde, paralaksla kayar.
Sürprizler: kuş sürüsü geçer, balon yanından süzülür, ay göz kırpar gibi parlar.

## Bölümler (`bolumler.gd`)

Bölüm: `hedef` (kat, çatı dahil), `hiz` (sallanma hızı), `genislik` (sallanma açısı), `dikey` (yukarı aşağı oynama),
`tolerans` (mıknatıs), `tema` (zemin ve kat renkleri). 12 bölüm: 5 → 20 kat, hız ve açı çok yavaş artar,
7. bölümden sonra dikey oynama. 12'den sonra "Ne kadar yükseğe?" sonsuz modu: hedef yok, rekor kaydedilir.

## Apartmanlar

Her biten kule `user://kule_yapma.cfg`'ye kaydedilir (katlar + hayvanlar). Giriş ekranında "apartmanlarım" galerisi;
apartman görünümünde kule yukarı aşağı kaydırılır, pencereye dokununca hayvan küçük bir şey yapar
(uyur, yemek yapar, dans eder, kitap okur, çiçek sular).

## Dosyalar

```
kule_yapma/
  kule_yapma.tscn / .gd   ana sahne: ekranlar (giriş, oyun, galeri, apartman), düğmeler, akış, dokunma
  bolumler.gd             bölüm verileri ve sonsuz mod ayarı
  vinc.gd                 vinç, makara, halat, sarkaç, kat asma ve bırakma
  blok.gd                 tek kat: katmanlar, hayvan, el sallama, ışıklar, hayvanın küçük işleri
  kule.gd                 kule: katlar, oturma/mıknatıs/ıska hesabı, sallanma, kutlama ışıkları
  kamera.gd               kulenin tepesini yumuşak izleyen kamera
  manzara.gd              yüksekliğe göre gökyüzü, katman süsleri, sürprizler
  apartman.gd             apartman görünümü (kaydırma, pencereye dokunma)
  galeri.gd               apartmanlarım galerisi
  kayit.gd                ilerleme, rekor, apartmanlar
  efektler.gd / sesler.gd
  gorseller/ (svg_uret.py)  sesler/ (ses_uret.py)  testler/
```

Kayıt `user://kule_yapma.cfg`: `[ilerleme] bolum`, `rekor`; `[apartmanlar] liste`.
