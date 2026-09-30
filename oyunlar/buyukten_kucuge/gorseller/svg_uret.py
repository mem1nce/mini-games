# Büyükten Küçüğe SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre yazar)
# Stil Hayvanları Besle / Müzik Kutusu ile aynı: koyu mor kalın hat, yuvarlak köşeler, radyal gradyanlı
# parlak dolgular, beyaz parıltılar.
#
# İki tür çıktı var:
# 1) sablonlar.json: oyunda boyutu değişen nesneler (halkalar, direk, sıralama nesneleri, bebekler).
#    Bunlar içe aktarılmaz; oyun (cizim.gd, SizeArt) şablonu her boyut için ayrı çizer. Böylece
#      - çizgi kalınlığı küçük ve büyük nesnede aynı görünür (stroke-width değerleri boyuta göre ayarlanır),
#      - renk tonları şablona yazılır: {L} {l} {c} {d} {D} (açıktan koyuya; tones() ile aynı formül cizim.gd'de),
#      - "boy" nesnelerinde (zürafa, kalem, çiçek, kule, direk) genişlik sabit kalır, sadece orta parça uzar:
#        üst parça 0..top, orta parça top..top+{N}, alt parça translate(0 {Y}) ile en altta; tuval yüksekliği {H}.
#    Kaynak önizlemeleri kaynak/<ad>.svg (varsayılan renk ve boyla; .gdignore: Godot içe aktarmaz;
#    ana menü kartı bunları kullanır).
# 2) Doğrudan içe aktarılan SVG'ler: nokta (yön ipucu), yuva (NinePatch), yildiz, isilti, arka_plan.
#
# Yeniden kullanılanlar (renkleri şablon tonlarına çevrilerek): balon (Toplama), balik ve ayi (Gölge Eşleştirme),
# agac (Araba Yarışı). yildiz.svg ve isilti.svg Hayvanları Besle'den kopya.

import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
GAMES = os.path.join(HERE, "..", "..")
OUT = "#3B2F6B"
SW = 7

# Şablon yer tutucuları (oyun doldurur)
H, N, Y = "{H}", "{N}", "{Y}"
TL, Tl, Tc, Td, TD = "{L}", "{l}", "{c}", "{d}", "{D}"


# --- Yardımcılar (Hayvanları Besle svg_uret.py ile aynı) ---

def write(name: str, text: str) -> None:
    path = os.path.join(HERE, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(name)


def svg(w, h, body: str, defs: str = "", box: str = "") -> str:
    box = box or f"0 0 {w} {h}"
    text = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{box}">\n'
    if defs:
        text += "  <defs>\n" + defs + "  </defs>\n"
    return text + body + "</svg>\n"


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


def tones(c: str) -> dict:
    # cizim.gd SizeArt.tones() ile aynı olmalı
    return {"L": light(c, 0.6), "l": light(c, 0.3), "c": c, "d": dark(c, 0.25), "D": dark(c, 0.55)}


def radial(gid: str, stops: list, cx: float = 0.4, cy: float = 0.3, r: float = 0.75) -> str:
    s = "".join(f'<stop offset="{o:g}" stop-color="{c}"/>' for o, c in stops)
    return f'    <radialGradient id="{gid}" cx="{cx:g}" cy="{cy:g}" r="{r:g}">{s}</radialGradient>\n'


def linear(gid: str, stops: list, x2: float = 0, y2: float = 1) -> str:
    s = "".join(f'<stop offset="{o:g}" stop-color="{c}"/>' for o, c in stops)
    return f'    <linearGradient id="{gid}" x1="0" y1="0" x2="{x2:g}" y2="{y2:g}">{s}</linearGradient>\n'


def st(width: float = SW) -> str:
    return f'stroke="{OUT}" stroke-width="{width:g}" stroke-linejoin="round" stroke-linecap="round"'


def shine(x: float, y: float, rx: float = 18, ry: float = 8, angle: float = -25, opacity: float = 0.8) -> str:
    return (f'  <ellipse cx="{x:g}" cy="{y:g}" rx="{rx:g}" ry="{ry:g}" transform="rotate({angle:g} {x:g} {y:g})" '
            f'fill="#FFFFFF" opacity="{opacity:g}"/>\n')


def outlined(shapes: str, fill: str, width: float = 14) -> str:
    # Birden çok şekil tek parça görünsün: önce hepsinin kalın dış hattı, sonra dolgusu
    return f'  <g fill="{OUT}" {st(width)}>{shapes}</g>\n  <g fill="{fill}">{shapes}</g>\n'


def body_tone(gid: str) -> str:
    # Renklenebilir ana dolgu (ışık sol üstten)
    return radial(gid, [(0, TL), (0.5, Tc), (1, Td)])


EYE_DEFS = (
    radial("goz", [(0, "#6A5A96"), (0.55, "#2A1F45"), (1, "#150F26")], 0.4, 0.35, 0.7)
    + '    <radialGradient id="yanak" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FF7FA3" stop-opacity="0.85"/>'
    '<stop offset="1" stop-color="#FF7FA3" stop-opacity="0"/></radialGradient>\n'
)


def eyes(y: float, dx: float, r: float = 9) -> str:
    out = ""
    for x in (100 - dx, 100 + dx):
        out += f'  <ellipse cx="{x:g}" cy="{y:g}" rx="{r:g}" ry="{r * 1.2:g}" fill="url(#goz)"/>\n'
        out += f'  <circle cx="{x - r * 0.35:g}" cy="{y - r * 0.45:g}" r="{r * 0.38:g}" fill="#FFFFFF"/>\n'
        out += f'  <circle cx="{x + r * 0.35:g}" cy="{y + r * 0.4:g}" r="{r * 0.16:g}" fill="#FFFFFF"/>\n'
    return out


def cheeks(y: float, dx: float) -> str:
    return "".join(f'  <ellipse cx="{x:g}" cy="{y:g}" rx="13" ry="8" fill="url(#yanak)"/>\n' for x in (100 - dx, 100 + dx))


# --- Şablon kaydı ---

TEMPLATES = {}


def template(name: str, w: float, h: float, body: str, defs: str = "", color: str = "", box: str = "", **extra) -> None:
    # Boyu sabit oranlı şablon (tuval w x h). color: varsayılan ton rengi (boşsa renklenmez)
    TEMPLATES[name] = dict(svg=svg(w, h, body, defs, box), w=w, h=h, sw=SW, tint=bool(color), color=color, **extra)


def tall(name: str, w: float, top: float, bottom: float, min_mid: float, preview_mid: float,
         body: str, defs: str = "", color: str = "") -> None:
    # Uzayan şablon: genişlik w sabit, yükseklik {H} = top + {N} + bottom
    text = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{H}" viewBox="0 0 {w} {H}">\n'
    if defs:
        text += "  <defs>\n" + defs + "  </defs>\n"
    text += body + "</svg>\n"
    TEMPLATES[name] = dict(svg=text, w=w, h=top + preview_mid + bottom, sw=SW, tint=bool(color), color=color,
                           top=top, bottom=bottom, min_mid=min_mid, preview_mid=preview_mid)


def fill_tokens(text: str, color: str, mid: float = 0, top: float = 0, bottom: float = 0) -> str:
    # Önizleme için yer tutucuları doldurur (oyundaki SizeArt._fill ile aynı iş)
    values = {"H": f"{top + mid + bottom:g}", "N": f"{mid:g}", "Y": f"{top + mid:g}"}
    if color:
        values.update(tones(color))
    for k, v in values.items():
        text = text.replace("{" + k + "}", v)
    return text


def repeat_down(pattern, start: float, step: float, count: int = 40) -> str:
    # Orta parçanın deseni: aşağı doğru tekrar eder, clipPath ile {N} boyunda kesilir
    return "".join(pattern(start + k * step, k) for k in range(count))


# --- Halka kulesi ---

def ring() -> None:
    # Yandan görünen yumuşak halka: kapsül biçimi, üstte açık, altta koyu; üst kenarda parlak çizgi
    defs = linear("hg", [(0, TL), (0.35, Tl), (0.7, Tc), (1, Td)])
    b = f'  <rect x="5" y="5" width="246" height="74" rx="37" fill="url(#hg)" {st()}/>\n'
    b += f'  <path d="M40 64 Q128 76 216 64" fill="none" stroke="{TD}" stroke-width="7" stroke-linecap="round" opacity="0.3"/>\n'
    b += '  <path d="M44 20 Q128 8 212 20" fill="none" stroke="#FFFFFF" stroke-width="7" stroke-linecap="round" opacity="0.65"/>\n'
    b += shine(34, 30, 9, 5, -40, 0.85)
    template("halka", 256, 84, b, defs, "#FF5A6E")


def rod() -> None:
    # Halka kulesinin direği: üstte top, ortada uzayan ahşap çubuk, altta geniş ahşap taban
    w, top, bottom = 240, 64, 44
    defs = linear("dg", [(0, "#F3CD92"), (0.5, "#E0A866"), (1, "#B87A45")], 1, 0)
    defs += linear("tg", [(0, "#EDBE7E"), (1, "#B87A45")])
    defs += radial("bg", [(0, TL), (0.55, Tc), (1, Td)], 0.38, 0.3, 0.8)
    b = f'  <rect x="106" y="{top - 8}" width="28" height="{N}" fill="url(#dg)"/>\n'
    b += f'  <path d="M106 {top - 8} V{Y} M134 {top - 8} V{Y}" fill="none" {st()}/>\n'
    b += f'  <g transform="translate(0 {Y})">\n'
    b += f'    <rect x="8" y="-2" width="224" height="40" rx="18" fill="url(#tg)" {st()}/>\n'
    b += '    <path d="M30 10 H210" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" opacity="0.45"/>\n'
    b += '    <path d="M34 28 H206" fill="none" stroke="#8A5A33" stroke-width="4" stroke-linecap="round" opacity="0.35"/>\n'
    b += '  </g>\n'
    b += f'  <circle cx="120" cy="{top - 30}" r="26" fill="url(#bg)" {st()}/>\n'
    b += shine(110, top - 42, 8, 5, -30, 0.85)
    tall("direk", w, top, bottom, 20, 220, b, defs, "#FF5A6E")


# --- Sıralama nesneleri: yeniden kullanılanlar (renkler ton yer tutucularına çevrilir) ---

def reuse(name: str, path: str, colors: dict, box: str, default: str) -> None:
    with open(os.path.join(GAMES, path), encoding="utf-8") as f:
        text = f.read()
    for old, new in colors.items():
        text = re.sub(re.escape(old), new, text, flags=re.IGNORECASE)
    body = text[text.index(">", text.index("<svg")) + 1:text.rindex("</svg>")]
    bx = [float(v) for v in box.split()]
    TEMPLATES[name] = dict(svg=svg(f"{bx[2]:g}", f"{bx[3]:g}", body.lstrip("\n"), box=box), w=bx[2], h=bx[3], sw=7,
                           tint=True, color=default)


def reused() -> None:
    reuse("balon", "toplama/nesneler/balon.svg",
          {"#C9E6FF": TL, "#4FA8FF": Tc, "#2A6FD6": Td, "#1C3F8A": TD, "#1C58B8": Td}, "44 10 168 240", "#4FA8FF")
    reuse("balik", "golge_eslestirme/esyalar/hayvanlar/balik.svg",
          {"#FF6B3D": Td, "#FF8A3D": Tc, "#FFB870": Tl}, "2 40 236 166", "#FF8A3D")
    reuse("ayi", "golge_eslestirme/esyalar/oyuncaklar/ayi.svg",
          {"#C8864B": Tc, "#F2C79A": TL}, "22 14 212 238", "#C8864B")
    reuse("agac", "araba_yarisi/gorseller/agac.svg",
          {"#9BE08A": TL, "#5FBF5F": Tc, "#3E9A4A": Td, "#2F6E3A": TD}, "3 18 196 237", "#5FBF5F")


# --- Sıralama nesneleri: uzayanlar (sadece boy değişir) ---

def giraffe() -> None:
    # Yandan zürafa (sağa bakar): üstte baş, ortada uzayan benekli boyun, altta gövde ve bacaklar
    w, top, bottom = 200, 96, 124
    c, spot = "#FFC94D", "#E0892E"
    defs = radial("zt", [(0, light(c, 0.5)), (0.55, c), (1, dark(c, 0.2))])
    defs += linear("zb", [(0, light(c, 0.35)), (0.5, c), (1, dark(c, 0.15))], 1, 0)
    defs += f'    <clipPath id="boyun"><rect x="82" y="{top - 20}" width="44" height="{N}"/></clipPath>\n' + EYE_DEFS
    b = f'  <rect x="82" y="{top - 20}" width="44" height="{N}" fill="url(#zb)"/>\n'
    spots = repeat_down(lambda y, k: f'<ellipse cx="{95 if k % 2 == 0 else 113}" cy="{y:g}" rx="9" ry="12" fill="{spot}"/>',
                        top - 4, 34)
    b += f'  <g clip-path="url(#boyun)">{spots}</g>\n'
    b += f'  <path d="M82 {top - 20} V{Y} M126 {top - 20} V{Y}" fill="none" {st()}/>\n'
    # Alt parça: kuyruk, bacaklar, gövde
    g = f'  <g transform="translate(0 {Y})">\n'
    g += f'    <path d="M30 34 Q10 44 14 70" fill="none" {st(6)}/><circle cx="14" cy="72" r="6" fill="{spot}" {st(5)}/>\n'
    for x in (40, 66, 128, 154):
        g += f'    <rect x="{x - 10}" y="40" width="20" height="78" rx="8" fill="url(#zb)" {st()}/>\n'
        g += f'    <rect x="{x - 10}" y="104" width="20" height="14" rx="5" fill="#8A5A33"/>\n'
        g += f'    <rect x="{x - 10}" y="40" width="20" height="78" rx="8" fill="none" {st()}/>\n'
    g += f'    <ellipse cx="98" cy="36" rx="82" ry="38" fill="url(#zt)" {st()}/>\n'
    for sx, sy, r in ((52, 30, 11), (84, 50, 9), (122, 26, 12), (150, 46, 9), (100, 18, 7)):
        g += f'    <ellipse cx="{sx}" cy="{sy}" rx="{r}" ry="{r * 0.8:g}" fill="{spot}"/>\n'
    g += '    <ellipse cx="62" cy="18" rx="18" ry="7" transform="rotate(-12 62 18)" fill="#FFFFFF" opacity="0.5"/>\n'
    g += '  </g>\n'
    b += g
    # Üst parça: boynuzlar, kulak, baş, burun
    for x in (98, 118):
        b += f'  <path d="M{x} 36 L{x + 2} 14" fill="none" {st(8)}/>\n'
        b += f'  <path d="M{x} 36 L{x + 2} 14" fill="none" stroke="{c}" stroke-width="2" stroke-linecap="round"/>\n'
        b += f'  <circle cx="{x + 2}" cy="12" r="7" fill="#B8652E" {st(5)}/>\n'
    b += f'  <ellipse cx="80" cy="46" rx="18" ry="9" transform="rotate(-25 80 46)" fill="url(#zt)" {st(6)}/>\n'
    b += f'  <ellipse cx="116" cy="56" rx="42" ry="33" fill="url(#zt)" {st()}/>\n'
    b += f'  <ellipse cx="150" cy="68" rx="30" ry="22" fill="{light(c, 0.55)}" {st()}/>\n'
    b += f'  <ellipse cx="144" cy="64" rx="3.5" ry="2.5" fill="{OUT}"/><ellipse cx="160" cy="66" rx="3.5" ry="2.5" fill="{OUT}"/>\n'
    b += f'  <path d="M140 78 Q150 84 160 78" fill="none" {st(4)}/>\n'
    b += '  <ellipse cx="120" cy="48" rx="7" ry="8.5" fill="url(#goz)"/><circle cx="118" cy="45" r="2.8" fill="#FFFFFF"/>\n'
    b += '  <ellipse cx="116" cy="70" rx="10" ry="6" fill="url(#yanak)"/>\n'
    b += shine(98, 36, 10, 5, -30, 0.7)
    tall("zurafa", w, top, bottom, 10, 170, b, defs)


def pencil() -> None:
    # Boya kalemi (ucu yukarıda): üstte ahşap uç ve renkli grafit, ortada uzayan gövde, altta metal kuşak ve silgi
    w, top, bottom = 100, 108, 62
    defs = linear("kg", [(0, Tl), (0.3, Tc), (0.7, Tc), (1, Td)], 1, 0)
    defs += linear("ah", [(0, "#FBE2B8"), (1, "#E3B37A")], 1, 0)
    defs += linear("mt", [(0, "#F4F2FA"), (0.5, "#C9C3DC"), (1, "#9A92B5")], 1, 0)
    b = f'  <rect x="12" y="{top - 6}" width="76" height="{N}" fill="url(#kg)"/>\n'
    b += f'  <rect x="36" y="{top - 6}" width="10" height="{N}" fill="#FFFFFF" opacity="0.35"/>\n'
    b += f'  <rect x="62" y="{top - 6}" width="8" height="{N}" fill="{TD}" opacity="0.25"/>\n'
    b += f'  <path d="M12 {top - 6} V{Y} M88 {top - 6} V{Y}" fill="none" {st()}/>\n'
    g = f'  <g transform="translate(0 {Y})">\n'
    g += f'    <rect x="8" y="-4" width="84" height="30" rx="5" fill="url(#mt)" {st()}/>\n'
    g += f'    <path d="M10 7 H90 M10 16 H90" fill="none" stroke="#8A83A6" stroke-width="3"/>\n'
    g += f'    <path d="M12 26 H88 V38 Q88 58 50 58 Q12 58 12 38 Z" fill="#FF9FB8" {st()}/>\n'
    g += '    <ellipse cx="30" cy="36" rx="6" ry="4" fill="#FFFFFF" opacity="0.6"/>\n'
    g += '  </g>\n'
    b += g
    b += f'  <path d="M12 {top} L50 10 L88 {top} Q75 {top - 10} 63 {top} Q50 {top - 10} 37 {top} Q25 {top - 10} 12 {top} Z" fill="url(#ah)" {st()}/>\n'
    b += f'  <path d="M36 42 L50 10 L64 42 Q57 38 50 42 Q43 38 36 42 Z" fill="{Tc}" {st(6)}/>\n'
    b += shine(40, 30, 3, 8, 22, 0.7)
    tall("kalem", w, top, bottom, 10, 170, b, defs, "#4FA8FF")


def flower() -> None:
    # Saksıda çiçek: üstte açmış çiçek, ortada uzayan sap, altta yapraklar ve saksı
    w, top, bottom = 160, 124, 96
    defs = radial("yp", [(0, TL), (0.6, Tc), (1, Td)], 0.5, 0.5, 0.6)
    defs += radial("gb", [(0, "#FFF3B0"), (0.6, "#FFD23F"), (1, "#E8A21C")], 0.4, 0.35, 0.7)
    defs += linear("sp", [(0, "#8EDB6E"), (1, "#3E9A4A")], 1, 0)
    defs += linear("sk", [(0, "#F29A6B"), (1, "#C9653E")], 1, 0)
    b = f'  <rect x="73" y="{top - 20}" width="14" height="{N}" fill="url(#sp)"/>\n'
    b += f'  <path d="M73 {top - 20} V{Y} M87 {top - 20} V{Y}" fill="none" {st(6)}/>\n'
    g = f'  <g transform="translate(0 {Y})">\n'
    g += f'    <rect x="73" y="-4" width="14" height="44" fill="url(#sp)"/><path d="M73 -4 V40 M87 -4 V40" fill="none" {st(6)}/>\n'
    for s in (1, -1):
        g += (f'    <path d="M80 26 Q{80 - s * 30} -8 {80 - s * 62} 4 Q{80 - s * 40} 30 80 30 Z" fill="url(#sp)" {st(6)}/>\n'
              f'    <path d="M{80 - s * 8} 25 Q{80 - s * 32} 10 {80 - s * 50} 8" fill="none" stroke="#2F6E3A" stroke-width="3" '
              f'stroke-linecap="round" opacity="0.5"/>\n')
    g += f'    <path d="M30 38 H130 L118 92 H42 Z" fill="url(#sk)" {st()}/>\n'
    g += f'    <rect x="24" y="30" width="112" height="20" rx="7" fill="#F4A77A" {st()}/>\n'
    g += '    <path d="M40 40 H90" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.5"/>\n'
    g += '  </g>\n'
    b += g
    cx, cy = 80, 68
    petals = ""
    for k in range(6):
        petals += f'<ellipse cx="{cx}" cy="{cy - 30}" rx="21" ry="28" transform="rotate({k * 60} {cx} {cy})"/>'
    b += outlined(petals, "url(#yp)")
    for k in range(6):
        b += f'  <ellipse cx="{cx}" cy="{cy - 36}" rx="7" ry="11" transform="rotate({k * 60 - 8} {cx} {cy})" fill="#FFFFFF" opacity="0.3"/>\n'
    b += f'  <circle cx="{cx}" cy="{cy}" r="22" fill="url(#gb)" {st(6)}/>\n'
    b += f'  <circle cx="{cx - 7}" cy="{cy - 3}" r="3.5" fill="{OUT}"/><circle cx="{cx + 7}" cy="{cy - 3}" r="3.5" fill="{OUT}"/>\n'
    b += f'  <path d="M{cx - 7} {cy + 7} Q{cx} {cy + 13} {cx + 7} {cy + 7}" fill="none" {st(3.5)}/>\n'
    tall("cicek", w, top, bottom, 10, 150, b, defs, "#FF7FC8")


def tower() -> None:
    # Masal kulesi: üstte bayraklı sivri çatı, ortada uzayan tuğla duvar, altta kapılı duvar ve taban
    w, top, bottom = 150, 116, 100
    wall = "#E3DDF2"
    defs = linear("dv", [(0, "#F6F3FC"), (0.55, wall), (1, "#BDB3D8")], 1, 0)
    defs += linear("ct", [(0, TL), (0.45, Tc), (1, Td)], 1, 0)
    defs += f'    <clipPath id="tugla"><rect x="24" y="{top - 10}" width="102" height="{N}"/></clipPath>\n'
    b = f'  <rect x="24" y="{top - 10}" width="102" height="{N}" fill="url(#dv)"/>\n'
    bricks = repeat_down(lambda y, k: (f'<path d="M24 {y:g} H126 M{50 if k % 2 else 75} {y:g} V{y + 22:g} '
                                       f'{"M100 %g V%g" % (y, y + 22) if k % 2 else ""}" />'), top + 6, 22)
    b += f'  <g clip-path="url(#tugla)" fill="none" stroke="#A89CC8" stroke-width="3" stroke-linecap="round">{bricks}</g>\n'
    b += f'  <path d="M24 {top - 10} V{Y} M126 {top - 10} V{Y}" fill="none" {st()}/>\n'
    g = f'  <g transform="translate(0 {Y})">\n'
    g += f'    <path d="M24 -6 V84 H126 V-6" fill="url(#dv)"/><path d="M24 -6 V84 M126 -6 V84" fill="none" {st()}/>\n'
    g += f'    <path d="M52 84 V44 Q52 22 75 22 Q98 22 98 44 V84 Z" fill="#9A6A45" {st()}/>\n'
    g += '    <path d="M75 26 V84" stroke="#6E4A2E" stroke-width="3"/><circle cx="88" cy="58" r="3.5" fill="#FFD23F"/>\n'
    g += f'    <rect x="14" y="78" width="122" height="16" rx="6" fill="#B8AED6" {st()}/>\n'
    g += '  </g>\n'
    b += g
    # Çatı: bayrak direği, bayrak, sivri koni, saçak
    b += f'  <path d="M75 30 V4" fill="none" {st(5)}/>\n'
    b += f'  <path d="M76 5 L100 12 L76 20 Z" fill="{Tc}" {st(5)}/>\n'
    b += f'  <path d="M75 22 Q60 60 12 {top - 8} H138 Q90 60 75 22 Z" fill="url(#ct)" {st()}/>\n'
    b += f'  <rect x="10" y="{top - 16}" width="130" height="18" rx="8" fill="{Td}" {st()}/>\n'
    b += f'  <path d="M58 58 Q48 80 32 {top - 22}" fill="none" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" opacity="0.45"/>\n'
    tall("kule", w, top, bottom, 10, 140, b, defs, "#A66BFF")


# --- İç içe bebekler: her karakter üst ve alt yarı (aynı tuvalde; üst üste gelince tam bebek) ---

def doll(name: str, ears: float, default: str) -> None:
    # Tuval 200 x (254 + ears). Baş (100, 72+e) r 56, gövde (100, 162+e) 86x84; açılma çizgisi split'te
    e = ears
    h = 254 + e
    split = 156 + e
    defs = body_tone("kb") + EYE_DEFS
    defs += radial("yz", [(0, "#FFFFFF"), (0.6, "#FFF4E8"), (1, "#F4D9C6")], 0.45, 0.35, 0.8)
    # Açılma yeri bir elips: ön yayı (aşağı kıvrık) üst yarının alt kenarı, arka yayı alt yarının ağzı.
    # Kapalıyken üst yarı ağzı (iki yay arasındaki koyu mercek) tam örter.
    front = f"Q100 {split + 26} 14 {split}"
    back = f"Q100 {split - 26} 186 {split}"
    defs += f'    <clipPath id="ust"><path d="M0 0 H200 V{split} L186 {split} {front} L0 {split} Z"/></clipPath>\n'
    defs += f'    <clipPath id="alt"><path d="M0 {h} V{split} L14 {split} {back} L200 {split} V{h} Z"/></clipPath>\n'
    defs += linear("ic", [(0, OUT), (1, TD)])
    shape = f'<circle cx="100" cy="{72 + e}" r="56"/><ellipse cx="100" cy="{162 + e}" rx="86" ry="84"/>'
    # Alt yarı: gövde, önlükte çiçek, ayaklar
    lo = f'  <g clip-path="url(#alt)">\n' + outlined(shape, "url(#kb)")
    lo += f'  <ellipse cx="100" cy="{196 + e}" rx="52" ry="40" fill="{TL}" {st(5)}/>\n'
    fx, fy = 100, 196 + e
    for k in range(5):
        lo += f'  <ellipse cx="{fx}" cy="{fy - 12}" rx="8" ry="11" transform="rotate({k * 72} {fx} {fy})" fill="{Tl}"/>\n'
    lo += f'  <circle cx="{fx}" cy="{fy}" r="7" fill="#FFD23F"/>\n'
    lo += '  </g>\n'
    for x in (66, 134):
        lo += f'  <ellipse cx="{x}" cy="{240 + e}" rx="22" ry="10" fill="{Td}" {st(6)}/>\n'
    lo += f'  <path d="M14 {split} {back} Q100 {split + 26} 14 {split + 1} Z" fill="url(#ic)" {st(6)}/>\n'
    # Üst yarı: kulaklar, gövde üstü, baş, yüz, patiler, kenar çizgisi
    up = ""
    if name == "tavsan":
        for s in (-1, 1):
            up += f'  <ellipse cx="{100 + s * 26}" cy="46" rx="17" ry="40" transform="rotate({s * 10} {100 + s * 26} 46)" fill="url(#kb)" {st()}/>\n'
            up += f'  <ellipse cx="{100 + s * 26}" cy="50" rx="8" ry="28" transform="rotate({s * 10} {100 + s * 26} 50)" fill="#FFB3C8"/>\n'
    elif name == "ayi":
        for s in (-1, 1):
            up += f'  <circle cx="{100 + s * 46}" cy="{32 + e}" r="20" fill="url(#kb)" {st()}/>\n'
            up += f'  <circle cx="{100 + s * 46}" cy="{32 + e}" r="10" fill="{TL}"/>\n'
    up += f'  <g clip-path="url(#ust)">\n' + outlined(shape, "url(#kb)") + '  </g>\n'
    if name == "penguen":
        up += f'  <path d="M90 {18 + e} Q100 {4 + e} 108 {17 + e}" fill="{Tc}" {st(5)}/>\n'
    # Yüz penceresi
    fy = 80 + e
    up += f'  <ellipse cx="100" cy="{fy}" rx="42" ry="36" fill="url(#yz)" {st(5)}/>\n'
    up += eyes(fy - 6, 16, 8)
    up += cheeks(fy + 12, 27)
    if name == "ayi":
        up += f'  <ellipse cx="100" cy="{fy + 10}" rx="7" ry="5" fill="{OUT}"/>\n'
        up += f'  <path d="M92 {fy + 18} Q100 {fy + 24} 108 {fy + 18}" fill="none" {st(4)}/>\n'
    elif name == "penguen":
        up += f'  <path d="M91 {fy + 6} L109 {fy + 6} L100 {fy + 17} Z" fill="#FFA63D" {st(4)}/>\n'
    else:
        up += f'  <path d="M95 {fy + 7} H105 L100 {fy + 12} Z" fill="#FF7FA3" {st(3.5)}/>\n'
        up += f'  <path d="M92 {fy + 16} Q96 {fy + 21} 100 {fy + 16} Q104 {fy + 21} 108 {fy + 16}" fill="none" {st(3.5)}/>\n'
    # Atkı ve patiler
    up += f'  <path d="M52 {122 + e} Q100 {140 + e} 148 {122 + e}" fill="none" stroke="{OUT}" stroke-width="20" stroke-linecap="round"/>\n'
    up += f'  <path d="M52 {122 + e} Q100 {140 + e} 148 {122 + e}" fill="none" stroke="{Td}" stroke-width="10" stroke-linecap="round"/>\n'
    for s in (-1, 1):
        up += f'  <ellipse cx="{100 + s * 40}" cy="{split - 12}" rx="15" ry="11" fill="{Tl}" {st(5)}/>\n'
    # Açılma yeri: üst yarının alt kenarı
    up += f'  <path d="M186 {split} {front}" fill="none" {st(6)}/>\n'
    up += shine(72, 38 + e, 16, 7, -35, 0.6)
    for part, body in (("alt", lo), ("ust", up)):
        TEMPLATES[f"bebek_{name}_{part}"] = dict(svg=svg(200, h, body, defs), w=200, h=h, sw=SW, tint=True, color=default,
                                                 split=split)


# --- Doğrudan içe aktarılan görseller ---

def dot() -> None:
    # Yön ipucu noktası: parlak pembe bilye
    defs = radial("n", [(0, "#FFD0DE"), (0.5, "#FF7A9A"), (1, "#D94873")])
    b = f'  <circle cx="32" cy="32" r="26" fill="url(#n)" {st(5)}/>\n' + shine(24, 22, 8, 5, -30, 0.85)
    write("nokta.svg", svg(64, 64, b, defs))


def slot() -> None:
    # Yuva (NinePatch; kenar payı 30): yarı saydam beyaz, yumuşak iç gölgeli yuvarlak kutu
    b = '  <rect x="3" y="3" width="90" height="90" rx="26" fill="#FFFFFF" fill-opacity="0.55"/>\n'
    b += '  <rect x="3" y="3" width="90" height="90" rx="26" fill="none" stroke="#3B2F6B" stroke-opacity="0.22" stroke-width="4"/>\n'
    b += '  <path d="M14 12 Q48 7 82 12" fill="none" stroke="#3B2F6B" stroke-opacity="0.08" stroke-width="6" stroke-linecap="round"/>\n'
    write("yuva.svg", svg(96, 96, b))


def background() -> None:
    # Oyun odası (1280x720): üstte çizgili pastel duvar, 420'de süpürgelik, altta ahşap zemin ve ortada yuvarlak halı.
    # Oyun zemin çizgisini ekran yüksekliğinin 420/720'sine koyar ve resmi buna göre ölçekler.
    defs = linear("duvar", [(0, "#FFF6EC"), (1, "#FDE6EA")])
    defs += linear("zemin", [(0, "#F2C894"), (1, "#DDA66C")])
    defs += radial("hali", [(0, "#DCD2FF"), (0.7, "#C7B8FA"), (1, "#B3A2F0")], 0.5, 0.45, 0.6)
    b = '  <rect width="1280" height="420" fill="url(#duvar)"/>\n'
    for k in range(0, 1280, 80):
        b += f'  <rect x="{k}" y="0" width="40" height="420" fill="#FFFFFF" opacity="0.35"/>\n'
    for x, y, r in ((150, 90, 7), (420, 60, 5), (700, 110, 6), (980, 70, 7), (1180, 140, 5), (260, 250, 5), (1060, 300, 6), (560, 300, 4)):
        b += f'  <circle cx="{x}" cy="{y}" r="{r}" fill="#F6B8CB" opacity="0.45"/>\n'
    b += '  <rect y="420" width="1280" height="300" fill="url(#zemin)"/>\n'
    for k, y in enumerate((470, 530, 600, 680)):
        b += f'  <path d="M0 {y} H1280" stroke="#C48A52" stroke-width="3" opacity="0.45"/>\n'
        for x in range(90 + (k % 2) * 160, 1280, 320):
            b += f'  <path d="M{x} {y - (50 if k else 50)} V{y}" stroke="#C48A52" stroke-width="3" opacity="0.35"/>\n'
    b += '  <ellipse cx="640" cy="585" rx="560" ry="112" fill="url(#hali)" opacity="0.9"/>\n'
    b += '  <ellipse cx="640" cy="585" rx="520" ry="92" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-dasharray="18 14" opacity="0.6"/>\n'
    b += '  <rect y="404" width="1280" height="20" fill="#FFFFFF"/>\n'
    b += '  <path d="M0 424 H1280" stroke="#E7C9B0" stroke-width="4"/>\n'
    write("arka_plan.svg", svg(1280, 720, b, defs))


def copy(src: str, name: str) -> None:
    with open(os.path.join(GAMES, src), encoding="utf-8") as f:
        write(name, f.read())


if __name__ == "__main__":
    ring()
    rod()
    reused()
    giraffe()
    pencil()
    flower()
    tower()
    for doll_name, ear, color in (("tavsan", 44, "#FF9EC4"), ("ayi", 16, "#D9955A"), ("penguen", 6, "#5A8CE8")):
        doll(doll_name, ear, color)
    with open(os.path.join(HERE, "sablonlar.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(TEMPLATES, f, ensure_ascii=False, indent=1)
    print("sablonlar.json:", len(TEMPLATES), "şablon")
    # Önizlemeler (Godot içe aktarmaz; ana menü kartı ve göz kontrolü için)
    os.makedirs(os.path.join(HERE, "kaynak"), exist_ok=True)
    with open(os.path.join(HERE, "kaynak", ".gdignore"), "w") as f:
        f.write("")
    for tname, t in TEMPLATES.items():
        mid = t.get("preview_mid", 0)
        write(f"kaynak/{tname}.svg", fill_tokens(t["svg"], t["color"], mid, t.get("top", 0), t.get("bottom", 0)))
    dot()
    slot()
    background()
    copy("hayvan_besle/gorseller/yildiz.svg", "yildiz.svg")
    copy("hayvan_besle/gorseller/isilti.svg", "isilti.svg")
