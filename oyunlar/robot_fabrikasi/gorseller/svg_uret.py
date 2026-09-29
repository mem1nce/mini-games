# Robot FabrikasÄ± SVG Ã¼reticisi (sadece Python standart kÃ¼tÃ¼phanesi).
# Ã‡alÄ±ÅŸtÄ±rma: python svg_uret.py   (bu klasÃ¶re ve parcalar/ alt klasÃ¶rÃ¼ne yazar)
# Tarz hafÄ±za oyunuyla uyumlu: yumuÅŸak gradyanlar, parlama noktalarÄ±, yumuÅŸak koyu dÄ±ÅŸ Ã§izgi.
# ParÃ§alar 160x160 tuvalde ortalÄ±. Her rengin renk kÃ¶rlÃ¼ÄŸÃ¼ iÃ§in bir deseni var (nokta, Ã§izgi, zikzak, dama).
# Not: Godot'nun SVG Ã§izicisi, iki kontrol noktasÄ± aynÄ± yÃ¼kseklikte olan kÃ¼bik eÄŸrinin degrade dolgusunu Ã§izmiyor;
# bu yÃ¼zden ÅŸekiller daire, dikdÃ¶rtgen, Ã§okgen ve yaylarla Ã§izilir.

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# renk: (aÃ§Ä±k, orta, koyu, dÄ±ÅŸ Ã§izgi)
COLORS = {
    "kirmizi": ("#FFA3A3", "#F2454F", "#C0263A", "#6E1422"),
    "mavi": ("#A6D4FF", "#3E8EEB", "#1E5DB5", "#10305E"),
    "sari": ("#FFF3A6", "#FFD02E", "#E0A000", "#6E4E00"),
    "yesil": ("#AEF2B4", "#3CC66A", "#1F8E48", "#0E4A26"),
}
PATTERNS = {"kirmizi": "nokta", "mavi": "cizgi", "sari": "zikzak", "yesil": "dama"}
SHAPES = ["daire", "kare", "ucgen", "yildiz"]
METAL = ("#FFFFFF", "#D8D6E6", "#9E9AB8", "#4A4466")
INK = "#3A3456"


class Svg:
    def __init__(self, w: int = 160, h: int = 160):
        self.w, self.h = w, h
        self.defs: list = []
        self.body: list = []
        self.n = 0

    def _id(self) -> str:
        self.n += 1
        return f"g{self.n}"

    def rgrad(self, colors, cx=0.4, cy=0.32, r=0.75) -> str:
        gid = self._id()
        stops = "".join(f'<stop offset="{i / max(1, len(colors) - 1):.2f}" stop-color="{c}"/>' for i, c in enumerate(colors))
        self.defs.append(f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}">{stops}</radialGradient>')
        return f"url(#{gid})"

    def lgrad(self, colors, x1=0.0, y1=0.0, x2=0.0, y2=1.0) -> str:
        gid = self._id()
        stops = "".join(f'<stop offset="{i / max(1, len(colors) - 1):.2f}" stop-color="{c}"/>' for i, c in enumerate(colors))
        self.defs.append(f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{stops}</linearGradient>')
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


def circle(s, cx, cy, r, fill, out=None, sw=5, extra=""):
    stroke = f' stroke="{out}" stroke-width="{sw}"' if out else ""
    s.add(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{fill}"{stroke} {extra}/>')


def shine(s, cx, cy, rx, ry, angle=-30, opacity=0.55):
    s.add(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" transform="rotate({angle} {cx:.1f} {cy:.1f})" fill="#FFFFFF" opacity="{opacity}"/>')


def star_path(cx, cy, ro, ri, n=5, rot=-90.0) -> str:
    pts = []
    for k in range(n * 2):
        r = ro if k % 2 == 0 else ri
        a = math.radians(rot + k * 180.0 / n)
        pts.append(f"{cx + r * math.cos(a):.1f} {cy + r * math.sin(a):.1f}")
    return "M " + " L ".join(pts) + " Z"


def poly(points) -> str:
    return "M " + " L ".join(f"{x:.1f} {y:.1f}" for x, y in points) + " Z"


def sparkle(s, cx, cy, r, color="#FFFFFF", opacity=0.95):
    d = (f"M {cx} {cy - r} L {cx + r * 0.2} {cy - r * 0.2} L {cx + r} {cy} L {cx + r * 0.2} {cy + r * 0.2} "
         f"L {cx} {cy + r} L {cx - r * 0.2} {cy + r * 0.2} L {cx - r} {cy} L {cx - r * 0.2} {cy - r * 0.2} Z")
    s.add(f'<path d="{d}" fill="{color}" opacity="{opacity}" stroke="{color}" stroke-width="2" stroke-linejoin="round"/>')


def rounded_shape(s, d, fill, out, sw=6, round_px=12):
    # KÃ¶ÅŸeleri yuvarlatÄ±lmÄ±ÅŸ Ã§okgen: Ã¶nce kalÄ±n dÄ±ÅŸ Ã§izgi, sonra aynÄ± dolguyla kalÄ±n kenar (kÃ¶ÅŸeler yuvarlanÄ±r)
    s.add(f'<path d="{d}" fill="{out}" stroke="{out}" stroke-width="{round_px + sw * 2}" stroke-linejoin="round"/>')
    s.add(f'<path d="{d}" fill="{fill}" stroke="{fill}" stroke-width="{round_px}" stroke-linejoin="round"/>')


# Åeklin yolu (merkez cx, cy; yarÄ±Ã§ap r); kÃ¶ÅŸeler rounded_shape ile yuvarlanÄ±r
def shape_d(shape, cx, cy, r) -> str:
    if shape == "daire":
        return f"M {cx - r} {cy} A {r} {r} 0 1 0 {cx + r} {cy} A {r} {r} 0 1 0 {cx - r} {cy} Z"
    if shape == "kare":
        k = r * 0.86
        return poly([(cx - k, cy - k), (cx + k, cy - k), (cx + k, cy + k), (cx - k, cy + k)])
    if shape == "ucgen":
        return poly([(cx, cy - r * 1.02), (cx + r * 1.0, cy + r * 0.78), (cx - r * 1.0, cy + r * 0.78)])
    return star_path(cx, cy + r * 0.06, r * 1.08, r * 0.52)


def pattern(s, color, clip_d, box=(0, 0, 160, 160), scale=1.0):
    # Rengin deseni: ÅŸeklin iÃ§ine kÄ±rpÄ±lmÄ±ÅŸ, koyu tonda yarÄ± saydam
    c = COLORS[color][2]
    kind = PATTERNS[color]
    x0, y0, x1, y1 = box
    clip = s.clip(f'<path d="{clip_d}"/>')
    items = ""
    g = 22 * scale
    if kind == "nokta":
        y = y0
        row = 0
        while y < y1 + g:
            x = x0 + (g / 2 if row % 2 else 0)
            while x < x1 + g:
                items += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{4.6 * scale:.1f}"/>'
                x += g
            y += g * 0.86
            row += 1
    elif kind == "cizgi":
        k = x0 - (y1 - y0)
        while k < x1 + 20:
            w = 3.5 * scale   # kırpmada ince çizgi kaybolabildiği için dolgulu şerit
            items += f'<path d="M {k - w:.1f} {y1:.1f} L {k + w:.1f} {y1:.1f} L {k + (y1 - y0) + w:.1f} {y0:.1f} L {k + (y1 - y0) - w:.1f} {y0:.1f} Z"/>'
            k += 20 * scale
    elif kind == "zikzak":
        y = y0 + 8
        while y < y1 + 10:
            pts = []
            x = x0 - 10
            up = True
            while x < x1 + 20:
                pts.append(f"{x:.1f} {y - (6 * scale if up else -6 * scale):.1f}")
                x += 11 * scale
                up = not up
            items += f'<path d="M {" L ".join(pts)}" fill="none" stroke="{c}" stroke-width="{4.5 * scale:.1f}" stroke-linejoin="round"/>'
            y += 24 * scale
    else:  # dama
        g2 = 14 * scale
        y = y0
        row = 0
        while y < y1:
            x = x0 + (g2 if row % 2 else 0)
            while x < x1:
                items += f'<rect x="{x:.1f}" y="{y:.1f}" width="{g2:.1f}" height="{g2:.1f}"/>'
                x += g2 * 2
            y += g2
            row += 1
    s.add(f'<g clip-path="{clip}" fill="{c}" opacity="0.48">{items}</g>')


def bolt(s, x, y, r=4.5):
    circle(s, x, y, r, "#E8E6F2", "#6A6488", 2)
    s.add(f'<path d="M {x - r * 0.5:.1f} {y:.1f} L {x + r * 0.5:.1f} {y:.1f}" stroke="#6A6488" stroke-width="1.6"/>')


# --- ParÃ§alar ---

def govde(shape, color) -> str:
    s = Svg()
    l, m, d, out = COLORS[color]
    fill = s.rgrad([l, m, d], 0.38, 0.3, 0.85)
    r = 54
    sd = shape_d(shape, 80, 82, r)
    rounded_shape(s, sd, fill, out, 6, 12 if shape != "daire" else 0.1)
    pattern(s, color, sd)
    # GÃ¶ÄŸÃ¼s paneli: 3 kÃ¼Ã§Ã¼k lamba
    s.add(f'<rect x="56" y="{76 if shape != "ucgen" else 90}" width="48" height="24" rx="9" fill="#FFFFFF" opacity="0.85" stroke="{out}" stroke-width="3"/>')
    yy = 88 if shape != "ucgen" else 102
    for k, lamp in enumerate(["#FF8FA0", "#FFE27A", "#8EF0C8"]):
        circle(s, 67 + k * 13, yy, 4.2, lamp, out, 1.6)
    if shape == "kare":
        for (x, y) in [(40, 42), (120, 42), (40, 122), (120, 122)]:
            bolt(s, x, y)
    shine(s, 58, 50, 13, 7, -30, 0.55)
    return s.text()


def kafa(shape, color) -> str:
    s = Svg()
    l, m, d, out = COLORS[color]
    fill = s.rgrad([l, m, d], 0.38, 0.3, 0.85)
    # Kulaklar (metal)
    for side in (-1, 1):
        s.add(f'<rect x="{80 + side * 58 - 9}" y="70" width="18" height="30" rx="7" fill="#D8D6E6" stroke="{INK}" stroke-width="4"/>')
    r = 50
    cy = 86
    sd = shape_d(shape, 80, cy, r)
    rounded_shape(s, sd, fill, out, 6, 12 if shape != "daire" else 0.1)
    pattern(s, color, sd)
    # YÃ¼z ekranÄ± (gÃ¶zler kapalÄ±: soluk; oyunda yanar)
    if shape == "ucgen":
        vx, vy, vw, vh = 52, 88, 56, 30
    elif shape == "yildiz":
        vx, vy, vw, vh = 56, 76, 48, 28
    else:
        vx, vy, vw, vh = 44, 70, 72, 38
    screen = s.lgrad(["#3A4068", "#1E2240"])
    s.add(f'<rect x="{vx}" y="{vy}" width="{vw}" height="{vh}" rx="{vh * 0.45:.1f}" fill="{screen}" stroke="{out}" stroke-width="4"/>')
    for side in (-1, 1):
        circle(s, 80 + side * vw * 0.22, vy + vh * 0.5, vh * 0.2, "#5A6A9A")
    shine(s, vx + 10, vy + 7, 6, 3, -10, 0.35)
    shine(s, 60, cy - 30, 12, 6, -30, 0.5)
    return s.text()


def kol(color) -> str:
    s = Svg()
    l, m, d, out = COLORS[color]
    tube = s.lgrad([l, m, d], 0, 0, 1, 0)
    circle(s, 80, 28, 18, s.rgrad(list(METAL[:3])), METAL[3], 5)
    s.add(f'<rect x="64" y="34" width="32" height="76" rx="15" fill="{tube}" stroke="{out}" stroke-width="5"/>')
    pattern(s, color, "M 64 34 L 96 34 L 96 110 L 64 110 Z")
    s.add(f'<rect x="60" y="68" width="40" height="10" rx="5" fill="#D8D6E6" stroke="{INK}" stroke-width="3"/>')
    # KÄ±skaÃ§ el
    claw = s.rgrad(list(METAL[:3]))
    s.add(f'<path d="M 80 108 C 56 110 48 128 54 146 L 66 142 C 62 132 68 124 80 122 C 92 124 98 132 94 142 L 106 146 C 112 128 104 110 80 108 Z" fill="{claw}" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>')
    shine(s, 72, 50, 4, 12, 0, 0.5)
    return s.text()


def tekerlek(color) -> str:
    s = Svg()
    l, m, d, out = COLORS[color]
    tire = s.rgrad(["#6A6480", "#3A3450", "#24202F"], 0.42, 0.38, 0.75)
    circle(s, 80, 80, 62, tire, "#1A1624", 6)
    for k in range(12):
        a = math.radians(k * 30)
        s.add(f'<path d="M {80 + 54 * math.cos(a):.1f} {80 + 54 * math.sin(a):.1f} L {80 + 64 * math.cos(a):.1f} {80 + 64 * math.sin(a):.1f}" stroke="#1A1624" stroke-width="5" stroke-linecap="round"/>')
    hub = s.rgrad([l, m, d], 0.38, 0.32, 0.8)
    hd = "M 44 80 A 36 36 0 1 0 116 80 A 36 36 0 1 0 44 80 Z"
    s.add(f'<path d="{hd}" fill="{hub}" stroke="{out}" stroke-width="5"/>')
    pattern(s, color, hd)
    for k in range(5):
        a = math.radians(-90 + k * 72)
        circle(s, 80 + 20 * math.cos(a), 80 + 20 * math.sin(a), 5, "#FFFFFF", out, 2, 'opacity="0.9"')
    circle(s, 80, 80, 8, "#E8E6F2", INK, 3)
    shine(s, 60, 60, 9, 5, -30, 0.5)
    return s.text()


def anten(color) -> str:
    s = Svg()
    l, m, d, out = COLORS[color]
    s.add(f'<rect x="54" y="126" width="52" height="22" rx="9" fill="#D8D6E6" stroke="{INK}" stroke-width="4.5"/>')
    s.add('<path d="M 80 126 C 70 118 90 110 80 102 C 70 94 90 86 80 78 C 70 70 90 62 80 56" fill="none" stroke="#4A4466" stroke-width="10" stroke-linecap="round"/>')
    s.add('<path d="M 80 126 C 70 118 90 110 80 102 C 70 94 90 86 80 78 C 70 70 90 62 80 56" fill="none" stroke="#C8C4DC" stroke-width="5" stroke-linecap="round"/>')
    ball = s.rgrad([l, m, d], 0.38, 0.3, 0.8)
    bd = "M 52 36 A 28 28 0 1 0 108 36 A 28 28 0 1 0 52 36 Z"
    s.add(f'<path d="{bd}" fill="{ball}" stroke="{out}" stroke-width="5"/>')
    pattern(s, color, bd)
    shine(s, 70, 26, 8, 5, -30, 0.7)
    return s.text()


def gear_d(cx, cy, r, teeth=8, depth=14, width=0.42) -> str:
    pts = []
    step = 2 * math.pi / teeth
    for k in range(teeth):
        a = k * step
        for (da, rr) in [(-step * width * 0.62, r), (-step * width * 0.42, r + depth), (step * width * 0.42, r + depth), (step * width * 0.62, r)]:
            pts.append((cx + rr * math.cos(a + da), cy + rr * math.sin(a + da)))
    return poly(pts)


def disli(color) -> str:
    s = Svg()
    l, m, d, out = COLORS[color]
    fill = s.rgrad([l, m, d], 0.38, 0.3, 0.85)
    gd = gear_d(80, 80, 50, 8, 16)
    rounded_shape(s, gd, fill, out, 5.5, 6)
    pattern(s, color, gd)
    circle(s, 80, 80, 22, "#F4F2FA", out, 5)
    circle(s, 80, 80, 9, "#6A6488")
    shine(s, 60, 54, 10, 5, -30, 0.5)
    return s.text()


def make_parts() -> None:
    for c in COLORS:
        for sh in SHAPES:
            write(f"parcalar/govde_{sh}_{c}.svg", govde(sh, c))
            write(f"parcalar/kafa_{sh}_{c}.svg", kafa(sh, c))
        write(f"parcalar/kol_{c}.svg", kol(c))
        write(f"parcalar/tekerlek_{c}.svg", tekerlek(c))
        write(f"parcalar/anten_{c}.svg", anten(c))
        write(f"parcalar/disli_{c}.svg", disli(c))


# --- Tabela simgeleri ---

def make_icons() -> None:
    for c in COLORS:
        l, m, d, out = COLORS[c]
        s = Svg(120, 120)
        fill = s.rgrad([l, m, d], 0.38, 0.3, 0.85)
        blob = "M 60 12 C 84 10 108 28 108 56 C 110 84 90 108 62 108 C 32 110 12 90 12 62 C 10 34 34 14 60 12 Z"
        s.add(f'<path d="{blob}" fill="{fill}" stroke="{out}" stroke-width="6"/>')
        pattern(s, c, blob, (0, 0, 120, 120), 1.1)
        shine(s, 42, 36, 11, 6, -30, 0.6)
        write(f"simge_renk_{c}.svg", s.text())
        for sh in SHAPES:
            s = Svg(120, 120)
            fill = s.rgrad([l, m, d], 0.38, 0.3, 0.85)
            sd = shape_d(sh, 60, 62, 40)
            rounded_shape(s, sd, fill, out, 5, 10 if sh != "daire" else 0.1)
            pattern(s, c, sd, (0, 0, 120, 120), 0.9)
            shine(s, 46, 44, 9, 5, -30, 0.55)
            write(f"simge_{sh}_{c}.svg", s.text())
    for sh in SHAPES:
        s = Svg(120, 120)
        fill = s.rgrad(["#8A84AE", "#5E5884", "#454066"], 0.38, 0.3, 0.85)
        rounded_shape(s, shape_d(sh, 60, 62, 40), fill, "#2A2440", 5, 10 if sh != "daire" else 0.1)
        shine(s, 46, 44, 9, 5, -30, 0.4)
        write(f"simge_{sh}.svg", s.text())


# --- Robot uzuvlarÄ± (ÅŸablonlara gÃ¶re) ---

def make_robot_bits() -> None:
    metal = lambda s: s.lgrad(list(METAL[:3]), 0, 0, 1, 0)
    # YaylÄ± bacak
    s = Svg(80, 150)
    for k in range(6):
        y = 18 + k * 17
        s.add(f'<ellipse cx="40" cy="{y}" rx="24" ry="8" fill="none" stroke="{METAL[3]}" stroke-width="9"/>')
        s.add(f'<ellipse cx="40" cy="{y}" rx="24" ry="8" fill="none" stroke="#D8D6E6" stroke-width="4"/>')
    s.add(f'<rect x="10" y="120" width="60" height="24" rx="11" fill="{metal(s)}" stroke="{INK}" stroke-width="5"/>')
    write("yay.svg", s.text())
    # Ä°nce bacak (Ã¶rÃ¼mcek)
    s = Svg(70, 150)
    s.add(f'<path d="M 35 8 L 35 120" stroke="{INK}" stroke-width="16" stroke-linecap="round"/>')
    s.add('<path d="M 35 8 L 35 120" stroke="#C8C4DC" stroke-width="8" stroke-linecap="round"/>')
    circle(s, 35, 64, 10, "#E8E6F2", INK, 4)
    s.add(f'<ellipse cx="35" cy="130" rx="26" ry="13" fill="{metal(s)}" stroke="{INK}" stroke-width="5"/>')
    write("bacak.svg", s.text())
    # Palet
    s = Svg(240, 100)
    s.add(f'<rect x="10" y="14" width="220" height="74" rx="37" fill="#3A3450" stroke="#1A1624" stroke-width="6"/>')
    for k in range(10):
        x = 30 + k * 20
        s.add(f'<rect x="{x}" y="12" width="9" height="9" rx="2" fill="#6A6480"/><rect x="{x}" y="81" width="9" height="9" rx="2" fill="#6A6480"/>')
    for x in (52, 120, 188):
        circle(s, x, 51, 24, s.rgrad(list(METAL[:3])), INK, 4.5)
        circle(s, x, 51, 7, "#6A6488")
    write("palet.svg", s.text())
    # Jet alevi
    s = Svg(80, 120)
    flame = s.lgrad(["#FFF6C0", "#FFB43A", "#FF5E3A"])
    s.add(f'<path d="M 40 112 C 14 88 16 50 26 28 L 40 6 L 54 28 C 64 50 66 88 40 112 Z" fill="{flame}" stroke="#E0502A" stroke-width="4" transform="rotate(180 40 60)"/>')
    s.add('<path d="M 40 100 C 30 86 30 64 40 44 C 50 64 50 86 40 100 Z" fill="#FFFBE0" opacity="0.9" transform="rotate(180 40 72)"/>')
    write("alev.svg", s.text())
    # Pogo sopasÄ±
    s = Svg(80, 170)
    s.add(f'<rect x="12" y="6" width="56" height="16" rx="8" fill="{metal(s)}" stroke="{INK}" stroke-width="4.5"/>')
    s.add(f'<path d="M 40 22 L 40 150" stroke="{INK}" stroke-width="14" stroke-linecap="round"/>')
    s.add('<path d="M 40 22 L 40 150" stroke="#C8C4DC" stroke-width="7" stroke-linecap="round"/>')
    for k in range(4):
        y = 70 + k * 16
        s.add(f'<ellipse cx="40" cy="{y}" rx="20" ry="7" fill="none" stroke="{METAL[3]}" stroke-width="8"/><ellipse cx="40" cy="{y}" rx="20" ry="7" fill="none" stroke="#E8E6F2" stroke-width="3"/>')
    circle(s, 40, 156, 10, "#3A3450", "#1A1624", 4)
    write("pogo.svg", s.text())
    # Ahtapot kolu (dokunaÃ§)
    s = Svg(70, 150)
    t = "M 35 6 C 58 36 12 62 34 90 C 48 108 30 128 46 142"
    s.add(f'<path d="{t}" fill="none" stroke="#5E3A8E" stroke-width="24" stroke-linecap="round"/>')
    s.add(f'<path d="{t}" fill="none" stroke="#B48CF0" stroke-width="15" stroke-linecap="round"/>')
    for (x, y) in [(40, 30), (30, 62), (38, 96), (40, 124)]:
        circle(s, x, y, 4, "#F0E0FF")
    write("dokunac.svg", s.text())
    # Pervane
    s = Svg(220, 80)
    s.add(f'<rect x="102" y="40" width="16" height="36" rx="6" fill="{metal(s)}" stroke="{INK}" stroke-width="4"/>')
    blade = s.rgrad(["#FFFFFF", "#DCEBFF", "#A6C4F0"], 0.4, 0.4, 0.8)
    for side in (-1, 1):
        s.add(f'<ellipse cx="{110 + side * 52}" cy="34" rx="50" ry="13" fill="{blade}" stroke="{INK}" stroke-width="4.5"/>')
    circle(s, 110, 34, 13, "#FF8F5A", "#8E3A1A", 4)
    write("pervane.svg", s.text())
    # Akordeon boyun
    s = Svg(80, 120)
    for k in range(5):
        y = 10 + k * 22
        s.add(f'<rect x="{14 + (k % 2) * 4}" y="{y}" width="{52 - (k % 2) * 8}" height="22" rx="10" fill="{metal(s)}" stroke="{INK}" stroke-width="4.5"/>')
    write("boyun.svg", s.text())
    # Kanat (sol)
    s = Svg(150, 110)
    wing = s.lgrad(["#FFFFFF", "#DCEBFF", "#9EC2F0"], 0, 0, 1, 1)
    s.add(f'<path d="M 140 30 L 30 8 C 10 6 6 30 22 40 L 40 50 C 18 56 16 76 34 80 L 60 84 C 44 94 52 108 70 104 L 140 80 Z" fill="{wing}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')
    s.add('<path d="M 130 38 L 44 26 M 130 58 L 52 62 M 130 74 L 80 90" stroke="#9EC2F0" stroke-width="3" stroke-linecap="round"/>')
    write("kanat.svg", s.text())
    # Roket kanatÃ§Ä±ÄŸÄ±
    s = Svg(80, 90)
    fin = s.lgrad(["#FF9A7A", "#E0503A"])
    s.add(f'<path d="M 70 10 L 70 70 L 10 84 C 8 60 30 30 70 10 Z" fill="{fin}" stroke="#7A1E12" stroke-width="5" stroke-linejoin="round"/>')
    write("kanatcik.svg", s.text())


# --- YardÄ±mcÄ± robot ---

def make_helper() -> None:
    s = Svg(200, 240)
    # Tek teker
    tire = s.rgrad(["#6A6480", "#3A3450"], 0.42, 0.38, 0.75)
    circle(s, 100, 214, 22, tire, "#1A1624", 5)
    circle(s, 100, 214, 8, "#E8E6F2", INK, 3)
    # GÃ¶vde (turuncu, yuvarlak karÄ±n)
    body = s.rgrad(["#FFD7A0", "#FF9E45", "#E0721E"], 0.4, 0.3, 0.85)
    s.add(f'<path d="M 58 158 A 42 42 0 1 0 142 158 A 42 42 0 1 0 58 158 Z" fill="{body}" stroke="#7A3A0E" stroke-width="6"/>')
    circle(s, 100, 162, 18, "#FFF3DC", "#7A3A0E", 4)
    s.add('<path d="M 92 162 L 108 162 M 100 154 L 100 170" stroke="#FF9E45" stroke-width="4" stroke-linecap="round"/>')
    shine(s, 80, 134, 10, 6, -30, 0.5)
    # Boyun
    s.add(f'<rect x="88" y="106" width="24" height="16" rx="6" fill="#D8D6E6" stroke="{INK}" stroke-width="4"/>')
    # BaÅŸ: krem, yuvarlak kÃ¶ÅŸeli televizyon gibi; ekran boÅŸ (yÃ¼z oyunda Ã§izilir)
    head = s.lgrad(["#FFFBF0", "#FFF0D6", "#F2D8B0"])
    s.add(f'<rect x="36" y="26" width="128" height="88" rx="30" fill="{head}" stroke="#7A3A0E" stroke-width="6"/>')
    screen = s.lgrad(["#34406E", "#1C2244"])
    s.add(f'<rect x="52" y="40" width="96" height="60" rx="22" fill="{screen}" stroke="#7A3A0E" stroke-width="4"/>')
    shine(s, 66, 48, 12, 4, -10, 0.3)
    for side in (-1, 1):
        s.add(f'<rect x="{100 + side * 72 - 8}" y="56" width="16" height="30" rx="7" fill="#FF9E45" stroke="#7A3A0E" stroke-width="4"/>')
    # Anten (ampul ayrÄ± sprite)
    s.add('<path d="M 100 26 L 100 8" stroke="#4A4466" stroke-width="5" stroke-linecap="round"/>')
    write("yardimci.svg", s.text())
    # Kol ve eller (omuzdan aÅŸaÄŸÄ± sarkan; Ã¼st uÃ§ dÃ¶ner)
    s = Svg(60, 110)
    s.add('<rect x="20" y="4" width="20" height="72" rx="10" fill="#FFB86A" stroke="#7A3A0E" stroke-width="4.5"/>')
    circle(s, 30, 88, 17, "#FFF3DC", "#7A3A0E", 4.5)
    write("yardimci_kol.svg", s.text())
    s = Svg(60, 110)
    s.add('<rect x="20" y="4" width="20" height="72" rx="10" fill="#FFB86A" stroke="#7A3A0E" stroke-width="4.5"/>')
    circle(s, 30, 88, 17, "#FFF3DC", "#7A3A0E", 4.5)
    s.add('<rect x="38" y="66" width="12" height="26" rx="6" fill="#FFF3DC" stroke="#7A3A0E" stroke-width="4" transform="rotate(20 44 79)"/>')
    write("yardimci_basparmak.svg", s.text())


# --- AtÃ¶lye, bant, kutular, kol, arayÃ¼z ---

def make_factory() -> None:
    # Dekor diÅŸlisi (nÃ¶tr, oyunda renklenir)
    s = Svg(200, 200)
    fill = s.rgrad(["#FFFFFF", "#E6E2F0", "#BDB6D2"], 0.38, 0.3, 0.85)
    rounded_shape(s, gear_d(100, 100, 66, 10, 20), fill, "#7A7298", 6, 6)
    circle(s, 100, 100, 28, "#F8F6FC", "#7A7298", 6)
    for k in range(6):
        a = math.radians(k * 60)
        circle(s, 100 + 46 * math.cos(a), 100 + 46 * math.sin(a), 8, "#D6D0E6", "#7A7298", 3)
    circle(s, 100, 100, 10, "#9A92B8")
    write("dekor_disli.svg", s.text())
    # Duvar lambasÄ±
    s = Svg(90, 110)
    s.add(f'<rect x="30" y="4" width="30" height="16" rx="5" fill="#C8A070" stroke="#6E4418" stroke-width="4"/>')
    bulb = s.rgrad(["#FFFFFF", "#FFF0B0", "#FFD060"], 0.45, 0.4, 0.7)
    circle(s, 45, 58, 30, bulb, "#8A6420", 5)
    for x in (30, 45, 60):
        s.add(f'<path d="M {x} 22 L {x} 90" stroke="#8A6420" stroke-width="3.5" opacity="0.7"/>')
    s.add('<path d="M 18 58 L 72 58" stroke="#8A6420" stroke-width="3.5" opacity="0.7"/>')
    shine(s, 36, 46, 7, 5, -30, 0.8)
    write("lamba.svg", s.text())
    # Boru (yatay, dÃ¶ÅŸenebilir) ve boru aÄŸÄ±zlarÄ±
    s = Svg(200, 48)
    pipe = s.lgrad(["#F8C890", "#D88A4A", "#A45A2A"])
    s.add(f'<rect x="-4" y="6" width="208" height="36" fill="{pipe}" stroke="#6E3A18" stroke-width="5"/>')
    s.add('<rect x="-4" y="12" width="208" height="7" fill="#FFFFFF" opacity="0.3"/>')
    s.add(f'<rect x="84" y="0" width="32" height="48" rx="6" fill="{pipe}" stroke="#6E3A18" stroke-width="5"/>')
    write("boru.svg", s.text())
    s = Svg(150, 170)
    pipe = s.lgrad(["#A45A2A", "#F8C890", "#D88A4A", "#A45A2A"], 0, 0, 1, 0)
    s.add(f'<rect x="35" y="-6" width="80" height="120" fill="{pipe}" stroke="#6E3A18" stroke-width="6"/>')
    s.add(f'<rect x="20" y="104" width="110" height="46" rx="16" fill="{pipe}" stroke="#6E3A18" stroke-width="6"/>')
    s.add('<ellipse cx="75" cy="144" rx="44" ry="10" fill="#3A2A20"/>')
    s.add('<rect x="46" y="-6" width="12" height="110" fill="#FFFFFF" opacity="0.3"/>')
    write("boru_agiz.svg", s.text())
    # Kutu: arka (iÃ§i), Ã¶n, kapak
    s = Svg(200, 170)
    s.add('<path d="M 14 20 L 186 20 L 176 160 L 24 160 Z" fill="#6E4A2A" stroke="#4A2E18" stroke-width="5" stroke-linejoin="round"/>')
    s.add('<path d="M 20 26 L 180 26 L 178 40 L 22 40 Z" fill="#4A2E18" opacity="0.5"/>')
    write("kutu_arka.svg", s.text())
    s = Svg(200, 170)
    wood = s.lgrad(["#F2C286", "#D89A5A", "#B87A40"])
    s.add(f'<path d="M 10 52 L 190 52 L 180 162 C 180 166 176 168 172 168 L 28 168 C 24 168 20 166 20 162 Z" fill="{wood}" stroke="#6E4418" stroke-width="6" stroke-linejoin="round"/>')
    for y in (86, 120, 150):
        s.add(f'<path d="M {14 + (y - 52) * 0.08:.1f} {y} L {186 - (y - 52) * 0.08:.1f} {y}" stroke="#8A5A28" stroke-width="3" opacity="0.5"/>')
    s.add('<rect x="6" y="46" width="188" height="16" rx="8" fill="#E8B06A" stroke="#6E4418" stroke-width="5"/>')
    for x in (30, 170):
        s.add(f'<rect x="{x - 8}" y="62" width="16" height="100" rx="5" fill="#C88A4A" stroke="#6E4418" stroke-width="3.5" opacity="0.9"/>')
        circle(s, x, 76, 3.5, "#6E4418")
        circle(s, x, 148, 3.5, "#6E4418")
    s.add('<rect x="20" y="50" width="160" height="5" rx="2" fill="#FFFFFF" opacity="0.4"/>')
    write("kutu_on.svg", s.text())
    s = Svg(200, 60)
    lid = s.lgrad(["#F8D4A0", "#E0A060"])
    s.add(f'<rect x="4" y="14" width="192" height="30" rx="12" fill="{lid}" stroke="#6E4418" stroke-width="5"/>')
    s.add('<rect x="80" y="4" width="40" height="16" rx="6" fill="#C88A4A" stroke="#6E4418" stroke-width="4"/>')
    write("kapak.svg", s.text())
    # Bant ucu makara diÅŸlisi (koyu metal)
    s = Svg(120, 120)
    fill = s.rgrad(["#D8D6E6", "#8E88AA", "#5E5880"], 0.38, 0.3, 0.85)
    rounded_shape(s, gear_d(60, 60, 42, 9, 12), fill, "#2A2440", 5, 5)
    circle(s, 60, 60, 14, "#E8E6F2", "#2A2440", 4)
    write("makara.svg", s.text())
    # Kol (bandÄ± durdurur): taban ve sap
    s = Svg(160, 110)
    base = s.lgrad(["#9ED0FF", "#5A8ED8", "#3A64A8"])
    s.add(f'<rect x="10" y="30" width="140" height="74" rx="22" fill="{base}" stroke="#1E3A6E" stroke-width="6"/>')
    s.add('<path d="M 60 30 A 20 20 0 0 1 100 30 Z" fill="#3A64A8" stroke="#1E3A6E" stroke-width="5"/>')
    for (x, c) in [(44, "#7EE08A"), (116, "#FF7A7A")]:
        circle(s, x, 66, 11, c, "#1E3A6E", 4)
    s.add('<rect x="22" y="38" width="116" height="8" rx="4" fill="#FFFFFF" opacity="0.35"/>')
    write("kol_taban.svg", s.text())
    s = Svg(60, 190)
    s.add(f'<rect x="22" y="40" width="16" height="146" rx="8" fill="#D8D6E6" stroke="{INK}" stroke-width="5"/>')
    knob = s.rgrad(["#FFB0B0", "#F2454F", "#B0203A"], 0.38, 0.3, 0.8)
    circle(s, 30, 30, 26, knob, "#6E1422", 6)
    shine(s, 22, 20, 7, 5, -30, 0.7)
    write("kol_sap.svg", s.text())
    # Galeri simgesi: Ã§erÃ§evede robot baÅŸÄ±
    s = Svg(140, 140)
    frame = s.lgrad(["#FFE6A6", "#F2B84A", "#D08A1E"])
    s.add(f'<rect x="10" y="14" width="120" height="112" rx="22" fill="{frame}" stroke="#7A4A0E" stroke-width="6"/>')
    s.add('<rect x="24" y="28" width="92" height="84" rx="14" fill="#DDEBFF" stroke="#7A4A0E" stroke-width="4"/>')
    head = s.rgrad(["#A6D4FF", "#3E8EEB", "#1E5DB5"], 0.38, 0.3, 0.85)
    s.add(f'<rect x="40" y="50" width="60" height="50" rx="16" fill="{head}" stroke="#10305E" stroke-width="5"/>')
    s.add('<rect x="48" y="62" width="44" height="22" rx="10" fill="#1E2240"/>')
    circle(s, 60, 73, 5, "#8EF0FF")
    circle(s, 80, 73, 5, "#8EF0FF")
    s.add('<path d="M 70 50 L 70 38" stroke="#4A4466" stroke-width="4"/>')
    circle(s, 70, 36, 6, "#FF8F5A", "#8E3A1A", 3)
    s.add(f'<path d="{star_path(116, 22, 14, 6)}" fill="#FFE27A" stroke="#B8680C" stroke-width="3.5" stroke-linejoin="round"/>')
    write("galeri.svg", s.text())
    # Duraklat / oynat
    s = Svg(100, 100)
    for x in (26, 56):
        s.add(f'<rect x="{x}" y="22" width="18" height="56" rx="8" fill="#FF9E45" stroke="#7A3A0E" stroke-width="5"/>')
    write("duraklat.svg", s.text())
    s = Svg(100, 100)
    play = s.lgrad(["#8FE87A", "#3DB85C"])
    s.add(f'<path d="M 32 18 L 80 50 L 32 82 Z" fill="{play}" stroke="#23703A" stroke-width="10" stroke-linejoin="round"/>')
    s.add(f'<path d="M 32 18 L 80 50 L 32 82 Z" fill="{play}" stroke="{play}" stroke-width="2" stroke-linejoin="round"/>')
    write("oynat.svg", s.text())
    # Efektler
    s = Svg(64, 64)
    sparkle(s, 32, 32, 29, "#FFFFFF", 1.0)
    write("parilti.svg", s.text())
    s = Svg(200, 200)
    s.defs.append('<radialGradient id="g" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFFFFF" stop-opacity="0.55"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>')
    circle(s, 100, 100, 100, "url(#g)")
    write("isik.svg", s.text())
    s = Svg(24, 36)
    s.add('<rect x="2" y="2" width="20" height="32" rx="6" fill="#FFFFFF"/>')
    write("konfeti.svg", s.text())
    s = Svg(100, 100)
    gold = s.rgrad(["#FFFBD0", "#FFD84A", "#F2A620"], 0.4, 0.3, 0.8)
    s.add(f'<path d="{star_path(50, 54, 40, 18)}" fill="{gold}" stroke="#B8680C" stroke-width="12" stroke-linejoin="round"/>')
    s.add(f'<path d="{star_path(50, 54, 40, 18)}" fill="{gold}" stroke="{gold}" stroke-width="4" stroke-linejoin="round"/>')
    shine(s, 40, 40, 7, 4, -30, 0.85)
    write("yildiz.svg", s.text())


if __name__ == "__main__":
    make_parts()
    make_icons()
    make_robot_bits()
    make_helper()
    make_factory()
