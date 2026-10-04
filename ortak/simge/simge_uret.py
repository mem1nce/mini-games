# Bouncy Zoo uygulama simgesini üretir. Proje kökünden:  python ortak/simge/simge_uret.py
#
# Trambolinde zıplayan aslan; arkadan panda ve zürafa bakar. Hayvanlar oyunlardaki çizimlerden alınır
# (oyunlar/araba_yarisi/gorseller/hayvanlar/), böylece simge uygulamanın içeriğiyle aynı tarzda kalır.
#
# Yazılan dosyalar:
#   ortak/simge/arka_plan.svg  Android uyarlanabilir simgesinin arka planı (tam kare gökyüzü, ışınlar, çimen)
#   ortak/simge/on_plan.svg    ön planı (saydam; önemli her şey ortadaki ~170 px yarıçaplı güvenli alanda)
#   icon.svg                   proje simgesi: ikisi üst üste, ön plan büyütülmüş, tam kare
# Godot bulunursa (GODOT ortam değişkeni ya da bilinen yollar) PNG'ler de yazılır:
#   ortak/simge/android_on_plan_432.png, android_arka_plan_432.png  uyarlanabilir simge (export_presets.cfg)
#   ortak/simge/simge_192.png   eski Android sürümleri için yuvarlak köşeli simge
#   .playstore/icon_512.png     Google Play simgesi (tam kare; köşeleri Play kendisi yuvarlatır)

import os
import re
import subprocess
import tempfile

KOK = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HAYVANLAR = os.path.join(KOK, "oyunlar", "araba_yarisi", "gorseller", "hayvanlar")
SIMGE = os.path.join(KOK, "ortak", "simge")

# icon.svg'de ön plan bu kadar büyütülür (uyarlanabilir simgede görünen alan kenarın ~%67'si)
TAM_SIMGE_OLCEK = 1.38


def hayvan(ad: str, x: float, y: float, olcek: float, aci: float = 0.0) -> tuple[str, str]:
    """Oyundaki hayvan SVG'sini (256x256) (x, y) merkezine yerleştirir. Kimlikler çakışmasın diye öneklenir;
    yerdeki gölge atılır. (defs, gövde) döndürür."""
    with open(os.path.join(HAYVANLAR, ad + ".svg"), encoding="utf-8") as f:
        metin = f.read()
    ic = metin[metin.index(">", metin.index("<svg")) + 1:metin.rindex("</svg>")]
    ic = re.sub(r'id="([^"]+)"', lambda m: 'id="%s_%s"' % (ad, m.group(1)), ic)
    ic = re.sub(r"url\(#([^)]+)\)", lambda m: "url(#%s_%s)" % (ad, m.group(1)), ic)
    ic = re.sub(r"\s*<ellipse[^>]*url\(#%s_golge\)[^>]*/>" % ad, "", ic)
    defs = ic[ic.index("<defs>") + 6:ic.index("</defs>")]
    govde = ic[ic.index("</defs>") + 7:]
    donusum = "translate(%.1f %.1f) rotate(%.1f) scale(%.3f) translate(-128 -128)" % (x, y, aci, olcek)
    return defs, '<g transform="%s">%s</g>' % (donusum, govde)


def arka_plan_ici() -> tuple[str, str]:
    defs = """
    <radialGradient id="gok" cx="0.5" cy="0.42" r="0.75">
      <stop offset="0" stop-color="#FFF7D6"/>
      <stop offset="0.35" stop-color="#BFEBFF"/>
      <stop offset="1" stop-color="#3FA9F0"/>
    </radialGradient>
    <linearGradient id="cimen" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#8EE06A"/>
      <stop offset="1" stop-color="#3FA53F"/>
    </linearGradient>"""
    # Güneş ışınları: ortadan yayılan, hafif açık dilimler
    isinlar = []
    for i in range(12):
        a = i * 30
        isinlar.append('<path d="M256 236 L256 -300 L400 -300 Z" transform="rotate(%d 256 236)"/>' % a)
    govde = """
  <rect width="512" height="512" fill="url(#gok)"/>
  <g fill="#FFFFFF" opacity="0.16">%s</g>
  <g fill="#FFFFFF" opacity="0.9">
    <ellipse cx="118" cy="128" rx="34" ry="18"/><circle cx="104" cy="118" r="17"/><circle cx="128" cy="112" r="21"/>
    <ellipse cx="398" cy="150" rx="30" ry="15"/><circle cx="388" cy="141" r="14"/><circle cx="408" cy="137" r="17"/>
  </g>
  <path d="M-20 420 Q130 372 256 384 Q382 372 532 420 V532 H-20 Z" fill="url(#cimen)"/>
  <path d="M-20 420 Q130 372 256 384 Q382 372 532 420" fill="none" stroke="#FFFFFF" stroke-width="5" opacity="0.35"/>
  <g fill="#FFE066"><circle cx="132" cy="430" r="7"/><circle cx="388" cy="436" r="7"/><circle cx="96" cy="452" r="5"/><circle cx="420" cy="458" r="5"/></g>
""" % "".join(isinlar)
    return defs, govde


def trambolin() -> tuple[str, str]:
    """(defs, arka yarısı + minder, ön çerçeve) — hayvanlar arka çerçeveyle ön çerçevenin arasına girer."""
    defs = ""
    cx, cy, rx, ry = 256, 352, 132, 30
    bacaklar = """
  <g stroke="#2F3A8F" stroke-width="12" stroke-linecap="round">
    <path d="M156 372 L146 408"/><path d="M356 372 L366 408"/><path d="M226 382 L222 414"/><path d="M286 382 L290 414"/>
  </g>"""
    # Minder: koyu mavi; ortası aslan az önce sektiği için hafifçe çökük ve gölgeli
    minder = ('<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="#3442A8"/>'
              '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="#26307F"/>'
              '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="#5664D8" opacity="0.6"/>') % (
        cx, cy, rx - 6, ry - 4, cx, cy + 6, 62, 15, cx - 40, cy - 12, 46, 7)
    cerceve = ('<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="none" stroke="#7A2A1A" stroke-width="24"/>'
               '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="none" stroke="#FF5A5F" stroke-width="16"/>'
               '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="none" stroke="#FFD23F" stroke-width="16" '
               'stroke-dasharray="26 26"/>' % ((cx, cy, rx, ry) * 3))
    arka = bacaklar + '<g clip-path="url(#ust_yari)">%s</g>' % cerceve + minder
    on = '<g clip-path="url(#alt_yari)">%s</g>' % cerceve
    on += '<path d="M%d %d Q%d %d %d %d" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" opacity="0.5"/>' % (
        cx - 70, cy + ry + 2, cx, cy + ry + 10, cx + 70, cy + ry + 2)
    defs += """
    <clipPath id="ust_yari"><rect x="0" y="0" width="512" height="%d"/></clipPath>
    <clipPath id="alt_yari"><rect x="0" y="%d" width="512" height="200"/></clipPath>""" % (cy, cy)
    return defs, arka, on


def on_plan_ici() -> tuple[str, str]:
    t_defs, t_arka, t_on = trambolin()
    p_defs, panda = hayvan("panda", 146, 300, 0.5, -12)
    z_defs, zurafa = hayvan("zurafa", 366, 292, 0.52, 10)
    a_defs, aslan = hayvan("aslan", 256, 204, 0.8, -6)
    defs = t_defs + p_defs + z_defs + a_defs
    hareket = """
  <g fill="none" stroke="#FFFFFF" stroke-width="7" stroke-linecap="round" opacity="0.95">
    <path d="M214 300 Q210 308 212 316"/><path d="M298 300 Q302 308 300 316"/><path d="M236 306 V316"/><path d="M276 306 V316"/>
  </g>
  <g fill="#FFD23F" stroke="#E08A00" stroke-width="3" stroke-linejoin="round">
    <path d="M124 176 l7 15 16 2 -12 11 3 16 -14 -8 -14 8 3 -16 -12 -11 16 -2 z"/>
    <path d="M378 128 l5 11 12 1.5 -9 8 2.5 12 -10.5 -6 -10.5 6 2.5 -12 -9 -8 12 -1.5 z"/>
  </g>
  <g fill="#FFFFFF"><path d="M384 214 l4 10 10 4 -10 4 -4 10 -4 -10 -10 -4 10 -4 z"/><path d="M152 112 l3 8 8 3 -8 3 -3 8 -3 -8 -8 -3 8 -3 z"/></g>"""
    # Panda ve zürafa trambolinin arkasından bakar: önce onlar, sonra trambolin, en üstte zıplayan aslan
    govde = panda + zurafa + t_arka + t_on + hareket + aslan
    return defs, govde


def svg(defs: str, govde: str, yorum: str) -> str:
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">\n'
            "  <!-- %s Üretici: ortak/simge/simge_uret.py -->\n  <defs>%s\n  </defs>%s\n</svg>\n" % (yorum, defs, govde))


def tam_simge(kose: float = 0.0) -> str:
    a_defs, a_govde = arka_plan_ici()
    o_defs, o_govde = on_plan_ici()
    olcek = TAM_SIMGE_OLCEK
    govde = a_govde + '<g transform="translate(256 262) scale(%.2f) translate(-256 -256)">%s</g>' % (olcek, o_govde)
    defs = a_defs + o_defs
    if kose > 0:
        defs += '<clipPath id="kose"><rect width="512" height="512" rx="%d"/></clipPath>' % kose
        govde = '<g clip-path="url(#kose)">%s</g>' % govde
    return svg(defs, govde, "Bouncy Zoo uygulama simgesi.")


def yaz(yol: str, metin: str) -> None:
    with open(yol, "w", encoding="utf-8", newline="\n") as f:
        f.write(metin)
    print("yazıldı:", os.path.relpath(yol, KOK))


GODOT_YOLLARI = [
    r"C:\Program Files\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
]

# Godot'nun SVG çizicisiyle (oyundaki görünümün aynısı) PNG yazar: her satır "svg_yolu|boyut|png_yolu"
CIZICI = """extends SceneTree
func _init() -> void:
	for satir in FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]).split("\\n", false):
		var p := satir.strip_edges().split("|")
		var img := Image.new()
		img.load_svg_from_string(FileAccess.get_file_as_string(p[0]), float(p[1]) / 512.0)
		img.save_png(p[2])
	quit()
"""


def png_yaz(isler: list[tuple[str, int, str]]) -> None:
    godot = os.environ.get("GODOT") or next((y for y in GODOT_YOLLARI if os.path.exists(y)), None)
    if not godot:
        print("Godot bulunamadı (GODOT ortam değişkeni); PNG'ler yazılmadı.")
        return
    with tempfile.TemporaryDirectory() as gecici:
        betik = os.path.join(gecici, "ciz.gd")
        liste = os.path.join(gecici, "liste.txt")
        satirlar = []
        for i, (metin, boyut, cikti) in enumerate(isler):
            kaynak = os.path.join(gecici, "%d.svg" % i)
            with open(kaynak, "w", encoding="utf-8") as f:
                f.write(metin)
            satirlar.append("%s|%d|%s" % (kaynak, boyut, cikti))
        with open(betik, "w", encoding="utf-8") as f:
            f.write(CIZICI)
        with open(liste, "w", encoding="utf-8") as f:
            f.write("\n".join(satirlar))
        sonuc = subprocess.run([godot, "--headless", "-s", betik, "--", liste], capture_output=True, text=True)
        if "ERROR" in sonuc.stdout + sonuc.stderr:
            raise SystemExit(sonuc.stdout + sonuc.stderr)
    for _, _, cikti in isler:
        print("yazıldı:", os.path.relpath(cikti, KOK))


def main() -> None:
    a_defs, a_govde = arka_plan_ici()
    o_defs, o_govde = on_plan_ici()
    arka = svg(a_defs, a_govde, "Bouncy Zoo simgesinin arka planı (Android uyarlanabilir simgesi, tam kare).")
    on = svg(o_defs, o_govde, "Bouncy Zoo simgesinin ön planı (saydam; önemli her şey ortadaki güvenli alanda).")
    tam = tam_simge()
    yaz(os.path.join(SIMGE, "arka_plan.svg"), arka)
    yaz(os.path.join(SIMGE, "on_plan.svg"), on)
    yaz(os.path.join(KOK, "icon.svg"), tam)
    png_yaz([
        (on, 432, os.path.join(SIMGE, "android_on_plan_432.png")),
        (arka, 432, os.path.join(SIMGE, "android_arka_plan_432.png")),
        (tam_simge(kose=112), 192, os.path.join(SIMGE, "simge_192.png")),
        (tam, 512, os.path.join(KOK, ".playstore", "icon_512.png")),
    ])


if __name__ == "__main__":
    main()
