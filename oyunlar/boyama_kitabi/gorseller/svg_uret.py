# Boyama Kitabı SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre yazar; içe aktarma: 2x + mipmap)
# Stil öbür oyunlarla aynı: koyu mor kalın hat, radyal gradyanlı dolgular, beyaz parıltılar.
#
# Renklenen simgeler iki katmandır: <ad>.svg (sabit renkli taban) ve <ad>_renk.svg (beyaz çizilir,
# oyunda seçili renkle çarpılarak tabanın üstüne konur). Damgalarda üstte bir katman daha var:
# damga_<ad>_renk.svg (seçili renk) ve damga_<ad>_ust.svg (yüz, parıltı gibi kendi renkli ayrıntılar).
#
# - Araçlar (128): kova, firca, gokkusagi, damga, silgi, geri_al, kaydet, buyutec, temizle
# - Damgalar (128): yildiz, kalp, cicek, parilti, gulen_yuz, balon
# - Giriş (256): yeni_resim, galerim; kategori simgeleri (128): kat_*; cop, onay, iptal (128)
# - bos_galeri.svg (400x300): galeri boşken; kart.svg (320x300): ana menü kartı

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = "#3B2F6B"
SW = 6


def write(name: str, w: float, h: float, body: str, defs: str = "") -> None:
    text = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:g}" height="{h:g}" viewBox="0 0 {w:g} {h:g}">\n'
    if defs:
        text += "  <defs>\n" + defs + "  </defs>\n"
    text += body + "</svg>\n"
    with open(os.path.join(HERE, name), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(name)


def hex_rgb(c: str) -> tuple:
    c = c.lstrip("#")
    return tuple(int(c[k:k + 2], 16) for k in (0, 2, 4))


def mix(a: str, b: str, t: float) -> str:
    ra, rb = hex_rgb(a), hex_rgb(b)
    return "#%02X%02X%02X" % tuple(round(ra[k] + (rb[k] - ra[k]) * t) for k in range(3))


def light(c: str, t: float = 0.45) -> str:
    return mix(c, "#FFFFFF", t)


def dark(c: str, t: float = 0.25) -> str:
    return mix(c, OUT, t)


def radial(gid: str, stops: list, cx: float = 0.4, cy: float = 0.3, r: float = 0.75) -> str:
    s = "".join(f'<stop offset="{o:g}" stop-color="{c}"/>' for o, c in stops)
    return f'    <radialGradient id="{gid}" cx="{cx:g}" cy="{cy:g}" r="{r:g}">{s}</radialGradient>\n'


def linear(gid: str, stops: list, x2: float = 0, y2: float = 1) -> str:
    s = "".join(f'<stop offset="{o:g}" stop-color="{c}"/>' for o, c in stops)
    return f'    <linearGradient id="{gid}" x1="0" y1="0" x2="{x2:g}" y2="{y2:g}">{s}</linearGradient>\n'


def ten(gid: str, base: str) -> str:
    return radial(gid, [(0, light(base, 0.55)), (0.55, base), (1, dark(base, 0.22))])


def st(width: float = SW) -> str:
    return f'stroke="{OUT}" stroke-width="{width:g}" stroke-linejoin="round" stroke-linecap="round"'


def shine(x, y, rx=10, ry=5, angle=-30, opacity=0.8) -> str:
    return f'  <ellipse cx="{x:g}" cy="{y:g}" rx="{rx:g}" ry="{ry:g}" transform="rotate({angle:g} {x:g} {y:g})" fill="#FFFFFF" opacity="{opacity:g}"/>\n'


def pts(points) -> str:
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def star(cx, cy, big, small, n=5, rot=-90.0) -> list:
    out = []
    for k in range(2 * n):
        r = big if k % 2 == 0 else small
        a = math.radians(rot + 180.0 * k / n)
        out.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return out


def heart_path(cx, cy, s) -> str:
    # s: yarı genişlik
    return (f"M{cx:g} {cy + s * 0.95:g} C{cx - s * 1.5:g} {cy + s * 0.1:g} {cx - s * 1.05:g} {cy - s * 1.0:g} {cx:g} {cy - s * 0.45:g} "
            f"C{cx + s * 1.05:g} {cy - s * 1.0:g} {cx + s * 1.5:g} {cy + s * 0.1:g} {cx:g} {cy + s * 0.95:g} Z")


def eyes(x1, x2, y, r=5.5) -> str:
    out = ""
    for x in (x1, x2):
        out += f'  <ellipse cx="{x:g}" cy="{y:g}" rx="{r:g}" ry="{r * 1.25:g}" fill="{OUT}"/>\n'
        out += f'  <circle cx="{x - r * 0.35:g}" cy="{y - r * 0.45:g}" r="{r * 0.4:g}" fill="#FFFFFF"/>\n'
    return out


def smile(x, y, w, width=4.5) -> str:
    return f'  <path d="M{x - w:g} {y:g} Q{x:g} {y + w * 0.8:g} {x + w:g} {y:g}" fill="none" {st(width)}/>\n'


# ============================ ARAÇLAR (128) ============================

def bucket() -> None:
    d = linear("kova", [(0, "#DCE7F2"), (0.5, "#B7C8DC"), (1, "#8FA3BE")], 1, 0)
    body = f'  <path d="M40 30 Q64 -6 88 30" fill="none" {st(6)}/>\n'
    body += f'  <path d="M28 50 L100 50 L92 112 Q64 122 36 112 Z" fill="url(#kova)" {st()}/>\n'
    body += shine(44, 72, 5, 14, 8, 0.7)
    write("kova.svg", 128, 128, body, d)
    paint = f'  <ellipse cx="64" cy="50" rx="36" ry="11" fill="#FFFFFF" {st(5)}/>\n'
    paint += f'  <path d="M88 54 Q90 70 96 76 Q102 84 96 90 Q88 92 88 82 Z" fill="#FFFFFF" {st(4.5)}/>\n'
    paint += f'  <ellipse cx="108" cy="114" rx="14" ry="6" fill="#FFFFFF" {st(4.5)}/>\n'
    write("kova_renk.svg", 128, 128, paint)


def brush() -> None:
    d = linear("sap", [(0, "#F2B874"), (1, "#C98543")], 1, 0) + linear("metal", [(0, "#EEF2F7"), (1, "#A9B6C8")], 1, 0)
    body = f'  <path d="M88 10 Q98 6 104 14 L78 66 L64 58 Z" fill="url(#sap)" {st()}/>\n'
    body += f'  <path d="M62 56 L80 66 L72 80 L52 70 Z" fill="url(#metal)" {st(5)}/>\n'
    body += shine(92, 20, 3, 9, 28, 0.7)
    write("firca.svg", 128, 128, body, d)
    tip = f'  <path d="M52 70 L72 80 Q66 104 40 116 Q24 120 22 114 Q30 108 34 96 Q40 76 52 70 Z" fill="#FFFFFF" {st(5)}/>\n'
    write("firca_renk.svg", 128, 128, tip)


def rainbow_brush() -> None:
    colors = ["#FF5B5B", "#FF9A3D", "#FFD23F", "#7BD85A", "#4AA3FF", "#8B6CF6"]
    body = ""
    for k, c in enumerate(colors):
        r = 50 - k * 7
        body += f'  <path d="M{64 - r} 76 A{r} {r} 0 0 1 {64 + r} 76" fill="none" stroke="{c}" stroke-width="7.5"/>\n'
    body += f'  <path d="M{64 - 54} 76 A54 54 0 0 1 {64 + 54} 76" fill="none" {st(4)}/>\n'
    body += f'  <path d="M{64 - 11} 76 A11 11 0 0 1 {64 + 11} 76" fill="none" {st(4)}/>\n'
    d = linear("sap", [(0, "#F2B874"), (1, "#C98543")], 1, 0)
    body += f'  <path d="M96 58 Q104 54 108 60 L88 104 L76 98 Z" fill="url(#sap)" {st(5)}/>\n'
    body += f'  <path d="M76 98 L88 104 Q84 118 68 122 Q62 122 62 118 Q70 112 72 106 Z" fill="#FF6FB5" {st(4.5)}/>\n'
    for (x, y, s) in ((24, 100, 9), (40, 112, 6)):
        body += f'  <polygon points="{pts(star(x, y, s, s * 0.45, 4, 0))}" fill="#FFD23F" {st(3)}/>\n'
    write("gokkusagi.svg", 128, 128, body, d)


def stamp_tool() -> None:
    d = linear("sap", [(0, "#C98BFF"), (1, "#8B5CE0")], 1, 0)
    body = f'  <circle cx="64" cy="24" r="16" fill="url(#sap)" {st()}/>\n'
    body += f'  <rect x="54" y="36" width="20" height="30" rx="4" fill="url(#sap)" {st()}/>\n'
    body += f'  <rect x="30" y="62" width="68" height="18" rx="7" fill="#F2B874" {st()}/>\n'
    body += shine(58, 18, 5, 3)
    write("damga.svg", 128, 128, body, d)
    tint = f'  <polygon points="{pts(star(64, 100, 26, 12))}" fill="#FFFFFF" {st(5)}/>\n'
    write("damga_renk.svg", 128, 128, tint)


def eraser() -> None:
    d = linear("pembe", [(0, "#FFC2D9"), (1, "#FF8FB6")], 1, 1) + linear("mavi", [(0, "#9CD2FF"), (1, "#5AA8F0")], 1, 1)
    body = f'  <g transform="rotate(-35 64 64)">\n'
    body += f'    <rect x="18" y="44" width="54" height="40" rx="9" fill="url(#pembe)" {st()}/>\n'
    body += f'    <rect x="66" y="44" width="44" height="40" rx="9" fill="url(#mavi)" {st()}/>\n'
    body += '    <ellipse cx="34" cy="54" rx="9" ry="4" fill="#FFFFFF" opacity="0.8"/>\n  </g>\n'
    for (x, y, r) in ((22, 108, 5), (36, 116, 4), (50, 110, 3)):
        body += f'  <circle cx="{x}" cy="{y}" r="{r}" fill="#FFC2D9" {st(3)}/>\n'
    write("silgi.svg", 128, 128, body, d)


def undo() -> None:
    d = radial("ok", [(0, "#FFE58A"), (0.6, "#FFC53D"), (1, "#F09A1C")])
    body = (f'  <path d="M34 60 L60 30 L60 46 Q104 44 106 82 Q108 104 88 112 Q98 94 88 78 Q80 68 60 70 L60 88 Z" '
            f'fill="url(#ok)" {st()}/>\n')
    body += shine(56, 42, 4, 8, 40)
    write("geri_al.svg", 128, 128, body, d)


def save_icon() -> None:
    d = linear("cerceve", [(0, "#FFD27A"), (1, "#E89A3C")], 1, 1) + linear("gok", [(0, "#BDE6FF"), (1, "#E9F7FF")])
    body = f'  <rect x="14" y="22" width="100" height="84" rx="12" fill="url(#cerceve)" {st()}/>\n'
    body += f'  <rect x="28" y="36" width="72" height="56" rx="6" fill="url(#gok)" {st(5)}/>\n'
    body += f'  <path d="M28 92 L28 80 Q44 66 58 78 Q72 62 100 80 L100 92 Z" fill="#7BD85A" {st(4)}/>\n'
    body += f'  <circle cx="84" cy="52" r="8" fill="#FFD23F" {st(4)}/>\n'
    body += f'  <path d="{heart_path(64, 58, 11)}" fill="#FF6F91" {st(4)}/>\n'
    body += shine(26, 30, 6, 3)
    write("kaydet.svg", 128, 128, body, d)


def magnifier() -> None:
    d = radial("cam", [(0, "#FFFFFF"), (0.7, "#D8F0FF"), (1, "#A9D8F5")])
    body = f'  <path d="M78 80 L108 110" {st(22)}/>\n'
    body += f'  <path d="M80 82 L106 108" stroke="#FF8A5B" stroke-width="12" stroke-linecap="round"/>\n'
    body += f'  <circle cx="54" cy="54" r="36" fill="url(#cam)" {st()}/>\n'
    body += f'  <rect x="38" y="42" width="32" height="24" rx="4" fill="none" {st(4.5)}/>\n'
    for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        x, y = 54 + sx * 24, 54 + sy * 21
        body += f'  <path d="M{x - sx * 7} {y} L{x} {y} L{x} {y - sy * 6}" fill="none" {st(4)}/>\n'
    body += shine(40, 34, 8, 4)
    write("buyutec.svg", 128, 128, body, d)


def broom() -> None:
    d = linear("sap", [(0, "#F2B874"), (1, "#C98543")], 1, 0) + linear("saman", [(0, "#FFE58A"), (1, "#F2B53D")])
    body = f'  <path d="M96 8 Q104 6 106 14 L74 70 L66 64 Z" fill="url(#sap)" {st(5)}/>\n'
    body += f'  <path d="M60 56 L84 72 Q78 104 52 122 L14 98 Q36 80 60 56 Z" fill="url(#saman)" {st()}/>\n'
    body += f'  <path d="M64 60 L80 70" {st(5)}/>\n'
    body += f'  <path d="M46 86 L30 106 M56 92 L42 114 M66 96 L56 118" fill="none" {st(3.5)}/>\n'
    for (x, y, s) in ((106, 58, 10), (100, 92, 7), (22, 40, 8)):
        body += f'  <polygon points="{pts(star(x, y, s, s * 0.42, 4, 0))}" fill="#FFD23F" {st(3)}/>\n'
    write("temizle.svg", 128, 128, body, d)


def trash() -> None:
    d = linear("kutu", [(0, "#FF9AA8"), (1, "#F0637A")], 1, 0)
    body = f'  <path d="M30 40 L98 40 L90 114 Q64 122 38 114 Z" fill="url(#kutu)" {st()}/>\n'
    body += f'  <rect x="22" y="26" width="84" height="16" rx="7" fill="#FF7A8E" {st()}/>\n'
    body += f'  <path d="M52 26 Q52 14 64 14 Q76 14 76 26" fill="none" {st()}/>\n'
    body += f'  <path d="M50 56 L53 102 M64 56 V104 M78 56 L75 102" fill="none" {st(5)}/>\n'
    body += shine(38, 60, 4, 12, 6, 0.6)
    write("cop.svg", 128, 128, body, d)


def yes_no() -> None:
    d = radial("yesil", [(0, "#A8F08A"), (0.6, "#5BCB4C"), (1, "#36A03A")])
    body = f'  <circle cx="64" cy="64" r="54" fill="url(#yesil)" {st()}/>\n'
    body += '  <path d="M36 66 L56 86 L94 44" fill="none" stroke="#FFFFFF" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>\n'
    body += shine(40, 34, 12, 6)
    write("onay.svg", 128, 128, body, d)
    d = radial("kirmizi", [(0, "#FFA3A3"), (0.6, "#FF5B5B"), (1, "#D93A4A")])
    body = f'  <circle cx="64" cy="64" r="54" fill="url(#kirmizi)" {st()}/>\n'
    body += '  <path d="M42 42 L86 86 M86 42 L42 86" fill="none" stroke="#FFFFFF" stroke-width="15" stroke-linecap="round"/>\n'
    body += shine(40, 34, 12, 6)
    write("iptal.svg", 128, 128, body, d)


# ============================ DAMGALAR (128) ============================

def stamps() -> None:
    # yıldız
    write("damga_yildiz_renk.svg", 128, 128, f'  <polygon points="{pts(star(64, 68, 56, 25))}" fill="#FFFFFF" {st()}/>\n')
    top = eyes(52, 76, 66, 5) + smile(64, 80, 8, 4) + shine(46, 40, 9, 4, -40, 0.75)
    write("damga_yildiz_ust.svg", 128, 128, top)
    # kalp
    write("damga_kalp_renk.svg", 128, 128, f'  <path d="{heart_path(64, 66, 44)}" fill="#FFFFFF" {st()}/>\n')
    write("damga_kalp_ust.svg", 128, 128, shine(40, 44, 11, 6, -40, 0.8) + shine(58, 38, 4, 3, 0, 0.6))
    # çiçek: taç yaprakları seçili renk, ortası sarı
    petals = "".join(f'<circle cx="{64 + 30 * math.cos(math.radians(72 * k - 90)):.1f}" cy="{64 + 30 * math.sin(math.radians(72 * k - 90)):.1f}" r="22"/>'
                     for k in range(5))
    body = f'  <g fill="{OUT}" {st(12)}>{petals}</g>\n  <g fill="#FFFFFF">{petals}</g>\n'
    write("damga_cicek_renk.svg", 128, 128, body)
    top = f'  <circle cx="64" cy="64" r="18" fill="#FFD23F" {st(5)}/>\n' + eyes(58, 70, 62, 3) + smile(64, 69, 4, 3)
    write("damga_cicek_ust.svg", 128, 128, top)
    # parıltı: dört köşeli iki yıldız
    body = f'  <polygon points="{pts(star(58, 66, 54, 14, 4, -90))}" fill="#FFFFFF" {st()}/>\n'
    body += f'  <polygon points="{pts(star(100, 28, 20, 6, 4, -90))}" fill="#FFFFFF" {st(4.5)}/>\n'
    write("damga_parilti_renk.svg", 128, 128, body)
    write("damga_parilti_ust.svg", 128, 128, shine(52, 52, 5, 10, 0, 0.8))
    # gülen yüz
    write("damga_gulen_yuz_renk.svg", 128, 128, f'  <circle cx="64" cy="64" r="52" fill="#FFFFFF" {st()}/>\n')
    top = eyes(46, 82, 54, 7)
    top += f'  <path d="M38 74 Q64 104 90 74" fill="none" {st(6)}/>\n'
    top += '  <ellipse cx="34" cy="78" rx="9" ry="5" fill="#FF7FA3" opacity="0.7"/><ellipse cx="94" cy="78" rx="9" ry="5" fill="#FF7FA3" opacity="0.7"/>\n'
    top += shine(40, 30, 10, 5, -35, 0.7)
    write("damga_gulen_yuz_ust.svg", 128, 128, top)
    # balon: ipi ve düğümü kendi renginde
    body = f'  <ellipse cx="64" cy="52" rx="38" ry="44" fill="#FFFFFF" {st()}/>\n'
    body += f'  <path d="M58 96 L70 96 L64 88 Z" fill="#FFFFFF" {st(4.5)}/>\n'
    write("damga_balon_renk.svg", 128, 128, body)
    top = f'  <path d="M64 98 Q54 108 64 116 Q74 124 62 128" fill="none" {st(3.5)}/>\n'
    top += shine(48, 32, 7, 12, 25, 0.8)
    write("damga_balon_ust.svg", 128, 128, top)


# ============================ GİRİŞ VE KATEGORİLER ============================

def new_picture() -> None:
    # Boş sayfa, üstünde boya kalemi ve parıltılar (256)
    d = linear("kagit", [(0, "#FFFFFF"), (1, "#EEF0FA")])
    d += linear("kalem", [(0, "#FF8A8A"), (1, "#E0485A")], 1, 0)
    body = f'  <rect x="46" y="30" width="150" height="190" rx="14" transform="rotate(-6 121 125)" fill="url(#kagit)" {st(8)}/>\n'
    for k, c in enumerate(("#FFD23F", "#7BD85A", "#4AA3FF")):
        y = 90 + k * 34
        body += f'  <path d="M78 {y + 8} Q120 {y - 8} 160 {y}" transform="rotate(-6 121 125)" fill="none" stroke="{c}" stroke-width="12" stroke-linecap="round" opacity="0.85"/>\n'
    body += '  <g transform="rotate(38 170 150)">\n'
    body += f'    <rect x="152" y="60" width="36" height="120" rx="8" fill="url(#kalem)" {st(8)}/>\n'
    body += f'    <path d="M152 176 L188 176 L170 214 Z" fill="#F7D2B0" {st(7)}/>\n'
    body += f'    <path d="M162 197 L178 197 L170 214 Z" fill="#E0485A" {st(5)}/>\n'
    body += f'    <rect x="152" y="80" width="36" height="12" fill="#FFFFFF" opacity="0.6"/>\n  </g>\n'
    for (x, y, s) in ((206, 50, 20), (226, 96, 12), (36, 214, 14)):
        body += f'  <polygon points="{pts(star(x, y, s, s * 0.42, 4, 0))}" fill="#FFD23F" {st(5)}/>\n'
    write("yeni_resim.svg", 256, 256, body, d)


def gallery() -> None:
    # Duvarda iki çerçeveli resim (256)
    d = linear("c1", [(0, "#FFD27A"), (1, "#E89A3C")], 1, 1) + linear("c2", [(0, "#C9A7FF"), (1, "#8B6CF6")], 1, 1)
    d += linear("gok", [(0, "#BDE6FF"), (1, "#E9F7FF")])
    body = f'  <rect x="112" y="30" width="118" height="100" rx="12" transform="rotate(8 171 80)" fill="url(#c2)" {st(8)}/>\n'
    body += f'  <rect x="128" y="46" width="86" height="68" rx="6" transform="rotate(8 171 80)" fill="#FFF4D6" {st(6)}/>\n'
    body += f'  <path d="{heart_path(171, 82, 20)}" transform="rotate(8 171 80)" fill="#FF6F91" {st(6)}/>\n'
    body += f'  <rect x="24" y="92" width="150" height="130" rx="14" transform="rotate(-5 99 157)" fill="url(#c1)" {st(8)}/>\n'
    body += f'  <rect x="44" y="112" width="110" height="90" rx="8" transform="rotate(-5 99 157)" fill="url(#gok)" {st(6)}/>\n'
    body += (f'  <path d="M44 202 L44 180 Q70 150 96 172 Q120 146 154 176 L154 202 Z" transform="rotate(-5 99 157)" '
             f'fill="#7BD85A" {st(6)}/>\n')
    body += f'  <circle cx="126" cy="136" r="14" fill="#FFD23F" {st(6)}/>\n'
    body += shine(40, 104, 10, 5)
    write("galerim.svg", 256, 256, body, d)


def categories() -> None:
    # Hayvanlar: kedi yüzü
    d = ten("ten", "#FFA84D")
    body = ""
    for s in (1, -1):
        body += f'  <path d="M{64 - s * 36} 60 L{64 - s * 42} 16 L{64 - s * 8} 40 Z" fill="url(#ten)" {st()}/>\n'
        body += f'  <path d="M{64 - s * 32} 50 L{64 - s * 35} 26 L{64 - s * 16} 40 Z" fill="#FF9FBF"/>\n'
    body += f'  <ellipse cx="64" cy="72" rx="46" ry="40" fill="url(#ten)" {st()}/>\n'
    body += eyes(48, 80, 68, 6)
    body += f'  <path d="M59 82 H69 L64 88 Z" fill="#FF7FA3" {st(3.5)}/>\n' + smile(64, 92, 8, 4)
    body += shine(40, 50, 9, 4)
    write("kat_hayvanlar.svg", 128, 128, body, d)
    # Araçlar: araba
    d = ten("ten", "#4AA3FF")
    body = f'  <path d="M34 64 L46 38 Q50 32 58 32 L80 32 Q88 32 92 38 L102 64 Z" fill="url(#ten)" {st()}/>\n'
    body += f'  <path d="M46 62 L54 42 L66 42 L66 62 Z M74 62 L74 42 L84 42 L92 62 Z" fill="#DDF3FF" {st(4)}/>\n'
    body += f'  <rect x="12" y="60" width="104" height="34" rx="14" fill="url(#ten)" {st()}/>\n'
    for x in (38, 90):
        body += f'  <circle cx="{x}" cy="96" r="15" fill="#5A4A6E" {st()}/><circle cx="{x}" cy="96" r="6" fill="#DDE3EC"/>\n'
    body += shine(30, 68, 9, 4, -10)
    write("kat_araclar.svg", 128, 128, body, d)
    # Oyuncaklar: renkli top
    body = f'  <circle cx="64" cy="64" r="50" fill="#FFFFFF" {st()}/>\n'
    body += f'  <path d="M64 14 Q30 64 64 114 Q18 110 14 64 Q18 18 64 14 Z" fill="#FF5B5B" {st(5)}/>\n'
    body += f'  <path d="M64 14 Q98 64 64 114 Q110 110 114 64 Q110 18 64 14 Z" fill="#4AA3FF" {st(5)}/>\n'
    body += f'  <path d="M64 14 Q44 64 64 114 Q84 64 64 14 Z" fill="#FFD23F" {st(5)}/>\n'
    body += shine(38, 36, 10, 5)
    write("kat_oyuncaklar.svg", 128, 128, body)
    # Doğa: çiçek
    body = f'  <path d="M64 70 Q60 96 66 120" fill="none" stroke="{OUT}" stroke-width="12" stroke-linecap="round"/>\n'
    body += '  <path d="M64 70 Q60 96 66 120" fill="none" stroke="#5BCB4C" stroke-width="5" stroke-linecap="round"/>\n'
    body += f'  <path d="M64 104 Q84 84 104 92 Q92 112 64 108 Z" fill="#7BD85A" {st(5)}/>\n'
    petals = "".join(f'<circle cx="{64 + 26 * math.cos(math.radians(72 * k - 90)):.1f}" cy="{50 + 26 * math.sin(math.radians(72 * k - 90)):.1f}" r="18"/>'
                     for k in range(5))
    body += f'  <g fill="{OUT}" {st(12)}>{petals}</g>\n  <g fill="#FF6FB5">{petals}</g>\n'
    body += f'  <circle cx="64" cy="50" r="16" fill="#FFD23F" {st(5)}/>\n' + eyes(58, 70, 48, 3) + smile(64, 55, 4, 3)
    write("kat_doga.svg", 128, 128, body)
    # Şekiller: üçgen, daire, kare
    body = f'  <rect x="62" y="62" width="50" height="50" rx="6" fill="#4AA3FF" {st()}/>\n'
    body += f'  <circle cx="42" cy="86" r="26" fill="#FFD23F" {st()}/>\n'
    body += f'  <path d="M64 12 L96 66 L32 66 Z" fill="#FF5B5B" {st()}/>\n'
    write("kat_sekiller.svg", 128, 128, body)


def empty_gallery() -> None:
    # Boş şövale ve yanında gülümseyen boya kalemi (400x300)
    d = linear("tahta", [(0, "#E8A45C"), (1, "#B87A45")], 1, 0) + linear("kagit", [(0, "#FFFFFF"), (1, "#EEF0FA")])
    d += linear("kalem", [(0, "#7BD85A"), (1, "#3FA046")], 1, 0)
    body = f'  <path d="M150 60 L104 280 M250 60 L296 280 M200 50 L200 280" fill="none" stroke="{OUT}" stroke-width="20" stroke-linecap="round"/>\n'
    body += '  <path d="M150 60 L104 280 M250 60 L296 280 M200 50 L200 280" fill="none" stroke="url(#tahta)" stroke-width="9" stroke-linecap="round"/>\n'
    body += f'  <rect x="112" y="40" width="176" height="150" rx="10" fill="url(#kagit)" {st(8)}/>\n'
    body += f'  <rect x="100" y="186" width="200" height="18" rx="8" fill="url(#tahta)" {st(7)}/>\n'
    for (x, y, s) in ((82, 70, 16), (318, 58, 12), (330, 120, 9)):
        body += f'  <polygon points="{pts(star(x, y, s, s * 0.42, 4, 0))}" fill="#FFD23F" {st(4)}/>\n'
    body += '  <g transform="rotate(14 350 210)">\n'
    body += f'    <rect x="330" y="150" width="40" height="110" rx="10" fill="url(#kalem)" {st(7)}/>\n'
    body += f'    <path d="M330 152 L370 152 L350 116 Z" fill="#F7D2B0" {st(6)}/>\n'
    body += f'    <path d="M342 130 L358 130 L350 116 Z" fill="#3FA046" {st(4)}/>\n'
    body += eyes(342, 358, 186, 4) + smile(350, 200, 7, 3.5)
    body += '  </g>\n'
    write("bos_galeri.svg", 400, 300, body, d)


def menu_card() -> None:
    # Ana menü kartı (320x300): yarısı boyanmış kedi sayfası, boya kalemleri
    d = linear("kagit", [(0, "#FFFFFF"), (1, "#F1EEFA")])
    d += linear("k1", [(0, "#FF8A8A"), (1, "#E0485A")], 1, 0) + linear("k2", [(0, "#8FD0FF"), (1, "#3E8EEB")], 1, 0)
    d += linear("k3", [(0, "#FFE58A"), (1, "#F2B53D")], 1, 0)
    body = f'  <rect x="36" y="26" width="220" height="220" rx="16" transform="rotate(-5 146 136)" fill="url(#kagit)" {st(8)}/>\n'
    g = '  <g transform="rotate(-5 146 136)">\n'
    for s in (1, -1):
        g += f'    <path d="M{146 - s * 56} 110 L{146 - s * 62} 50 L{146 - s * 16} 84 Z" fill="{"#FFA84D" if s == 1 else "#FFFFFF"}" {st(7)}/>\n'
    g += f'    <ellipse cx="146" cy="190" rx="62" ry="46" fill="#FFFFFF" {st(7)}/>\n'
    g += f'    <path d="M146 144 L146 236 Q208 232 208 190 Q208 146 146 144 Z" fill="#8B6CF6" opacity="0.9"/>\n'
    g += f'    <ellipse cx="146" cy="190" rx="62" ry="46" fill="none" {st(7)}/>\n'
    g += f'    <ellipse cx="146" cy="120" rx="72" ry="58" fill="#FFA84D" {st(7)}/>\n'
    g += f'    <path d="M146 62 L146 178 Q74 176 74 120 Q74 64 146 62 Z" fill="#FFFFFF"/>\n'
    g += f'    <ellipse cx="146" cy="120" rx="72" ry="58" fill="none" {st(7)}/>\n'
    g += eyes(122, 170, 116, 7).replace("  <", "    <")
    g += f'    <path d="M139 136 H153 L146 144 Z" fill="{OUT}"/>\n'
    g += '  </g>\n'
    body += g
    for k, (c, x, rot) in enumerate((("k1", 232, 20), ("k2", 262, 34), ("k3", 290, 48))):
        body += f'  <g transform="rotate({rot} {x} 200)">\n'
        body += f'    <rect x="{x - 14}" y="130" width="28" height="104" rx="7" fill="url(#{c})" {st(6)}/>\n'
        body += f'    <path d="M{x - 14} 132 L{x + 14} 132 L{x} 100 Z" fill="#F7D2B0" {st(5)}/>\n'
        body += '  </g>\n'
    body += f'  <polygon points="{pts(star(40, 250, 18, 7, 4, 0))}" fill="#FFD23F" {st(4)}/>\n'
    write("kart.svg", 320, 300, body, d)


if __name__ == "__main__":
    bucket()
    brush()
    rainbow_brush()
    stamp_tool()
    eraser()
    undo()
    save_icon()
    magnifier()
    broom()
    trash()
    yes_no()
    stamps()
    new_picture()
    gallery()
    categories()
    empty_gallery()
    menu_card()
