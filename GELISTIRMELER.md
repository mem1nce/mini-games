# Geliştirmeler

Uygulamanın geneline dair eksikler ve öneriler. Maddeler önem sırasındadır; bir madde bitince yanına ✅ ve tarih/PR ekleyin. Oyuna özel maddeleri o oyunun sahibi yapar (sahiplik `CLAUDE.md`'de).

---

## Google Play Aileler Politikası ve "Teacher Approved" incelemesi (29 Eylül 2026)

**Kapsam:**
- Bütün kod: `ana_menu/`, `ortak/`, `oyunlar/` altındaki 10 oyun ve `project.godot`.
- Resmi Google Play sayfaları (kaynaklar en altta).

Bu incelemede kod değiştirilmedi.

**Öncelik:**
- 🔴 Yayından önce şart (politika gereği).
- 🟠 Teacher Approved değerlendirmesini doğrudan etkiler.
- 🟡 Kaliteyi ve erişilebilirliği artırır.
- 🟢 İnce ayar.

### Kısa sonuç

- **Kod temiz:** İnternete bağlanan, veri toplayan, dış link açan, reklam ya da satın alma içeren hiçbir şey yok. Data safety formunda "veri toplanmıyor ve paylaşılmıyor" beyan edilebilir.
- **Yayın engeli:** Uygulama içinde gizlilik politikası yok. Play bunu veri toplamayan uygulamalar dahil herkesten istiyor.
- **Android ayarları yok:** Dışa aktarma ayarları henüz kurulmadı. Hedef API 36 ve izinler bu kurulumda halledilmeli.
- **Teacher Approved için en büyük riskler:**
  - Köstebek'teki "vurma", bomba ve oyun sonu.
  - Uçan Kuş ile Meyve Topla'daki can kaybı, oyun sonu ve okuma gerektiren yazılar.
  - Bazı oyunların öğrenmeye katkısının zayıf olması.
  - Seslendirmenin cihazın metinden-sese motoruna bağlı olması.
- **Güçlü yanlar:**
  - Reklamsız, satın almasız, tamamen çevrimdışı.
  - Oyunların çoğunda yazı yok.
  - Sesler yumuşak, görseller tutarlı ve özenli.
  - Dokunma alanları büyük.
  - Çoğu oyunda yanlışa ceza yok.

### Kod taraması: veri, internet, dış bağlantı

Bütün `.gd`, `.tscn`, `.tres` dosyaları ve `project.godot` aşağıdaki API'ler için tarandı.

| Kontrol | Sonuç |
|---|---|
| İnternet (`HTTPRequest`, `HTTPClient`, `StreamPeer*`, `WebSocket*`, `WebRTC`, `ENet`, `MultiplayerPeer`, `UDP/TCP`) | Yok |
| Dış link ya da program açma (`OS.shell_open`, `OS.execute`, `OS.create_process`, `JavaScriptBridge`) | Yok |
| Reklam, uygulama içi satın alma, analiz ya da çökme raporlama SDK'sı, Android eklentisi (`Engine.get_singleton`) | Yok |
| Cihaz kimliği (`OS.get_unique_id`), konum, kamera, mikrofon, pano, titreşim, izin isteme | Yok |
| Kalıcı veri | Sadece `user://` altında yerel ilerleme dosyaları (aşağıda). Kişisel veri yok, cihazdan çıkmıyor. |
| Metinden sese (TTS) | Kullanılmıyor (Toplama ve Çıkarma'daki sesli sayma kaldırıldı). |

İlerleme dosyaları:
- `yol_yap.cfg`, `hafiza.cfg`, `meyve_topla.cfg`: ulaşılan bölüm.
- `golge_eslestirme.cfg`: ulaşılan bölüm.
- `kostebek.cfg`: rekor skor.
- `toplama.cfg`, `cikarma.cfg`: ulaşılan bölüm.
- `araba_yarisi.cfg`: açık pist sayısı, yıldızlar, seçilen renk ve hayvan.

İsim, e-posta, yaş gibi bilgi hiçbir yerde istenmiyor.

### Öncelik sırasına göre maddeler

| # | Öncelik | Konu | Nerede | Kim |
|---|---|---|---|---|
| 1 | 🔴 | Gizlilik politikası (Play Console + uygulama içi) | yeni metin, `ana_menu/` | ortak |
| 2 | 🔴 | Android dışa aktarma: hedef API 36, izinler, AAB | `export_presets.cfg` (yok) | ortak |
| 3 | 🔴 | Play Console beyanları: hedef kitle, Data safety, reklam, IARC, uygulama kaydı | Play Console | ortak |
| 4 | 🟠 | Ebeveyn köşesi ve ebeveyn kapısı | `ana_menu/`, `ortak/` | ortak |
| 5 | 🟠 | Köstebek: vurma, bomba, can ve oyun sonu | `oyunlar/kostebek/` | emirsalihgmrk |
| 6 | 🟠 | Uçan Kuş: can, oyun sonu, puan ve yazılar | `oyunlar/ucan_kus/` | mem1nce |
| 7 | 🟠 | Meyve Topla: kalp kaybı, taş/çürük elma ve yazılar | `oyunlar/meyve_topla/` | mem1nce |
| 8 | 🟠 | Öğrenmeye katkı: refleks oyunlarına öğrenme ekleme | birkaç oyun | sahipler |
| 10 | 🟡 | Tutarlı geri düğmesi | 5 oyun | sahipler |
| 11 | 🟡 | Ana menüde Android geri tuşu uygulamayı hemen kapatıyor | `ortak/sahne_gecis.gd` | ortak |
| 12 | 🟡 | Sadece renge dayalı ayrım (renk körlüğü) | `oyunlar/dondurmaci/` | mem1nce |
| 13 | 🟡 | Uygulama genelinde ses ayarı yok | `ortak/`, ebeveyn köşesi | ortak |
| 14 | 🟡 | Gerçek Android cihazda test | hepsi | ortak |
| 15 | 🟡 | Mağaza sayfası (açıklama, ekran görüntüleri) | Play Console | ortak |
| 16 | 🟢 | Okumayı gerektiren küçük yazılar | ana menü, kutlama yazıları | ortak + sahipler |
| 17 | 🟢 | Test ve betikler pakete girmesin | dışa aktarma filtresi | ortak |

---

#### 1. 🔴 Gizlilik politikası: Play Console'da ve uygulamanın içinde

**Sorun:** Uygulamada gizlilik politikası yok.

**Kaynak:**
- Kullanıcı Verileri politikası: *"All apps must post a privacy policy link in the designated field within Play Console, and a privacy policy link or text within the app itself."*
- Aynı politika: *"Apps that do not access any personal and sensitive user data must still submit a privacy policy."*
- Aileler Politikası da, çocuğa yönelik uygulamanın veri uygulamalarını doğru anlatan bir gizlilik politikası olmasını istiyor.

**Öneri:**
- Kısa, sade bir metin yaz. İçeriği:
  - Veri toplanmaz, internet kullanılmaz.
  - Reklam ve satın alma yoktur.
  - İlerleme sadece cihazda saklanır ve uygulama silinince silinir.
  - Sesli sayma cihazın metinden-sese özelliğini kullanır.
  - İletişim e-postası.
- Metni bir web adresinde yayınla (ör. GitHub Pages) ve Play Console'a o adresi gir.
- Uygulama içinde link değil **metin olarak** göster (madde 4'teki ebeveyn köşesinde). Böylece internet ya da dış link gerekmez.
- Metin, madde 3'teki Data safety beyanıyla birebir uyuşmalı.

#### 2. 🔴 Android dışa aktarma: hedef API 36, izinler, AAB

**Sorun:** Projede `export_presets.cfg` yok, Android ayarları hiç yapılmamış.

**Kaynak:** 31 Ağustos 2026'dan beri yeni uygulamalar ve güncellemeler **Android 16 (API 36)** hedeflemek zorunda (1 Kasım 2026'ya kadar uzatma istenebiliyor).

**Öneri:**
- Godot 4.7.2 Android şablonunun hedef SDK'sına bak. 36 değilse Gradle derlemesini açıp `target_sdk` değerini 36 yap.
- **Bütün izinleri kapalı tut.** Uygulamanın hiçbir izne ihtiyacı yok (internet de gerekmez).
- Mağazaya imzalı **release AAB** yükle. Godot'nun debug derlemeleri uzaktan hata ayıklama için internet izni ekleyebilir.
- Derlemeden sonra son manifesti doğrula. `aapt2 dump permissions <apk>` ya da Play Console'daki "App bundle explorer" ile:
  - `INTERNET`, `AD_ID` ya da konum izni olmadığını kontrol et.
  - Politika, yalnızca çocuklara yönelik uygulamaların API 33+ hedeflerken `AD_ID` istememesini şart koşuyor.
- Play Console'un derleme uyarılarını (ör. 16 KB bellek sayfası desteği) yükleme sırasında kontrol et.

#### 3. 🔴 Play Console beyanları

Bunlar yayınlamadan önce doldurulmak zorunda:

- **Hedef kitle ve içerik:**
  - Yaş grupları olarak **"5 ve altı"** ile **"6-8"** seçilmeli. Gölge Eşleştirme 1-3 yaşa göre tasarlandı, diğer oyunlar 4-8.
  - Teacher Approved ölçütü içeriğin **en küçük hedef yaş grubuna** uygun olmasını istiyor. Yani Köstebek ve Uçan Kuş da "5 ve altı" ölçüsüyle değerlendirilir (madde 5-7).
- **Data safety:** "Veri toplanmıyor, paylaşılmıyor". Şu anki kodla doğru.
- **Reklam içeriyor mu:** Hayır.
- **İçerik derecelendirme (IARC) anketi:** Köstebek'teki vurma ve bomba temaları "çizgi film şiddeti" sorusuna evet dedirtebilir (madde 5).
- **Uygulama kaydı ve geliştirici doğrulaması:** 15 Temmuz 2026 duyurusuna göre Play uygulamalarının Play Console'a kaydedilmesi gerekiyor. Hesap sahibinin yapacağı bir iş.
- **Teacher Approved:** Aileler Politikası'na uyan uygulamalar değerlendirmeye katılmayı seçebiliyor, ama programa alınma garanti değil.

#### 4. 🟠 Ebeveyn köşesi ve ebeveyn kapısı

**Sorun:** Uygulamada yetişkinlere yönelik hiçbir alan yok. Madde 1 (gizlilik metni) ve madde 13 (ses) için bir yer gerekiyor.

**Öneri:** Ana menüde küçük, göze batmayan bir "ebeveyn" simgesi. Açmak için yetişkinin çözebileceği bir kapı olsun: birkaç saniye basılı tutma ve üstüne basit bir işlem ya da işaretleri sırayla seçme. İçinde:
- Gizlilik metni.
- Ses aç/kapat.
- Oyunların ilerlemesini sıfırlama.
- Emeği geçenler (`CREDITS.md`).
- Kısa bir "bu uygulamada ne öğrenilir" açıklaması.

**Not:** Ebeveyn kapısını resmi politika metninde zorunluluk olarak doğrulayamadım. Ama ileride dış link, "bizi değerlendirin" ya da satın alma gibi bir şey eklenirse, bunları yetişkin kapısının arkasına koymak çocuk uygulamalarında yerleşik bir uygulama. Kapı şimdiden hazır olursa sonra kolaylık olur.

#### 5. 🟠 Köstebek: vurma, bomba, can ve oyun sonu (sahibi emirsalihgmrk)

**Sorun:**
- Oyunun adı ve mekaniği bir hayvana "vurmak". Kasklı köstebeğin kaskı çatlayıp parçalanıyor, köstebeğin "sersem" yüzü var.
- Fitili yanan bir **bomba** var ve 1 can götürüyor.
- 3 can bitince "oyun bitti" ekranı çıkıyor, skor ve rekor gösteriliyor.

**Kaynak:** Teacher Approved ölçütü: *"Avoid inappropriate crude language or humor, sexual or provocative content, violent or scary content"*. Ayrıca içerik en küçük yaş grubuna göre değerlendiriliyor. Can ve oyun sonu, projenin kendi kuralıyla da ("Yanlış cevapta ceza yok") çelişiyor.

**Öneri:**
- "Vurmak" yerine "dokun, selamla ya da gıdıkla" teması: köstebek kıkırdayıp saklanır, kask yerine şapka uçar.
- Bomba yerine zararsız bir nesne: ör. dokununca "puf" diye kaçan uykulu bir kirpi. Ceza yerine sadece puan gelmez.
- Can ve oyun sonu yerine süreli ya da sınırsız tur, sonunda kutlama.
- Rekor ekranı yerine toplanan yıldızlar ve kutlama.

Bu maddeler arkadaşının oyunu olduğu için sadece raporlandı, dosyalarına dokunulmadı.

#### 6. 🟠 Uçan Kuş: can, oyun sonu, puan ve yazılar (sahibi mem1nce)

**Sorun:**
- 3 can, direğe çarpınca can kaybı ve oyun bitti ekranı var.
- Zamanlamaya dayalı "zıpla ve geç" oynanışı 4-5 yaş için çabuk hayal kırıklığı yaratıyor.
- Ekrandaki "Uçan Kuş", "Başlamak için dokun", "Puan: N" ve "Tekrar oyna" okumayı gerektiriyor.

**Öneri:**
- Can ve oyun sonunu kaldır: kuş direğe değince yumuşakça sekip devam etsin.
- Puan yerine toplanan yıldız göster.
- Yazıları simge ve animasyonla değiştir: dokunan el, tekrar oku, oynat simgesi.
- İstersen iki zorluk: "sakin" (varsayılan, geniş aralık) ve "hızlı".

#### 7. 🟠 Meyve Topla: kalp kaybı, taş/çürük elma ve yazılar (sahibi mem1nce)

**Sorun:**
- Çürük elma ya da taş kalp götürüyor, kirpi "sersemliyor", kalpler bitince bölüm baştan başlıyor.
- Başlangıçta "Başlamak için dokun" ve "Bölüm N" yazıları var.

**Öneri:**
- Kalp sistemini kaldır ya da kötü nesneyi sadece kısa bir yavaşlamaya çevir. Proje kuralı "ceza yok" diyor.
- Taş yerine zararsız ve komik bir nesne kullan.
- Yazıları simge ve sesle değiştir: bölüm numarası yerine ilerleme yıldızları.

#### 8. 🟠 Öğrenmeye katkı

**Kaynak:** Teacher Approved ölçütü: *"Support healthy development, with or without a focus on education, including creativity and imagination"*.

**Durum:**
- Öğrenme odağı belirgin olan oyunlar:
  - Toplama ve Çıkarma: sayılar ve işlemler.
  - Hafıza: görsel bellek.
  - Gölge Eşleştirme: şekil tanıma.
  - Yol Yap: problem çözme, uzamsal düşünme.
  - Dondurmacı: sıralama ve eşleştirme.
- Uçan Kuş, Köstebek, Meyve Topla ve Araba Yarışı ağırlıkla refleks ve el-göz koordinasyonu.

**Öneri:** Refleks oyunlarına hafif öğrenme katmanları:
- Araba Yarışı: podyumda yıldızları sesli say, garajda renk ve hayvan adlarını seslendir, pist haritasında temaları (orman, çöl, kar, şehir) anlatan kısa sesler.
- Meyve Topla: meyve adlarını seslendir, hedef meyve bölümlerinde "3 elma topla" gibi sayma.
- Köstebek: çıkan meyve ve sebzelerin adları.
- Uçan Kuş: renkli halkalardan geçerek renk tanıma.
- Mağaza açıklamasında her oyunun neyi desteklediğini yaz (madde 15).

#### 10. 🟡 Tutarlı geri düğmesi

**Sorun:** İki farklı geri düğmesi davranışı var:
- Dokununca çalışan: Uçan Kuş, Dondurmacı, Yol Yap, Hafıza, Meyve Topla.
- Basılı tutunca çalışan (`ortak/basili_geri_dugmesi.gd`): Gölge Eşleştirme, Köstebek, Toplama, Çıkarma, Araba Yarışı.

Aynı simgenin oyundan oyuna farklı davranması çocuğun kafasını karıştırır. Teacher Approved de arayüzün kolay anlaşılmasını istiyor.

**Öneri:** Birini seç ve bütün oyunlara uygula. Öneri basılı-tut: kazara çıkışı önlüyor ve dolan halka ne yapılacağını gösteriyor. Kararı `CLAUDE.md`'ye kural olarak yaz.

#### 11. 🟡 Ana menüde Android geri tuşu uygulamayı hemen kapatıyor

**Sorun:** `ortak/sahne_gecis.gd` içindeki `geri()`, ana menüdeyken `get_tree().quit()` çağırıyor. Küçük çocuk geri tuşuna kazara basınca uygulama kapanıyor.

**Öneri:** Ana menüde tek basışı yok say. Çıkış için iki basış ya da kısa bir bekleme iste, ya da çıkışı ebeveyn köşesine taşı.

#### 12. 🟡 Sadece renge dayalı ayrım (sahibi mem1nce)

**Sorun:** Dondurmacı'daki 6 tat topu sadece renkle ayırt ediliyor: şekil, nokta ve yüz hepsinde aynı. Renk körlüğü olan çocuklar limon, fıstık ve vanilyayı ya da çilekle yaban mersinini karıştırabilir.

**Öneri:** Her topun üstüne küçük bir işaret ekle: çilek, limon dilimi, fıstık, çikolata parçası, yaban mersini, vanilya çubuğu. Yeni oyunlarda da bilgiyi sadece renkle vermemeye dikkat et.

#### 13. 🟡 Uygulama genelinde ses ayarı yok

**Sorun:** Anne-baba sesi kapatamıyor. Toplama ve Çıkarma'da sadece seslendirme düğmesi var.

**Öneri:** Ebeveyn köşesine (madde 4) "ses açık/kapalı" ekle. Ayarı `user://` içinde sakla. Seçenek:
- Bütün sesleri kapatmak için `AudioServer` ana veriyolunu kısmak.
- Ya da efekt ve seslendirme için iki ayrı veriyolu.

#### 14. 🟡 Gerçek Android cihazda test

**Sorun:** Hiçbir oyun henüz gerçek bir telefonda denenmedi. Teacher Approved kaliteyi değerlendirirken hata ve takılmalar puan kırdırır.

**Kontrol et:**
- Düşük ve orta seviye bir telefonda akıcılık (hedef 60 FPS).
- Çentik ve yuvarlak köşeli ekranlar.
- Farklı en-boy oranları.
- Dikey-yatay geçişleri.
- Uygulama arka plana gidip gelince ses ve duraklatma.
- Uzun oturumda bellek.

#### 15. 🟡 Mağaza sayfası

- **Açıklama:**
  - Kısa ve dürüst olsun.
  - Her oyunun ne öğrettiğini söylesin.
  - "Reklamsız, satın almasız, internetsiz çalışır" bilgisini içersin.
- **Ekran görüntüleri:** Gerçek oyun ekranlarından alınmalı. Testlerdeki ekran görüntüsü betikleri kullanılabilir.
- **Uyum:** Play, mağaza görsellerinin çocuklara yönelik izlenimi ile hedef kitle beyanının uyuşup uyuşmadığına bakıyor. Bizde ikisi de çocuk, sorun yok. Yine de görseller içerikle birebir aynı olmalı.

#### 16. 🟢 Okumayı gerektiren küçük yazılar

- **Ana menü:** Kartlarda oyunların adı yazıyor. Okuma bilmeyen çocuk için karta dokunulunca adın seslendirilmesi iyi olur.
- **Kutlama yazıları:** Hafıza, Yol Yap ve Meyve Topla'daki "Harika!", "Süper!", "Tebrikler!" yazıları yanında sesli de söylenebilir.

#### 17. 🟢 Test ve betikler pakete girmesin

**Sorun:** `oyunlar/*/testler/` klasörlerindeki test script'leri Godot kaynağı olduğu için Android paketine girer. Zararsız ama gereksiz.

**Öneri:** Dışa aktarma ayarında hariç tutma filtresi ekle: `oyunlar/*/testler/*, *.py`. `.py` ses ve görsel üreticileri zaten kaynak değil.

---

**Kaynaklar** (29 Eylül 2026'da okundu):
- [Google Play Aileler Politikaları](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
- [Aileler uygulamalarında veri uygulamaları](https://support.google.com/googleplay/android-developer/answer/11043825?hl=en)
- [Kullanıcı Verileri politikası (gizlilik politikası şartı)](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Hedef kitle ve içerik ayarları](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en)
- [Teacher Approved programı](https://google.play/business/programs/teacherapproved/)
- [Hedef API seviyesi şartları](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [Politika duyurusu: 15 Temmuz 2026](https://support.google.com/googleplay/android-developer/answer/17134731?hl=en-GB)
