# Kule Yapma (Hayvan Apartmanı) — Tasarım

Tek dokunuşla apartman katı bırakıp kule yapma. 4-8 yaş, **dikey** ekran (720x1280, `expand`), yazı yok
(sadece "Mükemmel!", kutlamada tek kelime ve sonuçtaki kat sayısı). Gerçek zorluk var, kaybetmek yumuşak ve komik:
bölüm başına 3 kalp, süre yok.
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
- Alttaki katın ortasına çok yakın bırakılırsa (**mıknatıs**: kat genişliğinin %15'i, ileride %5'i) ortaya kayar;
  daha uzaksa bırakıldığı yerde kaymış olarak oturur ve kuleyi o yana eğer. Oturunca esner-zıplar, toz çıkar,
  kata bir hayvan ailesi taşınır (pencerede belirir, el sallar).
- Katın ağırlık merkezi alttaki katın kenarının dışındaysa kat kenarda yana yatarak devrilir, yere düşüp zıplar,
  "puf" diye kaybolur: 1 kalp gider.
- Eğim (en üst katın zemine göre kayması) biriktikçe kule o yana yatar ve daha çok sallanır; bölümün eğim sınırı
  aşılırsa en üstteki 1-2 kat devrilir: 1 kalp gider.
- Tam ortaysa (küçük bir pay) "Mükemmel!", parıltı ve ışık halkası, eğim biraz düzelir; art arda mükemmeller kombo;
  art arda 3 mükemmel 1 kalp geri verir (en fazla 3).
- Kalpler bitince kule yumuşakça sallanıp yıkılır, katlar zıplayarak dağılır, hayvanlar şemsiye ve balonlarla
  süzülerek yere iner; ulaşılan kat sayısı kutlanır ve büyük "tekrar dene" çıkar. Hedefe ulaşmadan sonraki bölüme
  geçilmez.
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

Bölüm: `hedef` (kat, çatı dahil), `hiz` (sallanma hızı), `aci` (sallanma açısı), `dikey` (yukarı aşağı oynama),
`miknatis` (0.15 → 0.05), `egim_siniri` (1.0 → 0.55), `kalp` (3), `tema` (zemin). 12 bölüm: 5 → 20 kat; ilk ikisi kolay
(yavaş vinç, geniş mıknatıs), sonra zorluk kademeli artar, 7. bölümden sonra dikey oynama. 12'den sonra "Ne kadar yükseğe?" sonsuz modu: hedef yok, rekor kaydedilir.

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
  kule.gd                 kule: katlar, yerleştirme kararı (mıknatıs/kaymış/devril), eğim, sallanma, kutlama ışıkları
  kamera.gd               kulenin tepesini yumuşak izleyen kamera
  manzara.gd              yüksekliğe göre gökyüzü, katman süsleri, sürprizler
  apartman.gd             apartman görünümü (kaydırma, pencereye dokunma)
  galeri.gd               apartmanlarım galerisi
  kayit.gd                ilerleme, rekor, apartmanlar
  efektler.gd / sesler.gd
  gorseller/ (svg_uret.py)  sesler/ (ses_uret.py)  testler/
```

Kayıt `user://kule_yapma.cfg`: `[ilerleme] bolum`, `rekor`; `[apartmanlar] liste`.
