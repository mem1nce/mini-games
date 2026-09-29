# Sihirli Bahçe SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre ve bitkiler/ alt klasörüne yazar)
# Tarz hafıza oyunuyla uyumlu: yumuşak gradyanlar, parlama noktaları, yumuşak koyu dış çizgi.
# Bitkiler: 240x300 tuval, bitkinin toprağa girdiği nokta (120, 288). Her bitkinin 5 aşaması ayrı çizilir:
#   _0 tohum, _1 filiz, _2 fidan, _3 tomurcuk, _4 olgun. Yeni bitki: PLANTS'e ekle, _3 ve _4 çizimini yaz.

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 240, 300
BX, BY = 120, 288          # bitkinin toprağa girdiği nokta
OUT_GREEN = "#2E6B3A"
OUT_BROWN = "#5E3A22"
LEAF = ("#B8EE9E", "#6CC66A", "#3F9A4C")


class Svg:
    def __init__(self, w: int = W, h: int = H):
        self.w, self.h = w, h
        self.defs: list = []
        self.body: list = []
        self.n = 0

    def _id(self) -> str:
        self.n += 1
        return f"g{self.n}"

    def rgrad(self, colors: list, cx: float = 0.4, cy: float = 0.32, r: float = 0.75) -> str:
        gid = self._id()
        stops = "".join(f'<stop offset="{i / max(1, len(colors) - 1):.2f}" stop-color="{c}"/>' for i, c in enumerate(colors))
        self.defs.append(f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}">{stops}</radialGradient>')
        return f"url(#{gid})"

    def lgrad(self, colors: list, x1=0.0, y1=0.0, x2=0.0, y2=1.0) -> str:
        gid = self._id()
        stops = "".join(f'<stop offset="{i / max(1, len(colors) - 1):.2f}" stop-color="{c}"/>' for i, c in enumerate(colors))
        self.defs.append(f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{stops}</linearGradient>')
        return f"url(#{gid})"

    def add(self, s: str) -> None:
        self.body.append(s)

    def text(self, scale: float = 1.0) -> str:
        # scale: çizimi bitkinin toprağa girdiği noktanın etrafında büyütür (küçük aşamalar ekranda görünsün)
        body = "\n  ".join(self.body)
        if scale != 1.0:
            body = f'<g transform="translate({BX} 292) scale({scale}) translate({-BX} -292)">\n  {body}\n  </g>'
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}">\n'
                f'  <defs>{"".join(self.defs)}</defs>\n  ' + body + "\n</svg>\n")


def write(rel: str, text: str) -> None:
    path = os.path.join(HERE, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


# --- Temel şekiller ---

def smooth(points: list) -> str:
    d = f"M {points[0][0]:.1f} {points[0][1]:.1f} "
    for i in range(len(points) - 1):
        p0 = points[i - 1] if i > 0 else points[i]
        p1, p2 = points[i], points[i + 1]
        p3 = points[i + 2] if i + 2 < len(points) else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f"C {c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {p2[0]:.1f} {p2[1]:.1f} "
    return d


def stem(s: Svg, points: list, width: float = 8.0, color: str = "#6CC66A", out: str = OUT_GREEN) -> None:
    d = smooth(points)
    s.add(f'<path d="{d}" fill="none" stroke="{out}" stroke-width="{width + 9}" stroke-linecap="round" stroke-linejoin="round"/>')
    s.add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')
    s.add(f'<path d="{d}" fill="none" stroke="#FFFFFF" stroke-width="{width * 0.28:.1f}" stroke-linecap="round" opacity="0.3" transform="translate({-width * 0.2:.1f} 0)"/>')


def leaf(s: Svg, x: float, y: float, length: float, width: float, angle: float, pal=LEAF, out: str = OUT_GREEN, vein: bool = True) -> None:
    # Taban (x, y), uç açısı angle derece (0 = sağa, -90 = yukarı)
    L, Wd = length, width
    d = f"M 0 0 C {L * 0.25:.1f} {-Wd:.1f} {L * 0.8:.1f} {-Wd * 0.9:.1f} {L:.1f} 0 C {L * 0.8:.1f} {Wd * 0.9:.1f} {L * 0.25:.1f} {Wd:.1f} 0 0 Z"
    fill = s.lgrad([pal[0], pal[1], pal[2]], 0, 0, 0, 1)
    tr = f'transform="translate({x:.1f} {y:.1f}) rotate({angle:.1f})"'
    s.add(f'<path d="{d}" {tr} fill="{fill}" stroke="{out}" stroke-width="5" stroke-linejoin="round"/>')
    if vein:
        s.add(f'<path d="M {L * 0.12:.1f} 0 Q {L * 0.5:.1f} {-Wd * 0.12:.1f} {L * 0.86:.1f} 0" {tr} fill="none" stroke="{out}" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>')
    s.add(f'<path d="M {L * 0.25:.1f} {-Wd * 0.45:.1f} Q {L * 0.45:.1f} {-Wd * 0.7:.1f} {L * 0.65:.1f} {-Wd * 0.55:.1f}" {tr} fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.45"/>')


def petal_path(L: float, Wd: float) -> str:
    # Not: Godot'nun SVG çizicisi, bir eğrinin iki kontrol noktası aynı yükseklikteyse degrade dolguyu çizmiyor;
    # bu yüzden kontrol noktaları birebir aynı yapılmaz.
    return f"M 0 0 C {L * 0.2:.1f} {-Wd:.1f} {L * 0.85:.1f} {-Wd * 0.94:.1f} {L:.1f} 0 C {L * 0.85:.1f} {Wd * 0.94:.1f} {L * 0.2:.1f} {Wd:.1f} 0 0 Z"


def petals(s: Svg, cx: float, cy: float, n: int, length: float, width: float, fill, out: str, start: float = -90.0, colors=None) -> None:
    for k in range(n):
        a = start + k * 360.0 / n
        f = colors[k % len(colors)] if colors else fill
        s.add(f'<path d="{petal_path(length, width)}" transform="translate({cx:.1f} {cy:.1f}) rotate({a:.1f})" fill="{f}" stroke="{out}" stroke-width="5" stroke-linejoin="round"/>')


def circle(s: Svg, cx, cy, r, fill, out=None, sw=5, extra="") -> None:
    stroke = f' stroke="{out}" stroke-width="{sw}"' if out else ""
    s.add(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{fill}"{stroke} {extra}/>')


def shine(s: Svg, cx, cy, rx, ry, angle=-30, opacity=0.55) -> None:
    s.add(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" transform="rotate({angle} {cx:.1f} {cy:.1f})" fill="#FFFFFF" opacity="{opacity}"/>')


def blob(s: Svg, circles: list, fill, out: str, sw: float = 10) -> None:
    # Birbirine değen dairelerden tek parça, sadece dış hatlı şekil (hafıza oyunundaki yele tekniği)
    s.add("<g>" + "".join(f'<circle cx="{c[0]:.1f}" cy="{c[1]:.1f}" r="{c[2]:.1f}" fill="{out}" stroke="{out}" stroke-width="{sw}"/>' for c in circles) + "</g>")
    s.add("<g>" + "".join(f'<circle cx="{c[0]:.1f}" cy="{c[1]:.1f}" r="{c[2]:.1f}" fill="{fill}"/>' for c in circles) + "</g>")


def star_path(cx, cy, ro, ri, n=5, rot=-90.0) -> str:
    pts = []
    for k in range(n * 2):
        r = ro if k % 2 == 0 else ri
        a = math.radians(rot + k * 180.0 / n)
        pts.append(f"{cx + r * math.cos(a):.1f} {cy + r * math.sin(a):.1f}")
    return "M " + " L ".join(pts) + " Z"


def sparkle(s: Svg, cx, cy, r, color="#FFFFFF", opacity=0.95) -> None:
    d = (f"M {cx} {cy - r} C {cx + r * 0.12} {cy - r * 0.12} {cx + r * 0.12} {cy - r * 0.12} {cx + r} {cy} "
         f"C {cx + r * 0.12} {cy + r * 0.12} {cx + r * 0.12} {cy + r * 0.12} {cx} {cy + r} "
         f"C {cx - r * 0.12} {cy + r * 0.12} {cx - r * 0.12} {cy + r * 0.12} {cx - r} {cy} "
         f"C {cx - r * 0.12} {cy - r * 0.12} {cx - r * 0.12} {cy - r * 0.12} {cx} {cy - r} Z")
    s.add(f'<path d="{d}" fill="{color}" opacity="{opacity}"/>')


def trunk(s: Svg, top_y: float, width: float = 14, branches=()) -> None:
    fill = s.lgrad(["#C08A55", "#8A5A32"], 0, 0, 1, 0)
    d = (f"M {BX - width * 0.75:.1f} {BY} C {BX - width * 0.5:.1f} {BY - 40} {BX - width * 0.4:.1f} {top_y + 30} {BX - width * 0.35:.1f} {top_y} "
         f"L {BX + width * 0.35:.1f} {top_y} C {BX + width * 0.4:.1f} {top_y + 30} {BX + width * 0.5:.1f} {BY - 40} {BX + width * 0.75:.1f} {BY} Z")
    for b in branches:
        stem(s, b, 6, "#A87444", OUT_BROWN)
    s.add(f'<path d="{d}" fill="{fill}" stroke="{OUT_BROWN}" stroke-width="5" stroke-linejoin="round"/>')
    s.add(f'<path d="M {BX - width * 0.1:.1f} {BY - 20} C {BX - width * 0.05:.1f} {BY - 60} {BX:.1f} {top_y + 50} {BX + width * 0.05:.1f} {top_y + 20}" fill="none" stroke="{OUT_BROWN}" stroke-width="2.5" opacity="0.4"/>')


# --- Tohum (aşama 0): küçük toprak tümseğinde yarı gömülü tohum ---

def mound_back(s: Svg) -> None:
    fill = s.rgrad(["#C99468", "#9C6A42", "#7A4E2E"], 0.45, 0.3, 0.8)
    s.add(f'<path d="M 72 290 C 80 262 104 250 120 250 C 138 250 160 262 168 290 Z" fill="{fill}" stroke="{OUT_BROWN}" stroke-width="5" stroke-linejoin="round"/>')
    shine(s, 104, 262, 12, 5, -15, 0.25)


def mound_front(s: Svg) -> None:
    fill = s.lgrad(["#A6734A", "#8A5A36"])
    s.add(f'<path d="M 92 290 C 98 276 110 272 120 272 C 132 272 144 276 150 290 Z" fill="{fill}"/>')
    for (x, y, r) in [(104, 282, 2.5), (134, 280, 2), (120, 286, 2)]:
        circle(s, x, y, r, "#6E4428", None, extra='opacity="0.6"')


def seed(s: Svg, style: str, colors: tuple) -> None:
    cx, cy = 120, 262
    c1, c2, out = colors
    fill = s.rgrad([c1, c2], 0.38, 0.3, 0.8)
    if style == "yassi":
        s.add(f'<ellipse cx="{cx}" cy="{cy}" rx="21" ry="12" transform="rotate(-12 {cx} {cy})" fill="{fill}" stroke="{out}" stroke-width="4.5"/>')
        s.add(f'<ellipse cx="{cx}" cy="{cy}" rx="14" ry="6" transform="rotate(-12 {cx} {cy})" fill="none" stroke="{out}" stroke-width="2" opacity="0.35"/>')
    elif style == "cizgili":
        s.add(f'<path d="M {cx} {cy - 22} C {cx + 14} {cy - 14} {cx + 13} {cy + 8} {cx} {cy + 16} C {cx - 13} {cy + 8} {cx - 14} {cy - 14} {cx} {cy - 22} Z" fill="{fill}" stroke="{out}" stroke-width="4.5"/>')
        for dx in (-5, 0, 5):
            s.add(f'<path d="M {cx + dx} {cy - 15} L {cx + dx * 1.3} {cy + 10}" stroke="#F4F0E6" stroke-width="2.5" stroke-linecap="round" opacity="0.85"/>')
    elif style == "kristal":
        s.add(f'<path d="M {cx} {cy - 22} L {cx + 13} {cy - 4} L {cx} {cy + 16} L {cx - 13} {cy - 4} Z" fill="{fill}" stroke="{out}" stroke-width="4" stroke-linejoin="round"/>')
        s.add(f'<path d="M {cx - 13} {cy - 4} L {cx + 13} {cy - 4} M {cx} {cy - 22} L {cx} {cy + 16}" stroke="{out}" stroke-width="1.8" opacity="0.45"/>')
    elif style == "yildiz":
        s.add(f'<path d="{star_path(cx, cy - 4, 17, 8)}" fill="{fill}" stroke="{out}" stroke-width="4" stroke-linejoin="round"/>')
    elif style == "hilal":
        s.add(f'<path d="M {cx + 4} {cy - 20} A 18 18 0 1 0 {cx + 8} {cy + 14} A 13 13 0 1 1 {cx + 4} {cy - 20} Z" fill="{fill}" stroke="{out}" stroke-width="4" stroke-linejoin="round"/>')
    elif style == "seker":
        circle(s, cx, cy - 3, 15, fill, out, 4.5)
        s.add(f'<path d="M {cx} {cy - 3} m -9 0 a 9 9 0 1 1 9 9 a 6 6 0 1 1 -6 -6" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.9"/>')
    elif style == "spor":
        for (dx, dy, r) in [(-9, 2, 9), (7, -4, 11), (1, 9, 7)]:
            circle(s, cx + dx, cy + dy - 4, r, fill, out, 4)
    elif style == "kalp":
        s.add(f'<path d="M {cx} {cy + 14} C {cx - 22} {cy} {cx - 14} {cy - 20} {cx} {cy - 10} C {cx + 14} {cy - 20} {cx + 22} {cy} {cx} {cy + 14} Z" fill="{fill}" stroke="{out}" stroke-width="4" stroke-linejoin="round"/>')
    else:  # oval / benekli / damla
        s.add(f'<ellipse cx="{cx}" cy="{cy - 2}" rx="12" ry="17" transform="rotate(18 {cx} {cy})" fill="{fill}" stroke="{out}" stroke-width="4.5"/>')
        if style == "benekli":
            for (dx, dy) in [(-3, -8), (4, 1), (-2, 8)]:
                circle(s, cx + dx, cy + dy - 2, 2.3, out, None, extra='opacity="0.5"')
    shine(s, cx - 5, cy - 11, 4.5, 3, -30, 0.8)


def stage0(p: dict) -> str:
    s = Svg()
    mound_back(s)
    seed(s, p["seed"], p["seed_colors"])
    mound_front(s)
    sparkle(s, 146, 238, 8, "#FFF6B0")
    sparkle(s, 96, 246, 5, "#FFFFFF", 0.8)
    return s.text(1.45)


# --- Filiz (1) ve fidan (2): büyüme tipine göre ---

def soil_lip(s: Svg) -> None:
    fill = s.lgrad(["#A6734A", "#8A5A36"])
    s.add(f'<path d="M 96 292 C 102 282 112 280 120 280 C 130 280 140 282 146 292 Z" fill="{fill}" stroke="{OUT_BROWN}" stroke-width="4" stroke-linejoin="round"/>')


def stage1(p: dict) -> str:
    s = Svg()
    kind, pal = p["kind"], p.get("leaf", LEAF)
    if kind == "mantar":
        cap = s.rgrad(p["cap_dim"], 0.4, 0.3, 0.8)
        s.add(f'<path d="M 114 290 L 115 262 L 125 262 L 126 290 Z" fill="#F4ECD8" stroke="{OUT_BROWN}" stroke-width="4" stroke-linejoin="round"/>')
        s.add(f'<path d="M 102 264 C 102 246 138 247 138 264 Z" fill="{cap}" stroke="{p["cap_out"]}" stroke-width="4.5" stroke-linejoin="round"/>')
        shine(s, 112, 254, 5, 3, -20, 0.6)
    elif kind == "agac":
        stem(s, [(120, 290), (119, 266), (121, 244)], 6, "#A87444", OUT_BROWN)
        leaf(s, 121, 246, 30, 13, -145, pal)
        leaf(s, 121, 246, 30, 13, -35, pal)
    elif kind == "sarmasik":
        stem(s, [(120, 290), (120, 262)], 7)
        for a in (-160, -20):
            leaf(s, 120, 262, 40, 22, a, pal)
    elif kind == "cali":
        stem(s, [(120, 290), (112, 268)], 5)
        stem(s, [(120, 290), (130, 264)], 5)
        leaf(s, 112, 268, 26, 13, -130, pal)
        leaf(s, 130, 264, 28, 14, -50, pal)
    else:
        stem(s, [(120, 290), (122, 268), (119, 246)], 7)
        leaf(s, 119, 248, 32, 15, -150, pal)
        leaf(s, 119, 248, 32, 15, -30, pal)
    soil_lip(s)
    return s.text(1.35)


def flower_body(s: Svg, top: float, pal=LEAF, leaves=((256, 52, -1), (226, 46, 1), (196, 36, -1)), sway: float = 4.0) -> None:
    # Çiçek gövdesi ve yaprakları: top = gövdenin üst ucu
    stem(s, [(120, 290), (120 + sway, (290 + top) / 2 + 20), (120 - sway * 0.5, top)], 8)
    for (y, length, side) in leaves:
        if y <= top + 8:
            continue
        x = 120 + sway * 0.5
        leaf(s, x, y, length, length * 0.42, -165 if side < 0 else -15, pal)


def stage2(p: dict) -> str:
    s = Svg()
    kind, pal = p["kind"], p.get("leaf", LEAF)
    if kind == "mantar":
        dim, out = p["cap_dim"], p["cap_out"]
        for (x, h, r) in [(102, 30, 17), (138, 22, 13)]:
            cap = s.rgrad(dim, 0.4, 0.3, 0.8)
            s.add(f'<path d="M {x - 6} 290 L {x - 5} {290 - h} L {x + 5} {290 - h} L {x + 6} 290 Z" fill="#F4ECD8" stroke="{OUT_BROWN}" stroke-width="4" stroke-linejoin="round"/>')
            s.add(f'<path d="M {x - r} {292 - h} C {x - r} {292 - h - r * 1.4} {x + r} {292 - h - r * 1.36} {x + r} {292 - h} Z" fill="{cap}" stroke="{out}" stroke-width="4.5" stroke-linejoin="round"/>')
            shine(s, x - r * 0.4, 290 - h - r * 0.7, r * 0.3, r * 0.18, -20, 0.6)
    elif kind == "agac":
        trunk(s, 196, 12, branches=[[(120, 230), (100, 212)], [(120, 218), (142, 200)]])
        blob(s, [(100, 208, 18), (142, 196, 20), (120, 188, 22)], s.rgrad([pal[0], pal[1], pal[2]], 0.4, 0.3, 0.8), OUT_GREEN, 10)
        shine(s, 112, 180, 7, 4, -25, 0.4)
    elif kind == "sarmasik":
        stem(s, [(120, 290), (118, 270), (126, 250)], 7)
        s.add(f'<path d="M 128 252 C 146 246 150 232 140 228 C 132 226 132 236 138 236" fill="none" stroke="{OUT_GREEN}" stroke-width="7" stroke-linecap="round"/>')
        s.add(f'<path d="M 128 252 C 146 246 150 232 140 228 C 132 226 132 236 138 236" fill="none" stroke="#6CC66A" stroke-width="3" stroke-linecap="round"/>')
        for (x, y, a, L) in [(120, 272, -165, 50), (122, 262, -20, 54), (126, 250, -95, 44)]:
            lobed_leaf(s, x, y, L, a, pal)
    elif kind == "cali":
        for (x, y, a) in [(98, 262, -140), (120, 250, -90), (144, 262, -40)]:
            stem(s, [(120, 290), (x, y)], 5)
            trefoil(s, x, y, 22, a, pal)
    else:
        flower_body(s, 200, pal)
    soil_lip(s)
    return s.text(1.1)


def lobed_leaf(s: Svg, x, y, L, angle, pal=LEAF) -> None:
    # Kabak yaprağı: beş dilimli, yuvarlak
    fill = s.rgrad([pal[0], pal[1], pal[2]], 0.4, 0.35, 0.8)
    pts = []
    for k in range(10):
        a = math.radians(k * 36)
        r = L * (0.5 if k % 2 == 0 else 0.34)
        pts.append((L * 0.5 + r * math.cos(a), r * math.sin(a) * 0.9))
    d = smooth(pts + [pts[0]]) + "Z"
    tr = f'transform="translate({x:.1f} {y:.1f}) rotate({angle:.1f})"'
    s.add(f'<path d="{d}" {tr} fill="{fill}" stroke="{OUT_GREEN}" stroke-width="5" stroke-linejoin="round"/>')
    s.add(f'<path d="M 4 0 L {L * 0.8:.1f} 0 M {L * 0.5:.1f} 0 L {L * 0.72:.1f} {-L * 0.28:.1f} M {L * 0.5:.1f} 0 L {L * 0.72:.1f} {L * 0.28:.1f}" {tr} stroke="{OUT_GREEN}" stroke-width="2.5" opacity="0.4" stroke-linecap="round"/>')
    s.add(f'<path d="M {L * 0.3:.1f} {-L * 0.22:.1f} Q {L * 0.45:.1f} {-L * 0.32:.1f} {L * 0.6:.1f} {-L * 0.25:.1f}" {tr} fill="none" stroke="#FFFFFF" stroke-width="3" opacity="0.4" stroke-linecap="round"/>')


def trefoil(s: Svg, x, y, L, angle, pal=LEAF) -> None:
    # Çilek yaprağı: üçlü, dişli kenarlı
    for da in (-40, 0, 40):
        leaf(s, x, y, L, L * 0.5, angle + da, pal)


# --- Bitkilere özel tomurcuk (3) ve olgun (4) çizimleri ---

def aycicegi(s: Svg, stage: int) -> None:
    pal = LEAF
    top = 96 if stage == 3 else 86
    stem(s, [(120, 290), (126, 210), (118, 150), (120, top)], 11)
    for (y, L, a) in [(262, 62, -168), (236, 66, -12), (200, 56, -170), (170, 50, -10)]:
        leaf(s, 121, y, L, L * 0.5, a, pal)
    if stage == 3:
        bud = s.rgrad(["#C6F0A8", "#6CC66A", "#3F9A4C"], 0.4, 0.3, 0.8)
        for k in range(8):
            a = -90 + k * 45
            s.add(f'<path d="{petal_path(20, 7)}" transform="translate(120 {top - 14}) rotate({a})" fill="#FFD54A" stroke="#B8741A" stroke-width="3.5"/>')
        circle(s, 120, top - 14, 24, bud, OUT_GREEN, 5)
        for k in range(6):
            a = math.radians(-90 + k * 60)
            s.add(f'<path d="M 120 {top - 14} L {120 + 22 * math.cos(a):.1f} {top - 14 + 22 * math.sin(a):.1f}" stroke="{OUT_GREEN}" stroke-width="2.5" opacity="0.4"/>')
        shine(s, 111, top - 25, 7, 4, -30, 0.5)
    else:
        cy = 80
        pet = s.lgrad(["#FFF08A", "#FFD23F", "#F4A92A"], 0, 0, 1, 0)
        petals(s, 120, cy, 18, 58, 13, pet, "#B8741A", -90)
        disk = s.rgrad(["#9C6A38", "#6E4424", "#4A2C16"], 0.4, 0.35, 0.8)
        circle(s, 120, cy, 34, disk, "#3E2412", 5)
        for k in range(34):
            r = 5 + 26 * math.sqrt(k / 34)
            a = k * 2.39996
            circle(s, 120 + r * math.cos(a), cy + r * math.sin(a), 2.4, "#C08850", None, extra='opacity="0.8"')
        shine(s, 108, cy - 14, 10, 5, -30, 0.35)


def lale(s: Svg, stage: int) -> None:
    pal = ("#C4F0A6", "#72C46E", "#44984E")
    heads = [(82, 128), (120, 100), (160, 126)]
    for (hx, hy) in heads:
        stem(s, [(120, 290), ((hx + 120) / 2, 210), (hx, hy + 14)], 7, "#6CC66A")
    for (x, y, L, a) in [(116, 286, 96, -118), (124, 286, 92, -62), (118, 284, 70, -150), (122, 284, 70, -30)]:
        leaf(s, x, y, L, 17, a, pal)
    colors = [("#FFB8D2", "#FF6FA0", "#D6406F"), ("#FFF1A0", "#FFCF3A", "#E09A12"), ("#FFB4A6", "#FF6F5E", "#D63F3A")]
    outs = ["#9C2A50", "#9A6208", "#9C2A26"]
    for i, (hx, hy) in enumerate(heads):
        if stage == 3:
            fill = s.lgrad(["#D8F5B8", "#8ED08A", colors[i][1]], 0, 0, 0, 1)
            s.add(f'<path d="M {hx} {hy - 26} C {hx + 13} {hy - 14} {hx + 12} {hy + 8} {hx} {hy + 14} C {hx - 12} {hy + 8} {hx - 13} {hy - 14} {hx} {hy - 26} Z" fill="{fill}" stroke="{OUT_GREEN}" stroke-width="4.5" stroke-linejoin="round"/>')
            shine(s, hx - 4, hy - 10, 3, 6, 0, 0.5)
        else:
            tulip_head(s, hx, hy, colors[i], outs[i])


def tulip_head(s: Svg, hx, hy, cols, out) -> None:
    fill = s.lgrad(list(cols), 0, 0, 0, 1)
    side = s.lgrad([cols[1], cols[2]], 0, 0, 0, 1)
    s.add(f'<path d="M {hx - 24} {hy - 22} C {hx - 30} {hy} {hx - 20} {hy + 18} {hx} {hy + 18} C {hx + 20} {hy + 18} {hx + 30} {hy} {hx + 24} {hy - 22} C {hx + 14} {hy - 12} {hx + 8} {hy - 12} {hx} {hy - 26} C {hx - 8} {hy - 12} {hx - 14} {hy - 12} {hx - 24} {hy - 22} Z" fill="{fill}" stroke="{out}" stroke-width="5" stroke-linejoin="round"/>')
    s.add(f'<path d="M {hx} {hy - 26} C {hx - 10} {hy - 6} {hx - 8} {hy + 10} {hx} {hy + 18} C {hx + 8} {hy + 10} {hx + 10} {hy - 6} {hx} {hy - 26} Z" fill="{side}" stroke="{out}" stroke-width="3" stroke-linejoin="round" opacity="0.9"/>')
    shine(s, hx - 14, hy - 6, 3.5, 8, 10, 0.55)


def cilek(s: Svg, stage: int) -> None:
    pal = ("#BFEFA0", "#62BF62", "#3A9448")
    for (x, y, a) in [(84, 244, -150), (156, 244, -30), (104, 222, -115), (138, 222, -65), (120, 214, -90)]:
        stem(s, [(120, 290), (x, y)], 5)
        trefoil(s, x, y, 30, a, pal)
    flower = [(92, 206), (152, 212)] if stage == 4 else [(92, 206), (150, 204), (124, 190)]
    for (fx, fy) in flower:
        petals(s, fx, fy, 5, 13, 8, "#FFFFFF", "#B9A9C6", -90)
        circle(s, fx, fy, 5, "#FFD23F", "#C28A12", 2.5)
    if stage == 3:
        berry = s.rgrad(["#E6F7B0", "#B8E07A", "#86B84E"], 0.4, 0.3, 0.8)
        s.add(f'<path d="M 120 262 C 104 262 104 240 120 236 C 136 240 136 262 120 262 Z" fill="{berry}" stroke="{OUT_GREEN}" stroke-width="4"/>')
        s.add(f'<path d="{star_path(120, 236, 11, 5, 5, -90)}" fill="#5CB85C" stroke="{OUT_GREEN}" stroke-width="3" stroke-linejoin="round"/>')
    else:
        cx, cy = 120, 232
        red = s.rgrad(["#FF9E9E", "#F2475A", "#C22840"], 0.38, 0.3, 0.8)
        s.add(f'<path d="M {cx} {cy + 58} C {cx - 26} {cy + 50} {cx - 58} {cy + 10} {cx - 52} {cy - 22} C {cx - 46} {cy - 44} {cx - 18} {cy - 46} {cx} {cy - 36} C {cx + 18} {cy - 46} {cx + 46} {cy - 44} {cx + 52} {cy - 22} C {cx + 58} {cy + 10} {cx + 26} {cy + 50} {cx} {cy + 58} Z" fill="{red}" stroke="#8E1E30" stroke-width="5.5" stroke-linejoin="round"/>')
        for k, (dx, dy) in enumerate([(-30, -14), (-8, -20), (16, -18), (34, -8), (-38, 6), (-16, 2), (8, 0), (30, 12), (-22, 22), (0, 24), (20, 30), (-6, 42)]):
            s.add(f'<ellipse cx="{cx + dx}" cy="{cy + dy}" rx="2.6" ry="4" fill="#FFE27A" stroke="#C99A20" stroke-width="1.2"/>')
        calyx = s.rgrad(["#9BE07A", "#4FAE52"], 0.4, 0.3, 0.8)
        s.add(f'<path d="{star_path(cx, cy - 38, 26, 10, 6, -90)}" fill="{calyx}" stroke="{OUT_GREEN}" stroke-width="4" stroke-linejoin="round"/>')
        stem(s, [(cx, cy - 44), (cx + 4, cy - 58)], 5)
        shine(s, cx - 30, cy - 14, 9, 16, 25, 0.5)
        circle(s, cx + 30, cy - 20, 3, "#FFFFFF", None, extra='opacity="0.7"')


def kabak(s: Svg, stage: int) -> None:
    pal = ("#C0EE9E", "#62BA5E", "#3A8E44")
    for (x, y, L, a) in [(118, 262, 64, -170), (124, 254, 64, -12), (116, 236, 56, -140), (126, 230, 56, -40)]:
        stem(s, [(120, 290), (x, y)], 6)
        lobed_leaf(s, x, y, L, a, pal)
    s.add(f'<path d="M 150 262 C 176 252 184 232 170 226 C 160 222 158 236 166 238" fill="none" stroke="{OUT_GREEN}" stroke-width="7" stroke-linecap="round"/>')
    s.add(f'<path d="M 150 262 C 176 252 184 232 170 226 C 160 222 158 236 166 238" fill="none" stroke="#6CC66A" stroke-width="3" stroke-linecap="round"/>')
    if stage == 3:
        stem(s, [(120, 290), (122, 230), (120, 196)], 7)
        fl = s.rgrad(["#FFF3A0", "#FFC83D", "#F29A1E"], 0.45, 0.35, 0.8)
        s.add(f'<path d="{star_path(120, 186, 34, 18, 5, -90)}" fill="{fl}" stroke="#A8620E" stroke-width="5" stroke-linejoin="round"/>')
        circle(s, 120, 188, 9, "#F29A1E", "#A8620E", 3)
        shine(s, 110, 176, 5, 3, -30, 0.6)
    else:
        cx, cy = 120, 236
        org = s.rgrad(["#FFD08A", "#FF9A2E", "#E06A12"], 0.4, 0.32, 0.8)
        for (dx, rx) in [(-38, 34), (38, 34), (-16, 34), (16, 34), (0, 30)]:
            s.add(f'<ellipse cx="{cx + dx}" cy="{cy}" rx="{rx}" ry="48" fill="{org}" stroke="#9A4A10" stroke-width="5"/>')
        shine(s, cx - 44, cy - 16, 7, 16, 10, 0.4)
        shine(s, cx - 6, cy - 22, 5, 12, 0, 0.35)
        s.add(f'<path d="M {cx - 4} {cy - 44} C {cx - 6} {cy - 60} {cx + 2} {cy - 70} {cx + 14} {cy - 72}" fill="none" stroke="{OUT_GREEN}" stroke-width="13" stroke-linecap="round"/>')
        s.add(f'<path d="M {cx - 4} {cy - 44} C {cx - 6} {cy - 60} {cx + 2} {cy - 70} {cx + 14} {cy - 72}" fill="none" stroke="#6CAE4E" stroke-width="7" stroke-linecap="round"/>')


BALLOONS = [(78, 116, 26, ("#FFD0E4", "#FF8FBE", "#E0588E"), "#9C2A58"),
            (120, 84, 30, ("#CDEBFF", "#7CC4FF", "#3E8EE0"), "#1F4E8C"),
            (162, 112, 26, ("#FFF4B8", "#FFD84A", "#E0A812"), "#8C6208"),
            (98, 158, 22, ("#D6F7C4", "#8EE07A", "#4FB04A"), "#2E6B3A"),
            (144, 158, 22, ("#E8D6FF", "#B98CFF", "#8A5CE0"), "#4E2E8C")]


def balon(s: Svg, stage: int) -> None:
    stem(s, [(120, 290), (121, 240), (120, 206)], 8)
    for (y, L, a) in [(262, 50, -165), (240, 48, -15)]:
        leaf(s, 121, y, L, L * 0.42, a, LEAF)
    for (bx, by, r, cols, out) in BALLOONS:
        if stage == 3:
            r2 = r * 0.42
            by2 = by + r * 0.9
            s.add(f'<path d="M 120 206 Q {(bx + 120) / 2} {by2 + 30} {bx} {by2 + r2}" fill="none" stroke="{OUT_GREEN}" stroke-width="3" stroke-linecap="round"/>')
            fill = s.rgrad([cols[0], cols[1]], 0.38, 0.3, 0.8)
            circle(s, bx, by2, r2, fill, out, 4)
            shine(s, bx - r2 * 0.35, by2 - r2 * 0.4, r2 * 0.3, r2 * 0.2, -30, 0.7)
        else:
            s.add(f'<path d="M 120 206 C {(bx + 120) / 2 + 6} {by + r + 50} {bx - 4} {by + r + 30} {bx} {by + r + 4}" fill="none" stroke="#7A6A8E" stroke-width="2.5" stroke-linecap="round"/>')
    if stage == 4:
        for (bx, by, r, cols, out) in BALLOONS:
            balloon(s, bx, by, r, cols, out)


def balloon(s: Svg, bx, by, r, cols, out) -> None:
    fill = s.rgrad(list(cols), 0.36, 0.3, 0.8)
    s.add(f'<path d="M {bx} {by + r * 1.12} C {bx - r * 1.1} {by + r * 0.9} {bx - r * 1.05} {by - r} {bx} {by - r} C {bx + r * 1.05} {by - r} {bx + r * 1.1} {by + r * 0.9} {bx} {by + r * 1.12} Z" fill="{fill}" stroke="{out}" stroke-width="4.5"/>')
    s.add(f'<path d="M {bx - 5} {by + r * 1.22} L {bx} {by + r * 1.08} L {bx + 5} {by + r * 1.22} Z" fill="{cols[1]}" stroke="{out}" stroke-width="3" stroke-linejoin="round"/>')
    shine(s, bx - r * 0.38, by - r * 0.35, r * 0.2, r * 0.34, 25, 0.75)


RAINBOW = [("#FFB0B0", "#FF5E6E", "#C8323F"), ("#FFD2A0", "#FF9A3C", "#C86412"), ("#FFF3A0", "#FFD93D", "#C89A10"),
           ("#C6F5B0", "#6CD46A", "#3A9A44"), ("#B8DEFF", "#5AA8F0", "#2A64B8"), ("#E2CCFF", "#A77CF2", "#6A42B8")]


def gokkusagi(s: Svg, stage: int) -> None:
    flower_body(s, 124, LEAF, leaves=((258, 54, -1), (232, 50, 1), (198, 40, -1)))
    cx, cy = 120, 112
    if stage == 3:
        for k in range(6):
            cols = RAINBOW[k]
            s.add(f'<path d="{petal_path(26, 9)}" transform="translate({cx} {cy + 8}) rotate({-150 + k * 24})" fill="{cols[1]}" stroke="{cols[2]}" stroke-width="3.5"/>')
        bud = s.rgrad(["#C6F0A8", "#6CC66A", "#3F9A4C"], 0.4, 0.3, 0.8)
        s.add(f'<path d="M {cx - 20} {cy + 12} C {cx - 22} {cy - 10} {cx + 22} {cy - 9} {cx + 20} {cy + 12} C {cx + 10} {cy + 22} {cx - 10} {cy + 21} {cx - 20} {cy + 12} Z" fill="{bud}" stroke="{OUT_GREEN}" stroke-width="4.5"/>')
    else:
        fills = [s.lgrad([c[0], c[1]], 0, 0, 1, 0) for c in RAINBOW]
        for k in range(6):
            a = -90 + k * 60
            s.add(f'<path d="{petal_path(52, 20)}" transform="translate({cx} {cy}) rotate({a})" fill="{fills[k]}" stroke="{RAINBOW[k][2]}" stroke-width="5" stroke-linejoin="round"/>')
            ra = math.radians(a)
            shine(s, cx + 30 * math.cos(ra) - 4, cy + 30 * math.sin(ra) - 4, 5, 3, a, 0.5)
        center = s.rgrad(["#FFFFFF", "#FFF4C8", "#FFD36A"], 0.4, 0.35, 0.8)
        circle(s, cx, cy, 18, center, "#C8962A", 4.5)
        sparkle(s, cx, cy, 9, "#FFFFFF")


def kelebek_cicegi(s: Svg, stage: int) -> None:
    flower_body(s, 132, ("#C4EEA8", "#70C46C", "#43984D"), leaves=((258, 52, -1), (230, 48, 1), (200, 38, -1)))
    cx, cy = 120, 118
    if stage == 3:
        bud = s.rgrad(["#F6D6FF", "#D08CF0", "#9A52C8"], 0.4, 0.3, 0.8)
        s.add(f'<path d="M {cx} {cy - 30} C {cx + 20} {cy - 10} {cx + 16} {cy + 12} {cx} {cy + 16} C {cx - 16} {cy + 12} {cx - 20} {cy - 10} {cx} {cy - 30} Z" fill="{bud}" stroke="#6A2E8E" stroke-width="4.5"/>')
        s.add(f'<path d="M {cx - 12} {cy + 12} C {cx - 8} {cy + 2} {cx + 8} {cy + 2} {cx + 12} {cy + 12} C {cx + 6} {cy + 20} {cx - 6} {cy + 20} {cx - 12} {cy + 12} Z" fill="#6CC66A" stroke="{OUT_GREEN}" stroke-width="3.5"/>')
        shine(s, cx - 6, cy - 12, 3, 7, 10, 0.5)
    else:
        up = s.rgrad(["#FFE0F4", "#FF8FD0", "#C8469A"], 0.35, 0.3, 0.85)
        low = s.rgrad(["#F0DCFF", "#B98CFF", "#7A4ED0"], 0.35, 0.3, 0.85)
        for side in (-1, 1):
            s.add(f'<path d="M {cx} {cy} C {cx + side * 20} {cy - 58} {cx + side * 74} {cy - 60} {cx + side * 66} {cy - 16} C {cx + side * 62} {cy + 4} {cx + side * 30} {cy + 6} {cx} {cy} Z" fill="{up}" stroke="#8E2A6A" stroke-width="5" stroke-linejoin="round"/>')
            s.add(f'<path d="M {cx} {cy + 2} C {cx + side * 42} {cy + 4} {cx + side * 56} {cy + 36} {cx + side * 34} {cy + 44} C {cx + side * 18} {cy + 48} {cx + side * 6} {cy + 26} {cx} {cy + 2} Z" fill="{low}" stroke="#4E2E8C" stroke-width="5" stroke-linejoin="round"/>')
            circle(s, cx + side * 44, cy - 28, 9, "#FFFFFF", "#8E2A6A", 3, 'opacity="0.9"')
            circle(s, cx + side * 44, cy - 28, 4, "#FFD84A")
            circle(s, cx + side * 30, cy + 26, 6, "#FFFFFF", None, extra='opacity="0.7"')
        s.add(f'<ellipse cx="{cx}" cy="{cy + 8}" rx="8" ry="22" fill="#6A3E8E" stroke="#3E1E5A" stroke-width="3.5"/>')
        for side in (-1, 1):
            s.add(f'<path d="M {cx + side * 3} {cy - 12} Q {cx + side * 12} {cy - 36} {cx + side * 22} {cy - 38}" fill="none" stroke="#3E1E5A" stroke-width="3" stroke-linecap="round"/>')
            circle(s, cx + side * 22, cy - 38, 4, "#FFD84A", "#3E1E5A", 2)


def mantar(s: Svg, stage: int, lit: bool) -> None:
    # Parlayan mantar: 3 mantar; gece açık (parlak turkuaz), gündüz kapalı (soluk)
    caps = [(92, 48, 26), (138, 64, 32), (170, 30, 18)] if stage == 4 else [(96, 36, 18), (136, 48, 22), (166, 24, 13)]
    for (x, h, r) in caps:
        s.add(f'<path d="M {x - r * 0.35} 292 C {x - r * 0.3} {290 - h * 0.5} {x - r * 0.3} {290 - h} {x - r * 0.25} {290 - h} L {x + r * 0.25} {290 - h} C {x + r * 0.3} {290 - h} {x + r * 0.3} {290 - h * 0.5} {x + r * 0.35} 292 Z" fill="#F6EEDC" stroke="{OUT_BROWN}" stroke-width="4" stroke-linejoin="round"/>')
        if lit:
            cap = s.rgrad(["#E8FFFA", "#7FF0DE", "#23B8B0"], 0.4, 0.3, 0.8)
            out = "#12706E"
        else:
            cap = s.rgrad(["#D6DEEE", "#98A8CC", "#6A7CA8"], 0.4, 0.3, 0.8)
            out = "#3E4A78"
        ry = r * (1.0 if stage == 4 else 1.25)
        s.add(f'<path d="M {x - r} {292 - h} C {x - r} {292 - h - ry * 1.3} {x + r} {292 - h - ry * 1.26} {x + r} {292 - h} C {x + r * 0.5} {296 - h} {x - r * 0.5} {297 - h} {x - r} {292 - h} Z" fill="{cap}" stroke="{out}" stroke-width="5" stroke-linejoin="round"/>')
        for (dx, dy, rr) in [(-0.45, 0.55, 0.16), (0.2, 0.75, 0.13), (0.5, 0.4, 0.11)]:
            circle(s, x + dx * r, 292 - h - dy * ry, rr * r, "#FFFFFF", None, extra=f'opacity="{0.85 if lit else 0.5}"')
        shine(s, x - r * 0.55, 288 - h - ry * 0.6, r * 0.18, r * 0.1, -30, 0.6)
    s.add(f'<path d="M 72 292 C 90 284 150 284 186 292" fill="none" stroke="#5CB85C" stroke-width="7" stroke-linecap="round"/>')


def ay_cicegi(s: Svg, stage: int, lit: bool) -> None:
    flower_body(s, 128, ("#C8E8D8", "#7EBFA6", "#4E927A"), leaves=((258, 52, -1), (230, 48, 1), (198, 36, -1)))
    cx, cy = 120, 110
    if not lit:
        bud = s.rgrad(["#F4F6FF", "#C6D2F4", "#8A9CD0"], 0.4, 0.3, 0.8)
        s.add(f'<path d="M {cx} {cy - 34} C {cx + 22} {cy - 12} {cx + 18} {cy + 14} {cx} {cy + 18} C {cx - 18} {cy + 14} {cx - 22} {cy - 12} {cx} {cy - 34} Z" fill="{bud}" stroke="#4E5E9A" stroke-width="4.5"/>')
        s.add(f'<path d="M {cx} {cy - 30} C {cx - 6} {cy - 10} {cx - 4} {cy + 8} {cx} {cy + 16}" fill="none" stroke="#4E5E9A" stroke-width="2.5" opacity="0.5"/>')
        s.add(f'<path d="M {cx - 14} {cy + 14} C {cx - 8} {cy + 4} {cx + 8} {cy + 4} {cx + 14} {cy + 14} C {cx + 6} {cy + 22} {cx - 6} {cy + 22} {cx - 14} {cy + 14} Z" fill="#7EBFA6" stroke="#2E6B5A" stroke-width="3.5"/>')
        shine(s, cx - 7, cy - 12, 3, 8, 10, 0.55)
        return
    pet = s.lgrad(["#FFFFFF", "#DDE6FF", "#A9BAF0"], 0, 0, 1, 0)
    petals(s, cx, cy, 10, 54, 14, pet, "#5A6AA8", -90)
    center = s.rgrad(["#2E3470", "#1E2250"], 0.5, 0.5, 0.7)
    circle(s, cx, cy, 22, center, "#14183A", 4)
    moon = s.rgrad(["#FFF8D0", "#FFD95A"], 0.4, 0.35, 0.8)
    s.add(f'<path d="M {cx + 6} {cy - 16} A 16 16 0 1 0 {cx + 10} {cy + 14} A 12 12 0 1 1 {cx + 6} {cy - 16} Z" fill="{moon}" stroke="#C89A20" stroke-width="2.5" stroke-linejoin="round"/>')
    sparkle(s, cx + 10, cy - 4, 4, "#FFFFFF")


def kristal(s: Svg, stage: int) -> None:
    flower_body(s, 122, ("#DDF5EE", "#8FD6C2", "#4FA894"), leaves=((258, 50, -1), (230, 46, 1), (198, 36, -1)))
    cx, cy = 120, 106
    ice = s.lgrad(["#FFFFFF", "#CFF0FF", "#8ED4F6"], 0, 0, 1, 1)
    pink = s.lgrad(["#FFFFFF", "#FFD8EE", "#F6A6D6"], 0, 0, 1, 1)
    if stage == 3:
        s.add(f'<path d="M {cx} {cy - 36} L {cx + 16} {cy - 8} L {cx + 10} {cy + 16} L {cx - 10} {cy + 16} L {cx - 16} {cy - 8} Z" fill="{ice}" stroke="#3E7EA8" stroke-width="4.5" stroke-linejoin="round"/>')
        s.add(f'<path d="M {cx} {cy - 36} L {cx} {cy + 16} M {cx - 16} {cy - 8} L {cx + 16} {cy - 8}" stroke="#3E7EA8" stroke-width="2" opacity="0.4"/>')
        sparkle(s, cx - 6, cy - 14, 6, "#FFFFFF")
        return
    for k in range(5):
        a = -90 + k * 72
        f = ice if k % 2 == 0 else pink
        tr = f'transform="translate({cx} {cy}) rotate({a})"'
        s.add(f'<path d="M 8 0 L 30 -17 L 56 0 L 30 17 Z" {tr} fill="{f}" stroke="#3E7EA8" stroke-width="4.5" stroke-linejoin="round"/>')
        s.add(f'<path d="M 8 0 L 56 0 M 30 -17 L 30 17" {tr} stroke="#3E7EA8" stroke-width="1.8" opacity="0.4"/>')
        s.add(f'<path d="M 14 -3 L 30 -13 L 36 -4 Z" {tr} fill="#FFFFFF" opacity="0.7"/>')
    gem = s.rgrad(["#FFE6F4", "#FF8FC8", "#D0488E"], 0.4, 0.3, 0.8)
    s.add(f'<path d="M {cx} {cy - 16} L {cx + 14} {cy - 4} L {cx + 9} {cy + 13} L {cx - 9} {cy + 13} L {cx - 14} {cy - 4} Z" fill="{gem}" stroke="#8E2A5E" stroke-width="3.5" stroke-linejoin="round"/>')
    sparkle(s, cx - 4, cy - 6, 6, "#FFFFFF")
    sparkle(s, cx + 44, cy - 42, 9, "#FFFFFF")
    sparkle(s, cx - 50, cy + 30, 6, "#FFFFFF", 0.8)


STAR_FRUITS = [(80, 104), (118, 70), (158, 96), (98, 138), (146, 140), (176, 126)]
LOLLIPOPS = [(76, 112, ("#FF8FB8", "#FFFFFF")), (122, 70, ("#7CC4FF", "#FFFFFF")), (166, 104, ("#FFD84A", "#FF8F5A")),
             (104, 146, ("#B98CFF", "#FFFFFF")), (150, 148, ("#8EE07A", "#FFFFFF"))]


def tree_canopy(s: Svg, cols, out, circles) -> None:
    fill = s.rgrad(list(cols), 0.4, 0.3, 0.85)
    blob(s, circles, fill, out, 11)


def yildiz_agaci(s: Svg, stage: int) -> None:
    trunk(s, 150, 18, branches=[[(120, 200), (90, 176)], [(120, 186), (152, 164)]])
    circles = [(120, 110, 56), (76, 128, 36), (164, 126, 38), (96, 84, 34), (146, 84, 34), (120, 150, 40)]
    tree_canopy(s, ("#A6E6A0", "#4FAE5E", "#2E7E48"), OUT_GREEN, circles)
    shine(s, 98, 80, 14, 8, -25, 0.35)
    if stage == 3:
        for (x, y) in STAR_FRUITS:
            petals(s, x, y, 5, 8, 5, "#FFFFFF", "#B9A9C6", -90)
            circle(s, x, y, 3, "#FFE27A")
    else:
        gold = s.rgrad(["#FFFBD0", "#FFD84A", "#F2A620"], 0.4, 0.3, 0.8)
        for (x, y) in STAR_FRUITS:
            s.add(f'<path d="M {x} {y - 22} L {x} {y - 14}" stroke="{OUT_GREEN}" stroke-width="3"/>')
            s.add(f'<path d="{star_path(x, y, 17, 8)}" fill="{gold}" stroke="#B8680C" stroke-width="7" stroke-linejoin="round"/>')
            s.add(f'<path d="{star_path(x, y, 17, 8)}" fill="{gold}" stroke="{gold}" stroke-width="2" stroke-linejoin="round"/>')
            shine(s, x - 4, y - 5, 3, 2, -30, 0.8)


def seker_agaci(s: Svg, stage: int) -> None:
    trunk(s, 156, 18, branches=[[(120, 204), (88, 182)], [(120, 190), (154, 170)]])
    circles = [(120, 112, 54), (78, 130, 36), (164, 128, 38), (98, 86, 34), (144, 86, 34), (120, 152, 38)]
    cols = ("#FFE6F2", "#FF9FCC", "#E4609E") if stage == 4 else ("#FFEAF4", "#FFC2DE", "#F28FBE")
    tree_canopy(s, cols, "#9C2A60", circles)
    shine(s, 98, 82, 14, 8, -25, 0.45)
    for (x, y) in [(100, 118), (140, 100), (124, 146), (82, 146), (160, 144)]:
        circle(s, x, y, 3, "#FFFFFF", None, extra='opacity="0.8"')
    if stage == 3:
        for (x, y, c) in LOLLIPOPS:
            circle(s, x, y, 7, c[0], "#9C2A60", 3)
    else:
        for (x, y, c) in LOLLIPOPS:
            s.add(f'<path d="M {x} {y + 16} L {x} {y + 34}" stroke="#E8E2F2" stroke-width="5" stroke-linecap="round"/>')
            circle(s, x, y, 18, c[0], "#6A2E5A", 4.5)
            s.add(f'<path d="M {x} {y} m -11 0 a 11 11 0 1 1 11 11 a 7 7 0 1 1 -7 -7 a 3 3 0 1 1 3 3" fill="none" stroke="{c[1]}" stroke-width="4" stroke-linecap="round"/>')
            shine(s, x - 7, y - 8, 4, 2.5, -30, 0.8)


# Bitkiler: tohum stili ve renkleri, büyüme tipi, yaprak paleti, tomurcuk/olgun çizimi
PLANTS = {
    "aycicegi": {"seed": "cizgili", "seed_colors": ("#7A6A5A", "#3A2E24", "#241A12"), "kind": "cicek", "draw": aycicegi},
    "lale": {"seed": "oval", "seed_colors": ("#F6D8B0", "#C8945A", "#7A4E22"), "kind": "cicek",
             "leaf": ("#C4F0A6", "#72C46E", "#44984E"), "draw": lale},
    "cilek": {"seed": "damla", "seed_colors": ("#FFB0B0", "#E0485A", "#8E1E30"), "kind": "cali",
              "leaf": ("#BFEFA0", "#62BF62", "#3A9448"), "draw": cilek},
    "kabak": {"seed": "yassi", "seed_colors": ("#FFF6DC", "#E8D2A0", "#9A7A3A"), "kind": "sarmasik",
              "leaf": ("#C0EE9E", "#62BA5E", "#3A8E44"), "draw": kabak},
    "balon": {"seed": "benekli", "seed_colors": ("#CDEBFF", "#7CC4FF", "#1F4E8C"), "kind": "cicek", "draw": balon},
    "gokkusagi": {"seed": "oval", "seed_colors": ("#FFE6A0", "#FF9A6A", "#B8462A"), "kind": "cicek", "draw": gokkusagi},
    "kelebek_cicegi": {"seed": "kalp", "seed_colors": ("#FFD0F0", "#E070C0", "#8E2A6A"), "kind": "cicek",
                       "leaf": ("#C4EEA8", "#70C46C", "#43984D"), "draw": kelebek_cicegi},
    "mantar": {"seed": "spor", "seed_colors": ("#DFFFF8", "#6FE0D2", "#12706E"), "kind": "mantar",
               "cap_dim": ["#D6DEEE", "#98A8CC", "#6A7CA8"], "cap_out": "#3E4A78", "draw": mantar, "night": True},
    "ay_cicegi": {"seed": "hilal", "seed_colors": ("#FFFBE0", "#E6D080", "#8C7420"), "kind": "cicek",
                  "leaf": ("#C8E8D8", "#7EBFA6", "#4E927A"), "draw": ay_cicegi, "night": True},
    "kristal": {"seed": "kristal", "seed_colors": ("#FFFFFF", "#9ED8FF", "#3E7EA8"), "kind": "cicek",
                "leaf": ("#DDF5EE", "#8FD6C2", "#4FA894"), "draw": kristal},
    "yildiz_agaci": {"seed": "yildiz", "seed_colors": ("#FFFBD0", "#FFC83D", "#A8620E"), "kind": "agac", "draw": yildiz_agaci},
    "seker_agaci": {"seed": "seker", "seed_colors": ("#FFD6EA", "#FF7FB8", "#9C2A60"), "kind": "agac",
                    "leaf": ("#FFE6F2", "#FFB0D4", "#E070A8"), "draw": seker_agaci},
}


def make_plants() -> None:
    for pid, p in PLANTS.items():
        write(f"bitkiler/{pid}_0.svg", stage0(p))
        write(f"bitkiler/{pid}_1.svg", stage1(p))
        write(f"bitkiler/{pid}_2.svg", stage2(p))
        for stage in (3, 4):
            s = Svg()
            if p.get("night"):
                p["draw"](s, stage, stage == 4)
            else:
                p["draw"](s, stage)
            soil_lip(s)
            write(f"bitkiler/{pid}_{stage}.svg", s.text())
        if p.get("night"):
            # Gündüz olgun ama kapalı hali
            s = Svg()
            p["draw"](s, 4, False)
            soil_lip(s)
            write(f"bitkiler/{pid}_4_kapali.svg", s.text())


# --------------------------------------------------------------------------------------------
# Diğer çizimler: hava düğmeleri, keseler, arayüz, canlılar, efektler, arka plan
# --------------------------------------------------------------------------------------------

def face(s: Svg, cx, cy, size, out="#3A2A4A", eyes="open", blush="#FF8FA8") -> None:
    # Sevimli yüz: gözler, gülümseme, yanaklar (size: yüz genişliğinin yarısı)
    ex = size * 0.42
    if eyes == "open":
        for side in (-1, 1):
            s.add(f'<ellipse cx="{cx + side * ex:.1f}" cy="{cy:.1f}" rx="{size * 0.12:.1f}" ry="{size * 0.15:.1f}" fill="{out}"/>')
            circle(s, cx + side * ex - size * 0.04, cy - size * 0.06, size * 0.05, "#FFFFFF")
    else:
        for side in (-1, 1):
            s.add(f'<path d="M {cx + side * ex - size * 0.13:.1f} {cy:.1f} Q {cx + side * ex:.1f} {cy - size * 0.14:.1f} {cx + side * ex + size * 0.13:.1f} {cy:.1f}" fill="none" stroke="{out}" stroke-width="{max(2.5, size * 0.07):.1f}" stroke-linecap="round"/>')
    s.add(f'<path d="M {cx - size * 0.16:.1f} {cy + size * 0.22:.1f} Q {cx:.1f} {cy + size * 0.38:.1f} {cx + size * 0.16:.1f} {cy + size * 0.22:.1f}" fill="none" stroke="{out}" stroke-width="{max(2.5, size * 0.07):.1f}" stroke-linecap="round"/>')
    for side in (-1, 1):
        s.add(f'<ellipse cx="{cx + side * size * 0.66:.1f}" cy="{cy + size * 0.2:.1f}" rx="{size * 0.14:.1f}" ry="{size * 0.09:.1f}" fill="{blush}" opacity="0.7"/>')


CLOUD = "M 30 92 C 8 92 6 62 30 58 C 30 32 64 24 78 42 C 88 14 132 10 144 40 C 164 30 190 42 186 66 C 206 70 204 96 182 96 Z"


def cloud_path(sx=1.0, sy=1.0, dx=0.0, dy=0.0) -> str:
    return f'd="{CLOUD}" transform="translate({dx} {dy}) scale({sx} {sy})"'


def make_controls() -> None:
    # Yağmur bulutu (sürüklenir)
    s = Svg(200, 170)
    body = s.rgrad(["#FFFFFF", "#E6F2FF", "#B8D4F2"], 0.4, 0.3, 0.8)
    for (x, y) in [(64, 128), (100, 142), (136, 128)]:
        drop = s.rgrad(["#D8F0FF", "#6CB8F6", "#2E7ED8"], 0.4, 0.35, 0.8)
        s.add(f'<path d="M {x} {y - 18} C {x + 8} {y - 6} {x + 12} {y + 2} {x + 12} {y + 8} C {x + 12} {y + 16} {x + 6} {y + 21} {x} {y + 21} C {x - 6} {y + 21} {x - 12} {y + 16} {x - 12} {y + 8} C {x - 12} {y + 2} {x - 8} {y - 6} {x} {y - 18} Z" fill="{drop}" stroke="#1F5A9C" stroke-width="4"/>')
        shine(s, x - 4, y + 4, 2.5, 4, 0, 0.8)
    s.add(f'<path {cloud_path(1.0, 1.0, 0, 6)} fill="{body}" stroke="#4E6E9C" stroke-width="6" stroke-linejoin="round"/>')
    shine(s, 70, 44, 16, 7, -15, 0.8)
    face(s, 100, 76, 26, "#3A4A6A", "closed")
    write("yagmur_bulutu.svg", s.text())

    # Güneş
    s = Svg(180, 180)
    rays = s.rgrad(["#FFF3A0", "#FFC83D"], 0.5, 0.5, 0.6)
    for k in range(12):
        a = k * 30
        s.add(f'<path d="M 0 -10 C 6 -10 10 -4 10 0 C 10 4 6 10 0 10 L -2 0 Z" transform="translate(90 90) rotate({a}) translate(62 0) scale(1.6 1.2)" fill="{rays}" stroke="#C8781A" stroke-width="3" stroke-linejoin="round"/>')
    disc = s.rgrad(["#FFFBE0", "#FFDD55", "#F7A92A"], 0.4, 0.35, 0.75)
    circle(s, 90, 90, 54, disc, "#C8781A", 6)
    shine(s, 70, 66, 14, 8, -30, 0.7)
    face(s, 90, 94, 30, "#8A4A10", "closed", "#FF9A7A")
    write("gunes.svg", s.text())

    # Rüzgar: kıvrılan esinti çizgileri ve iki yaprak
    s = Svg(180, 160)
    for (d, w) in [("M 22 58 C 60 58 96 58 118 50 C 146 40 142 12 120 16 C 104 20 108 38 122 36", 13),
                   ("M 14 92 C 60 92 110 92 142 88 C 170 84 172 116 150 118 C 134 120 132 104 142 100", 13),
                   ("M 34 124 C 60 124 82 124 100 128", 11)]:
        s.add(f'<path d="{d}" fill="none" stroke="#3E6E9C" stroke-width="{w + 8}" stroke-linecap="round" stroke-linejoin="round"/>')
        s.add(f'<path d="{d}" fill="none" stroke="#DDF1FF" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
        s.add(f'<path d="{d}" fill="none" stroke="#FFFFFF" stroke-width="{w * 0.35:.1f}" stroke-linecap="round" opacity="0.8" transform="translate(0 -2)"/>')
    leaf(s, 58, 30, 30, 12, -20, LEAF)
    leaf(s, 118, 138, 26, 11, 20, ("#FFE6A0", "#FFB84A", "#E0852A"), "#9A5A10")
    write("ruzgar.svg", s.text())

    # Ay: uykulu hilal ve yıldızlar
    s = Svg(180, 180)
    moon = s.rgrad(["#FFFDE8", "#FFE680", "#F2C040"], 0.35, 0.3, 0.85)
    s.add(f'<path d="M 108 22 A 68 68 0 1 0 150 132 A 54 54 0 1 1 108 22 Z" fill="{moon}" stroke="#B8861A" stroke-width="6" stroke-linejoin="round"/>')
    shine(s, 58, 60, 10, 18, 25, 0.6)
    s.add('<path d="M 60 104 Q 68 96 76 104" fill="none" stroke="#8A5A10" stroke-width="4" stroke-linecap="round"/>')
    s.add('<path d="M 70 124 Q 82 132 94 124" fill="none" stroke="#8A5A10" stroke-width="4" stroke-linecap="round"/>')
    s.add('<ellipse cx="58" cy="118" rx="7" ry="4.5" fill="#FF9AA8" opacity="0.7"/>')
    for (x, y, r) in [(138, 48, 16), (156, 84, 10)]:
        star = s.rgrad(["#FFFFFF", "#FFE680"], 0.4, 0.35, 0.8)
        s.add(f'<path d="{star_path(x, y, r, r * 0.45)}" fill="{star}" stroke="#B8861A" stroke-width="3.5" stroke-linejoin="round"/>')
    write("ay.svg", s.text())

    # Su damlası (ihtiyaç baloncuğu ve yağmur)
    s = Svg(80, 100)
    drop = s.rgrad(["#E0F4FF", "#6CB8F6", "#2E7ED8"], 0.4, 0.4, 0.8)
    s.add(f'<path d="M 40 8 C 54 30 68 46 68 64 C 68 80 56 92 40 92 C 24 92 12 80 12 64 C 12 46 26 30 40 8 Z" fill="{drop}" stroke="#1F5A9C" stroke-width="5"/>')
    shine(s, 30, 62, 6, 10, 15, 0.8)
    write("damla.svg", s.text())


PACKS = {
    "pembe": ("#FFE0EE", "#FF9CC6", "#E05C98", "#8E2A5A"),
    "turuncu": ("#FFF0D4", "#FFBE6A", "#F08A2A", "#8E4A10"),
    "mor": ("#EEE0FF", "#B996F2", "#8660D0", "#44287E"),
}


def make_packs() -> None:
    for name, (c0, c1, c2, out) in PACKS.items():
        s = Svg(160, 190)
        bag = s.lgrad([c0, c1, c2], 0, 0, 1, 1)
        s.add(f'<path d="M 26 44 L 134 44 L 142 170 C 142 178 136 184 128 184 L 32 184 C 24 184 18 178 18 170 Z" fill="{bag}" stroke="{out}" stroke-width="6" stroke-linejoin="round"/>')
        # Kıvrık üst kenar (zikzak)
        zig = " ".join(f"L {26 + k * 9} {44 - (8 if k % 2 else 0)}" for k in range(13))
        s.add(f'<path d="M 26 44 {zig} L 134 44 L 136 58 L 24 58 Z" fill="{c0}" stroke="{out}" stroke-width="5" stroke-linejoin="round"/>')
        s.add(f'<path d="M 24 58 L 136 58" stroke="{out}" stroke-width="4" opacity="0.5"/>')
        shine(s, 44, 100, 7, 26, 5, 0.45)
        # Ön etiket: beyaz daire içinde kesenin simgesi
        circle(s, 80, 118, 40, "#FFFFFF", out, 5, 'opacity="0.95"')
        if name == "pembe":
            pet = s.rgrad(["#FFE0EE", "#FF8FBE"], 0.4, 0.35, 0.8)
            petals(s, 80, 116, 5, 22, 11, pet, "#9C2A58", -90)
            circle(s, 80, 116, 8, "#FFD84A", "#B8861A", 3)
        elif name == "turuncu":
            red = s.rgrad(["#FF9E9E", "#F2475A", "#C22840"], 0.38, 0.3, 0.8)
            s.add(f'<path d="M 80 146 C 66 142 50 122 54 108 C 57 98 70 96 80 102 C 90 96 103 98 106 108 C 110 122 94 142 80 146 Z" fill="{red}" stroke="#8E1E30" stroke-width="4.5"/>')
            s.add(f'<path d="{star_path(80, 100, 14, 6, 6)}" fill="#6CC66A" stroke="{OUT_GREEN}" stroke-width="3" stroke-linejoin="round"/>')
            for (dx, dy) in [(-12, 12), (4, 10), (14, 22), (-4, 26)]:
                s.add(f'<ellipse cx="{80 + dx}" cy="{112 + dy}" rx="2" ry="3" fill="#FFE27A"/>')
        else:
            moon = s.rgrad(["#FFFDE8", "#FFE680"], 0.4, 0.35, 0.8)
            s.add(f'<path d="M 84 90 A 28 28 0 1 0 104 132 A 22 22 0 1 1 84 90 Z" fill="{moon}" stroke="#B8861A" stroke-width="4" stroke-linejoin="round"/>')
            s.add(f'<path d="{star_path(104, 104, 10, 4.5)}" fill="#FFFFFF" stroke="#B8861A" stroke-width="3" stroke-linejoin="round"/>')
        # İp
        s.add(f'<path d="M 34 58 C 50 70 110 70 126 58" fill="none" stroke="#C8A070" stroke-width="5" stroke-linecap="round"/>')
        s.add('<path d="M 118 64 C 128 76 124 88 116 90 M 118 64 C 132 70 140 80 136 88" fill="none" stroke="#C8A070" stroke-width="4" stroke-linecap="round"/>')
        sparkle(s, 134, 28, 10, "#FFF6B0")
        write(f"kese_{name}.svg", s.text())


def make_ui() -> None:
    # Albüm kitabı
    s = Svg(160, 160)
    s.add('<rect x="30" y="24" width="112" height="120" rx="14" fill="#F4EEDC" stroke="#6A4A2E" stroke-width="5"/>')
    cover = s.lgrad(["#C9A2FF", "#9A6AE0", "#7348B8"], 0, 0, 1, 1)
    s.add(f'<rect x="18" y="16" width="112" height="124" rx="16" fill="{cover}" stroke="#3E2270" stroke-width="6"/>')
    s.add('<rect x="18" y="16" width="22" height="124" rx="10" fill="#5E3A9C" opacity="0.6"/>')
    circle(s, 84, 74, 30, "#FFFFFF", "#3E2270", 4, 'opacity="0.95"')
    pet = s.rgrad(["#FFE0EE", "#FF8FBE"], 0.4, 0.35, 0.8)
    petals(s, 84, 72, 5, 18, 9, pet, "#9C2A58", -90)
    circle(s, 84, 72, 7, "#FFD84A", "#B8861A", 3)
    s.add('<path d="M 106 16 L 106 150 L 114 142 L 122 150 L 122 16 Z" fill="#FF6F8E" stroke="#9C2A48" stroke-width="4" stroke-linejoin="round"/>')
    shine(s, 50, 34, 14, 5, -10, 0.45)
    sparkle(s, 132, 22, 12, "#FFF6B0")
    write("kitap.svg", s.text())

    # Sepet
    s = Svg(140, 120)
    s.add('<path d="M 30 56 C 30 10 110 10 110 56" fill="none" stroke="#7A4E22" stroke-width="15" stroke-linecap="round"/>')
    s.add('<path d="M 30 56 C 30 10 110 10 110 56" fill="none" stroke="#D8A060" stroke-width="7" stroke-linecap="round"/>')
    basket = s.lgrad(["#F2C680", "#D89A4E", "#B0733A"])
    s.add(f'<path d="M 14 54 L 126 54 L 114 108 C 112 114 108 116 102 116 L 38 116 C 32 116 28 114 26 108 Z" fill="{basket}" stroke="#6E4418" stroke-width="5" stroke-linejoin="round"/>')
    for k in range(5):
        y = 66 + k * 10
        s.add(f'<path d="M {18 + k * 2.4:.1f} {y} Q 70 {y + 6} {122 - k * 2.4:.1f} {y}" fill="none" stroke="#8A5A28" stroke-width="2.5" opacity="0.55"/>')
    for k in range(6):
        x = 32 + k * 15
        s.add(f'<path d="M {x} 58 L {x + (k - 2.5) * 1.6:.1f} 112" stroke="#8A5A28" stroke-width="2.5" opacity="0.4"/>')
    s.add('<rect x="10" y="48" width="120" height="14" rx="7" fill="#E8B06A" stroke="#6E4418" stroke-width="4.5"/>')
    shine(s, 36, 52, 12, 3, 0, 0.5)
    write("sepet.svg", s.text())

    # Kapat (albüm): yuvarlak içinde çarpı değil, "tamam" işareti daha dostça
    s = Svg(100, 100)
    s.add('<path d="M 24 52 L 42 70 L 78 32" fill="none" stroke="#2E7A3A" stroke-width="18" stroke-linecap="round" stroke-linejoin="round"/>')
    s.add('<path d="M 24 52 L 42 70 L 78 32" fill="none" stroke="#7EDC6A" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>')
    write("tamam.svg", s.text())


def make_critters() -> None:
    # Kelebek: gövde + kanat çifti (beyaz tonlu, oyunda renklenir)
    s = Svg(140, 110)
    wing = s.rgrad(["#FFFFFF", "#F2F2F2", "#D0D0D0"], 0.5, 0.4, 0.7)
    for side in (-1, 1):
        s.add(f'<path d="M 70 52 C {70 + side * 12} 12 {70 + side * 62} 4 {70 + side * 62} 34 C {70 + side * 62} 52 {70 + side * 30} 58 70 52 Z" fill="{wing}" stroke="#4A3A5A" stroke-width="4.5" stroke-linejoin="round"/>')
        s.add(f'<path d="M 70 56 C {70 + side * 36} 58 {70 + side * 50} 84 {70 + side * 32} 94 C {70 + side * 18} 100 {70 + side * 6} 76 70 56 Z" fill="{wing}" stroke="#4A3A5A" stroke-width="4.5" stroke-linejoin="round"/>')
        circle(s, 70 + side * 40, 32, 9, "#FFFFFF", "#4A3A5A", 2.5, 'opacity="0.9"')
        circle(s, 70 + side * 30, 78, 6, "#FFFFFF", None, extra='opacity="0.8"')
    write("kelebek_kanat.svg", s.text())
    s = Svg(140, 110)
    s.add('<ellipse cx="70" cy="60" rx="7" ry="24" fill="#5A3E7A" stroke="#2E1E44" stroke-width="3.5"/>')
    circle(s, 70, 34, 9, "#5A3E7A", "#2E1E44", 3.5)
    for side in (-1, 1):
        s.add(f'<path d="M {70 + side * 3} 28 Q {70 + side * 10} 12 {70 + side * 18} 10" fill="none" stroke="#2E1E44" stroke-width="3" stroke-linecap="round"/>')
        circle(s, 70 + side * 18, 10, 3.5, "#FFD84A", "#2E1E44", 2)
    circle(s, 66, 32, 2.2, "#FFFFFF")
    write("kelebek_govde.svg", s.text())

    # Arı: gövde (çizgili, sevimli yüz) + kanatlar
    s = Svg(120, 100)
    body = s.rgrad(["#FFF3A0", "#FFD23F", "#E8A21A"], 0.4, 0.3, 0.8)
    s.add('<path d="M 18 60 L 6 64 L 18 68 Z" fill="#3A2A20"/>')
    s.add(f'<ellipse cx="54" cy="64" rx="38" ry="26" fill="{body}" stroke="#4A3010" stroke-width="5"/>')
    for x in (40, 58):
        s.add(f'<path d="M {x} 40 C {x + 6} 52 {x + 6} 76 {x} 88" fill="none" stroke="#3A2A20" stroke-width="8" stroke-linecap="round"/>')
    circle(s, 88, 58, 20, body, "#4A3010", 5)
    face(s, 90, 56, 16, "#3A2A20", "open")
    shine(s, 44, 50, 9, 4, -15, 0.6)
    write("ari_govde.svg", s.text())
    s = Svg(120, 100)
    for (x, a) in [(50, -30), (66, -10)]:
        s.add(f'<ellipse cx="{x}" cy="26" rx="14" ry="22" transform="rotate({a} {x} 30)" fill="#E8F6FF" stroke="#6A8AAE" stroke-width="3.5" opacity="0.9"/>')
    write("ari_kanat.svg", s.text())

    # Uğur böceği
    s = Svg(110, 90)
    circle(s, 80, 50, 18, "#3A2A30", "#1E1418", 4)
    for side in (-1, 1):
        s.add(f'<path d="M 84 {50 + side * 12} Q 96 {50 + side * 26} 104 {50 + side * 24}" fill="none" stroke="#1E1418" stroke-width="3" stroke-linecap="round"/>')
    shell = s.rgrad(["#FF9E9E", "#F2404E", "#B81E30"], 0.4, 0.3, 0.8)
    s.add(f'<ellipse cx="48" cy="50" rx="36" ry="32" fill="{shell}" stroke="#6A1420" stroke-width="5"/>')
    s.add('<path d="M 84 50 L 12 50" stroke="#6A1420" stroke-width="3.5"/>')
    for (x, y, r) in [(40, 32, 7), (60, 34, 6), (30, 62, 6), (52, 66, 7), (68, 58, 5)]:
        circle(s, x, y, r, "#2A1A20")
    shine(s, 34, 30, 9, 5, -20, 0.6)
    circle(s, 86, 44, 4, "#FFFFFF")
    circle(s, 86, 56, 4, "#FFFFFF")
    circle(s, 87, 44, 2, "#1E1418")
    circle(s, 87, 56, 2, "#1E1418")
    write("ugur_bocegi.svg", s.text())

    # Salyangoz: gövde ve kabuk ayrı (kabuğa saklanabilsin)
    s = Svg(160, 110)
    body = s.lgrad(["#F4F2C0", "#D8D890", "#B8B870"])
    s.add(f'<path d="M 10 98 C 20 86 60 84 110 84 C 124 84 128 70 126 58 C 125 46 136 40 144 46 C 152 52 150 66 146 78 C 142 92 128 100 110 100 L 16 102 C 8 102 6 100 10 98 Z" fill="{body}" stroke="#7A7A3A" stroke-width="4.5" stroke-linejoin="round"/>')
    for (x, a) in [(134, -20), (144, 10)]:
        s.add(f'<path d="M {x} 48 Q {x - 4 + a * 0.3} 30 {x + a * 0.4} 20" fill="none" stroke="#7A7A3A" stroke-width="4" stroke-linecap="round"/>')
        circle(s, x + a * 0.4, 20, 5, "#3A3A20")
    circle(s, 136, 64, 3, "#3A3A20")
    s.add('<path d="M 134 74 Q 140 78 146 72" fill="none" stroke="#3A3A20" stroke-width="2.5" stroke-linecap="round"/>')
    write("salyangoz_govde.svg", s.text())
    s = Svg(160, 110)
    shell = s.rgrad(["#FFE0C8", "#F2A070", "#C86A3A"], 0.4, 0.3, 0.85)
    circle(s, 70, 56, 40, shell, "#7A3A1A", 5.5)
    s.add('<path d="M 70 56 m -6 0 a 6 6 0 1 1 6 6 a 14 14 0 1 1 -14 -14 a 22 22 0 1 1 22 22 a 30 30 0 1 1 -30 -30" fill="none" stroke="#7A3A1A" stroke-width="4" stroke-linecap="round" opacity="0.7"/>')
    shine(s, 54, 34, 11, 6, -30, 0.55)
    write("salyangoz_kabuk.svg", s.text())

    # Kurbağa
    s = Svg(160, 130)
    green = s.rgrad(["#C8F6A0", "#7ED65A", "#4AA83A"], 0.4, 0.3, 0.8)
    for side in (-1, 1):
        s.add(f'<ellipse cx="{80 + side * 50}" cy="110" rx="22" ry="11" fill="{green}" stroke="#2E6B2A" stroke-width="4.5"/>')
    s.add(f'<ellipse cx="80" cy="88" rx="56" ry="36" fill="{green}" stroke="#2E6B2A" stroke-width="5.5"/>')
    for side in (-1, 1):
        circle(s, 80 + side * 30, 52, 20, green, "#2E6B2A", 5.5)
        circle(s, 80 + side * 30, 52, 12, "#FFFFFF", "#2E6B2A", 3)
        circle(s, 80 + side * 30 + 2, 54, 7, "#2A2A30")
        circle(s, 80 + side * 30 - 1, 50, 2.5, "#FFFFFF")
    s.add('<ellipse cx="80" cy="96" rx="34" ry="18" fill="#E8FFD0" opacity="0.8"/>')
    s.add('<path d="M 58 80 Q 80 96 102 80" fill="none" stroke="#2E6B2A" stroke-width="4.5" stroke-linecap="round"/>')
    for side in (-1, 1):
        s.add(f'<ellipse cx="{80 + side * 42}" cy="82" rx="9" ry="5" fill="#FF9AA8" opacity="0.7"/>')
    shine(s, 50, 70, 10, 5, -20, 0.5)
    write("kurbaga.svg", s.text())


def make_effects() -> None:
    s = Svg(64, 64)
    sparkle(s, 32, 32, 30, "#FFFFFF", 1.0)
    write("parilti.svg", s.text())

    s = Svg(200, 200)
    g = s.rgrad(["#FFFFFF", "#FFFFFF"], 0.5, 0.5, 0.5)
    s.defs[-1] = s.defs[-1].replace('<stop offset="1.00" stop-color="#FFFFFF"/>', '<stop offset="0.35" stop-color="#FFFFFF" stop-opacity="0.55"/><stop offset="1.00" stop-color="#FFFFFF" stop-opacity="0"/>')
    circle(s, 100, 100, 100, g)
    write("isik.svg", s.text())

    s = Svg(100, 100)
    gold = s.rgrad(["#FFFBD0", "#FFD84A", "#F2A620"], 0.4, 0.3, 0.8)
    s.add(f'<path d="{star_path(50, 54, 40, 18)}" fill="{gold}" stroke="#B8680C" stroke-width="12" stroke-linejoin="round"/>')
    s.add(f'<path d="{star_path(50, 54, 40, 18)}" fill="{gold}" stroke="{gold}" stroke-width="4" stroke-linejoin="round"/>')
    shine(s, 40, 40, 7, 4, -30, 0.85)
    write("yildiz.svg", s.text())

    s = Svg(90, 120)
    fill = s.rgrad(["#FFFFFF", "#F0F0F0", "#C8C8C8"], 0.36, 0.3, 0.8)
    s.add(f'<path d="M 45 92 C 8 86 6 10 45 8 C 84 10 82 86 45 92 Z" fill="{fill}" stroke="#5A5A6A" stroke-width="4.5"/>')
    s.add('<path d="M 39 100 L 45 90 L 51 100 Z" fill="#E8E8E8" stroke="#5A5A6A" stroke-width="3" stroke-linejoin="round"/>')
    s.add('<path d="M 45 100 C 40 108 50 112 45 120" fill="none" stroke="#7A7A8A" stroke-width="2.5"/>')
    shine(s, 32, 30, 7, 13, 20, 0.85)
    write("balon.svg", s.text())

    s = Svg(280, 150)
    for k, (c0, c1, c2) in enumerate(RAINBOW):
        r = 110 - k * 11
        s.add(f'<path d="M {140 - r} 140 A {r} {r} 0 0 1 {140 + r} 140" fill="none" stroke="{c1}" stroke-width="12"/>')
    s.add('<path d="M 30 140 A 110 110 0 0 1 250 140" fill="none" stroke="#FFFFFF" stroke-width="3" opacity="0.5"/>')
    for x in (34, 246):
        body = s.rgrad(["#FFFFFF", "#E6F2FF"], 0.4, 0.3, 0.8)
        s.add(f'<path {cloud_path(0.42, 0.42, x - 42, 108)} fill="{body}" stroke="#8AA4C8" stroke-width="7"/>')
    write("gokkusagi.svg", s.text())

    s = Svg(60, 90)
    for k in range(9):
        a = math.radians(-90 + (k - 4) * 20)
        s.add(f'<path d="M 30 40 L {30 + 24 * math.cos(a):.1f} {40 + 24 * math.sin(a):.1f}" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round"/>')
        circle(s, 30 + 24 * math.cos(a), 40 + 24 * math.sin(a), 3.5, "#FFFFFF")
    s.add('<path d="M 30 40 L 30 70" stroke="#E8E2D0" stroke-width="2.5"/>')
    s.add('<ellipse cx="30" cy="76" rx="4" ry="8" fill="#A87444" stroke="#5E3A22" stroke-width="2"/>')
    write("tohum_tuy.svg", s.text())

    s = Svg(48, 32)
    leaf(s, 4, 16, 40, 12, 0, LEAF, OUT_GREEN)
    write("yaprak.svg", s.text())

    s = Svg(32, 28)
    s.add('<path d="M 4 18 C 2 8 12 2 18 4 C 26 4 30 12 28 18 C 26 26 8 26 4 18 Z" fill="#8A5A36" stroke="#5E3A22" stroke-width="2.5"/>')
    write("toprak_parca.svg", s.text())

    s = Svg(64, 60)
    heart = s.rgrad(["#FFD0DC", "#FF6F8E", "#D63E60"], 0.4, 0.3, 0.8)
    s.add(f'<path d="M 32 54 C 8 38 2 22 12 12 C 20 4 30 8 32 16 C 34 8 44 4 52 12 C 62 22 56 38 32 54 Z" fill="{heart}" stroke="#8E1E3A" stroke-width="4"/>')
    shine(s, 20, 20, 5, 3, -30, 0.8)
    write("kalp.svg", s.text())

    # Lale başı (renk değiştirme animasyonu için beyaz tonlu)
    s = Svg(70, 70)
    tulip_head(s, 35, 42, ("#FFFFFF", "#F0F0F0", "#C8C8C8"), "#5A5A6A")
    write("lale_bas.svg", s.text())


def make_background() -> None:
    wide = 2000
    # Uzak ve yakın tepeler (gündüz renkleri; gece oyunda karartılır)
    def hills(height, base, parts, cols, out, bushes=0, seed=1):
        s = Svg(wide, height)
        pts = []
        for x in range(-40, wide + 60, 40):
            y = base + sum(a * math.sin(2 * math.pi * k * x / wide + ph) for k, a, ph in parts)
            pts.append((x, y))
        fill = s.lgrad(list(cols))
        extra = ""
        if bushes:
            rnd = __import__("random").Random(seed)
            for i in range(bushes):
                x = rnd.uniform(40, wide - 40)
                y = base + sum(a * math.sin(2 * math.pi * k * x / wide + ph) for k, a, ph in parts)
                r = rnd.uniform(18, 30)
                extra += f'<circle cx="{x:.1f}" cy="{y + 6:.1f}" r="{r:.1f}" fill="{cols[0]}" stroke="{out}" stroke-width="4"/>'
        s.add(extra)
        s.add(f'<path d="{smooth(pts)} L {wide + 60} {height + 10} L -40 {height + 10} Z" fill="{fill}" stroke="{out}" stroke-width="5" stroke-linejoin="round"/>')
        return s.text()

    write("tepe_uzak.svg", hills(300, 120, [(2, 40, 0.4), (3, 24, 1.8), (5, 10, 0.6)], ("#C6EAC0", "#A6D8A8"), "#86B892"))
    write("tepe_yakin.svg", hills(260, 110, [(3, 26, 2.0), (4, 16, 0.3), (7, 7, 1.2)], ("#A8E08A", "#82CC6E"), "#5E9E52", 16, 7))

    # Ahşap kulübe
    s = Svg(280, 280)
    wall = s.lgrad(["#E8B878", "#C8884E"])
    s.add(f'<rect x="56" y="112" width="168" height="150" rx="6" fill="{wall}" stroke="#6E4020" stroke-width="6"/>')
    for k in range(1, 6):
        s.add(f'<path d="M 60 {112 + k * 25} L 220 {112 + k * 25}" stroke="#8E5A2E" stroke-width="3" opacity="0.45"/>')
    s.add('<rect x="176" y="30" width="28" height="60" rx="4" fill="#B86A4A" stroke="#6E3020" stroke-width="5"/>')
    roof = s.lgrad(["#FF9A7A", "#E0604A", "#B8402E"])
    s.add(f'<path d="M 30 124 L 140 34 L 250 124 C 254 130 248 136 240 134 L 40 134 C 32 136 26 130 30 124 Z" fill="{roof}" stroke="#7A2A1E" stroke-width="6" stroke-linejoin="round"/>')
    for k in range(1, 4):
        y = 34 + k * 24
        dx = (y - 34) * 110 / 90
        s.add(f'<path d="M {140 - dx + 6:.1f} {y} L {140 + dx - 6:.1f} {y}" stroke="#9A3A28" stroke-width="3" opacity="0.5"/>')
    shine(s, 104, 70, 20, 6, -38, 0.35)
    s.add('<rect x="120" y="178" width="46" height="84" rx="20" fill="#8A5A30" stroke="#5E3A1E" stroke-width="5"/>')
    circle(s, 156, 222, 4, "#FFD84A", "#8A6A10", 2)
    circle(s, 88, 170, 22, "#BFE4FF", "#5E3A1E", 5)
    s.add('<path d="M 88 148 L 88 192 M 66 170 L 110 170" stroke="#5E3A1E" stroke-width="4"/>')
    shine(s, 80, 162, 5, 3, -30, 0.7)
    s.add('<rect x="186" y="222" width="30" height="24" rx="4" fill="#C86A3A" stroke="#6E3020" stroke-width="4"/>')
    petals(s, 201, 212, 5, 9, 5, "#FF8FBE", "#9C2A58", -90)
    circle(s, 201, 212, 3.5, "#FFD84A")
    write("kulube.svg", s.text())
    s = Svg(280, 280)
    glow = s.rgrad(["#FFF6C0", "#FFD86A"], 0.5, 0.5, 0.6)
    circle(s, 88, 170, 20, glow)
    s.add('<path d="M 88 150 L 88 190 M 68 170 L 108 170" stroke="#5E3A1E" stroke-width="4"/>')
    write("kulube_isik.svg", s.text())

    # Çit parçası (yan yana döşenir): 200 genişlik, direkler 40 ve 140'ta
    s = Svg(200, 120)
    wood = s.lgrad(["#FFFFFF", "#F2E8D8", "#D8C8B0"], 0, 0, 1, 0)
    for y in (48, 84):
        s.add(f'<rect x="-4" y="{y}" width="208" height="14" fill="{wood}" stroke="#8A7458" stroke-width="4"/>')
    for x in (40, 140):
        s.add(f'<path d="M {x - 12} 118 L {x - 12} 22 L {x} 8 L {x + 12} 22 L {x + 12} 118 Z" fill="{wood}" stroke="#8A7458" stroke-width="4.5" stroke-linejoin="round"/>')
        shine(s, x - 5, 40, 2.5, 12, 0, 0.6)
    write("cit.svg", s.text())

    # Çimen öbeği
    s = Svg(100, 70)
    for (x, h, a, c) in [(30, 44, -18, "#6CC66A"), (46, 60, -4, "#5CB85C"), (60, 50, 12, "#7ED67A"), (74, 36, 24, "#62BE5E")]:
        s.add(f'<path d="M {x - 6} 70 Q {x + a * 0.2} {70 - h * 0.6} {x + a} {70 - h} Q {x + 4 + a * 0.2} {70 - h * 0.5} {x + 6} 70 Z" fill="{c}" stroke="{OUT_GREEN}" stroke-width="3.5" stroke-linejoin="round"/>')
    write("cimen.svg", s.text())

    # Gökyüzü bulutu
    s = Svg(220, 110)
    body = s.rgrad(["#FFFFFF", "#F0F7FF"], 0.4, 0.3, 0.8)
    s.add(f'<path {cloud_path(1.0, 1.0, 10, 4)} fill="{body}"/>')
    write("bulut.svg", s.text())

    # Toprak parseli: kabarık toprak yatağı ve önde tahta kenar
    s = Svg(230, 110)
    soil = s.rgrad(["#9A6A44", "#7A4E30", "#5E3A22"], 0.45, 0.25, 0.8)
    s.add(f'<path d="M 14 70 C 20 36 60 26 115 26 C 170 26 210 36 216 70 Z" fill="{soil}" stroke="{OUT_BROWN}" stroke-width="5" stroke-linejoin="round"/>')
    for (x, y) in [(60, 50), (90, 40), (140, 44), (170, 56), (118, 58), (40, 62), (190, 64)]:
        s.add(f'<ellipse cx="{x}" cy="{y}" rx="5" ry="2.5" fill="#4E2E18" opacity="0.5"/>')
    shine(s, 80, 36, 26, 5, -4, 0.18)
    plank = s.lgrad(["#E0B070", "#B8804A"])
    s.add(f'<rect x="8" y="66" width="214" height="36" rx="12" fill="{plank}" stroke="#6E4420" stroke-width="5"/>')
    s.add('<path d="M 76 68 L 76 100 M 154 68 L 154 100" stroke="#6E4420" stroke-width="3" opacity="0.5"/>')
    s.add('<path d="M 20 74 L 210 74" stroke="#FFFFFF" stroke-width="3" opacity="0.35"/>')
    write("parsel.svg", s.text())

    # Su birikintisi
    s = Svg(170, 60)
    water = s.rgrad(["#E0F6FF", "#8ED0F6", "#4E9ED8"], 0.45, 0.4, 0.7)
    s.add(f'<path d="M 10 32 C 8 14 50 8 86 10 C 126 8 164 16 160 32 C 158 48 120 54 84 52 C 44 54 12 48 10 32 Z" fill="{water}" stroke="#2E6EA8" stroke-width="4.5"/>')
    s.add('<path d="M 40 24 Q 70 18 100 20" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.8"/>')
    write("su_birikintisi.svg", s.text())


if __name__ == "__main__":
    make_plants()
    make_controls()
    make_packs()
    make_ui()
    make_critters()
    make_effects()
    make_background()
