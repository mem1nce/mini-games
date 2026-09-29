# Araba Yarışı — Tasarım

Yandan görünen, tombul oyuncak arabalarla sakin ve neşeli bir yarış. 4-8 yaş, okuma gerektirmez.
**Yatay** ekran (1280x720, `expand`). Tek kontrol: ekrana basılı tut = hızlan, bırak = yumuşakça yavaşla.
Araba devrilmez, yoldan çıkmaz, kaza yapmaz; ceza yok.

## Ekranlar ve akış

```
GARAJ (giriş) ──▶ HARİTA ──▶ YARIŞ ──▶ PODYUM ──▶ sonraki pist (YARIŞ) / tekrar (YARIŞ)
   ◀── ana menü     ◀── garaj    ◀── harita   ◀── harita
```

- **Garaj**: ortada döner platformda araba, solda 6 renk, sağda 8 şoför hayvan; altta büyük "oynat" oku.
  Seçim anında arabaya uygulanır (boya sıçraması / hayvan zıplayarak oturur) ve kaydedilir.
- **Harita**: 4 tema bölgesi (orman, çöl, kar, gece şehri) yan yana; 8 pist düğmesi noktalı bir yolla bağlı.
  Açılmamış pistler gri ve kilitli; sıradaki pist nabız gibi atar, arabamız onun yanında durur.
  Bitirilen pistlerin altında toplanan en iyi yıldız sayısı.
- **Yarış**: 3-2-1 ışıkları (kırmızı, kırmızı, yeşil; yazı yok) → yarış → bitiş çizgisi → kısa kutlama → podyum.
  2 sn dokunulmazsa ekranda basılı tutan bir el simgesi belirir.
- **Podyum**: 2-1-3 dizilişli basamaklar, arabalar üstünde neşeyle zıplar, konfeti. Çocuk kaçıncı olursa
  olsun kutlama olur ve sonraki pist açılır. Üstte toplanan yıldızlar tek tek sayılır.
  Sağda büyük "sonraki pist" oku, solda küçük "tekrar" düğmesi.
- **Duraklat** (sağ üst): oyun durur, büyük "devam" ve küçük "tekrar" düğmesi.
- **Geri** (sol üst, her ekranda): ortak `basili_geri_dugmesi.gd` (basılı tutunca dolan halka) — yarışta çocuk
  ekrana sürekli bastığı için kazara çıkışı önler. Düğmelerde başlayan dokunuş gaz sayılmaz.

## Hareket (fizik motoru yok)

- Yol bir `Curve2D`: pist parçalarından (düz, tepe, yokuş...) sık noktalarla üretilir; x hep artar.
- Arabanın durumu yol boyunca uzaklık `s` ve hız. Arka ve ön tekerleğin temas noktaları eğriden
  (`s ∓ dingil/2`) okunur; araba ikisinin ortasına oturur, açısı ikisini birleştiren doğrudur.
  Böylece tepelerde doğal olarak eğilir.
- Gaz: hedef hız = azami hız; bırakınca hedef 0, yumuşak yavaşlama. Yokuş yukarı biraz yavaşlatır, aşağı biraz hızlandırır.
- Tekerlekler hıza göre döner. Gövde bir yay-sönümleyici ile yaylanır: hızlanınca arkaya, yavaşlayınca
  öne yatar; kasis, iniş ve eğim değişiminde zıplar.
- **Rampa**: yol üstünde kama. Tekerlekler rampanın yüksekliğini de okur (araba rampaya tırmanırken burnu kalkar).
  Ön tekerlek rampa ucuna gelince zıplama başlar: yatay hız sabit, dikey hareket iki parçalı parabol
  (çıkışta normal, inişte daha hafif yerçekimi = süzülme). Konum başlangıçtan geçen süreyle hesaplanır
  (kare hızından bağımsız). Yere değince yaylanma + toz.
  Zıplama yüksekliği hıza bağlı (en az %45): havadaki yıldızlar, gaza basarak gelindiğinde alınacak yükseklikte.
- **Su birikintisi**: kısa süre yavaşlatır, su sıçrar, araba hafifçe sallanır. **Kasis**: küçük hoplama + "boing".
  Rakipler de aynı etkileri yaşar (ceza değil, komik efekt).
- **Şeritler**: yol yukarıdan hafif görünen bir bant. Çocuğun arabası öndeki şeritte, rakipler arkadaki iki
  şeritte (biraz küçük ve yukarıda) — yan görünümde üst üste binmezler. Yıldızlar çocuğun şeridinde.

## Rakipler (rubber band)

`rakip_zekasi.gd` her kare her rakibin hedef hızını belirler:
- Taban hız rakibe ve piste göre (%80-90).
- Rakip çocuğun önündeyse aradaki mesafeyle yavaşlar (çok öndeyse %40'a kadar); gerideyse hızlanır (en çok %104).
- Son %20'de rakip hızı %97 ile sınırlı: gaza basan çocuk öndeyse önde kalır.
- Hafif, yavaş dalgalanma (rakipler robot gibi görünmesin).
Rakiplerin rengi ve şoförü çocuğun seçtiklerinden farklıdır.

## Pistler (`pistler.gd`)

8 pist, 4 tema × 2. Her pist sıralı **parçalar** listesi; yeni pist = listeye bir sözlük:

```gdscript
{"theme": "orman", "rivals": 0.84, "pieces": [
	{"type": "flat", "len": 1600, "stars": 3},
	{"type": "hill", "len": 1800, "h": 90, "stars": 4},   # h < 0 ise çukur
	{"type": "slope", "len": 1200, "h": -60},             # yokuş (aşağı)
	{"type": "puddle"}, {"type": "bump"},
	{"type": "ramp", "size": 1, "stars": 3},              # havadaki yıldızlar
	...
]}
```

- Rampadan sonra iniş için düz alan otomatik eklenir. Bitiş çizgisi sonda.
- `validate()`: her pistin süresi (~60-90 sn), rampa iniş alanları ve öğe çakışmaları kontrol edilir
  (oyun açılırken ve testte çalışır).
- Zorluk çok yavaş artar: 1-2 orman (düz, kısa, 1-2 küçük rampa), 3-4 çöl (tepeler), 5-6 kar
  (büyük rampa), 7-8 gece şehri (daha çok rampa ve tepe).

## Görseller (SVG, `gorseller/`)

- Araba: tombul, yuvarlak hatlı, büyük tekerlekli; yüzü/gözü yok. Her renk için ayrı gövde SVG'si
  (yumuşak gradyan, parlama, koyu dış çizgi) + ortak cam, iç kabin, tekerlek. Şoför kabinin cam şekline
  kırpılır (`clip_children`): baş ve omuzlar camdan görünür, önünde küçük direksiyon.
- Şoförler: hafıza oyununun 8 hayvanı (`gorseller/hayvanlar/` içine kopya; oyunlar birbirine bağımlı değil).
- Paralaks: her tema için 3 döşenebilir katman (uzak, orta, yakın) — `gorseller/arka_plan_uret.py` ile üretilir
  (sınırlı, uyumlu paletler) + yol kenarı süsleri (çalı, ağaç, kaktüs, kar çamı, sokak lambası).
- Tema efektleri hafif: orman uçuşan yapraklar, çöl sıcak güneş ışığı ve toz zerreleri, kar yumuşak kar,
  gece şehri yanan pencereler, sokak lambaları ve yıldızlar.

## His ve kamera

- Kamera yumuşak takip (üstel), hız arttıkça ileri bakar, zıplamada hafif uzaklaşır.
- Egzozdan gazla orantılı duman; yıldızda parıltı + zıplayan "+1"; su sıçraması; inişte toz; bitişte konfeti.
- Üstte ilerleme çubuğu: üç arabanın küçük simgeleri bitiş bayrağına ilerler; yanında yıldız sayısı.
- Tween'ler yumuşak (SINE/BACK/ELASTIC), parçacıklar `CPUParticles2D`, 60 FPS hedefi.
- Sesler `sesler/ses_uret.py` ile sentezlenir (ortak `ortak/ses/sentez.py`): hıza göre perdesi değişen
  motor, yıldız, su, kasis, zıplama, iniş, geri sayım, bitiş, podyum, düğme.

## Dosyalar

```
araba_yarisi/
  araba_yarisi.tscn / .gd   ana sahne: ekranlar arası akış, yarış durumu, dokunma, kayıt
  pistler.gd                tema ve pist verileri + validate()
  pist.gd                   pist yükleyici: parçalardan Curve2D, yol/rampa/engel/yıldız/süs, sorgular
  araba.gd                  araba hareketi: eğri, rampa zıplaması, engeller, yaylanma
  araba_gorunum.gd          araba görünümü (gövde rengi, şoför, tekerlek) — garaj, harita, podyum da kullanır
  rakip_zekasi.gd           rakiplerin hedef hızı (rubber band)
  kamera.gd                 takip, ileri bakış, zıplamada uzaklaşma
  arka_plan.gd              gökyüzü, paralaks katmanlar, tema efektleri
  efektler.gd               parçacıklar ve açılır "+1"
  arayuz.gd                 yarış arayüzü: ilerleme, yıldız, geri/duraklat, geri sayım, duraklatma
  garaj.gd / harita.gd / podyum.gd   diğer ekranlar
  sesler.gd                 ses havuzu + motor sesi
  gorseller/  sesler/  testler/
```

Kayıt `user://araba_yarisi.cfg`: `[ilerleme] acik` (açık pist sayısı), `[yildiz] pist_N` (en iyi),
`[garaj] renk, hayvan`.
