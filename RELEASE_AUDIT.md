# Minik Oyunlar — Yayın Öncesi Kalan İşler

**Güncelleme:** 2 Ekim 2026
**Durum:** Kodla yapılabilecek düzeltmeler uygulandı. Bu dosyada yalnızca geliştirici dışında, yayıncı/ebeveyn/hukuk danışmanı tarafından yapılması gereken işler bırakılmıştır.

## Kullanıcının yapması gerekenler

### 1. Gerçek cihaz ve Godot doğrulaması

Bu ortamda Godot 4.7.2 çalıştırıcısı bulunmadığı için aşağıdaki testleri Godot kurulu bir bilgisayarda çalıştırın:

- [MANUAL_QA_CHECKLIST.md](C:/Users/emirs/Desktop/mini-games/MANUAL_QA_CHECKLIST.md) içindeki genel ve 20 oyunluk kontrol listesini tamamlayın.
- Android ve iOS gerçek cihazlarda geri hareketi, arka plana alma, çağrı/bildirim, çoklu dokunma, çentik/güvenli alan ve ekran kapanması senaryolarını deneyin.
- 16:9, 19.5:9, 20:9, 21:9, 4:3 ve 16:10 ekran görüntülerini inceleyin.
- Godot test betiklerini ve `ortak/testler/ekran_uyumu_testi.gd` testini çalıştırın.
- Bozuk/eksik kayıt dosyalarıyla açılış ve güncelleme davranışını deneyin.

### 2. Android ve iOS mağaza ayarları

- Godot 4.7.2 ile Android release export profili oluşturun.
- Paket adı, version name/code, hedef API, ARM64, AAB ve özgün adaptive icon katmanlarını ayarlayın.
- iOS bundle identifier, sürüm, ikonlar, splash ve gerekli Info.plist açıklamalarını ayarlayın.
- Keystore, sertifika, provisioning profile ve parolaları git dışında güvenli yerde tutun.
- Final AAB/IPA manifestini kontrol edin; uygulamanın ihtiyaç duymadığı internet, reklam kimliği, konum, kamera, mikrofon ve depolama izinlerini eklemeyin.
- Release paketini açıp Python betikleri, testler, ham kaynaklar ve gereksiz belgelerin runtime paketine girmediğini kontrol edin. Uygulama içi lisans metinleri ve gerekli OFL metni kalmalıdır.

### 3. Hukuk ve mağaza beyanları

- [PRIVACY_POLICY_DRAFT.md](C:/Users/emirs/Desktop/mini-games/PRIVACY_POLICY_DRAFT.md) içindeki yayıncı adı, e-posta, tarih ve URL alanlarını doldurun.
- Gizlilik politikasını KVKK, GDPR, COPPA, Google Play Families ve Apple Kids konusunda hukuk danışmanına inceletin.
- Gizlilik politikasını herkese açık HTTPS adresinde yayınlayın ve Play Console/App Store alanlarına girin.
- Google Play Data Safety, hedef kitle, Families, reklam/IAP, IARC ve içerik derecelendirmesi formlarını mevcut davranışla tutarlı doldurun.
- Apple Kids kategorisi ve yaş derecelendirmesi beyanlarını doldurun.
- “Minik Oyunlar” ve “Bouncy Zoo: Kids Games 4-8” adları için mağaza ve marka benzerliği araması yapın.
- Köstebek, bomba/vurma ve oyun sonu gibi içeriklerin hedef yaş ve mağaza politikalarına uygunluğunu değerlendirin.

### 4. Mağaza içeriği

- [STORE_LISTING_DRAFT.md](C:/Users/emirs/Desktop/mini-games/STORE_LISTING_DRAFT.md) metinlerini gerçek özelliklerle karşılaştırıp son haline getirin.
- Her oyundan debug öğesi olmayan mağaza ekran görüntüleri alın.
- Gizlilik URL’si, destek URL’si, yayıncı adı, yaş grubu ve iletişim bilgilerini mağaza sayfasına ekleyin.

## Tamamlanan teknik işler

- Tüm üretim `ConfigFile` kayıt yazımları [ortak/guvenli_kayit.gd](C:/Users/emirs/Desktop/mini-games/ortak/guvenli_kayit.gd) üzerinden geçici dosya + yeniden adlandırma akışına taşındı.
- Kayıtlara `meta/schema_version=1` alanı eklendi.
- Kayıt yolu `user://` ile sınırlandırıldı.
- Ebeveyn-korumalı Lisanslar ekranına Türkçe/İngilizce gizlilik özeti eklendi.
- Boyama ekranının arka plana alma/kapanma sırasında otomatik kayıt davranışı mevcut kodda doğrulandı; gereksiz tekrar uygulanmadı.
- Lisans denetimi son değişikliklerden sonra başarılı çalıştırıldı; Godot runtime doğrulaması bu ortamda yapılamadı.

## Kodla çözülemeyen veya dış doğrulama isteyen konular

- Godot kurulumu ve gerçek cihaz testleri
- Android/iOS geliştirici hesapları ve mağaza başvuruları
- İmzalama anahtarı, sertifika ve provisioning işlemleri
- Hukuki inceleme ve gizlilik politikası onayı
- Mağaza/marka araması ve içerik derecelendirmesi
- Final AAB/IPA manifest ve paket boyutu incelemesi
