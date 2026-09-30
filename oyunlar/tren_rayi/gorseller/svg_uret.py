# Tren Rayı SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre yazar; hayvanlar/ klasörü hafıza oyunundan kopyadır, buna dokunmaz)
# Tarz hafıza oyunuyla uyumlu: yumuşak gradyanlar, parlama noktaları, yumuşak koyu dış çizgi.
# Kuşbakışı çizim. Ray parçaları ve zemin karoları 128x128; hücre ortası (64, 64).
# Parça açıklıkları (döndürülmemiş): duz = batı-doğu, kose = doğu-güney, t = batı-doğu-güney, capraz = dört yön.
# Not: Godot'nun SVG çizicisi, iki kontrol noktası aynı yükseklikte olan kübik eğrinin degrade dolgusunu çizmiyor;
# bu yüzden şekiller daire, elips, dikdörtgen, çokgen ve yaylarla çizilir.

import math
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
INK = "#4A3B5C"            # yumuşak koyu dış çizgi
T = 128                    # karo boyu
GAUGE = 20                 # ray ekseninden raylara uzaklık
SLEEPER_HALF = 31          # travers yarı boyu (eksene dik)


class Svg:
    def __init__(self, w: int = T, h: int = T):
        self.w, self.h = w, h
        self.defs: list = []
        self.body: list = []
        self.n = 0

    def _id(self) -> str:
        self.n += 1
        return f"g{self.n}"

    def _stops(self, colors, opacities=None) -> str:
        out = ""
        for i, c in enumerate(colors):
            op = f' stop-opacity="{opacities[i]}"' if opacities else ""
            out += f'<stop offset="{i / max(1, len(colors) - 1):.2f}" stop-color="{c}"{op}/>'
        return out

    def rgrad(self, colors, cx=0.4, cy=0.32, r=0.75, opacities=None) -> str:
        gid = self._id()
        self.defs.append(f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}">{self._stops(colors, opacities)}</radialGradient>')
        return f"url(#{gid})"

    def lgrad(self, colors, x1=0.0, y1=0.0, x2=0.0, y2=1.0, opacities=None) -> str:
        gid = self._id()
        self.defs.append(f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{self._stops(colors, opacities)}</linearGradient>')
        return f"url(#{gid})"

    def ugrad(self, colors, x1, y1, x2, y2, opacities=None) -> str:
        """Kullanıcı koordinatlı doğrusal degrade (döndürülmüş şekillerde ışık yönü sabit kalsın diye)"""
        gid = self._id()
        self.defs.append(f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}">{self._stops(colors, opacities)}</linearGradient>')
        return f"url(#{gid})"

    def urgrad(self, colors, cx, cy, r, opacities=None) -> str:
        gid = self._id()
        self.defs.append(f'<radialGradient id="{gid}" gradientUnits="userSpaceOnUse" cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}">{self._stops(colors, opacities)}</radialGradient>')
        return f"url(#{gid})"

    def clip(self, inner: str) -> str:
        gid = self._id()
        self.defs.append(f'<clipPath id="{gid}">{inner}</clipPath>')
        return f"url(#{gid})"

    def add(self, s: str) -> None:
        self.body.append(s)

    def text(self) -> str:
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}">\n'
                f'  <defs>{"".join(self.defs)}</defs>\n  ' + "\n  ".join(self.body) + "\n</svg>\n")


def write(rel: str, text: str) -> None:
    path = os.path.join(HERE, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def st(out, sw):
    return f' stroke="{out}" stroke-width="{sw}" stroke-linejoin="round"' if out else ""


def circle(s, cx, cy, r, fill, out=None, sw=3.0, extra=""):
    s.add(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{fill}"{st(out, sw)} {extra}/>')


def ellipse(s, cx, cy, rx, ry, fill, out=None, sw=3.0, angle=0.0, extra=""):
    tr = f' transform="rotate({angle:.1f} {cx:.1f} {cy:.1f})"' if angle else ""
    s.add(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{fill}"{st(out, sw)}{tr} {extra}/>')


def rect(s, x, y, w, h, rx, fill, out=None, sw=3.0, extra=""):
    s.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx:.1f}" fill="{fill}"{st(out, sw)} {extra}/>')


def poly(s, pts, fill, out=None, sw=3.0, extra=""):
    p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    s.add(f'<polygon points="{p}" fill="{fill}"{st(out, sw)} {extra}/>')


def shine(s, cx, cy, rx, ry, angle=-30, opacity=0.55):
    s.add(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" transform="rotate({angle} {cx:.1f} {cy:.1f})" fill="#FFFFFF" opacity="{opacity}"/>')


def shadow(s, cx, cy, rx, ry, opacity=0.28):
    g = s.rgrad(["#2A1F3A", "#2A1F3A"], 0.5, 0.5, 0.5, opacities=[opacity, 0])
    s.add(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{g}"/>')


def star_pts(cx, cy, ro, ri, n=5, rot=-90.0):
    pts = []
    for k in range(n * 2):
        r = ro if k % 2 == 0 else ri
        a = math.radians(rot + k * 180.0 / n)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def arc_pts(cx, cy, r, a0, a1, steps=24):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / steps)),
             cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / steps))) for i in range(steps + 1)]


# --- Ray parçaları ---------------------------------------------------------------------------------------
# Bir parça, "iz"lerden oluşur: düz iz (iki kenar ortası arası) ya da yay iz (köşe merkezli, yarıçap 64).
# Önce bütün izlerin gölgesi, sonra traversleri, en üstte rayları çizilir (kavşaklar temiz görünsün).

WOOD = ("#D99A62", "#A8683A", "#6B4226")
RAIL = ("#FFFFFF", "#C9CFDC", "#8A92A8", "#454B63")


def track_line(ax, ay, bx, by):
    return ("line", (ax, ay, bx, by))


def track_arc(cx, cy, a0, a1):
    return ("arc", (cx, cy, a0, a1))


def _sleepers(tr, count=6):
    """Traverslerin (merkez, açı) listesi"""
    kind, p = tr
    out = []
    if kind == "line":
        ax, ay, bx, by = p
        ang = math.degrees(math.atan2(by - ay, bx - ax))
        for i in range(count):
            t = (i + 0.5) / count
            out.append((ax + (bx - ax) * t, ay + (by - ay) * t, ang))
    else:
        cx, cy, a0, a1 = p
        for i in range(count):
            a = a0 + (a1 - a0) * (i + 0.5) / count
            x = cx + 64 * math.cos(math.radians(a))
            y = cy + 64 * math.sin(math.radians(a))
            out.append((x, y, a + 90))
    return out


def _rail_paths(tr):
    """Bir izin iki rayı: her biri (dolgu yolu, dış çizgi yolu 1, dış çizgi yolu 2, parlama yolu)"""
    kind, p = tr
    rails = []
    w = 3.6                      # rayın yarı kalınlığı
    if kind == "line":
        ax, ay, bx, by = p
        dx, dy = bx - ax, by - ay
        ln = math.hypot(dx, dy)
        nx, ny = -dy / ln, dx / ln
        for side in (-1, 1):
            o = side * GAUGE
            e1 = [(ax + nx * (o - w), ay + ny * (o - w)), (bx + nx * (o - w), by + ny * (o - w))]
            e2 = [(ax + nx * (o + w), ay + ny * (o + w)), (bx + nx * (o + w), by + ny * (o + w))]
            hl = [(ax + nx * (o - 1), ay + ny * (o - 1)), (bx + nx * (o - 1), by + ny * (o - 1))]
            rails.append((e1 + e2[::-1], e1, e2, hl))
    else:
        cx, cy, a0, a1 = p
        for side in (-1, 1):
            r = 64 + side * GAUGE
            e1 = arc_pts(cx, cy, r - w, a0, a1)
            e2 = arc_pts(cx, cy, r + w, a0, a1)
            hl = arc_pts(cx, cy, r - 1, a0, a1)
            rails.append((e1 + e2[::-1], e1, e2, hl))
    return rails


def _pl(pts):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)


def track_svg(tracks, sleeper_skip=None) -> str:
    s = Svg()
    sleepers = []
    for i, tr in enumerate(tracks):
        for j, sl in enumerate(_sleepers(tr)):
            if sleeper_skip and sleeper_skip(i, j):
                continue
            sleepers.append(sl)
    wood = s.lgrad([WOOD[0], WOOD[1]], 0, 0, 1, 0)
    # Gölge (hafif aşağı-sağa kaymış)
    for x, y, a in sleepers:
        s.add(f'<rect x="{x - 6 + 2.5:.1f}" y="{y - SLEEPER_HALF + 4:.1f}" width="12" height="{2 * SLEEPER_HALF}" rx="4" '
              f'fill="#2A1F3A" opacity="0.16" transform="rotate({a:.1f} {x + 2.5:.1f} {y + 4:.1f})"/>')
    for x, y, a in sleepers:
        s.add(f'<rect x="{x - 6:.1f}" y="{y - SLEEPER_HALF:.1f}" width="12" height="{2 * SLEEPER_HALF}" rx="4" fill="{wood}" '
              f'stroke="{WOOD[2]}" stroke-width="2.2" transform="rotate({a:.1f} {x:.1f} {y:.1f})"/>')
        # ahşap damarı
        s.add(f'<line x1="{x - 1.5:.1f}" y1="{y - SLEEPER_HALF + 7:.1f}" x2="{x - 1.5:.1f}" y2="{y + SLEEPER_HALF - 9:.1f}" '
              f'stroke="#FFFFFF" stroke-opacity="0.28" stroke-width="2" stroke-linecap="round" transform="rotate({a:.1f} {x:.1f} {y:.1f})"/>')
    rail_fill = s.lgrad([RAIL[1], RAIL[2]], 0, 0, 1, 1)
    rails = [r for tr in tracks for r in _rail_paths(tr)]
    for fill_pts, _e1, _e2, _hl in rails:
        s.add(f'<polygon points="{_pl([(x + 2, y + 3) for x, y in fill_pts])}" fill="#2A1F3A" opacity="0.18"/>')
    for fill_pts, e1, e2, hl in rails:
        s.add(f'<polygon points="{_pl(fill_pts)}" fill="{rail_fill}"/>')
        s.add(f'<polyline points="{_pl(e1)}" fill="none" stroke="{RAIL[3]}" stroke-width="2.2" stroke-linejoin="round"/>')
        s.add(f'<polyline points="{_pl(e2)}" fill="none" stroke="{RAIL[3]}" stroke-width="2.2" stroke-linejoin="round"/>')
        s.add(f'<polyline points="{_pl(hl)}" fill="none" stroke="{RAIL[0]}" stroke-opacity="0.85" stroke-width="1.8"/>')
    return s.text()


def glow_svg(tracks) -> str:
    """Bağlı rayların parlaması: izler boyunca yumuşak, geniş beyaz şerit (Godot'ta renklenir)"""
    s = Svg()
    for width, op in ((84, 0.16), (66, 0.2), (48, 0.28), (30, 0.4)):
        for kind, p in tracks:
            if kind == "line":
                ax, ay, bx, by = p
                s.add(f'<line x1="{ax}" y1="{ay}" x2="{bx}" y2="{by}" stroke="#FFFFFF" stroke-opacity="{op}" stroke-width="{width}"/>')
            else:
                cx, cy, a0, a1 = p
                s.add(f'<polyline points="{_pl(arc_pts(cx, cy, 64, a0, a1))}" fill="none" stroke="#FFFFFF" stroke-opacity="{op}" stroke-width="{width}"/>')
    return s.text()


PIECES = {
    "duz": [track_line(0, 64, 128, 64)],
    "kose": [track_arc(128, 128, 180, 270)],
    "t": [track_line(0, 64, 128, 64), track_arc(128, 128, 180, 270), track_arc(0, 128, 270, 360)],
    "capraz": [track_line(0, 64, 128, 64), track_line(64, 0, 64, 128)],
}


def _t_skip(i, j):
    # Kavşakta yay traverslerinin düz raya binenleri çizilmez
    return i > 0 and ((i == 1 and j >= 3) or (i == 2 and j <= 2))


def _cross_skip(i, j):
    return i == 1 and j in (2, 3)


def pieces():
    for name, tracks in PIECES.items():
        skip = _t_skip if name == "t" else (_cross_skip if name == "capraz" else None)
        write(f"ray_{name}.svg", track_svg(tracks, skip))
        write(f"ray_{name}_isik.svg", glow_svg(tracks))


def bolt():
    s = Svg(40, 40)
    shadow(s, 21, 24, 16, 12)
    circle(s, 20, 20, 14, s.rgrad(["#FFFFFF", "#C9CFDC", "#7E86A0"], 0.35, 0.3, 0.8), INK, 2.6)
    hexa = [(20 + 8 * math.cos(math.radians(30 + 60 * k)), 20 + 8 * math.sin(math.radians(30 + 60 * k))) for k in range(6)]
    poly(s, hexa, s.lgrad(["#E7EAF2", "#9AA2B8"]), "#5A607A", 1.8)
    s.add('<line x1="15" y1="20" x2="25" y2="20" stroke="#5A607A" stroke-width="2.6" stroke-linecap="round"/>')
    shine(s, 15, 14, 4, 2.4, -35, 0.8)
    write("civata.svg", s.text())


# --- Zemin karoları (her tema) --------------------------------------------------------------------------

THEMES = {
    # zemin açık, zemin koyu, ayrıntı rengi
    "ciftlik": ("#A4DE7A", "#86C95E", "#5FA843"),
    "orman": ("#B79A6E", "#9C7F55", "#6F8F3E"),
    "kar": ("#FFFFFF", "#E3EEFA", "#B9CCE6"),
    "sahil": ("#FBE7B5", "#F1D48F", "#D9B46A"),
    "gece": ("#5C5F80", "#4B4E6D", "#3A3C57"),
}


def tile(theme):
    light, dark, detail = THEMES[theme]
    s = Svg()
    rng = random.Random(theme)
    rect(s, 0, 0, T, T, 0, s.lgrad([light, dark], 0, 0, 0.6, 1))
    if theme == "ciftlik":
        for _ in range(9):
            x, y = rng.uniform(14, 114), rng.uniform(14, 114)
            s.add(f'<path d="M{x - 5:.1f} {y + 3:.1f} L{x - 2:.1f} {y - 5:.1f} M{x:.1f} {y + 3:.1f} L{x + 1:.1f} {y - 6:.1f} M{x + 4:.1f} {y + 3:.1f} L{x + 5:.1f} {y - 4:.1f}" '
                  f'stroke="{detail}" stroke-width="2.4" stroke-linecap="round" fill="none" opacity="0.8"/>')
        for _ in range(3):
            x, y = rng.uniform(16, 112), rng.uniform(16, 112)
            c = rng.choice(["#FFFFFF", "#FFE066", "#FF9CC2"])
            for k in range(5):
                a = math.radians(k * 72)
                circle(s, x + 3.2 * math.cos(a), y + 3.2 * math.sin(a), 2.4, c)
            circle(s, x, y, 1.8, "#FFB020")
    elif theme == "orman":
        for _ in range(4):
            x, y = rng.uniform(18, 110), rng.uniform(18, 110)
            ellipse(s, x, y, rng.uniform(10, 16), rng.uniform(6, 10), detail, extra='opacity="0.55"', angle=rng.uniform(0, 180))
        for _ in range(10):
            x, y = rng.uniform(8, 120), rng.uniform(8, 120)
            a = rng.uniform(0, 180)
            s.add(f'<line x1="{x:.1f}" y1="{y:.1f}" x2="{x + 7 * math.cos(math.radians(a)):.1f}" y2="{y + 7 * math.sin(math.radians(a)):.1f}" '
                  f'stroke="#7A5E3A" stroke-width="2" stroke-linecap="round" opacity="0.7"/>')
        for _ in range(4):
            circle(s, rng.uniform(10, 118), rng.uniform(10, 118), rng.uniform(1.5, 2.8), "#8A6E48", extra='opacity="0.8"')
    elif theme == "kar":
        for _ in range(5):
            x, y = rng.uniform(16, 112), rng.uniform(16, 112)
            ellipse(s, x, y, rng.uniform(12, 20), rng.uniform(5, 8), detail, extra='opacity="0.35"')
        for _ in range(6):
            x, y = rng.uniform(10, 118), rng.uniform(10, 118)
            poly(s, star_pts(x, y, 3.6, 1.2, 4, 0), "#FFFFFF")
            circle(s, x, y, 1.0, "#CFE6FF")
    elif theme == "sahil":
        for k in range(4):
            y = 20 + k * 28 + rng.uniform(-4, 4)
            s.add(f'<polyline points="{_pl([(x, y + 3 * math.sin(x / 11.0 + k)) for x in range(6, 124, 6)])}" fill="none" '
                  f'stroke="{detail}" stroke-width="2" stroke-linecap="round" opacity="0.45"/>')
        for _ in range(5):
            circle(s, rng.uniform(10, 118), rng.uniform(10, 118), rng.uniform(1.4, 2.6), rng.choice(["#FFFFFF", "#F7B7A3", "#E8C27A"]))
    elif theme == "gece":
        for _ in range(26):
            circle(s, rng.uniform(4, 124), rng.uniform(4, 124), rng.uniform(0.8, 1.8),
                   rng.choice(["#6E7196", "#3E4060", "#7C7FA6"]), extra='opacity="0.8"')
    # Hücre kenarı: içte açık, dışta koyu ince çizgi (ızgara seçilsin)
    rect(s, 1.5, 1.5, T - 3, T - 3, 10, "none", "#FFFFFF", 2.5, 'stroke-opacity="0.28"')
    rect(s, 0, 0, T, T, 0, "none", "#2A1F3A", 2.0, 'stroke-opacity="0.14"')
    write(f"zemin_{theme}.svg", s.text())


# --- Engeller (tema başına: A ağaç türü, G su türü, K kaya türü) -------------------------------------------

def _tree_round(s, cx, cy, r, greens, fruit=None):
    shadow(s, cx + 6, cy + 10, r * 1.05, r * 0.85)
    circle(s, cx, cy, r, s.rgrad(greens, 0.38, 0.3, 0.8), INK, 3.2)
    for a, rr in ((200, 0.55), (320, 0.5), (80, 0.52)):
        x = cx + r * 0.42 * math.cos(math.radians(a))
        y = cy + r * 0.42 * math.sin(math.radians(a))
        circle(s, x, y, r * rr * 0.62, s.rgrad([greens[0], greens[1]], 0.35, 0.3, 0.8), extra='opacity="0.75"')
    if fruit:
        for a in (30, 150, 260, 340, 100):
            x = cx + r * 0.62 * math.cos(math.radians(a))
            y = cy + r * 0.62 * math.sin(math.radians(a))
            circle(s, x, y, 5.5, s.rgrad([fruit[0], fruit[1]], 0.35, 0.3, 0.8), INK, 1.8)
            shine(s, x - 1.6, y - 1.8, 1.8, 1.1, -30, 0.8)
    shine(s, cx - r * 0.35, cy - r * 0.42, r * 0.28, r * 0.14, -35, 0.45)


def _pine(s, cx, cy, r, greens, snow=False, lights=False):
    shadow(s, cx + 6, cy + 10, r * 1.05, r * 0.9)
    for layer, (rr, rot) in enumerate(((1.0, 0), (0.74, 18), (0.48, 36))):
        pts = star_pts(cx, cy, r * rr, r * rr * 0.62, 8, rot - 90)
        g = s.rgrad([greens[0], greens[1], greens[2]], 0.4, 0.35, 0.8)
        poly(s, pts, g, INK if layer == 0 else greens[2], 3.0 if layer == 0 else 1.8)
        if snow:
            spts = star_pts(cx, cy, r * rr * 0.9, r * rr * 0.55, 8, rot - 90)
            poly(s, [(x * 0.55 + cx * 0.45 - 2, y * 0.55 + cy * 0.45 - 2) for x, y in spts], "#FFFFFF", extra='opacity="0.9"')
    circle(s, cx, cy, r * 0.12, "#8A5A34", INK, 1.6)
    if lights:
        for k in range(10):
            a = math.radians(k * 36 + 10)
            rr = r * (0.8 if k % 2 == 0 else 0.5)
            col = ["#FFE066", "#FF7A9A", "#7FD4FF"][k % 3]
            circle(s, cx + rr * math.cos(a), cy + rr * math.sin(a), 6, col, extra='opacity="0.35"')
            circle(s, cx + rr * math.cos(a), cy + rr * math.sin(a), 3, col)


def _pond(s, cx, cy, rx, ry, water, rim, extra=None):
    shadow(s, cx + 3, cy + 6, rx + 6, ry + 6, 0.2)
    ellipse(s, cx, cy, rx + 5, ry + 5, rim, INK, 3)
    ellipse(s, cx, cy, rx, ry, s.rgrad(water, 0.4, 0.35, 0.8))
    s.add(f'<path d="M{cx - rx * 0.5:.1f} {cy - ry * 0.25:.1f} q{rx * 0.18:.1f} -{ry * 0.12:.1f} {rx * 0.36:.1f} 0" stroke="#FFFFFF" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.7"/>')
    s.add(f'<path d="M{cx + rx * 0.05:.1f} {cy + ry * 0.35:.1f} q{rx * 0.15:.1f} -{ry * 0.1:.1f} {rx * 0.3:.1f} 0" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.5"/>')
    if extra:
        extra(s)


def _rock(s, cx, cy, r, greys, snow=False):
    shadow(s, cx + 5, cy + 9, r * 1.1, r * 0.8)
    for dx, dy, rr in ((-r * 0.45, r * 0.25, 0.62), (r * 0.42, r * 0.3, 0.55), (0, -r * 0.12, 0.8)):
        pts = []
        for k in range(7):
            a = math.radians(k * 360 / 7 + 12)
            q = r * rr * (0.86 + 0.14 * math.sin(k * 2.3))
            pts.append((cx + dx + q * math.cos(a), cy + dy + q * math.sin(a)))
        poly(s, pts, s.rgrad(greys, 0.35, 0.3, 0.8), INK, 3)
        if snow:
            ellipse(s, cx + dx - r * rr * 0.12, cy + dy - r * rr * 0.28, r * rr * 0.55, r * rr * 0.32, "#FFFFFF", extra='opacity="0.95"')
        shine(s, cx + dx - r * rr * 0.3, cy + dy - r * rr * 0.35, r * rr * 0.22, r * rr * 0.1, -30, 0.5)


def obstacles():
    # Çiftlik
    s = Svg(); _tree_round(s, 64, 60, 44, ["#9BE27A", "#5DB847", "#2F7D35"], ("#FF8A8A", "#E3343F")); write("engel_ciftlik_A.svg", s.text())
    s = Svg()
    def lily(s):
        circle(s, 50, 70, 11, "#6CCB5A", "#2F7D35", 2)
        poly(s, [(50, 70), (61, 64), (61, 70)], "#8FD6F0")
        circle(s, 80, 54, 5, "#FFFFFF", "#E07AA0", 1.6)
        circle(s, 80, 54, 2, "#FFD35A")
    _pond(s, 64, 64, 44, 34, ["#B6ECFF", "#5CB8F0", "#2E86C8"], "#C9A87A", lily); write("engel_ciftlik_G.svg", s.text())
    s = Svg()
    shadow(s, 70, 74, 46, 36)
    circle(s, 64, 64, 42, s.rgrad(["#FFF1A6", "#F5CF5C", "#C99A2E"], 0.38, 0.3, 0.8), INK, 3.2)
    s.add(f'<polyline points="{_pl([(64 + (4 + t * 1.1) * math.cos(t * 0.55), 64 + (4 + t * 1.1) * math.sin(t * 0.55)) for t in range(0, 34)])}" '
          f'fill="none" stroke="#B98A28" stroke-width="2.6" stroke-linecap="round" opacity="0.8"/>')
    shine(s, 48, 44, 10, 5, -35, 0.5)
    write("engel_ciftlik_K.svg", s.text())
    # Orman
    s = Svg(); _pine(s, 64, 62, 48, ["#8FE08A", "#3FA85A", "#1E6B3C"]); write("engel_orman_A.svg", s.text())
    s = Svg()
    def reeds(s):
        for x, y in ((30, 44), (36, 40), (94, 86), (100, 82)):
            ellipse(s, x, y, 3, 8, "#8A5A34", INK, 1.4)
    _pond(s, 64, 64, 42, 32, ["#A8E6D8", "#4AA89A", "#2A7A70"], "#8C7A5A", reeds); write("engel_orman_G.svg", s.text())
    s = Svg(); _rock(s, 64, 64, 40, ["#D9DCE6", "#A3A8BA", "#6F748C"]); write("engel_orman_K.svg", s.text())
    # Karlı dağlar
    s = Svg(); _pine(s, 64, 62, 48, ["#7ED0A0", "#2E8C66", "#1A5A44"], snow=True); write("engel_kar_A.svg", s.text())
    s = Svg()
    def ice(s):
        for x1, y1, x2, y2 in ((40, 58, 58, 70), (58, 70, 72, 62), (72, 62, 90, 72)):
            s.add(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#FFFFFF" stroke-width="2" opacity="0.75"/>')
    _pond(s, 64, 64, 44, 34, ["#FFFFFF", "#C8E8FF", "#8CC4EE"], "#FFFFFF", ice); write("engel_kar_G.svg", s.text())
    s = Svg(); _rock(s, 64, 64, 40, ["#E6E8F2", "#AEB3C6", "#7A7F98"], snow=True); write("engel_kar_K.svg", s.text())
    # Sahil
    s = Svg()
    shadow(s, 72, 74, 46, 36)
    for k in range(7):
        a = k * 360 / 7 + 8
        x2 = 64 + 50 * math.cos(math.radians(a))
        y2 = 64 + 50 * math.sin(math.radians(a))
        ellipse(s, (64 + x2) / 2, (64 + y2) / 2, 27, 9, s.lgrad(["#9BE27A", "#3E9E4A"], 0, 0, 0, 1), INK, 2.6, a)
        s.add(f'<line x1="64" y1="64" x2="{x2:.1f}" y2="{y2:.1f}" stroke="#2F7D35" stroke-width="2" opacity="0.8"/>')
    for dx, dy in ((-6, -4), (5, -3), (0, 6)):
        circle(s, 64 + dx, 64 + dy, 7, s.rgrad(["#C9965A", "#8A5A34"], 0.35, 0.3, 0.8), INK, 1.8)
    write("engel_sahil_A.svg", s.text())
    s = Svg()
    def starfish(s):
        poly(s, star_pts(78, 72, 11, 5, 5, -80), "#FF8A6A", INK, 1.8)
        circle(s, 46, 56, 5, "#FFFFFF", "#B9C6D8", 1.4)
    _pond(s, 64, 64, 42, 32, ["#C8F4FF", "#5CD0E8", "#2FA3C8"], "#F1D48F", starfish); write("engel_sahil_G.svg", s.text())
    s = Svg()
    shadow(s, 70, 74, 48, 38)
    rect(s, 26, 30, 76, 68, 10, s.rgrad(["#FFF0C2", "#F2CE82", "#C99A4E"], 0.35, 0.3, 0.9), INK, 3)
    for x, y in ((30, 34), (98, 34), (30, 94), (98, 94)):
        circle(s, x, y, 13, s.rgrad(["#FFF0C2", "#EBC173", "#B9894A"], 0.35, 0.3, 0.9), INK, 2.6)
        circle(s, x, y, 5, "#C99A4E")
    rect(s, 50, 50, 28, 28, 6, "#E3B66A", "#B9894A", 2)
    s.add('<line x1="64" y1="50" x2="64" y2="30" stroke="#8A5A34" stroke-width="2.4"/>')
    poly(s, [(64, 22), (80, 27), (64, 32)], "#FF6F7D", INK, 1.6)
    write("engel_sahil_K.svg", s.text())
    # Gece şehri
    s = Svg(); _pine(s, 64, 62, 46, ["#6FB88A", "#2F6E58", "#1B4238"], lights=True); write("engel_gece_A.svg", s.text())
    s = Svg()
    shadow(s, 68, 72, 48, 40)
    circle(s, 64, 64, 44, s.rgrad(["#E9ECF6", "#B7BDD2", "#8990AC"], 0.38, 0.3, 0.85), INK, 3)
    circle(s, 64, 64, 34, s.rgrad(["#B6ECFF", "#4AA3E8", "#2266A8"], 0.4, 0.35, 0.8))
    for k in range(8):
        a = math.radians(k * 45)
        circle(s, 64 + 20 * math.cos(a), 64 + 20 * math.sin(a), 4, "#FFFFFF", extra='opacity="0.7"')
    circle(s, 64, 64, 10, s.rgrad(["#FFFFFF", "#CFE9FF"], 0.4, 0.35, 0.8), "#6B8FB8", 2)
    write("engel_gece_G.svg", s.text())
    s = Svg()
    shadow(s, 70, 74, 50, 42)
    # Çatı (kuşbakışı iki eğimli): üst yarı açık, alt yarı koyu
    poly(s, [(18, 26), (110, 26), (110, 64), (18, 64)], s.lgrad(["#FF9A8A", "#E0584E"]), INK, 3)
    poly(s, [(18, 64), (110, 64), (110, 102), (18, 102)], s.lgrad(["#C9453E", "#A8322E"]), INK, 3)
    for x in range(28, 106, 14):
        s.add(f'<line x1="{x}" y1="28" x2="{x}" y2="62" stroke="#FFFFFF" stroke-width="1.6" opacity="0.3"/>')
    rect(s, 80, 36, 16, 18, 3, "#8C8FA8", INK, 2)
    rect(s, 34, 72, 20, 16, 4, "#FFE27A", INK, 2, 'opacity="0.95"')
    circle(s, 44, 80, 16, "#FFE27A", extra='opacity="0.25"')
    write("engel_gece_K.svg", s.text())


# --- Peron (yolcu bekleme yeri), istasyon ---------------------------------------------------------------

def platform():
    s = Svg()
    shadow(s, 66, 72, 50, 40, 0.22)
    rect(s, 16, 20, 96, 88, 14, s.lgrad(["#F3E4C8", "#D9C29A"]), INK, 3)
    for y in (42, 64, 86):
        s.add(f'<line x1="20" y1="{y}" x2="108" y2="{y}" stroke="#B89A6C" stroke-width="2" opacity="0.6"/>')
    rect(s, 22, 26, 84, 10, 4, "#FFFFFF", extra='opacity="0.3"')
    # küçük tabela direği
    circle(s, 100, 30, 9, s.rgrad(["#8FE0FF", "#3E8EEB"], 0.35, 0.3, 0.8), INK, 2.2)
    s.add('<path d="M96 30 L104 30 M100 26 L100 34" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round"/>')
    write("peron.svg", s.text())


def station():
    # 256x192: ray yatay y=128'de soldan girer, sağda tampon; bina rayın üstünde (y 8..84)
    s = Svg(256, 192)
    shadow(s, 132, 70, 124, 60, 0.22)
    # peron taşları
    rect(s, 6, 76, 244, 22, 8, s.lgrad(["#F2EEE6", "#CFC6B6"]), INK, 3)
    for x in range(26, 246, 22):
        s.add(f'<line x1="{x}" y1="80" x2="{x}" y2="94" stroke="#B3A994" stroke-width="1.8"/>')
    # bina çatısı
    rect(s, 20, 8, 216, 72, 16, s.lgrad(["#8FD0FF", "#3E8EEB"]), INK, 3.4)
    rect(s, 20, 40, 216, 40, 14, s.lgrad(["#3C7FD8", "#2A62B8"]), extra='opacity="0.75"')
    for x in range(36, 230, 16):
        s.add(f'<line x1="{x}" y1="12" x2="{x}" y2="38" stroke="#FFFFFF" stroke-width="1.8" opacity="0.28"/>')
    shine(s, 60, 20, 30, 6, 0, 0.45)
    # saat
    circle(s, 128, 40, 17, s.rgrad(["#FFFFFF", "#F2EEE6"], 0.4, 0.35, 0.8), INK, 3)
    s.add('<path d="M128 40 L128 30 M128 40 L135 44" stroke="#4A3B5C" stroke-width="2.6" stroke-linecap="round"/>')
    # saksılar
    for x in (40, 216):
        circle(s, x, 60, 10, s.rgrad(["#E8A070", "#B96A3E"], 0.35, 0.3, 0.8), INK, 2)
        for k in range(5):
            a = math.radians(k * 72)
            circle(s, x + 5 * math.cos(a), 60 + 5 * math.sin(a), 3.6, "#FF7FA8")
        circle(s, x, 60, 2.6, "#FFD35A")
    # tampon (ray sonu)
    rect(s, 226, 104, 18, 48, 6, s.lgrad(["#FF8A8A", "#D9343F"], 0, 0, 1, 0), INK, 3)
    for y in (116, 140):
        circle(s, 222, y, 6, s.rgrad(["#FFFFFF", "#C9CFDC", "#8A92A8"], 0.35, 0.3, 0.8), INK, 2)
    write("istasyon.svg", s.text())


# --- Lokomotif ve vagonlar (kuşbakışı, sağa bakar) --------------------------------------------------------

def locomotive():
    s = Svg(220, 120)
    shadow(s, 114, 70, 106, 52, 0.25)
    # tekerlekler (yanlardan görünür)
    for x in (56, 104, 152):
        for y in (8, 100):
            rect(s, x - 15, y, 30, 12, 5, s.lgrad(["#5C5474", "#2E2842"]), INK, 2.2)
    # şasi
    rect(s, 14, 16, 194, 88, 24, s.lgrad(["#7A3350", "#5A2240"]), INK, 3)
    # inek mahmuzu (ön)
    poly(s, [(200, 32), (216, 48), (216, 72), (200, 88)], s.lgrad(["#FFE27A", "#E9A800"], 0, 0, 1, 0), INK, 3)
    for y in (48, 60, 72):
        s.add(f'<line x1="204" y1="{y}" x2="213" y2="{y}" stroke="#B98A10" stroke-width="2"/>')
    # kazan (silindir: ortası açık)
    rect(s, 68, 28, 132, 64, 32, s.lgrad(["#C7303F", "#FF7A7A", "#FFA3A3", "#E8404C", "#B0283A"]), INK, 3)
    for x in (104, 146):
        rect(s, x - 5, 27, 10, 66, 4, s.lgrad(["#FFE27A", "#F5C23A", "#C9900E"], 0, 0, 0, 1), INK, 2)
    shine(s, 132, 47, 44, 5, 0, 0.5)
    # ön kapak ve far
    circle(s, 192, 60, 16, s.rgrad(["#8C86A6", "#5C5474", "#3A344E"], 0.4, 0.35, 0.8), INK, 2.6)
    circle(s, 202, 60, 13, "#FFF3A6", extra='opacity="0.35"')
    circle(s, 200, 60, 7, s.rgrad(["#FFFFFF", "#FFE066", "#F5B400"], 0.4, 0.35, 0.8), INK, 2)
    # baca ve buhar kubbesi
    circle(s, 170, 60, 15, s.rgrad(["#6E6888", "#3E3856", "#262036"], 0.4, 0.35, 0.8), INK, 3)
    circle(s, 170, 60, 8, "#1C1728")
    shine(s, 164, 53, 5, 2.4, -35, 0.6)
    circle(s, 125, 60, 11, s.rgrad(["#FFF3A6", "#F5C23A", "#C9900E"], 0.35, 0.3, 0.8), INK, 2.4)
    shine(s, 122, 56, 4, 2.2, -35, 0.8)
    # kabin çatısı
    rect(s, 10, 18, 66, 84, 18, s.lgrad(["#8FD0FF", "#3E8EEB", "#2A62B8"], 0, 0, 0, 1), INK, 3.2)
    rect(s, 18, 26, 50, 68, 12, "none", "#FFFFFF", 2, 'stroke-opacity="0.35"')
    shine(s, 32, 32, 15, 5, -10, 0.5)
    write("lokomotif.svg", s.text())


WAGON_COLORS = {
    "kirmizi": ("#FFB0B0", "#F2545E", "#B82E3C"),
    "mavi": ("#AEDBFF", "#4AA3FF", "#2466C2"),
    "sari": ("#FFF1A6", "#FFC93D", "#D08E0A"),
    "yesil": ("#B6F2B4", "#4FC45F", "#2A8A3E"),
    "mor": ("#DCC6FF", "#A66BFF", "#6E3EC2"),
}
WAGON_DESIGNS = ["yolcu", "acik", "kargo", "tanker", "odun", "cicek"]


def wagon(design, color):
    light, mid, dark = WAGON_COLORS[color]
    s = Svg(160, 110)
    shadow(s, 84, 62, 78, 48, 0.25)
    # bağlantı kancaları
    for x in (0, 150):
        rect(s, x, 49, 10, 12, 3, "#6E6888", INK, 2)
    for x in (44, 116):
        for y in (6, 92):
            rect(s, x - 13, y, 26, 12, 5, s.lgrad(["#5C5474", "#2E2842"]), INK, 2.2)
    body = s.lgrad([dark, mid, light, mid, dark])
    if design == "yolcu":
        rect(s, 8, 14, 144, 82, 20, body, INK, 3)
        rect(s, 16, 22, 128, 66, 14, "none", "#FFFFFF", 2, 'stroke-opacity="0.35"')
        s.add(f'<line x1="18" y1="55" x2="142" y2="55" stroke="{dark}" stroke-width="2.4" opacity="0.6"/>')
        for x in (52, 108):
            circle(s, x, 55, 19, s.rgrad(["#E8F8FF", "#9FD8F5", "#5AA8D8"], 0.4, 0.35, 0.8), INK, 3)
            shine(s, x - 6, 48, 6, 3, -35, 0.8)
    elif design == "acik":
        rect(s, 8, 14, 144, 82, 16, body, INK, 3)
        rect(s, 18, 24, 124, 62, 10, s.lgrad(["#7A5A40", "#5A3E2A"]), INK, 2)
        rng = random.Random(color)
        blocks = ["#FF7A8A", "#FFD35A", "#6FCF7A", "#6AB6FF", "#B98AFF"]
        for i, (x, y) in enumerate(((30, 36), (60, 38), (96, 34), (120, 62), (42, 66), (78, 64))):
            c = blocks[(i + rng.randint(0, 4)) % 5]
            rect(s, x - 11, y - 11, 22, 22, 5, s.rgrad(["#FFFFFF", c, c], 0.35, 0.3, 0.9), INK, 2, f'transform="rotate({rng.randint(-15, 15)} {x} {y})"')
    elif design == "kargo":
        rect(s, 8, 14, 144, 82, 12, body, INK, 3)
        for x in range(22, 146, 12):
            s.add(f'<line x1="{x}" y1="18" x2="{x}" y2="92" stroke="{dark}" stroke-width="2" opacity="0.45"/>')
        rect(s, 62, 38, 36, 34, 6, s.lgrad([light, mid]), INK, 2.4)
        s.add(f'<line x1="80" y1="40" x2="80" y2="70" stroke="{dark}" stroke-width="2"/>')
    elif design == "tanker":
        rect(s, 8, 16, 144, 78, 36, body, INK, 3)
        for x in (40, 120):
            rect(s, x - 4, 15, 8, 80, 3, s.lgrad(["#E7EAF2", "#9AA2B8"], 0, 0, 0, 1), INK, 1.8)
        circle(s, 80, 55, 15, s.rgrad([light, mid, dark], 0.35, 0.3, 0.9), INK, 2.6)
        circle(s, 80, 55, 7, s.rgrad(["#E8F8FF", "#9FD8F5"], 0.4, 0.35, 0.8), INK, 1.6)
        shine(s, 40, 40, 26, 4, 0, 0.5)
    elif design == "odun":
        rect(s, 8, 14, 144, 82, 10, s.lgrad([mid, dark]), INK, 3)
        for y in (32, 55, 78):
            rect(s, 14, y - 11, 132, 22, 11, s.lgrad(["#E6A873", "#B7773F", "#8A5226"]), INK, 2.2)
            circle(s, 136, y, 9, s.rgrad(["#F7D2A0", "#D9A56A"], 0.5, 0.5, 0.7), "#8A5226", 1.6)
            circle(s, 136, y, 4, "none", "#B7773F", 1.2)
        for x in (10, 146):
            rect(s, x - 3, 16, 6, 78, 3, light, INK, 1.8)
    elif design == "cicek":
        rect(s, 8, 14, 144, 82, 16, body, INK, 3)
        rect(s, 18, 24, 124, 62, 10, s.lgrad(["#8BC96A", "#5E9E48"]), INK, 2)
        rng = random.Random("cicek" + color)
        for x, y in ((34, 40), (62, 66), (88, 38), (116, 64), (40, 72), (118, 36), (80, 56)):
            c = rng.choice(["#FF7FA8", "#FFE066", "#FFFFFF", "#B98AFF", "#FF9A5A"])
            for k in range(5):
                a = math.radians(k * 72 + rng.randint(0, 60))
                circle(s, x + 6 * math.cos(a), y + 6 * math.sin(a), 5, c, INK, 1.2)
            circle(s, x, y, 3.6, "#FFB020", INK, 1.2)
    if design not in ("tanker",):
        shine(s, 40, 26, 26, 4, 0, 0.4)
    write(f"vagon_{design}_{color}.svg", s.text())


# --- Efektler ve düğmeler ---------------------------------------------------------------------------------

def effects():
    s = Svg(96, 96)
    circle(s, 48, 48, 40, s.rgrad(["#FFFFFF", "#EEEAF6", "#C4BDD8"], 0.38, 0.32, 0.8), "#B3ABCB", 2.5)
    circle(s, 36, 40, 20, "#FFFFFF", extra='opacity="0.7"')
    write("duman.svg", s.text())
    s = Svg(96, 96)
    circle(s, 48, 48, 32, "none", "#FFFFFF", 14)
    circle(s, 48, 48, 32, "none", "#FFFFFF", 5, 'stroke-opacity="0.9"')
    write("halka.svg", s.text())
    s = Svg(64, 64)
    poly(s, star_pts(32, 32, 30, 8, 4, -90), s.rgrad(["#FFFFFF", "#FFF6B0", "#FFD35A"], 0.5, 0.5, 0.6))
    write("parilti.svg", s.text())
    s = Svg(96, 96)
    poly(s, star_pts(48, 50, 42, 18), s.rgrad(["#FFF6B0", "#FFD35A", "#F5A800"], 0.4, 0.35, 0.8), INK, 4)
    shine(s, 38, 36, 9, 5, -35, 0.7)
    write("yildiz.svg", s.text())
    s = Svg(24, 14)
    rect(s, 0, 0, 24, 14, 3, "#FFFFFF")
    write("konfeti.svg", s.text())
    s = Svg(128, 128)
    circle(s, 64, 64, 60, s.rgrad(["#FFFFFF", "#FFFFFF"], 0.5, 0.5, 0.5, opacities=[1, 0]))
    write("isik.svg", s.text())
    # "?" balonu
    s = Svg(120, 120)
    shadow(s, 62, 104, 34, 8)
    ellipse(s, 60, 52, 48, 42, s.rgrad(["#FFFFFF", "#F4F0FF"], 0.4, 0.35, 0.8), INK, 4)
    poly(s, [(44, 84), (40, 104), (62, 90)], "#FFFFFF", INK, 4)
    s.add('<rect x="42" y="80" width="26" height="8" fill="#FFFFFF"/>')
    s.add('<path d="M47 40 C47 26 73 26 73 40 C73 50 60 50 60 60 L60 64" fill="none" stroke="#8A6CF0" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>')
    circle(s, 60, 76, 5.5, "#8A6CF0")
    write("soru.svg", s.text())


def buttons():
    # Hareket: yeşil daire, beyaz yan görünüşlü tren simgesi
    s = Svg(160, 160)
    shadow(s, 80, 148, 60, 9, 0.3)
    circle(s, 80, 76, 68, s.rgrad(["#B6F5A0", "#4FC45F", "#2A8A3E"], 0.38, 0.3, 0.85), INK, 5)
    circle(s, 80, 76, 58, "none", "#FFFFFF", 3, 'stroke-opacity="0.35"')
    w = "#FFFFFF"
    rect(s, 38, 64, 58, 30, 8, w, INK, 3)          # kazan
    rect(s, 84, 46, 34, 48, 6, w, INK, 3)          # kabin
    rect(s, 90, 52, 22, 16, 3, "#8FE0A0", INK, 2.4)  # kabin penceresi
    rect(s, 48, 46, 12, 20, 3, w, INK, 3)          # baca
    for x in (52, 76, 104):
        circle(s, x, 100, 10, w, INK, 3)
    poly(s, [(38, 88), (26, 100), (40, 100)], w, INK, 3)
    circle(s, 44, 34, 7, "#FFFFFF", extra='opacity="0.8"')
    circle(s, 34, 24, 5, "#FFFFFF", extra='opacity="0.6"')
    shine(s, 52, 36, 18, 8, -30, 0.35)
    write("hareket.svg", s.text())
    # Baştan başlat: dönen ok
    s = Svg(96, 96)
    pts = arc_pts(48, 48, 24, -60, 220, 30)
    s.add(f'<polyline points="{_pl(pts)}" fill="none" stroke="{INK}" stroke-width="17" stroke-linecap="round"/>')
    s.add(f'<polyline points="{_pl(pts)}" fill="none" stroke="#8A6CF0" stroke-width="9" stroke-linecap="round"/>')
    # ok ucu: yayın başında, yayın tersine (saat yönünün tersi) bakar
    a0 = math.radians(-60)
    ex, ey = pts[0]
    tx, ty = math.sin(a0), -math.cos(a0)
    nx, ny = math.cos(a0), math.sin(a0)
    poly(s, [(ex + tx * 16, ey + ty * 16), (ex + nx * 14 - tx * 4, ey + ny * 14 - ty * 4), (ex - nx * 14 - tx * 4, ey - ny * 14 - ty * 4)], "#8A6CF0", INK, 4)
    write("yeniden.svg", s.text())
    # Oynat
    s = Svg(200, 200)
    shadow(s, 100, 186, 72, 10, 0.3)
    circle(s, 100, 94, 84, s.rgrad(["#B6F5A0", "#4FC45F", "#2A8A3E"], 0.38, 0.3, 0.85), INK, 6)
    circle(s, 100, 94, 72, "none", "#FFFFFF", 4, 'stroke-opacity="0.35"')
    poly(s, [(80, 56), (140, 94), (80, 132)], "#FFFFFF", INK, 5)
    shine(s, 66, 50, 22, 10, -30, 0.4)
    write("oynat.svg", s.text())


if __name__ == "__main__":
    pieces()
    bolt()
    for theme in THEMES:
        tile(theme)
    obstacles()
    platform()
    station()
    locomotive()
    for design in WAGON_DESIGNS:
        for color in WAGON_COLORS:
            wagon(design, color)
    effects()
    buttons()
    print("tamam")
