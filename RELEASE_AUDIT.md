# Minik Oyunlar — Yayın Öncesi Denetim Raporu

**Tarih:** 2 Ekim 2026  
**Kapsam:** Godot 4.7 Mobile projesi, `ana_menu/`, `ortak/`, `oyunlar/`, proje ayarları, lisans belgeleri ve test betikleri.  
**Durum:** Bu rapor hazırlanırken kaynak kodu, proje ayarları ve varlıklar değiştirilmedi. Yalnızca bu rapor ve istenen mağaza/gizlilik taslakları eklendi. Düzeltme commit'i henüz atılmadı; kullanıcı onayından sonra atılmalı.

## Yönetici özeti

| Önem | Bulgu sayısı | Kısa sonuç |
|---|---:|---|
| Kritik | 4 | Mağazaya yüklemeyi engelleyen export/gizlilik hazırlığı ve veri dayanıklılığı eksikleri var. |
| Önemli | 9 | Ebeveyn kapısı kapsamı, mobil yaşam döngüsü, erişilebilirlik ve doğrulanmamış gerçek cihaz davranışları tamamlanmalı. |
| Küçük | 7 | Paket temizliği, performans ölçümü, belge/isim ve bakım iyileştirmeleri. |

**Yayın kararı: HAZIR DEĞİL.** Kodun çevrimdışı ve veri toplamayan olması güçlü bir temel; ancak Android/iOS export profilleri, mağaza gizlilik beyanları, kalıcı kayıtların güvenli yazımı ve gerçek cihaz doğrulaması tamamlanmadan paket yayınlanmamalı.

## Kritik bulgular

### K-1 — Export profili yok

- **Kanıt:** [export_presets.cfg](C:/Users/emirs/Desktop/mini-games/export_presets.cfg) bulunmuyor; proje yalnızca [project.godot](C:/Users/emirs/Desktop/mini-games/project.godot) ile geliyor.
- **Risk:** Paket adı, sürüm/kod, hedef API, 64-bit mimari, AAB, imza, adaptive icon, iOS bundle ve izinler mağazaya yüklenmeden doğrulanamaz.
- **Öneri:** Kullanılan Godot 4.7.2 export şablonuyla Android release AAB ve iOS export preset’leri oluşturulsun. Android hedef API mağazanın güncel gereksinimine göre ayarlansın (bu tarih için API 36 doğrulanmalı), ARM64 açık olsun, izinler kapalı kalsın ve final manifest `aapt2`/Play App Bundle Explorer ile kontrol edilsin. iOS Info.plist açıklamaları yalnızca gerçekten kullanılan özellikler için bırakılmalı.
- **Onay sonrası grup:** Export ve imzalama hazırlığı.

### K-2 — Uygulama içi ve mağaza için doğrulanabilir gizlilik metni yok

- **Kanıt:** Projede uygulama içi gizlilik metni/ebeveyn ayarları ekranı bulunamadı. Mevcut Lisanslar ekranı [ana_menu/lisanslar.gd](C:/Users/emirs/Desktop/mini-games/ana_menu/lisanslar.gd) içinde lisansları gösteriyor; gizlilik politikasını göstermiyor.
- **Risk:** Çocuk uygulamalarında veri toplanmasa bile mağaza gizlilik politikası alanı ve uygulama içinde erişilebilir açıklama beklenir.
- **Öneri:** [PRIVACY_POLICY_DRAFT.md](C:/Users/emirs/Desktop/mini-games/PRIVACY_POLICY_DRAFT.md) hukuki incelemeden geçirilsin; erişilebilir bir ebeveyn ekranına Türkçe/İngilizce metin eklensin ve mağaza URL’si yayınlanmadan önce doldurulsun.
- **Not:** Taslakta bugün doğrulanan “ağ yok, reklam/analitik yok, kişisel veri yok, ilerleme yalnızca cihazda” kapsamı yazılmıştır.

### K-3 — Kayıtlar sürümsüz ve atomik değil

- **Kanıt:** Oyun kayıtları ve ayarlar [oyunlar/](C:/Users/emirs/Desktop/mini-games/oyunlar/) altında doğrudan `ConfigFile.save(...)` ile `.cfg` dosyasına yazılıyor; `version` alanı ve geçici dosyaya yazıp yeniden adlandırma yok. Boyama eserleri [oyunlar/boyama_kitabi/eser_deposu.gd](C:/Users/emirs/Desktop/mini-games/oyunlar/boyama_kitabi/eser_deposu.gd) içinde doğrudan klasör dosyalarına yazılıyor.
- **Risk:** Uygulama kapanırken yarım kalan yazım bozuk kayıt üretebilir; gelecek sürümlerde eski format güvenli biçimde dönüştürülemez.
- **Öneri:** Ortak sürümleme/atomik yazma yardımcı bileşeni tasarlansın. Her dosyada `schema_version` bulunsun; okuma `OK` değilse bozuk/eksik veriyi varsayılanla açsın ve hatayı görünür biçimde kayda alsın. `*.tmp` yazılıp başarıyla kapatıldıktan sonra platforma uygun atomik yeniden adlandırma yapılsın. Boyama için `eser.cfg`, `firca.png`, `kucuk.png` birlikte güvenli commit mantığıyla ele alınmalı.
- **Onay sonrası grup:** Kayıt migrasyonu ve bozuk kayıt testleri.

### K-4 — Runtime ve export doğrulaması tamamlanamıyor

- **Kanıt:** Ortamda `godot`/`godot4` çalıştırıcısı bulunamadı; bu nedenle sahne yükleme, GDScript uyarıları, otomatik testler, orphan node ve ekran görüntüsü testleri çalıştırılamadı.
- **Risk:** Derleme/runtime hataları ve mağaza cihazı davranışları raporlanmadan kalır.
- **Öneri:** Godot 4.7.2 kurulumu olan bir makinede aşağıdaki test planı çalıştırılmalı; sonuçlar bu rapora eklenmeden yayın yapılmamalı.

## Önemli bulgular

### Ö-1 — Ebeveyn kapısı yalnızca Lisanslar ekranında

- **Kanıt:** Ana menüdeki bilgi düğmesi [ana_menu/ana_menu.gd](C:/Users/emirs/Desktop/mini-games/ana_menu/ana_menu.gd) içinde 3 saniye basılı tutma ile Lisanslar’ı açıyor; [ortak/basili_geri_dugmesi.gd](C:/Users/emirs/Desktop/mini-games/ortak/basili_geri_dugmesi.gd) ortak uzun basma davranışını sağlıyor.
- **Eksik:** Ses ayarı ana menüde doğrudan erişilebilir. Boyama Galerisi’nde eser silme gibi geri alınamaz işlem için ebeveyn kapısı doğrulanmadı. Gelecekte dış bağlantı, satın alma, ayar veya paylaşım eklenirse bunlar için merkezi kapı yok.
- **Öneri:** `ParentGate` ortak bileşeni eklenmeli; önerilen metinsiz yöntem iki parmakla 3 saniye basılı tutma veya yetişkinin çözebileceği görsel çarpma sorusu. Ses ayarı, silme ve tüm dışa çıkan işlemler bu bileşenle korunmalı. Silme işlemi ayrıca ikinci onay ve mümkünse geri alma sağlamalı.

### Ö-2 — Uygulama yaşam döngüsü Boyama Kitabı’nda eksik

- **Kanıt:** [ortak/ses_yoneticisi.gd](C:/Users/emirs/Desktop/mini-games/ortak/ses_yoneticisi.gd) uygulama duraklatılınca sesleri duraklatıyor; ancak [oyunlar/boyama_kitabi/boyama_kitabi.gd](C:/Users/emirs/Desktop/mini-games/oyunlar/boyama_kitabi/boyama_kitabi.gd) içinde `NOTIFICATION_APPLICATION_PAUSED` için otomatik kayıt bulunamadı.
- **Risk:** Telefon araması/bildirim/arka plana alma sırasında son çizimler kaybolabilir. Her oyunun “devam ederken duraklatma” davranışı da gerçek cihazda doğrulanmamış.
- **Öneri:** Boyama ekranında pause/quit öncesi idempotent otomatik kayıt; oyunlarda ortak pause politikası; dönüşte input ve tween durumunun güvenli devamı. Android ve iOS’ta çağrı/bildirim senaryoları test edilmeli.

### Ö-3 — Android geri davranışı kodda var, cihazda doğrulanmadı

- **Kanıt:** [project.godot](C:/Users/emirs/Desktop/mini-games/project.godot) `config/quit_on_go_back=false`; [ortak/sahne_gecis.gd](C:/Users/emirs/Desktop/mini-games/ortak/sahne_gecis.gd) `NOTIFICATION_WM_GO_BACK_REQUEST` ve Escape’i yönetiyor.
- **Risk:** Sahne geçişi/Android gesture entegrasyonu yalnızca kod incelemesiyle garanti edilemez.
- **Öneri:** Gerçek Android’de her oyunda geri → menü, menüde geri → güvenli çıkış; lisans ekranında geri → menü; hızlı ardışık geri ve geçiş sırasında geri senaryoları test edilmeli.

### Ö-4 — Güvenli alan testi kısmi

- **Kanıt:** [ortak/ekran_yardimcisi.gd](C:/Users/emirs/Desktop/mini-games/ortak/ekran_yardimcisi.gd) güvenli alan yardımcılarını ve [ortak/testler/ekran_uyumu_testi.gd](C:/Users/emirs/Desktop/mini-games/ortak/testler/ekran_uyumu_testi.gd) 16:9–21:9, 4:3, 16:10 ve çentik senaryolarını tanımlıyor.
- **Risk:** Test çalıştırılamadığı için bütün oyunların iç ekranlarında taşma/kesilme sonucu yok.
- **Öneri:** Testi 7 oran ve çentik seçeneğiyle çalıştır; `ADIMLAR` her oyunun önemli iç ekranlarını kapsıyor mu kontrol et; PNG’leri elle incele. Özellikle geri, skor, palet, oyun sonu ve galeri düğmelerini kontrol et.

### Ö-5 — Çoklu dokunma ve avuç içi davranışı doğrulanmadı

- **Kanıt:** Ortak sürükleme bileşeni tek parmak kilidi uyguluyor; oyunların kendi input yöneticileri farklı.
- **Risk:** İkinci parmak/avuç dokunuşu oyunu kilitleyebilir veya geri düğmesiyle oyun input’unu çakıştırabilir.
- **Öneri:** Her oyunda birinci parmak aktifken rastgele ikinci `ScreenTouch`, iptal edilen touch ve parmak sırası senaryolarını test et; ortak davranışa taşınabilecek korumaları belirle.

### Ö-6 — Ses seviyesi/limiter ölçümü tamamlanmadı

- **Kanıt:** [default_bus_layout.tres](C:/Users/emirs/Desktop/mini-games/default_bus_layout.tres) ve [ortak/ses_yoneticisi.gd](C:/Users/emirs/Desktop/mini-games/ortak/ses_yoneticisi.gd) Muzik/Efekt yollarını yönetiyor; Müzik Kutusu kendi bus’ına limiter ekliyor.
- **Risk:** Tüm Master yolu için limiter olup olmadığı ve 201 WAV/42 OGG arasında ani yüksek ses bulunup bulunmadığı otomatik olarak ölçülmedi.
- **Öneri:** Master’a güvenli tavanlı limiter ekle; tüm sesleri LUFS/peak ile ölç; kısa efektlerin tepe değerlerini düşür ve müzik/efekt ayarını ebeveyn ekranında ayrı kontrol edilebilir yap. Mevcut UI yalnızca üç mod sunuyor: tümü, yalnız efekt, sessiz.

### Ö-7 — Paket içeriği filtrelenmemiş

- **Kanıt:** Export preset yok; repoda 32 Python betiği, `testler/` sahneleri/betikleri ve kaynak varlık klasörleri bulunuyor.
- **Risk:** Python üretim betikleri, test içeriği, `RELEASE_AUDIT.md` ve lisans kanıtlarının runtime pakete girip girmediği kontrol edilemez.
- **Öneri:** Export filtreleri oluştur; release paketini açıp içerik manifestini incele. Runtime için gereken lisans metinleri kalsın; üretim kaynakları/testler/dokümanlar hariç tutulsun. `ortak/fontlar/OFL.txt` ve uygulama içi lisans metinleri paketlenmeli.

### Ö-8 — Renkle tek başına ayrım riski

- **Kanıt:** Menü kategorileri simge + renk kullanıyor; bazı oyunlarda görsel seçim/palet davranışları renk ağırlıklı.
- **Risk:** Renk görme farklılıkları olan çocuklar bazı seçenekleri ayırt edemeyebilir.
- **Öneri:** Rengi her zaman şekil, desen, simge veya konumla destekle; Boyama paletinde renk örneğine ek olarak desen/ikon ve sesli geri bildirim kullan. Her oyunun gerçek cihaz ekranında düşük doygunluk/grayscale kontrolü yap.

### Ö-9 — Okuma gerektirmeyen akış tüm ekranlarda kanıtlanmadı

- **Kanıt:** Oyunların çoğu görsel; ana menü kategori/ad metinleri ve bazı kutlama/yardım metinleri içeriyor.
- **Risk:** 4–8 yaş grubunun küçük yazıları okuyamaması durumunda giriş/çıkış ve kategori keşfi zorlaşabilir.
- **Öneri:** Her oyun için simgeli giriş/geri/yardım akışı; metin yalnızca destekleyici olsun. Metin boyutu, kontrast ve İngilizce fallback gerçek cihazda gözle kontrol edilsin.

## Küçük bulgular

### KÜ-1 — En büyük paket girdileri

Kaynak dosya boyutlarına göre ilk 20 dosya çoğunlukla müzik ve WAV efektleridir. En büyükleri: `muzik_ucan_kus.ogg` (1.224 MB), `muzik_yol_yap.ogg` (0.995 MB), `muzik_meyve_topla.ogg` (0.853 MB), `muzik_hafiza.ogg` (0.391 MB), `muzik_dondurmaci.ogg` (0.386 MB), `muzik_menu.ogg` (0.368 MB), birkaç ~0.278 MB `final.wav`, Nunito.ttf (0.264 MB) ve Boyama Kitabı PNG’leri. Toplam kaynak boyutu/runtime export boyutu aynı değildir; import sonrası ölçüm yapılmalı.

### KÜ-2 — Ses formatı politikası ölçümle doğrulanmalı

Müzikler OGG, kısa efektlerin çoğu WAV. Uzun WAV olup olmadığı, örnekleme oranları ve import sıkıştırması otomatik süre/bitrate raporuyla doğrulanmalı.

### KÜ-3 — Kare hızı/pil profili yok

Proje Mobile renderer kullanıyor; ancak proje ayarında sabit 60 FPS veya menüde düşük işlem politikası kanıtlanmadı. `_process` kullanan çok sayıda animasyon ve çizim bulunuyor. 60 FPS cihaz profili, düşük pil ve uzun süreli Müzik Kutusu testi yapılmalı.

### KÜ-4 — Kullanılmayan dosya analizi çalıştırılmadı

Godot resource dependency scan çalışmadığı için kullanılmayan sahne/script/asset listesi güvenilir biçimde üretilemedi. Silme yapılmamalı; Godot import/resource scan sonrasında aday liste çıkarılıp kullanıcı onayı alınmalı.

### KÜ-5 — Marka/isim hukuki araması insan kararı gerektiriyor

Proje belgeleri varlıkların özgün/CC0/OFL olduğunu ve lisans denetiminin geçtiğini gösteriyor. Buna rağmen uygulama adı ve mağaza adı benzerlikleri, sınıf/oyun adlarının ticari marka kapsamı ve mağaza araması hukuki/insan doğrulamasıdır.

### KÜ-6 — Godot lisans ekranı kapsamı iyi ama paket testi gerekli

Lisans ekranı `Engine.get_license_text()`, `get_copyright_info()` ve `get_license_info()` kullanıyor; Nunito OFL ve ses atıfları da gösteriliyor. Release export’ta ekranın açıldığı ve tüm uzun metinlerin yüklenebildiği test edilmeli.

### KÜ-7 — Uygulama simgesi ve splash kaynakta özelleştirilmiş, export bağlantısı doğrulanmadı

`project.godot` özgün `icon.svg` kullanıyor ve Godot varsayılan splash görseli kapalı. Android adaptive icon katmanlarının ve iOS icon set’inin export preset olmadığı için gerçekten bağlandığı doğrulanamaz.

## Olumlu doğrulamalar

- [lisans_denetle.py](C:/Users/emirs/Desktop/mini-games/lisans_denetle.py) çalıştırıldı: **3279 dosyada sorun yok**.
- `CREDITS.md`, [LISANSLAR.md](C:/Users/emirs/Desktop/mini-games/LISANSLAR.md), [LISANS_KANITLARI.md](C:/Users/emirs/Desktop/mini-games/LISANS_KANITLARI.md) ve [ortak/sesler/SESLER.md](C:/Users/emirs/Desktop/mini-games/ortak/sesler/SESLER.md) mevcut.
- Kod taramasında reklam, analitik, crash SDK’sı, IAP, `HTTPRequest`, `HTTPClient`, `StreamPeer`, WebSocket/ENet, `OS.shell_open`, cihaz kimliği, kamera, mikrofon veya konum API’si bulunmadı.
- Kalıcı yazımlar `user://` altındaki ilerleme/ayar/yerel Boyama Kitabı eserleriyle sınırlı görünüyor; kişisel bilgi alınmıyor.
- `config/quit_on_go_back=false`, yatay 1280×720 canvas ve `canvas_items`/`expand` ayarları mevcut.
- Bilgi/Lisanslar ekranı 3 saniyelik uzun basma ile korunuyor; mevcut lisans testi bu kapıyı hedefliyor.

## Kayıt envanteri

| Kayıt | İçerik |
|---|---|
| `user://ana_menu.cfg` | Yeni rozeti/menü ilerleme durumu |
| `user://ses_ayari.cfg` | Ses modu |
| `user://<oyun>.cfg` | Oyunlara göre bölüm, rekor, ayar veya ilerleme: `yol_yap`, `hafiza`, `meyve_topla`, `golge_eslestirme`, `kostebek`, `toplama`, `cikarma`, `araba_yarisi`, `buyukten_kucuge`, `hayvan_besle`, `balik_tutma`, `kule_yapma`, `sihirli_bahce`, `robot_fabrikasi`, `tren_rayi`, `zipla_zipla` |
| `user://boyama_kitabi/<eser>/` | `eser.cfg`, `firca.png`, `kucuk.png` |

## Test durumu

Projede **31** `*test*.gd` betiği bulundu. Bunlar menü/lisans, oyun mantığı, üreticiler, ekran görüntüsü, ses ve ekran uyumu senaryolarını kapsıyor. Godot executable olmadığı için hiçbiri bu denetim sırasında çalıştırılamadı. Çalıştırılacak asgari komutlar:

```text
godot --path . --headless --fixed-fps 60 -s res://ana_menu/testler/menu_testi.gd
godot --path . --headless --fixed-fps 60 -s res://ana_menu/testler/lisans_testi.gd
godot --path . --fixed-fps 60 -s res://ortak/testler/ekran_uyumu_testi.gd -- <çıktı-klasörü> centik
```

Her oyun klasöründeki `testler/` betikleri de Godot 4.7.2 ile tek tek çalıştırılmalı. Orphan node, sinyal, tween ve timer sayımı henüz runtime kanıtı değildir; geçiş döngüsü için en az 50 kez menü → oyun → geri, ardından orphan ve ses kontrolü yapılmalı.

## Kullanıcının kararını gerektirenler

1. Uygulama adı/İngilizce mağaza adı ve marka benzerliği için hukuki/mağaza araması.
2. Gizlilik politikasının hukuki incelemesi ve yayınlanacak iletişim e-postası/URL.
3. Android Play Console geliştirici hesabı, hedef API ve imzalama anahtarının güvenli saklanması.
4. iOS geliştirici hesabı, bundle identifier, sertifika/provisioning ve gerçek cihaz.
5. Yaş hedefi, içerik derecelendirmesi ve Google Play Families/Data Safety beyanları.
6. Köstebek/bomba/vurma gibi içeriklerin çocuk mağazası politikalarına uygunluğu.
7. Gerçek cihaz matrisi: Android/iOS, 16:9, 19.5:9, 20:9, 4:3, çentik, düşük donanım, çağrı/bildirim.

## Önerilen onay sonrası commit grupları

1. `gizlilik ve ebeveyn kapısı`
2. `kayıt sürümleme ve atomik yazma`
3. `uygulama yaşam döngüsü ve ses ayarları`
4. `android ios export presetleri`
5. `erişilebilirlik ve ekran uyumu`
6. `performans paketleme ve yayın testleri`

