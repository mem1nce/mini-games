# Manuel QA Kontrol Listesi

Gerçek cihazlarda Godot 4.7.2 release build ile, her test turunda ses açık/efekt-only/sessiz ve Türkçe/İngilizce modları ayrı denenmelidir. Her madde için cihaz, OS, çözünürlük/oran, build numarası ve sonucu kaydedin.

## Mağaza ve gizlilik

- [ ] Android release AAB yalnızca ARM64 içeriyor; paket adı, version name/code ve hedef API doğru.
- [ ] iOS bundle identifier, sürüm, ikonlar, splash ve Info.plist açıklamaları doğru.
- [ ] Final manifestte INTERNET, reklam kimliği, konum, kamera, mikrofon ve depolama izni yok.
- [ ] İmzalama anahtarı, sertifika ve parolalar git deposunda değil; `export_credentials.cfg` ve benzeri dosyalar yok.
- [ ] Play Data Safety, Families, hedef yaş, reklam/IAP ve IARC yanıtları gizlilik metniyle tutarlı.
- [ ] Uygulama içi gizlilik metni ve mağaza gizlilik URL’si erişilebilir.
- [ ] Lisanslar ekranı ebeveyn kapısından açılıyor; Godot, üçüncü taraf, Nunito OFL ve ses atıfları görünür.

## Genel uygulama

- [ ] İlk açılışta yatay yön, splash ve ana menü doğru; varsayılan Godot ikonu/splash görünmüyor.
- [ ] Türkçe ve `--language en` akışında taşan/çevrilmemiş metin yok.
- [ ] Ana menü kartları 16:9, 19.5:9, 20:9, 21:9, 4:3 ve 16:10 oranlarında kesilmiyor.
- [ ] Çentik/kavisli ekran simülasyonunda geri, ses, skor, palet ve kartlar güvenli alanda.
- [ ] Android geri hareketi her oyundan menüye, menüden güvenli çıkışa gidiyor; geçiş sırasında çift geri kilitlemiyor.
- [ ] Lisans ekranında Android geri/Escape menüye dönüyor.
- [ ] Aynı oyuna menüden girip çıkma 50 kez sonra orphan node, açık ses, kalan timer/tween veya sinyal yok.
- [ ] Her oyun ikinci açılışta ilk açılıştaki temiz başlangıç durumuna geliyor; eski geçiş/touch durumu taşınmıyor.
- [ ] Arka plana alma ve geri gelme: ses duruyor, oyun input’u duruyor, dönüşte devam ediyor.
- [ ] Telefon araması, bildirim ve ekran kilidi sonrası uygulama bozulmuyor.
- [ ] Birinci parmak aktifken ikinci parmak/avuç dokunuşu hiçbir oyunu kilitlemiyor.
- [ ] Ekran kapanmaması gereken Müzik Kutusu oturumunda ekran açık kalıyor.
- [ ] Sessiz modda cihaz sessiz davranışı ve başka uygulama müziğiyle ses odaklanması kabul edilebilir.

## Oyun bazlı test

Her satırda: giriş ekranı, ana oynanış, oyun içi geri, oyun sonu/tekrar, arka plan ve çoklu dokunma denenir.

- [ ] Hayvanları Besle — sürükle bırak, yanlış eşleşme, hayvan sesi, bölüm ilerlemesi ve kayıt.
- [ ] Boyama Kitabı — fırça/silgi/damga, galeri, otomatik kayıt, eser silme için ebeveyn kapısı ve bozuk eser.
- [ ] Dondurmacı — tarif/örüntü dokunuşları, renk dışı ayırt edici ipucu ve tekrar başlatma.
- [ ] Balık Tutma — olta sürükleme, balık/çöp etkileşimi, bölüm açılması ve ses.
- [ ] Sihirli Bahçe — tüm dokunma hedefleri, animasyon bitişleri ve kayıt.
- [ ] Müzik Kutusu — her melodi/hayvan, uzun süre açık ekran, ses seviyesi ve arka plana alma.
- [ ] Meyve Topla — can/yanlış nesne/oyun sonu, hareket sınırı ve kayıt.
- [ ] Hafıza — kart aç/kapat, tekrar oynama, tema ilerlemesi ve ses.
- [ ] Gölge Eşleştirme — tek parmak sürükleme, ipucu eli, yanlış hedef ve ilerleme.
- [ ] Yol Yap — bölüm seçimi, sürükleme, tamamlanma ve kayıt.
- [ ] Tren Rayı — bölüm giriş/çıkış, ray yerleştirme, ses döngüleri ve kayıt.
- [ ] Büyükten Küçüğe — üç alt oyunun tamamı, boyut karşılaştırması, ipucu eli ve ilerleme.
- [ ] Robot Fabrikası — parça sürükleme, bölüm durumu, yeniden açma ve ekran oranları.
- [ ] Köstebek — hızlı dokunuş, oyun sonu, ses ve çocuk yaş grubuna uygun içerik.
- [ ] Uçan Kuş — dokunma zamanlaması, engel/oyun sonu, ekran oranları ve tekrar başlatma.
- [ ] Kule Yapma — kule yüksekliği, fizik/animasyon, bölüm kaydı ve geri.
- [ ] Toplama — sayı/şekil dokunuşları, ses ve ilerleme.
- [ ] Araba Yarışı — garaj, pist, duraklat/devam, yıldızlar, araç seçimi ve kayıt.
- [ ] Zıpla Zıpla — zıplama/touch iptali, rekor, tekrar başlatma ve sınırlar.
- [ ] Çıkarma — sayı/simge dokunuşları, ses, ilerleme ve yanlış cevapta ceza olmaması.

## Kayıt ve bozuk veri

- [ ] Her `user://*.cfg` dosyası bozuk metinle değiştirildiğinde uygulama çökmüyor ve varsayılanla açılıyor.
- [ ] Eksik bölüm/anahtar, eski anahtar ve gelecekteki `schema_version` güvenle ele alınıyor.
- [ ] Kayıt sırasında uygulama kapatıldığında eski sağlam kayıt korunuyor.
- [ ] Boyama eserinde yalnızca `eser.cfg`, yalnızca PNG veya yarım klasör varken galeri açılıyor.
- [ ] Uygulama silinip yeniden kurulunca yerel veri davranışı mağaza metniyle uyumlu.

## Görsel ve erişilebilirlik

- [ ] En küçük dokunma hedefi yaklaşık 120 px’den küçük değil.
- [ ] Renk tek bilgi kanalı değil; şekil/simge/desen/ses ile destekleniyor.
- [ ] Düşük parlaklık, renk körlüğü simülasyonu ve grayscale görünümünde seçimler anlaşılır.
- [ ] Okuma bilmeyen çocuk yalnızca simgelerle oyuna girip çıkabiliyor.
- [ ] Kutlama/ses ani yüksek değil; Master limiter ve ses modu doğru.

