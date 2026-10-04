# Lisans ve gizlilik kayıtlarının tutarlılık denetimi. Proje kökünden:  python lisans_denetle.py
# Yalnızca Python standart kütüphanesi gerekir. Sorun bulursa hepsini listeler ve çıkış kodu 1 olur.
# Yayından önce ve dışarıdan bir varlık (ses, yazı tipi, görsel) eklendiğinde çalıştır.
#
# Denetledikleri:
#   1. ortak/sesler/ içindeki her ses SESLER.md'de yazılı (ve tersi)
#   2. SESLER.md'deki her kaynak paketin bağlantısı ve lisansı var; lisans CC0 ya da "bize ait"
#   3. Oyunların sesler/ klasöründeki her ses ya o klasörün ses_uret.py betiğinde üretiliyor ya da kaynak/ içinde
#   4. kaynak/ içindeki her özgün kayıt bir CREDITS.md'de ve LISANS_KANITLARI.md'de yazılı
#   5. Her kaynak paketin sayfası LISANS_KANITLARI.md'de, yapanı Lisanslar ekranında (lisans_metinleri.gd)
#   6. Her yazı tipinin yanında lisans dosyası var
#   7. SVG'lerde dış kaynak izi yok (çizim programı imzası, gömülü resim, yazı tipi adı)
#   8. Dosya adlarında, kodda ve çeviri tablosunda (ceviriler.csv) bilinen oyun / marka adı yok
#   9. Kodda ağ bağlantısı, reklam, analiz ya da izin gerektiren özellik yok (gizlilik politikasıyla uyum)
#  10. Kayıtlar yalnızca user:// içine yazılıyor (geliştirici araçları hariç)

import os
import re
import subprocess
import sys

KOK = os.path.dirname(os.path.abspath(__file__))
SES_UZANTILARI = (".ogg", ".wav", ".mp3")
UYGUN_LISANSLAR = ("CC0", "bize ait")
MARKALAR = ("flappy", "lego", "whack", "mario", "nintendo", "pokemon", "pikachu", "disney", "pixar", "minecraft",
            "angry bird", "angrybird", "tetris", "sonic", "mcqueen", "wall-e", "bb-8", "bb8", "r2d2", "r2-d2",
            "peppa", "paw patrol", "minion", "spongebob", "barbie", "hello kitty", "toca boca", "candy crush",
            "fruit ninja", "doodle jump", "subway surf", "cocomelon", "baby shark", "bluey",
            # oyuncak ve çocuk markaları, Türk çocuk çizgi filmleri, dondurma markası
            "jenga", "brio", "duplo", "playmobil", "hot wheels", "crayola", "play-doh", "tamagotchi", "pepee",
            "niloya", "rafadan", "kral şakir", "algida",
            # "memory" Ravensburger'in tescilli markası (eşleştirme kartı oyunu); oyun adında kullanılmaz
            "memory")
AG_VE_IZIN = ("HTTPRequest", "HTTPClient", "WebSocketPeer", "StreamPeerTCP", "PacketPeerUDP", "ENetConnection",
              "ENetMultiplayerPeer", "WebRTC", "TCPServer", "UDPServer", "UPNP", "JavaScriptBridge", "shell_open",
              "vibrate_handheld", "AudioStreamMicrophone", "AudioEffectRecord", "AudioEffectCapture", "CameraFeed",
              "CameraServer", "get_unique_id", "request_permission", "get_system_dir", "admob", "firebase",
              "analytics", "crashlytics")
# Çalışırken değil, geliştirirken kullanılan ve proje klasörüne yazan araçlar
GELISTIRICI_ARACLARI = ("oyunlar/boyama_kitabi/sayfalar/derle.gd",)
# Bu dosyalar marka adlarını ve yasak sözcükleri bilerek anar (inceleme raporu, kanıtlar, bu betik)
RAPOR_DOSYALARI = ("LISANSLAR.md", "LISANS_KANITLARI.md", "lisans_denetle.py")

sorunlar = []


def sorun(metin):
    sorunlar.append(metin)


def oku(yol):
    with open(os.path.join(KOK, yol), encoding="utf-8", errors="ignore") as f:
        return f.read()


def dosyalar():
    """Git'in izlediği ve henüz eklenmemiş (yok sayılmayan) dosyalar; git yoksa klasör taraması"""
    try:
        cikti = subprocess.run(["git", "ls-files", "-co", "--exclude-standard"], cwd=KOK, capture_output=True,
                               text=True, encoding="utf-8", check=True).stdout
        liste = [d for d in cikti.splitlines() if d and os.path.exists(os.path.join(KOK, d))]
    except Exception:  # noqa: BLE001
        liste = []
        for kok, klasorler, adlar in os.walk(KOK):
            klasorler[:] = [k for k in klasorler if k not in (".git", ".godot", "__pycache__", "android")]
            for ad in adlar:
                liste.append(os.path.relpath(os.path.join(kok, ad), KOK).replace(os.sep, "/"))
    return sorted(liste)


def sade(metin):
    return re.sub(r"[^a-z0-9]", "", metin.lower())


def tablo_satirlari(metin, baslik):
    """Markdown'da verilen başlığın altındaki tablonun satırları (hücre listeleri)"""
    bolum = metin.split(baslik, 1)
    if len(bolum) < 2:
        return []
    satirlar = []
    for satir in bolum[1].split("\n## ")[0].splitlines():
        if satir.startswith("|") and not set(satir) <= set("|-: "):
            satirlar.append([h.strip() for h in satir.strip().strip("|").split("|")])
    return satirlar[1:]      # ilk satır sütun başlıkları


def denetle():
    hepsi = dosyalar()
    sesler_md = oku("ortak/sesler/SESLER.md")
    kanitlar = oku("LISANS_KANITLARI.md")
    ekran = sade(oku("ana_menu/lisans_metinleri.gd"))
    credits = "\n".join(oku(d) for d in hepsi if d.endswith("CREDITS.md"))

    # 1. ortak sesler <-> SESLER.md
    ortak = sorted(os.path.basename(d) for d in hepsi if d.startswith("ortak/sesler/") and d.endswith(SES_UZANTILARI))
    yazili = sorted(s[0] for s in tablo_satirlari(sesler_md, "## Dosyalar"))
    for ad in ortak:
        if ad not in yazili:
            sorun("ortak/sesler/%s SESLER.md'de yazılı değil" % ad)
    for ad in yazili:
        if ad not in ortak:
            sorun("SESLER.md'de yazılı %s dosyası ortak/sesler/ içinde yok" % ad)

    # 2 ve 5. kaynak paketler
    paketler = tablo_satirlari(sesler_md, "## Kaynak paketler")
    paket_adlari = [p[0] for p in paketler]
    for kisa, paket, yapan, sayfa, lisans in paketler:
        if not any(lisans.startswith(u) for u in UYGUN_LISANSLAR):
            sorun("SESLER.md: '%s' paketinin lisansı uygun değil: %s" % (kisa, lisans))
        if lisans.startswith("bize ait"):
            continue
        if not sayfa.startswith("http"):
            sorun("SESLER.md: '%s' paketinin kaynak bağlantısı yok" % kisa)
        elif sayfa not in kanitlar:
            sorun("LISANS_KANITLARI.md'de '%s' paketinin sayfası yok: %s" % (kisa, sayfa))
        if sade(yapan) not in ekran:
            sorun("Lisanslar ekranında (lisans_metinleri.gd) '%s' adı geçmiyor (paket: %s)" % (yapan, kisa))
    for satir in tablo_satirlari(sesler_md, "## Dosyalar"):
        if satir[1] not in paket_adlari:
            sorun("SESLER.md: %s dosyasının paketi '%s' kaynak paketler tablosunda yok" % (satir[0], satir[1]))

    # 3 ve 4. oyun sesleri
    for d in hepsi:
        if not (d.startswith("oyunlar/") and d.endswith(SES_UZANTILARI)):
            continue
        klasor, ad = os.path.split(d)
        if klasor.endswith("/kaynak"):
            if ad not in credits:
                sorun("%s hiçbir CREDITS.md'de yazılı değil" % d)
            if ad not in kanitlar:
                sorun("%s LISANS_KANITLARI.md'de yazılı değil" % d)
            continue
        betik = klasor + "/ses_uret.py"
        if betik not in hepsi:
            sorun("%s: bu klasörde üretim betiği (ses_uret.py) yok, sesin kaynağı belirsiz" % d)
            continue
        govde = os.path.splitext(ad)[0]
        kok_ad = re.sub(r"_?\d+$", "", govde)
        if govde not in oku(betik) and kok_ad not in oku(betik):
            sorun("%s: %s içinde üretilmiyor, sesin kaynağı belirsiz" % (d, betik))

    # 6. yazı tipleri
    for d in hepsi:
        if d.lower().endswith((".ttf", ".otf", ".woff", ".woff2")):
            klasor = os.path.dirname(d)
            if not any(os.path.dirname(x) == klasor and re.search(r"(OFL|LICENSE|LICENCE)", os.path.basename(x), re.I)
                       for x in hepsi):
                sorun("%s: yanında lisans dosyası yok (ör. OFL.txt)" % d)

    # 7. SVG'lerde dış kaynak izi
    iz = re.compile(r"inkscape|sodipodi|illustrator|adobe|figma|freepik|flaticon|svgrepo|fontawesome|font awesome|"
                    r"noun ?project|shutterstock|<metadata|<image|data:image|font-family|<text", re.I)
    for d in hepsi:
        if d.endswith(".svg"):
            m = iz.search(oku(d))
            if m:
                sorun("%s: dış kaynak izi olabilir ('%s')" % (d, m.group(0)))

    # 8. marka adları (dosya adları ve metin dosyaları)
    metin_uzantilari = (".gd", ".tscn", ".tres", ".godot", ".md", ".py", ".cfg", ".json", ".csv")
    for d in hepsi:
        if d in RAPOR_DOSYALARI or d.endswith("OFL.txt"):
            continue
        ad = d.lower()
        icerik = oku(d).lower() if d.endswith(metin_uzantilari) else ""
        for marka in MARKALAR:
            if marka in ad:
                sorun("%s: dosya adında marka / oyun adı ('%s')" % (d, marka))
            elif re.search(r"(?<![a-z0-9çğıöşü])%s(?![a-z0-9çğıöşü])" % re.escape(marka), icerik):
                sorun("%s: içinde marka / oyun adı geçiyor ('%s')" % (d, marka))

    # 9 ve 10. ağ, izin ve kayıt yerleri (testler ve geliştirici araçları hariç)
    yazma = re.compile(r"(FileAccess\.open\(|\.save\(|save_png\(|save_jpg\(|make_dir_recursive_absolute\(|"
                       r"remove_absolute\()")
    for d in hepsi:
        if not d.endswith(".gd") or "/testler/" in d or d in GELISTIRICI_ARACLARI:
            continue
        icerik = oku(d)
        for sozcuk in AG_VE_IZIN:
            if re.search(r"(?<![A-Za-z_])%s(?![A-Za-z_])" % re.escape(sozcuk), icerik, re.I if sozcuk.islower() else 0):
                sorun("%s: gizlilik politikasıyla çelişebilir ('%s')" % (d, sozcuk))
        if "globalize_path" in icerik or re.search(r'"([A-Za-z]:[\\/]|file://)', icerik):
            sorun("%s: user:// dışında bir yola erişiyor olabilir" % d)
        if yazma.search(icerik) and "user://" not in icerik:
            sorun("%s: dosya yazıyor ama user:// yolu görünmüyor" % d)
    if "addons" in {d.split("/")[0] for d in hepsi}:
        sorun("addons/ klasörü var: eklentilerin lisansı ve izinleri elle incelenmeli")
    if "export_presets.cfg" in hepsi:
        ayar = oku("export_presets.cfg")
        for izin in re.findall(r"permissions/(\w+)=true", ayar):
            sorun("export_presets.cfg: Android izni açık: %s (gizlilik politikası hiçbir izin istenmediğini söylüyor)" % izin)

    return len(hepsi)


if __name__ == "__main__":
    sayi = denetle()
    if sorunlar:
        print("%d sorun bulundu:" % len(sorunlar))
        for s in sorunlar:
            print("  - " + s)
        sys.exit(1)
    print("Lisans denetimi: sorun yok (%d dosya tarandı)" % sayi)
