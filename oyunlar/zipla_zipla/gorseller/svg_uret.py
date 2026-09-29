# Zıpla Zıpla SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre yazar)
# - Basamaklar (basamak_<tur>.svg): 160x100 tuval, NinePatchRect ile kullanılır: sol 50 ve sağ 50 birim
#   köşe, ortadaki 60 birim yatayda döşenir. Süslemeler 60 birim periyotlu çizildiği için döşenen
#   parçalar birebir birleşir; basamak genişliği 160 + 60k olunca hiç bozulma olmaz (basamak.gd buna
#   yuvarlar). Görünen üst kenar (yürüme yüzeyi) y = CAP_TOP.
# - Arka plan katmanları (arka_<katman>.svg): 1280 genişlik, hem yatayda hem dikeyde döşenebilir
#   (kenarlar birebir birleşir). Uzaktan yakına doğru koyulaşan mavi bulut kümeleri.
# - Başlangıçtaki tepeler (tepeler.svg): 1280x360, yatayda döşenebilir.

import math
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
OUTLINE = "#3B2F6B"
W, H = 160, 100
PERIOD = 60.0
SURFACE = 26.0          # kapağın altındaki gövde üst kenarı
CAP_TOP = 20.0          # görünen üst kenar: kurbağa burada durur
BOTTOM = 92.0
RADIUS = 22.0


def write(name: str, text: str) -> None:
    with open(os.path.join(HERE, name), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(name)


def f(v: float) -> str:
    return f"{v:.1f}".rstrip("0").rstrip(".")


# --------------------------------------------------------------------------------------------
# Basamaklar
# --------------------------------------------------------------------------------------------

def body_path() -> str:
    # Yuvarlak köşeli kalın blok (üst köşeler biraz daha yuvarlak)
    l, r, t, b, rad = 5.0, W - 5.0, SURFACE, BOTTOM, RADIUS
    return (f"M {f(l + rad)} {f(t)} H {f(r - rad)} Q {f(r)} {f(t)} {f(r)} {f(t + rad)} "
            f"V {f(b - 16)} Q {f(r)} {f(b)} {f(r - 16)} {f(b)} H {f(l + 16)} Q {f(l)} {f(b)} {f(l)} {f(b - 16)} "
            f"V {f(t + rad)} Q {f(l)} {f(t)} {f(l + rad)} {f(t)} Z")


def drip_edge(fn, top: float) -> str:
    # Üst kaplamanın (krema, çimen, kar) şekli: üstte gövdeden taşan kapak, altta damlalı kenar fn(x)
    pts = [(x, fn(x)) for x in [i * 2.0 for i in range(int(W / 2) + 1)]]
    d = f"M 0 {f(top)} H {W} V {f(pts[-1][1])} "
    for x, y in reversed(pts):
        d += f"L {f(x)} {f(y)} "
    return d + "Z"


def edge_line(fn) -> str:
    pts = [(x, fn(x)) for x in [i * 2.0 for i in range(int(W / 2) + 1)]]
    return "M " + " L ".join(f"{f(x)} {f(y)}" for x, y in pts)


def periodic(xs: list) -> list:
    # Periyot içindeki konumları bütün tuvale yayar (döşenen parçalar birleşsin)
    out = []
    for x in xs:
        k = -1
        while x + k * PERIOD < W + 20:
            out.append(x + k * PERIOD)
            k += 1
    return out


def platform(name: str, body: tuple, cap: tuple, fn, extras: str, cap_top: float) -> None:
    # body/cap: (açık, orta, koyu) renkler
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <linearGradient id="govde" gradientUnits="userSpaceOnUse" x1="0" y1="{f(SURFACE)}" x2="0" y2="{f(BOTTOM)}">
      <stop offset="0" stop-color="{body[0]}"/>
      <stop offset="0.55" stop-color="{body[1]}"/>
      <stop offset="1" stop-color="{body[2]}"/>
    </linearGradient>
    <linearGradient id="kapak" gradientUnits="userSpaceOnUse" x1="0" y1="{f(cap_top)}" x2="0" y2="{f(SURFACE + 22)}">
      <stop offset="0" stop-color="{cap[0]}"/>
      <stop offset="0.5" stop-color="{cap[1]}"/>
      <stop offset="1" stop-color="{cap[2]}"/>
    </linearGradient>
    <clipPath id="kirp"><path d="{body_path_top(cap_top)}"/></clipPath>
  </defs>
  <path d="{body_path()}" transform="translate(0 5)" fill="{OUTLINE}" opacity="0.25"/>
  <path d="{body_path_top(cap_top)}" fill="url(#govde)"/>
  <g clip-path="url(#kirp)">
{extras}
    <path d="{drip_edge(fn, cap_top - 10)}" fill="url(#kapak)"/>
    <path d="{edge_line(fn)}" fill="none" stroke="{OUTLINE}" stroke-width="4" stroke-linejoin="round" opacity="0.9"/>
    <rect x="0" y="{f(cap_top + 3)}" width="{W}" height="4" fill="#FFFFFF" opacity="0.45"/>
  </g>
  <path d="{body_path_top(cap_top)}" fill="none" stroke="{OUTLINE}" stroke-width="5" stroke-linejoin="round"/>
  <ellipse cx="28" cy="{f(cap_top + 9)}" rx="12" ry="4.5" fill="#FFFFFF" opacity="0.85"/>
  <circle cx="45" cy="{f(cap_top + 8)}" r="3" fill="#FFFFFF" opacity="0.8"/>
</svg>
"""
    write(name, svg)


def body_path_top(cap_top: float) -> str:
    # Kapak gövdenin biraz üstünden başlar (çimen/krema yüzeyden taşar); dış şekil bu
    l, r, t, b, rad = 5.0, W - 5.0, cap_top, BOTTOM, RADIUS
    return (f"M {f(l + rad)} {f(t)} H {f(r - rad)} Q {f(r)} {f(t)} {f(r)} {f(t + rad)} "
            f"V {f(b - 16)} Q {f(r)} {f(b)} {f(r - 16)} {f(b)} H {f(l + 16)} Q {f(l)} {f(b)} {f(l)} {f(b - 16)} "
            f"V {f(t + rad)} Q {f(l)} {f(t)} {f(l + rad)} {f(t)} Z")


def drips(base: float, depth: float, count: int, sharp: float = 3.0):
    # count damla / periyot; damla profili yumuşak (|sin|^sharp)
    def fn(x: float) -> float:
        s = abs(math.sin(math.pi * count * x / PERIOD))
        return base + depth * s ** sharp
    return fn


def grass_edge(base: float):
    # Çimen alt kenarı: dalgalı, arada küçük sivri uçlar
    def fn(x: float) -> float:
        p = (x % 30.0) / 30.0
        tip = max(0.0, 1.0 - abs(p - 0.5) * 4.0)
        return base + 3.0 * math.sin(2 * math.pi * x / 60.0) + 7.0 * tip
    return fn


def build_platforms() -> None:
    rng = random.Random(7)
    # Çimenli toprak: kahverengi gövde, taşlar, yeşil çimen
    stones = ""
    for x, y, r in [(14, 64, 6), (40, 78, 4.5), (46, 56, 3.5)]:
        for px in periodic([x]):
            stones += f'    <ellipse cx="{f(px)}" cy="{y}" rx="{r}" ry="{r * 0.75}" fill="#8A5A34" stroke="#5E3A1E" stroke-width="2"/>\n'
            stones += f'    <circle cx="{f(px - r * 0.3)}" cy="{f(y - r * 0.3)}" r="{f(r * 0.3)}" fill="#C8956A"/>\n'
    blades = ""
    for x in [14, 44]:
        for px in periodic([x]):
            if px < 16 or px > W - 16:
                continue      # köşelerin yuvarlak kısmında yaprak olmasın
            blades += (f'  <path d="M {f(px - 5)} {f(SURFACE - 4)} Q {f(px - 3)} {f(SURFACE - 16)} {f(px)} {f(SURFACE - 20)} '
                       f'Q {f(px + 1)} {f(SURFACE - 12)} {f(px + 5)} {f(SURFACE - 4)} Z" fill="#6BD36B" stroke="{OUTLINE}" stroke-width="3" stroke-linejoin="round"/>\n')
    platform("basamak_cim.svg", ("#C98B55", "#A86A3C", "#7E4A26"), ("#A8F07A", "#6BD35B", "#3FA844"),
             grass_edge(SURFACE + 12), stones, CAP_TOP)
    _add_blades("basamak_cim.svg", blades)

    # Peynirli kek: sarı gövde, delikler, turuncu krema
    holes = ""
    for x, y, r in [(16, 70, 7), (44, 58, 5), (36, 82, 3.5)]:
        for px in periodic([x]):
            holes += f'    <circle cx="{f(px)}" cy="{y}" r="{r}" fill="#E8A91E" stroke="#B87A10" stroke-width="2"/>\n'
            holes += f'    <path d="M {f(px - r * 0.7)} {f(y + r * 0.3)} A {r} {r} 0 0 0 {f(px + r * 0.7)} {f(y + r * 0.3)}" fill="none" stroke="#FFF1A8" stroke-width="2" opacity="0.8"/>\n'
    platform("basamak_kek.svg", ("#FFF0A0", "#FFD84A", "#F0B020"), ("#FFD2A0", "#FF9F45", "#F07A1E"),
             drips(SURFACE + 8, 16, 1, 4.0), holes, CAP_TOP)

    # Pembe şekerli: pembe gövde, beyaz krema, renkli şeker serpintisi
    sprinkles = ""
    colors = ["#FF5C8A", "#5CC9FF", "#FFD23F", "#8EE05A", "#B98CFF"]
    for k in range(4):
        x = 7 + k * 15 + rng.uniform(-3, 3)
        y = rng.uniform(48, 82)
        a = rng.uniform(0, 180)
        c = colors[k % len(colors)]
        for px in periodic([x]):
            sprinkles += (f'    <rect x="{f(px - 6)}" y="{f(y - 2.2)}" width="12" height="4.4" rx="2.2" fill="{c}" '
                          f'transform="rotate({f(a)} {f(px)} {f(y)})"/>\n')
    platform("basamak_seker.svg", ("#FFC2DA", "#FF8FBC", "#E0609A"), ("#FFFFFF", "#FFF4FA", "#F4DDEB"),
             drips(SURFACE + 7, 13, 1, 2.5), sprinkles, CAP_TOP)

    # Mavi buzlu: buz mavisi gövde, parlak kristal çizgiler, üstte kar
    crystals = ""
    for x, y in [(20, 62), (48, 76)]:
        for px in periodic([x]):
            crystals += (f'    <path d="M {f(px - 12)} {f(y + 8)} L {f(px - 2)} {f(y - 10)} L {f(px + 10)} {f(y + 6)}" '
                         f'fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" opacity="0.7"/>\n')
            crystals += f'    <circle cx="{f(px + 14)}" cy="{f(y - 8)}" r="2.5" fill="#FFFFFF" opacity="0.85"/>\n'
    platform("basamak_buz.svg", ("#D6F3FF", "#8FD4FF", "#4FA3E6"), ("#FFFFFF", "#F2FAFF", "#D2E9FA"),
             drips(SURFACE + 6, 10, 1, 1.5), crystals, CAP_TOP)


def _add_blades(name: str, blades: str) -> None:
    # Çimen yaprakları yüzeyin üstüne taşar: gövde çizgisinin üstüne eklenir
    path = os.path.join(HERE, name)
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    text = text.replace("</svg>", blades + "</svg>")
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


# --------------------------------------------------------------------------------------------
# Arka plan
# --------------------------------------------------------------------------------------------

BG_W = 1280


def cloud(cx: float, cy: float, w: float, rng: random.Random) -> list:
    # Kabarık bulut: düz tabanlı, ortası yüksek daire kümesi. (x, y, r) listesi döner; taban y = cy.
    parts = []
    n = max(3, int(w / 70))
    for i in range(n):
        t = (i + 0.5) / n
        r = w / n * rng.uniform(0.75, 0.95) * (1.0 + 0.9 * math.sin(math.pi * t))
        parts.append((cx - w / 2 + t * w, cy - r * 0.55, r))
    return parts


def cloud_svg(parts: list, cy: float, w: float, cx: float, color: str, rim: str, shade: str) -> str:
    # Önce hafif koyu alt gölge, sonra bulut, sonra üst kenarda parlama kavisleri
    out = ""
    for x, y, r in parts:
        out += f'  <circle cx="{f(x)}" cy="{f(y + 8)}" r="{f(r)}" fill="{shade}"/>\n'
    out += f'  <rect x="{f(cx - w / 2)}" y="{f(cy - 30)}" width="{f(w)}" height="38" rx="19" fill="{shade}"/>\n'
    for x, y, r in parts:
        out += f'  <circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{color}"/>\n'
    out += f'  <rect x="{f(cx - w / 2)}" y="{f(cy - 38)}" width="{f(w)}" height="38" rx="19" fill="{color}"/>\n'
    for x, y, r in parts[1:-1]:
        out += (f'  <path d="M {f(x - r * 0.6)} {f(y - r * 0.45)} A {f(r * 0.85)} {f(r * 0.85)} 0 0 1 {f(x + r * 0.1)} {f(y - r * 0.75)}" '
                f'fill="none" stroke="{rim}" stroke-width="{f(max(4.0, r * 0.1))}" stroke-linecap="round" opacity="0.8"/>\n')
    return out


def background_layer(name: str, tile_h: int, clouds: list, color: str, rim: str, shade: str, seed: int) -> None:
    # Dağınık bulut kümeleri; kenardan taşan bulut karşı kenarda da çizilir (her yönde döşenir)
    rng = random.Random(seed)
    body = ""
    for cx, cy, w in clouds:
        parts = cloud(cx, cy, w, rng)
        for dx in (-BG_W, 0, BG_W):
            for dy in (-tile_h, 0, tile_h):
                moved = [(x + dx, y + dy, r) for x, y, r in parts]
                body += cloud_svg(moved, cy + dy, w, cx + dx, color, rim, shade)
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{BG_W}" height="{tile_h}" viewBox="0 0 {BG_W} {tile_h}">
{body}</svg>
"""
    write(name, svg)


def hills() -> None:
    # Başlangıçtaki bulut tepeleri: üç sıra kabarık tepe, aşağı doğru koyulaşan mavi; yatayda döşenebilir
    def ridge(base: float, amp: float, waves: int, phase: float, bumps: int) -> str:
        pts = []
        for i in range(0, BG_W + 1, 8):
            u = i / BG_W
            y = base - amp * (0.5 + 0.5 * math.sin(2 * math.pi * waves * u + phase))
            y -= 16 * abs(math.sin(math.pi * bumps * u))       # kabarık bulut tümsekleri
            pts.append(f"{i} {f(y)}")
        return "M 0 420 L " + " L ".join(pts) + f" L {BG_W} 420 Z"
    rows = [
        (170, 80, 3, 0.4, 14, "#C6E5FC", "#E8F5FF"),
        (250, 70, 2, 2.2, 11, "#9DCBF1", "#C9E6FB"),
        (330, 50, 4, 1.1, 17, "#76AEE2", "#A7D0F3"),
    ]
    body = ""
    for base, amp, waves, phase, bumps, color, rim in rows:
        d = ridge(base, amp, waves, phase, bumps)
        body += f'  <path d="{d}" fill="{color}" stroke="{OUTLINE}" stroke-width="5" stroke-opacity="0.25" stroke-linejoin="round"/>\n'
        top = d.split(" L ", 1)[1].rsplit(" L ", 1)[0]
        body += (f'  <path d="M {top}" fill="none" stroke="{rim}" stroke-width="6" stroke-linecap="round" '
                 f'transform="translate(0 9)" opacity="0.8"/>\n')
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{BG_W}" height="420" viewBox="0 0 {BG_W} 420">
{body}</svg>
"""
    write("tepeler.svg", svg)


if __name__ == "__main__":
    build_platforms()
    # Uzak: küçük beyaz bulutlar; orta: açık mavi; yakın: en koyu mavi, büyük ve ekranın kenarlarında
    background_layer("arka_uzak.svg", 1000, [(150, 180, 170), (700, 90, 130), (1060, 420, 190), (420, 560, 140),
                                             (880, 800, 160), (230, 900, 120)], "#FFFFFF", "#FFFFFF", "#D8ECFB", 11)
    background_layer("arka_orta.svg", 1300, [(260, 300, 300), (1000, 720, 340), (520, 1150, 260)],
                     "#CBE6FC", "#EEF8FF", "#B3D8F6", 23)
    background_layer("arka_yakin.svg", 1700, [(90, 420, 420), (1190, 1180, 460)],
                     "#A4CFF3", "#D2E9FB", "#86B9E6", 37)
    hills()
