# Hayvanları Besle SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre ve alt klasörlerine yazar)
# Stil Müzik Kutusu ile aynı (yardımcılar oradaki svg_uret.py'den): koyu mor kalın hat, yuvarlak köşeler,
# radyal gradyanlı parlak dolgular, beyaz parıltılar, altta yumuşak gölge.
#
# - Hayvanlar parçalı çizilir, hepsi aynı 256'lık tuvalde (üst üste konunca tam hayvan olur):
#     hayvanlar/<ad>_govde.svg  gölge, kuyruk, gövde, karın, ayaklar
#     hayvanlar/<ad>_kafa.svg   kulaklar, kafa, burun, desenler (göz ve ağız YOK: onları hayvan_yuzu.gd çizer)
#   Yüzün yerleri (göz, ağız, yanak) FACES sözlüğündedir; aynı sayılar hayvanlar/<ad>.tres içine yazılır.
#   Kedi, köpek ve inek Müzik Kutusu'ndaki çizimlerden bölündü.
# - Yiyecekler: yiyecekler/<ad>.svg (256 tuval). havuc.svg ve muz.svg Köstebek'ten kopya (bu betik yazmaz).
# - Sahne: balon (düşünce balonu), tabak, cit (çit parçası), tepe_uzak, tepe_yakin, gunes, cicek.
# - kart_tavsan.svg: ana menü kartı için yüzü çizilmiş tam tavşan (oyunda kullanılmaz).
# kalp.svg Köstebek'ten, yildiz.svg / bulut.svg / isilti.svg Gölge Eşleştirme'den kopya.

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = "#3B2F6B"
SW = 7


# --- Yardımcılar (Müzik Kutusu svg_uret.py ile aynı) ---

def write(name: str, w: float, h: float, body: str, defs: str = "") -> None:
    text = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:g}" height="{h:g}" viewBox="0 0 {w:g} {h:g}">\n'
    if defs:
        text += "  <defs>\n" + defs + "  </defs>\n"
    text += body + "</svg>\n"
    path = os.path.join(HERE, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
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
    # Hayvanların ve nesnelerin ana dolgusu: ışık sol üstten
    return radial(gid, [(0, light(base, 0.55)), (0.55, base), (1, dark(base, 0.22))])


SHADOW_DEF = ('    <radialGradient id="golge" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#3A2A4A" stop-opacity="0.3"/>'
              '<stop offset="1" stop-color="#3A2A4A" stop-opacity="0"/></radialGradient>\n')
EYE_DEFS = (
    radial("goz", [(0, "#6A5A96"), (0.55, "#2A1F45"), (1, "#150F26")], 0.4, 0.35, 0.7)
    + '    <radialGradient id="yanak" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FF7FA3" stop-opacity="0.85"/>'
    '<stop offset="1" stop-color="#FF7FA3" stop-opacity="0"/></radialGradient>\n'
)


def st(width: float = SW) -> str:
    return f'stroke="{OUT}" stroke-width="{width:g}" stroke-linejoin="round" stroke-linecap="round"'


def shine(x: float, y: float, rx: float = 18, ry: float = 8, angle: float = -25, opacity: float = 0.8) -> str:
    return f'  <ellipse cx="{x:g}" cy="{y:g}" rx="{rx:g}" ry="{ry:g}" transform="rotate({angle:g} {x:g} {y:g})" fill="#FFFFFF" opacity="{opacity:g}"/>\n'


def outlined(shapes: str, fill: str, width: float = 14) -> str:
    # Birden çok şekil tek parça görünsün: önce hepsinin kalın dış hattı, sonra dolgusu
    return f'  <g fill="{OUT}" {st(width)}>{shapes}</g>\n  <g fill="{fill}">{shapes}</g>\n'


def animal_base(belly: str = "", feet: str = "", body_fill: str = "url(#ten)") -> str:
    body = '  <ellipse cx="128" cy="246" rx="80" ry="10" fill="url(#golge)"/>\n'
    body += f'  <ellipse cx="128" cy="210" rx="54" ry="34" fill="{body_fill}" {st()}/>\n'
    if belly:
        body += f'  <ellipse cx="128" cy="216" rx="30" ry="20" fill="{belly}"/>\n'
    fc = feet or body_fill
    for x in (102, 154):
        body += f'  <ellipse cx="{x}" cy="238" rx="21" ry="11" fill="{fc}" {st(6)}/>\n'
    return body


def head(rx: float = 70, ry: float = 60, cy: float = 132, fill: str = "url(#ten)") -> str:
    return f'  <ellipse cx="128" cy="{cy:g}" rx="{rx:g}" ry="{ry:g}" fill="{fill}" {st()}/>\n'


def whiskers(y: float, dx: float = 40) -> str:
    x1, x2 = 128 - dx, 128 + dx
    return (f'  <path d="M{x1} {y - 4} L{x1 - 26} {y - 10} M{x1} {y + 4} L{x1 - 24} {y + 10} '
            f'M{x2} {y - 4} L{x2 + 26} {y - 10} M{x2} {y + 4} L{x2 + 24} {y + 10}" {st(4)}/>\n')


# --- Hayvanlar: her biri (gövde defs, gövde, kafa defs, kafa) döndürür ---

def cat() -> tuple:
    c = "#FFA84D"
    bd = ten("ten", c) + SHADOW_DEF
    b = f'  <path d="M176 224 C226 222 236 170 206 150" fill="none" stroke="{OUT}" stroke-width="26" stroke-linecap="round"/>\n'
    b += f'  <path d="M176 224 C226 222 236 170 206 150" fill="none" stroke="{c}" stroke-width="13" stroke-linecap="round"/>\n'
    b += animal_base("#FFE0B8")
    hd = ten("ten", c)
    h = ""
    for s in (1, -1):
        h += f'  <path d="M{128 - s * 58} 112 L{128 - s * 64} 42 L{128 - s * 12} 80 Z" fill="url(#ten)" {st()}/>\n'
        h += f'  <path d="M{128 - s * 52} 96 L{128 - s * 56} 58 L{128 - s * 26} 80 Z" fill="#FF9FBF"/>\n'
    h += head()
    h += '  <path d="M114 80 Q118 92 114 100 M128 78 V96 M142 80 Q138 92 142 100" fill="none" stroke="#E07B28" stroke-width="6" stroke-linecap="round"/>\n'
    h += f'  <path d="M120 142 H136 L128 151 Z" fill="#FF7FA3" {st(4)}/>\n'
    h += whiskers(150)
    h += shine(92, 96, 16, 7, -30)
    return bd, b, hd, h


def dog() -> tuple:
    c = "#E8A45C"
    bd = ten("ten", c) + SHADOW_DEF
    b = f'  <path d="M180 206 C214 196 222 170 214 150" fill="none" stroke="{OUT}" stroke-width="24" stroke-linecap="round"/>\n'
    b += f'  <path d="M180 206 C214 196 222 170 214 150" fill="none" stroke="{c}" stroke-width="11" stroke-linecap="round"/>\n'
    b += animal_base("#F9DDB4")
    hd = ten("ten", c) + ten("kulak", "#9B5E3A")
    h = head(72, 60)
    h += '  <ellipse cx="154" cy="124" rx="26" ry="24" fill="#B87A45"/>\n'
    h += f'  <ellipse cx="128" cy="160" rx="38" ry="26" fill="#F9DDB4" {st(5)}/>\n'
    for s in (1, -1):
        x = 128 - s * 68
        h += f'  <ellipse cx="{x}" cy="130" rx="22" ry="46" transform="rotate({s * 18} {x} 130)" fill="url(#kulak)" {st()}/>\n'
    h += f'  <ellipse cx="128" cy="146" rx="14" ry="10" fill="{OUT}"/><ellipse cx="124" cy="142" rx="5" ry="3" fill="#FFFFFF" opacity="0.7"/>\n'
    h += f'  <path d="M128 155 V160" {st(4)}/>\n'
    h += shine(92, 94, 16, 7, -30)
    return bd, b, hd, h


def cow() -> tuple:
    c = "#F4EEF8"
    bd = ten("ten", c) + SHADOW_DEF
    b = animal_base()
    b += '  <ellipse cx="160" cy="206" rx="16" ry="12" fill="#5A4A6E"/>\n'
    b += '  <ellipse cx="100" cy="198" rx="10" ry="8" fill="#5A4A6E"/>\n'
    hd = ten("ten", c) + ten("burun", "#FFB3C6") + ten("boynuz", "#FFF1C8")
    hd += '    <clipPath id="kafa"><ellipse cx="128" cy="132" rx="70" ry="60"/></clipPath>\n'
    h = ""
    for s in (1, -1):
        h += f'  <path d="M{128 - s * 34} 84 Q{128 - s * 44} 50 {128 - s * 60} 48 Q{128 - s * 54} 66 {128 - s * 50} 90 Z" fill="url(#boynuz)" {st(6)}/>\n'
        x = 128 - s * 76
        h += f'  <ellipse cx="{x}" cy="108" rx="28" ry="13" transform="rotate({s * 20} {x} 108)" fill="url(#ten)" {st(6)}/>\n'
        h += f'  <ellipse cx="{x}" cy="108" rx="15" ry="6" transform="rotate({s * 20} {x} 108)" fill="#FFB3C6"/>\n'
    h += head()
    h += '  <g clip-path="url(#kafa)" fill="#5A4A6E"><ellipse cx="82" cy="92" rx="30" ry="24"/><ellipse cx="176" cy="150" rx="22" ry="30"/></g>\n'
    h += head().replace('fill="url(#ten)"', 'fill="none"')
    h += f'  <ellipse cx="128" cy="166" rx="46" ry="28" fill="url(#burun)" {st(6)}/>\n'
    h += '  <ellipse cx="112" cy="158" rx="6" ry="8" fill="#B8577A"/><ellipse cx="144" cy="158" rx="6" ry="8" fill="#B8577A"/>\n'
    h += shine(96, 152, 12, 5, -20, 0.6) + shine(154, 90, 14, 6, 30, 0.7)
    return bd, b, hd, h


def rabbit() -> tuple:
    # Hafıza'daki tavşanın renkleri: beyaz-lila ten, pembe kulak içi
    tone = radial("ten", [(0, "#FFFFFF"), (0.6, "#F8EEF8"), (1, "#E2D0EC")])
    bd = tone + SHADOW_DEF
    b = f'  <circle cx="182" cy="208" r="17" fill="url(#ten)" {st(6)}/>\n'
    b += animal_base("#FFF4FA")
    hd = tone + linear("ic", [(0, "#FFC6DA"), (1, "#FF97BC")])
    h = ""
    for s in (1, -1):
        x = 128 - s * 26
        h += f'  <ellipse cx="{x}" cy="62" rx="19" ry="52" transform="rotate({-s * 10} {x} 100)" fill="url(#ten)" {st()}/>\n'
        h += f'  <ellipse cx="{x}" cy="66" rx="9" ry="38" transform="rotate({-s * 10} {x} 100)" fill="url(#ic)"/>\n'
    h += head(68, 58, 136)
    h += f'  <path d="M121 146 Q128 142 135 146 L128 154 Z" fill="#FF7FA3" {st(4)}/>\n'
    h += whiskers(154, 38)
    h += shine(94, 104, 15, 7, -30)
    return bd, b, hd, h


def monkey() -> tuple:
    c, face = "#A9693E", "#F6D2A2"
    bd = ten("ten", c) + SHADOW_DEF
    tail = "M176 222 C232 226 238 168 206 162 C186 160 184 186 202 186"
    b = f'  <path d="{tail}" fill="none" stroke="{OUT}" stroke-width="22" stroke-linecap="round"/>\n'
    b += f'  <path d="{tail}" fill="none" stroke="{c}" stroke-width="9" stroke-linecap="round"/>\n'
    b += animal_base(face)
    hd = ten("ten", c) + ten("yuz", face)
    h = ""
    for x in (60, 196):
        h += f'  <circle cx="{x}" cy="132" r="27" fill="url(#ten)" {st()}/><circle cx="{x}" cy="132" r="14" fill="{face}"/>\n'
    h += head(70, 60, 132)
    h += f'  <path d="M120 74 Q116 58 130 56 Q140 58 134 68" fill="none" {st(6)}/>\n'
    mask = '<circle cx="105" cy="124" r="27"/><circle cx="151" cy="124" r="27"/><ellipse cx="128" cy="158" rx="48" ry="30"/>'
    h += f'  <g fill="{OUT}" {st(10)}>{mask}</g>\n  <g fill="url(#yuz)">{mask}</g>\n'
    h += f'  <circle cx="121" cy="150" r="3.5" fill="{OUT}"/><circle cx="135" cy="150" r="3.5" fill="{OUT}"/>\n'
    h += shine(90, 90, 15, 7, -30)
    return bd, b, hd, h


def mouse() -> tuple:
    c = "#C3BBD9"
    bd = ten("ten", c) + SHADOW_DEF
    tail = "M178 226 C228 232 240 194 216 182 C200 174 194 196 210 198"
    b = f'  <path d="{tail}" fill="none" stroke="{OUT}" stroke-width="14" stroke-linecap="round"/>\n'
    b += f'  <path d="{tail}" fill="none" stroke="#FFB3C6" stroke-width="5" stroke-linecap="round"/>\n'
    b += animal_base("#EFEAF8", "#FFC6D6")
    hd = ten("ten", c) + ten("kulak", "#FFB3C6")
    h = ""
    for x in (70, 186):
        h += f'  <circle cx="{x}" cy="86" r="38" fill="url(#ten)" {st()}/><circle cx="{x}" cy="88" r="24" fill="url(#kulak)"/>\n'
    h += head(64, 56, 140)
    h += f'  <circle cx="128" cy="156" r="9" fill="#FF7FA3" {st(4)}/>\n'
    h += whiskers(160, 34)
    h += shine(96, 110, 14, 6, -30)
    return bd, b, hd, h


def bear() -> tuple:
    c, muzzle = "#B07A4A", "#F2D2A6"
    bd = ten("ten", c) + SHADOW_DEF
    b = animal_base("#E3B98A")
    hd = ten("ten", c) + ten("burun", muzzle) + radial("nokta", [(0, "#7A5A6E"), (1, "#2A1F45")], 0.4, 0.3, 0.8)
    h = ""
    for x in (72, 184):
        h += f'  <circle cx="{x}" cy="84" r="26" fill="url(#ten)" {st()}/><circle cx="{x}" cy="86" r="13" fill="#E8B88A"/>\n'
    h += head(72, 62, 134)
    h += f'  <ellipse cx="128" cy="162" rx="36" ry="26" fill="url(#burun)" {st(5)}/>\n'
    h += f'  <path d="M116 146 Q128 140 140 146 Q138 156 128 158 Q118 156 116 146 Z" fill="url(#nokta)" {st(4)}/>\n'
    h += '  <ellipse cx="124" cy="146" rx="4" ry="2.5" fill="#FFFFFF" opacity="0.7"/>\n'
    h += shine(90, 96, 16, 7, -30)
    return bd, b, hd, h


def squirrel() -> tuple:
    c = "#D9823B"
    bd = ten("ten", c) + SHADOW_DEF
    tail = "M160 222 C226 220 240 150 204 104"
    b = f'  <path d="{tail}" fill="none" stroke="{OUT}" stroke-width="66" stroke-linecap="round"/>\n'
    b += f'  <path d="{tail}" fill="none" stroke="{c}" stroke-width="52" stroke-linecap="round"/>\n'
    b += f'  <path d="{tail}" fill="none" stroke="{light(c, 0.35)}" stroke-width="18" stroke-linecap="round" opacity="0.8"/>\n'
    b += animal_base("#FCE3C0")
    hd = ten("ten", c)
    h = ""
    for s in (1, -1):
        h += f'  <path d="M{128 - s * 56} 116 L{128 - s * 52} 54 L{128 - s * 16} 88 Z" fill="url(#ten)" {st()}/>\n'
        h += f'  <path d="M{128 - s * 52} 56 L{128 - s * 58} 40 M{128 - s * 52} 56 L{128 - s * 46} 40" {st(5)}/>\n'
        h += f'  <path d="M{128 - s * 50} 102 L{128 - s * 49} 70 L{128 - s * 28} 90 Z" fill="#FFB3A0"/>\n'
    h += head(64, 56, 138)
    h += '  <ellipse cx="128" cy="158" rx="34" ry="22" fill="#FCE3C0"/>\n'
    h += f'  <ellipse cx="128" cy="150" rx="8" ry="6" fill="{OUT}"/>\n'
    h += shine(96, 108, 14, 6, -30)
    return bd, b, hd, h


def panda() -> tuple:
    # Hafıza'daki pandanın renkleri
    white, black = "#F1F3F9", "#36324C"
    tone = radial("ten", [(0, "#FFFFFF"), (0.6, white), (1, "#D5DAEA")])
    dark_tone = radial("siyah", [(0, "#625C7A"), (0.6, black), (1, "#211E30")])
    bd = tone + dark_tone + SHADOW_DEF
    b = '  <ellipse cx="128" cy="246" rx="80" ry="10" fill="url(#golge)"/>\n'
    b += f'  <ellipse cx="128" cy="210" rx="54" ry="34" fill="url(#siyah)" {st()}/>\n'
    b += '  <ellipse cx="128" cy="218" rx="34" ry="22" fill="url(#ten)"/>\n'
    for x in (102, 154):
        b += f'  <ellipse cx="{x}" cy="238" rx="21" ry="11" fill="url(#siyah)" {st(6)}/>\n'
    hd = tone + dark_tone
    h = ""
    for x in (72, 184):
        h += f'  <circle cx="{x}" cy="84" r="25" fill="url(#siyah)" {st()}/>\n'
    h += head(70, 60, 134)
    for x, a in ((100, 30), (156, -30)):
        h += f'  <ellipse cx="{x}" cy="130" rx="21" ry="27" transform="rotate({a} {x} 130)" fill="url(#siyah)"/>\n'
    h += f'  <path d="M119 152 Q128 147 137 152 Q135 159 128 160 Q121 159 119 152 Z" fill="{black}" {st(3)}/>\n'
    h += shine(92, 96, 15, 7, -30)
    return bd, b, hd, h


def bird() -> tuple:
    c = "#5BB8F5"
    bd = ten("ten", c) + SHADOW_DEF
    b = ""
    for s in (1, -1):
        x = 128 - s * 50
        b += f'  <ellipse cx="{x}" cy="206" rx="18" ry="28" transform="rotate({s * 30} {x} 206)" fill="{dark(c, 0.15)}" {st(6)}/>\n'
    b = animal_base("#E8F6FF", "#FF9A3D") + b
    hd = ten("ten", c)
    crest = "M122 84 Q112 58 124 48 M130 82 Q134 54 148 52"
    h = f'  <path d="{crest}" fill="none" stroke="{OUT}" stroke-width="16" stroke-linecap="round"/>\n'
    h += f'  <path d="{crest}" fill="none" stroke="{c}" stroke-width="7" stroke-linecap="round"/>\n'
    h += head(64, 56, 134)
    h += '  <ellipse cx="128" cy="164" rx="36" ry="20" fill="#E8F6FF" opacity="0.8"/>\n'
    h += shine(96, 104, 14, 6, -30)
    return bd, b, hd, h


# Yüz yerleri (256 tuvalinde): gözler (y, merkeze uzaklık, yarıçaplar), ağız (y, genişlik), yanaklar (y, uzaklık),
# ten rengi (çiğnerken şişen yanak), özellikler. hayvanlar/<ad>.tres içindeki değerler bunlarla aynıdır.
FACES = {
    "kedi": dict(eye=(124, 26, 14, 17), mouth=(155, 12), cheek=(150, 48), skin="#FFA84D"),
    "kopek": dict(eye=(120, 26, 14, 17), mouth=(161, 13), cheek=(156, 52), skin="#E8A45C"),
    "inek": dict(eye=(114, 28, 13, 16), mouth=(180, 12), cheek=(142, 54), skin="#F4EEF8"),
    "tavsan": dict(eye=(128, 26, 13, 16), mouth=(158, 11), cheek=(154, 46), skin="#F8EEF8", teeth=True),
    "maymun": dict(eye=(124, 22, 12, 15), mouth=(163, 14), cheek=(158, 40), skin="#F6D2A2"),
    "fare": dict(eye=(132, 24, 12, 15), mouth=(168, 10), cheek=(158, 44), skin="#C3BBD9", teeth=True),
    "ayi": dict(eye=(122, 28, 12, 15), mouth=(166, 12), cheek=(152, 54), skin="#B07A4A"),
    "sincap": dict(eye=(128, 24, 12, 15), mouth=(160, 11), cheek=(156, 44), skin="#D9823B", teeth=True),
    "panda": dict(eye=(128, 28, 10, 13), mouth=(163, 11), cheek=(156, 50), skin="#F1F3F9", eye_white=True),
    "kus": dict(eye=(124, 24, 13, 16), mouth=(152, 16), cheek=(150, 44), skin="#5BB8F5", beak=True),
}

ANIMALS = {"kedi": cat, "kopek": dog, "inek": cow, "tavsan": rabbit, "maymun": monkey, "fare": mouse,
           "ayi": bear, "sincap": squirrel, "panda": panda, "kus": bird}


def animals() -> None:
    for name, draw in ANIMALS.items():
        bd, b, hd, h = draw()
        write(f"hayvanlar/{name}_govde.svg", 256, 256, b, bd)
        write(f"hayvanlar/{name}_kafa.svg", 256, 256, h, hd)


# Ana menü kartı için yüzü çizilmiş, ağzı açık, mutlu tavşan
def card_rabbit() -> None:
    bd, b, hd, h = rabbit()
    y, dx, rx, ry = FACES["tavsan"]["eye"]
    face = ""
    for x in (128 - dx, 128 + dx):
        face += f'  <ellipse cx="{x:g}" cy="{y:g}" rx="{rx:g}" ry="{ry:g}" fill="url(#goz)"/>\n'
        face += f'  <ellipse cx="{x - rx * 0.35:g}" cy="{y - ry * 0.45:g}" rx="{rx * 0.42:g}" ry="{ry * 0.4:g}" fill="#FFFFFF"/>\n'
    cy, cdx = FACES["tavsan"]["cheek"]
    face += "".join(f'  <ellipse cx="{x:g}" cy="{cy:g}" rx="17" ry="10" fill="url(#yanak)"/>\n' for x in (128 - cdx, 128 + cdx))
    my = FACES["tavsan"]["mouth"][0]
    face += (f'  <path d="M112 {my} Q128 {my - 3} 144 {my} Q142 {my + 22} 128 {my + 22} Q114 {my + 22} 112 {my} Z" fill="#8A2A4A" {st(5)}/>\n'
             f'  <path d="M118 {my + 14} Q128 {my + 8} 138 {my + 14} Q136 {my + 20} 128 {my + 20} Q120 {my + 20} 118 {my + 14} Z" fill="#FF8FB0"/>\n')
    defs = bd + hd.replace(radial("ten", [(0, "#FFFFFF"), (0.6, "#F8EEF8"), (1, "#E2D0EC")]), "") + EYE_DEFS
    write("kart_tavsan.svg", 256, 256, b + h + face, defs)


# --- Yiyecekler (256 tuval) ---

def bone() -> None:
    defs = radial("kemik", [(0, "#FFFFFF"), (0.6, "#FFF4DE"), (1, "#E6D2AE")])
    shapes = ('<rect x="72" y="110" width="112" height="36" rx="12"/>'
              '<circle cx="70" cy="106" r="24"/><circle cx="70" cy="150" r="24"/>'
              '<circle cx="186" cy="106" r="24"/><circle cx="186" cy="150" r="24"/>')
    body = '  <g transform="rotate(-24 128 128)">\n' + outlined(shapes, "url(#kemik)")
    body += shine(66, 96, 10, 5, -30) + shine(120, 118, 30, 5, 0, 0.7)
    body += "  </g>\n"
    write("yiyecekler/kemik.svg", 256, 256, body, defs)


def fish() -> None:
    defs = radial("pul", [(0, "#BDF2FF"), (0.55, "#4FC3E8"), (1, "#2E86C4")], 0.35, 0.3, 0.8)
    defs += ten("yuzgec", "#FF9A3D")
    body = '  <g transform="rotate(-12 128 128)">\n'
    body += f'  <path d="M176 128 L230 90 Q222 128 230 166 Z" fill="url(#yuzgec)" {st()}/>\n'
    body += f'  <path d="M96 88 Q124 58 150 90 Z" fill="url(#yuzgec)" {st(6)}/>\n'
    body += f'  <ellipse cx="116" cy="128" rx="74" ry="46" fill="url(#pul)" {st()}/>\n'
    body += f'  <path d="M120 100 Q108 128 120 156 M144 100 Q132 128 144 156" fill="none" stroke="#2E86C4" stroke-width="5" stroke-linecap="round" opacity="0.6"/>\n'
    body += f'  <circle cx="76" cy="118" r="13" fill="#FFFFFF" {st(4)}/><circle cx="73" cy="118" r="6.5" fill="{OUT}"/>\n'
    body += f'  <path d="M50 138 Q58 146 66 140" fill="none" {st(4)}/>\n'
    body += shine(100, 100, 22, 7, -15)
    body += "  </g>\n"
    write("yiyecekler/balik.svg", 256, 256, body, defs)


def cheese() -> None:
    defs = radial("peynir", [(0, "#FFF4B0"), (0.55, "#FFD23F"), (1, "#F0A81E")], 0.35, 0.3, 0.85)
    defs += linear("yan", [(0, "#FFC83A"), (1, "#E89A18")])
    body = f'  <path d="M36 150 L200 78 L224 110 L224 190 L36 190 Z" fill="url(#yan)" {st()}/>\n'
    body += f'  <path d="M36 150 L200 78 L224 110 L60 170 Z" fill="url(#peynir)" {st(6)}/>\n'
    body += f'  <path d="M60 170 L224 110" fill="none" {st(5)}/>\n'
    body += f'  <path d="M60 170 L60 190" fill="none" {st(5)}/>\n'
    for x, y, r in ((96, 182, 11), (150, 160, 14), (196, 180, 9), (190, 136, 8), (120, 136, 7)):
        body += f'  <circle cx="{x}" cy="{y}" r="{r}" fill="#E8961C" {st(3)}/>\n'
    body += shine(120, 118, 24, 5, -24)
    write("yiyecekler/peynir.svg", 256, 256, body, defs)


def honey() -> None:
    defs = linear("bal", [(0, "#FFC94A"), (0.5, "#FFA41E"), (1, "#E07A10")], 1, 1)
    defs += ten("kapak", "#FF6B6B")
    body = f'  <rect x="64" y="96" width="128" height="124" rx="38" fill="url(#bal)" {st()}/>\n'
    body += f'  <ellipse cx="128" cy="160" rx="38" ry="30" fill="#FFF3D0" {st(5)}/>\n'
    hexagon = " ".join(f"{128 + 14 * math.cos(math.radians(60 * k)):.1f},{160 + 14 * math.sin(math.radians(60 * k)):.1f}" for k in range(6))
    body += f'  <polygon points="{hexagon}" fill="#FFB52E" {st(4)}/>\n'
    scallop = "M56 100 Q58 72 76 70 H180 Q198 72 200 100 Q188 94 178 104 Q166 92 152 104 Q140 92 128 104 Q116 92 104 104 Q90 92 78 104 Q68 94 56 100 Z"
    body += f'  <path d="{scallop}" fill="url(#kapak)" {st(6)}/>\n'
    for x, y in ((86, 84), (118, 80), (150, 84), (178, 82)):
        body += f'  <circle cx="{x}" cy="{y}" r="5" fill="#FFFFFF" opacity="0.9"/>\n'
    body += f'  <path d="M68 70 H188" {st(6)}/>\n'
    body += f'  <path d="M150 104 Q150 124 156 126 Q162 124 160 104 Z" fill="#FFA41E" {st(4)}/>\n'
    body += shine(84, 138, 8, 22, 0, 0.6)
    write("yiyecekler/bal.svg", 256, 256, body, defs)


def acorn() -> None:
    defs = radial("fistik", [(0, "#FFD9A0"), (0.55, "#E09A52"), (1, "#B06A2C")], 0.35, 0.3, 0.8)
    defs += ten("sapka", "#8B5A2B")
    body = f'  <ellipse cx="128" cy="156" rx="54" ry="64" fill="url(#fistik)" {st()}/>\n'
    body += f'  <path d="M128 222 L128 214" {st(6)}/>\n'
    body += f'  <path d="M64 124 Q64 70 128 66 Q192 70 192 124 Q128 142 64 124 Z" fill="url(#sapka)" {st()}/>\n'
    body += (f'  <path d="M84 96 L108 124 M104 80 L136 128 M128 72 L160 124 M152 76 L176 110 M172 92 L148 128 '
             f'M150 76 L112 128 M122 70 L86 118" fill="none" stroke="#5E3A1A" stroke-width="3" stroke-linecap="round" opacity="0.55"/>\n')
    body += f'  <path d="M128 66 Q126 46 138 34" fill="none" {st(10)}/>\n'
    body += '  <path d="M128 66 Q126 46 138 34" fill="none" stroke="#8B5A2B" stroke-width="4" stroke-linecap="round"/>\n'
    body += shine(102, 158, 10, 20, 10, 0.6) + shine(100, 88, 14, 5, -25, 0.5)
    write("yiyecekler/palamut.svg", 256, 256, body, defs)


def grass() -> None:
    defs = linear("ot", [(0, "#B8F07A"), (1, "#4EA83C")])
    defs += linear("ot2", [(0, "#DDF79A"), (1, "#7BC24A")])
    # Her yaprak kendi hattıyla; önce yandakiler, en son ortadakiler (öndekiler)
    order = sorted(range(-44, 45, 11), key=lambda a: -abs(a))
    body = ""
    for a in order:
        k = (a + 44) // 11
        r = 128 if k % 2 == 0 else 112
        ang = math.radians(a - 90)
        tx, ty = 128 + r * math.cos(ang), 176 + r * math.sin(ang)
        nx, ny = -math.sin(ang), math.cos(ang)
        w = 16
        c1 = (128 + (tx - 128) * 0.5 + nx * w, 176 + (ty - 176) * 0.5 + ny * w)
        c2 = (128 + (tx - 128) * 0.5 - nx * w, 176 + (ty - 176) * 0.5 - ny * w)
        grad = "ot" if k % 2 == 0 else "ot2"
        body += (f'  <path d="M128 176 Q{c1[0]:.1f} {c1[1]:.1f} {tx:.1f} {ty:.1f} Q{c2[0]:.1f} {c2[1]:.1f} 128 176 Z" '
                 f'fill="url(#{grad})" {st(5)}/>\n')
    body += f'  <path d="M110 176 L100 226 H156 L146 176 Z" fill="url(#ot)" {st(6)}/>\n'
    body += f'  <rect x="98" y="166" width="60" height="22" rx="8" fill="#C98A4A" {st(6)}/>\n'
    body += '  <path d="M104 172 L152 182 M104 182 L152 172" stroke="#8B5A2B" stroke-width="3" stroke-linecap="round"/>\n'
    for x, y in ((84, 74), (170, 64)):
        petals = "".join(f'<circle cx="{x + 9 * math.cos(math.radians(72 * i)):.1f}" cy="{y + 9 * math.sin(math.radians(72 * i)):.1f}" r="7"/>' for i in range(5))
        body += f'  <g fill="#FFFFFF" {st(3)}>{petals}</g><circle cx="{x}" cy="{y}" r="6" fill="#FFD23F" {st(3)}/>\n'
    write("yiyecekler/ot.svg", 256, 256, body, defs)


def bamboo() -> None:
    defs = linear("bambu", [(0, "#A8E48A"), (0.5, "#6CC454"), (1, "#3E9A3A")], 1, 0)
    defs += linear("yaprak", [(0, "#9BE27A"), (1, "#3E9A3A")])
    body = ""
    for x, top, bottom in ((100, 40, 222), (146, 60, 226)):
        body += f'  <rect x="{x - 17}" y="{top}" width="34" height="{bottom - top}" rx="14" fill="url(#bambu)" {st()}/>\n'
        y = top + 50
        while y < bottom - 20:
            body += f'  <rect x="{x - 20}" y="{y - 5}" width="40" height="10" rx="5" fill="#5DB048" {st(4)}/>\n'
            y += 52
        body += shine(x - 7, (top + bottom) / 2, 3, 30, 0, 0.5)
    for x, y, a in ((76, 86, -40), (174, 110, 35), (166, 150, 55)):
        body += f'  <ellipse cx="{x}" cy="{y}" rx="30" ry="11" transform="rotate({a} {x} {y})" fill="url(#yaprak)" {st(5)}/>\n'
    write("yiyecekler/bambu.svg", 256, 256, body, defs)


def seeds() -> None:
    defs = ten("kase", "#FF8FA3") + radial("yigin", [(0, "#FFF0C8"), (1, "#E6C58A")], 0.4, 0.3, 0.8)
    body = f'  <ellipse cx="128" cy="140" rx="84" ry="30" fill="url(#yigin)" {st(6)}/>\n'
    rng = [(84, 128, -20), (108, 118, 15), (134, 114, -10), (160, 122, 25), (178, 136, -30), (96, 142, 35),
           (122, 136, -25), (148, 140, 10), (70, 140, 20), (116, 104, 0), (142, 100, 30), (164, 108, -15)]
    for x, y, a in rng:
        body += (f'  <g transform="rotate({a} {x} {y})"><ellipse cx="{x}" cy="{y}" rx="7" ry="11" fill="#4A3A4E" {st(2.5)}/>'
                 f'<path d="M{x} {y - 8} V{y + 8}" stroke="#E8E0F0" stroke-width="2" stroke-linecap="round"/></g>\n')
    body += f'  <path d="M40 142 Q44 214 128 214 Q212 214 216 142 Q128 170 40 142 Z" fill="url(#kase)" {st()}/>\n'
    body += '  <path d="M58 170 Q128 186 198 170" fill="none" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" opacity="0.6"/>\n'
    for x, y, a in ((56, 222, 30), (206, 224, -20)):
        body += f'  <ellipse cx="{x}" cy="{y}" rx="6" ry="9" transform="rotate({a} {x} {y})" fill="#4A3A4E" {st(2.5)}/>\n'
    write("yiyecekler/tohum.svg", 256, 256, body, defs)


# --- Sahne parçaları ---

def bubble() -> None:
    # Düşünce balonu (240x210): bulut biçimli balon, sol altta başa doğru iki küçük kabarcık.
    # Balonun iç merkezi (120, 88); yiyecek resmi ve noktalar dusunce_balonu.gd'de buna göre yerleşir.
    defs = radial("balon", [(0, "#FFFFFF"), (0.7, "#FFFFFF"), (1, "#EDE6FA")], 0.45, 0.35, 0.8)
    shapes = ('<circle cx="62" cy="92" r="44"/><circle cx="104" cy="56" r="44"/><circle cx="152" cy="58" r="42"/>'
              '<circle cx="186" cy="96" r="40"/><circle cx="148" cy="130" r="36"/><circle cx="92" cy="130" r="36"/>'
              '<ellipse cx="122" cy="94" rx="80" ry="50"/>')
    body = outlined(shapes, "url(#balon)", 12)
    body += f'  <circle cx="70" cy="178" r="14" fill="#FFFFFF" {st(5)}/>\n'
    body += f'  <circle cx="52" cy="200" r="8" fill="#FFFFFF" {st(4)}/>\n'
    write("balon.svg", 240, 212, body, defs)


def plate() -> None:
    defs = radial("tabak", [(0, "#FFFFFF"), (0.7, "#F2F8FF"), (1, "#C9DDF5")], 0.45, 0.3, 0.8)
    body = f'  <ellipse cx="128" cy="54" rx="118" ry="38" fill="url(#tabak)" {st(6)}/>\n'
    body += '  <ellipse cx="128" cy="52" rx="80" ry="22" fill="#E3EEFB"/>\n'
    body += '  <path d="M40 58 Q128 92 216 58" fill="none" stroke="#7FB2F0" stroke-width="5" stroke-linecap="round" opacity="0.6"/>\n'
    write("tabak.svg", 256, 104, body, defs)


def fence() -> None:
    # Çit parçası (160x150): yan yana döşenir
    defs = linear("tahta", [(0, "#FFFFFF"), (1, "#F1E3D2")])
    body = ""
    for y in (62, 110):
        body += f'  <rect x="-6" y="{y}" width="172" height="18" rx="6" fill="url(#tahta)" {st(5)}/>\n'
    for x in (40, 120):
        body += f'  <path d="M{x - 20} 146 V34 L{x} 12 L{x + 20} 34 V146 Z" fill="url(#tahta)" {st(5)}/>\n'
    write("cit.svg", 160, 150, body, defs)


def hills() -> None:
    far = '  <path d="M0 150 Q170 60 380 120 T800 100 T1200 120 T1600 90 V300 H0 Z" fill="#BFE7A6"/>\n'
    write("tepe_uzak.svg", 1600, 300, far)
    defs = linear("cim", [(0, "#9EDB7E"), (1, "#7CC862")])
    near = '  <path d="M0 120 Q260 50 560 110 T1100 96 T1600 110 V300 H0 Z" fill="url(#cim)"/>\n'
    write("tepe_yakin.svg", 1600, 300, near, defs)


def sun() -> None:
    defs = radial("gunes", [(0, "#FFF6B0"), (0.6, "#FFD84A"), (1, "#FFB52E")])
    rays = ""
    for k in range(10):
        a = math.radians(k * 36)
        x1, y1 = 100 + 64 * math.cos(a), 100 + 64 * math.sin(a)
        x2, y2 = 100 + 90 * math.cos(a), 100 + 90 * math.sin(a)
        rays += f"M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f} "
    body = f'  <path d="{rays}" stroke="#FFC83A" stroke-width="12" stroke-linecap="round"/>\n'
    body += f'  <circle cx="100" cy="100" r="54" fill="url(#gunes)" {st(6)}/>\n'
    body += f'  <path d="M76 96 Q84 88 92 96 M108 96 Q116 88 124 96" fill="none" {st(5)}/>\n'
    body += f'  <path d="M84 114 Q100 128 116 114" fill="none" {st(5)}/>\n'
    body += '  <ellipse cx="72" cy="112" rx="9" ry="5" fill="#FF9AB0" opacity="0.7"/><ellipse cx="128" cy="112" rx="9" ry="5" fill="#FF9AB0" opacity="0.7"/>\n'
    write("gunes.svg", 200, 200, body, defs)


def flower() -> None:
    petals = "".join(f'<circle cx="{32 + 13 * math.cos(math.radians(72 * i - 90)):.1f}" cy="{30 + 13 * math.sin(math.radians(72 * i - 90)):.1f}" r="10"/>' for i in range(5))
    body = f'  <path d="M32 40 V62" {st(5)}/>\n'
    body += f'  <g fill="#FFFFFF" {st(4)}>{petals}</g>\n'
    body += f'  <circle cx="32" cy="30" r="8" fill="#FFD23F" {st(4)}/>\n'
    write("cicek.svg", 64, 64, body)


if __name__ == "__main__":
    animals()
    card_rabbit()
    bone()
    fish()
    cheese()
    honey()
    acorn()
    grass()
    bamboo()
    seeds()
    bubble()
    plate()
    fence()
    hills()
    sun()
    flower()
