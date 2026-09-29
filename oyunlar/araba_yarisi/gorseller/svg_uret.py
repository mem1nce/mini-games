# Araba Yarışı SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre yazar)
# - Araba gövdesi her renk için ayrı SVG (aynı şablon, renk paleti farklı): araba_<renk>.svg
# - Arabanın ortak parçaları: kabin içi, direksiyon, tekerlek, gölge
# - Her tema için 3 döşenebilir paralaks katmanı (sol ve sağ kenarı birebir birleşir): arka_<tema>_<katman>.svg
# Arabanın bütün parçaları aynı 360x224 tuvali paylaşır; tekerlek merkezleri (98,178) ve (262,178), yarıçap 40.

import math
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))


def write(name: str, text: str) -> None:
    with open(os.path.join(HERE, name), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(name)


# --------------------------------------------------------------------------------------------
# Araba
# --------------------------------------------------------------------------------------------

# Gövde: tombul alt gövde + kabarcık kabin, iki tekerlek kemeri
BODY = ("M 51.5 190 C 34 190 22 178 22 158 C 22 132 32 112 60 108 L 84 106 "
        "C 92 70 116 22 170 16 C 210 12 240 20 258 36 C 272 50 284 78 292 102 "
        "C 318 104 336 114 340 134 C 344 158 340 180 312 190 L 308.5 190 "
        "A 48 48 0 1 0 215.5 190 L 144.5 190 A 48 48 0 1 0 51.5 190 Z")
# Cam (gövdede delik; şoför buradan görünür)
WINDOW = ("M 100 107 C 108 76 130 34 172 30 C 206 27 232 35 246 48 "
          "C 259 60 268 82 275 107 Z")
# Tekerlek kemerlerinin içi (tekerlekle kemer arasındaki boşluk koyu görünsün)
ARCHES = "M 215.5 190 A 48 48 0 1 1 308.5 190 Z M 51.5 190 A 48 48 0 1 1 144.5 190 Z"

# renk adı: (açık, orta, koyu, dış çizgi)
CAR_COLORS = {
    "kirmizi": ("#FF9A8F", "#F2545B", "#BF2E40", "#5E1626"),
    "turuncu": ("#FFC98A", "#FF962E", "#D9620F", "#5E2A06"),
    "sari": ("#FFF1A6", "#FFD23F", "#DDA200", "#5C4200"),
    "yesil": ("#9CF2BF", "#35C47B", "#1D8A52", "#0D4027"),
    "mavi": ("#9ED0FF", "#3E8EEB", "#1E5DB5", "#0F2B57"),
    "mor": ("#DCBDFF", "#9B5DE5", "#6933AD", "#2F1652"),
}


def car_body(light: str, mid: str, dark: str, outline: str) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="360" height="224" viewBox="0 0 360 224">
  <defs>
    <linearGradient id="govde" gradientUnits="userSpaceOnUse" x1="0" y1="14" x2="0" y2="192">
      <stop offset="0" stop-color="{light}"/>
      <stop offset="0.5" stop-color="{mid}"/>
      <stop offset="0.6" stop-color="{mid}"/>
      <stop offset="1" stop-color="{dark}"/>
    </linearGradient>
    <linearGradient id="cam" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#EAF7FF" stop-opacity="0.34"/>
      <stop offset="1" stop-color="#A9DAF7" stop-opacity="0.12"/>
    </linearGradient>
    <linearGradient id="tampon" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="#C9C6D8"/>
    </linearGradient>
    <radialGradient id="far" cx="0.4" cy="0.35" r="0.7">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="#FFE27A"/>
    </radialGradient>
    <clipPath id="pencere"><path d="{WINDOW}"/></clipPath>
    <clipPath id="govde_kirp"><path d="{BODY}"/></clipPath>
  </defs>
  <path d="{ARCHES}" fill="#2A2236"/>
  <!-- Egzoz borusu -->
  <rect x="6" y="177" width="24" height="11" rx="5" fill="#B9B5C9" stroke="{outline}" stroke-width="4"/>
  <!-- Gövde (cam yeri boş) -->
  <path d="{BODY} {WINDOW}" fill="url(#govde)" fill-rule="evenodd"/>
  <!-- Alt kısımda yumuşak gölge, omuzda ışık çizgisi -->
  <g clip-path="url(#govde_kirp)">
    <path d="M 18 174 C 120 184 240 184 346 170 L 346 200 L 18 200 Z" fill="{dark}" opacity="0.45"/>
    <path d="M 64 120 C 130 115 220 115 302 120" fill="none" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" opacity="0.4"/>
  </g>
  <!-- Cam: hafif mavi ton ve iki yansıma -->
  <path d="{WINDOW}" fill="url(#cam)"/>
  <g clip-path="url(#pencere)" fill="#FFFFFF">
    <path d="M 250 24 L 270 24 L 226 116 L 206 116 Z" opacity="0.2"/>
    <path d="M 280 24 L 288 24 L 244 116 L 236 116 Z" opacity="0.16"/>
    <path d="M 118 60 L 126 60 L 108 100 L 100 100 Z" opacity="0.14"/>
  </g>
  <!-- Kapı çizgisi ve kolu -->
  <path d="M 180 113 C 183 134 183 158 178 186" fill="none" stroke="{outline}" stroke-width="3" stroke-linecap="round" opacity="0.35"/>
  <rect x="194" y="121" width="22" height="7" rx="3.5" fill="#FFFFFF" opacity="0.8" stroke="{outline}" stroke-width="2.5"/>
  <!-- Dış çizgiler -->
  <path d="{BODY}" fill="none" stroke="{outline}" stroke-width="6" stroke-linejoin="round"/>
  <path d="{WINDOW}" fill="none" stroke="{outline}" stroke-width="5" stroke-linejoin="round"/>
  <!-- Tavandaki parlama -->
  <path d="M 124 34 C 146 24 184 20 212 25" fill="none" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" opacity="0.6"/>
  <!-- Far, stop lambası, tamponlar -->
  <rect x="323" y="120" width="16" height="22" rx="8" fill="url(#far)" stroke="{outline}" stroke-width="4"/>
  <rect x="19" y="124" width="12" height="22" rx="5" fill="#FF6B6B" stroke="{outline}" stroke-width="4"/>
  <rect x="304" y="172" width="42" height="18" rx="9" fill="url(#tampon)" stroke="{outline}" stroke-width="4"/>
  <rect x="13" y="170" width="42" height="18" rx="9" fill="url(#tampon)" stroke="{outline}" stroke-width="4"/>
</svg>
"""


def car_interior() -> str:
    # Kabinin içi: şoförün arkasında görünen koyu, yumuşak zemin (şoför buna kırpılır)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="360" height="224" viewBox="0 0 360 224">
  <defs>
    <linearGradient id="ic" x1="0" y1="0" x2="1" y2="0.4">
      <stop offset="0" stop-color="#3A3150"/>
      <stop offset="1" stop-color="#5B4F76"/>
    </linearGradient>
  </defs>
  <path d="{WINDOW}" fill="url(#ic)"/>
  <!-- Koltuk arkalığı -->
  <path d="M 120 107 L 124 68 C 126 56 134 50 146 50 L 152 50 C 162 50 168 58 166 70 L 162 107 Z" fill="#7C6D9A" opacity="0.9"/>
</svg>
"""


def steering() -> str:
    # Şoförün önünde: gösterge paneli ve direksiyon
    return """<svg xmlns="http://www.w3.org/2000/svg" width="360" height="224" viewBox="0 0 360 224">
  <path d="M 236 107 C 242 94 256 88 274 90 L 278 107 Z" fill="#3A3150"/>
  <path d="M 248 98 L 264 106" stroke="#2A2236" stroke-width="7" stroke-linecap="round"/>
  <ellipse cx="245" cy="90" rx="7" ry="20" transform="rotate(-18 245 90)" fill="none" stroke="#2A2236" stroke-width="9"/>
  <ellipse cx="245" cy="90" rx="7" ry="20" transform="rotate(-18 245 90)" fill="none" stroke="#6E6589" stroke-width="3.5"/>
</svg>
"""


def wheel() -> str:
    holes = ""
    for k in range(5):
        a = -math.pi / 2 + k * 2 * math.pi / 5
        holes += f'<circle cx="{44 + 14 * math.cos(a):.2f}" cy="{44 + 14 * math.sin(a):.2f}" r="4.6" fill="#8D88A3"/>'
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="88" height="88" viewBox="0 0 88 88">
  <defs>
    <radialGradient id="lastik" cx="0.42" cy="0.38" r="0.7">
      <stop offset="0" stop-color="#5A5268"/>
      <stop offset="1" stop-color="#2B2636"/>
    </radialGradient>
    <radialGradient id="jant" cx="0.38" cy="0.32" r="0.75">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="#CFCCDC"/>
    </radialGradient>
  </defs>
  <circle cx="44" cy="44" r="37.5" fill="url(#lastik)" stroke="#1C1826" stroke-width="5"/>
  <path d="M 18 34 A 28 28 0 0 1 34 18" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.2"/>
  <circle cx="44" cy="44" r="23" fill="url(#jant)" stroke="#1C1826" stroke-width="4"/>
  {holes}
  <circle cx="44" cy="44" r="6" fill="#6E6886"/>
  <circle cx="42" cy="42" r="2" fill="#FFFFFF" opacity="0.8"/>
</svg>
"""


def shadow() -> str:
    return """<svg xmlns="http://www.w3.org/2000/svg" width="240" height="40" viewBox="0 0 240 40">
  <defs>
    <radialGradient id="g" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#1A1030" stop-opacity="0.38"/>
      <stop offset="0.6" stop-color="#1A1030" stop-opacity="0.2"/>
      <stop offset="1" stop-color="#1A1030" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <ellipse cx="120" cy="20" rx="120" ry="20" fill="url(#g)"/>
</svg>
"""


def make_car() -> None:
    for name, colors in CAR_COLORS.items():
        write(f"araba_{name}.svg", car_body(*colors))
    write("araba_ic.svg", car_interior())
    write("direksiyon.svg", steering())
    write("teker.svg", wheel())
    write("golge.svg", shadow())


# --------------------------------------------------------------------------------------------
# Paralaks katmanları: W genişliğinde, yatayda döşenir. Kenarlarda kesilen şekiller karşı kenarda
# da çizilir; sırt çizgileri W'ye göre periyodik fonksiyonlardır.
# --------------------------------------------------------------------------------------------

W = 1600


def smooth(points: list) -> str:
    # Noktalardan geçen yumuşak eğri (Catmull-Rom -> kübik Bezier)
    d = f"M {points[0][0]:.1f} {points[0][1]:.1f} "
    for i in range(len(points) - 1):
        p0 = points[i - 1] if i > 0 else points[i]
        p1, p2 = points[i], points[i + 1]
        p3 = points[i + 2] if i + 2 < len(points) else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f"C {c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {p2[0]:.1f} {p2[1]:.1f} "
    return d


def silhouette(func, height: int, step: int = 20) -> str:
    # Sırt çizgisi func(x) ile üstü, tuvalin altı ile altı kapanan şekil (kenarlardan taşar)
    pts = [(x, func(x)) for x in range(-2 * step, W + 3 * step, step)]
    return smooth(pts) + f"L {W + 3 * step} {height + 10} L {-2 * step} {height + 10} Z"


def waves(x: float, parts: list) -> float:
    return sum(a * math.sin(2 * math.pi * k * x / W + ph) for k, a, ph in parts)


def peaks(x: float, items: list) -> float:
    # Sivri tepeler: her tepe (merkez, yükseklik, yarı genişlik); W'ye göre sarılır
    h = 0.0
    for cx, ph, half in items:
        dx = min(abs(x - cx), abs(x - cx - W), abs(x - cx + W))
        t = max(0.0, 1.0 - dx / half)
        h = max(h, ph * (t * t * (3 - 2 * t)))
    return h


def wrapped(x: float, half: float) -> list:
    # Kenara taşan şekil karşı kenarda da çizilsin
    out = [x]
    if x - half < 0:
        out.append(x + W)
    if x + half > W:
        out.append(x - W)
    return out


def grad(gid: str, top: str, bottom: str, y1: float = 0.0, y2: float = 1.0) -> str:
    return (f'<linearGradient id="{gid}" x1="0" y1="{y1}" x2="0" y2="{y2}">'
            f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>')


def layer_svg(height: int, defs: str, body: str) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{height}" viewBox="0 0 {W} {height}">\n'
            f'  <defs>{defs}</defs>\n{body}\n</svg>\n')


def round_tree(x: float, ground: float, size: float, leaf: str, light: str, trunk: str) -> str:
    s = size
    return (f'<rect x="{x - s * 0.09:.1f}" y="{ground - s * 0.55:.1f}" width="{s * 0.18:.1f}" height="{s * 0.6:.1f}" rx="{s * 0.06:.1f}" fill="{trunk}"/>'
            f'<circle cx="{x:.1f}" cy="{ground - s * 0.8:.1f}" r="{s * 0.42:.1f}" fill="{leaf}"/>'
            f'<circle cx="{x - s * 0.3:.1f}" cy="{ground - s * 0.6:.1f}" r="{s * 0.3:.1f}" fill="{leaf}"/>'
            f'<circle cx="{x + s * 0.3:.1f}" cy="{ground - s * 0.62:.1f}" r="{s * 0.3:.1f}" fill="{leaf}"/>'
            f'<circle cx="{x - s * 0.1:.1f}" cy="{ground - s * 0.92:.1f}" r="{s * 0.2:.1f}" fill="{light}"/>')


def pine(x: float, ground: float, size: float, leaf: str, snow: str, trunk: str) -> str:
    s = size
    out = f'<rect x="{x - s * 0.06:.1f}" y="{ground - s * 0.25:.1f}" width="{s * 0.12:.1f}" height="{s * 0.28:.1f}" fill="{trunk}"/>'
    for i, (w, top, bot) in enumerate([(0.42, 0.62, 0.2), (0.34, 0.9, 0.48), (0.25, 1.15, 0.76)]):
        out += (f'<path d="M {x - s * w:.1f} {ground - s * bot:.1f} L {x:.1f} {ground - s * top:.1f} '
                f'L {x + s * w:.1f} {ground - s * bot:.1f} Z" fill="{leaf}" stroke="{leaf}" stroke-width="{s * 0.06:.1f}" stroke-linejoin="round"/>')
        if snow:
            out += (f'<path d="M {x - s * w * 0.45:.1f} {ground - s * (top - (top - bot) * 0.45):.1f} L {x:.1f} {ground - s * top:.1f} '
                    f'L {x + s * w * 0.45:.1f} {ground - s * (top - (top - bot) * 0.45):.1f} '
                    f'Q {x:.1f} {ground - s * (top - (top - bot) * 0.3):.1f} {x - s * w * 0.45:.1f} {ground - s * (top - (top - bot) * 0.45):.1f} Z" '
                    f'fill="{snow}" stroke="{snow}" stroke-width="{s * 0.04:.1f}" stroke-linejoin="round"/>')
    return out


def forest() -> None:
    rng = random.Random(11)
    # Uzak: puslu mavi-yeşil dağlar (iki sıra)
    back = lambda x: 200 - peaks(x, [(150, 110, 260), (560, 150, 300), (980, 120, 260), (1330, 140, 280)])
    front = lambda x: 250 - peaks(x, [(330, 90, 240), (760, 110, 280), (1150, 80, 220), (1500, 95, 240)]) + waves(x, [(7, 6, 0.3)])
    write("arka_orman_uzak.svg", layer_svg(420, grad("a", "#B7D7E6", "#CFE6EC") + grad("b", "#A2C9DA", "#BCDDE4"),
          f'<path d="{silhouette(back, 420)}" fill="url(#a)"/><path d="{silhouette(front, 420)}" fill="url(#b)"/>'))
    # Orta: yumuşak yeşil tepeler ve yuvarlak ağaçlar
    hill = lambda x: 150 + waves(x, [(2, 34, 0.5), (3, 22, 2.1), (5, 10, 1.0)])
    trees = ""
    for i in range(14):
        x = i * W / 14 + rng.uniform(-30, 30)
        for xx in wrapped(x, 60):
            trees += round_tree(xx, hill(xx) + 12, rng.uniform(70, 105), "#6DB86C", "#86C982", "#86705C")
    write("arka_orman_orta.svg", layer_svg(340, grad("a", "#9AD08A", "#86C27A"),
          f'<path d="{silhouette(hill, 340)}" fill="url(#a)"/>{trees}'))
    # Yakın: koyu çalı sırası
    bush = lambda x: 130 + waves(x, [(4, 16, 0.2), (9, 9, 1.7), (15, 5, 0.4)])
    tops = ""
    for i in range(22):
        x = i * W / 22 + rng.uniform(-20, 20)
        r = rng.uniform(34, 56)
        for xx in wrapped(x, r):
            tops += f'<circle cx="{xx:.1f}" cy="{bush(xx) + 8:.1f}" r="{r:.1f}" fill="#5DA85B"/>'
            tops += f'<circle cx="{xx - r * 0.25:.1f}" cy="{bush(xx) - r * 0.2:.1f}" r="{r * 0.35:.1f}" fill="#6FB76A"/>'
    write("arka_orman_yakin.svg", layer_svg(260, grad("a", "#5DA85B", "#4E9A50"),
          f'{tops}<path d="{silhouette(bush, 260)}" fill="url(#a)"/>'))


def desert() -> None:
    rng = random.Random(23)
    # Uzak: düz tepeli kayalıklar
    def mesa(x: float) -> float:
        h = 0.0
        for cx, top, half in [(200, 150, 170), (640, 120, 120), (1040, 175, 210), (1420, 110, 110)]:
            dx = min(abs(x - cx), abs(x - cx - W), abs(x - cx + W))
            t = max(0.0, min(1.0, (half - dx) / 45.0))
            h = max(h, top * (t * t * (3 - 2 * t)))
        return 300 - h + waves(x, [(6, 5, 0.4)])
    stripes = "".join(f'<rect x="0" y="{y}" width="{W}" height="6" fill="#D99E7C" opacity="0.35"/>' for y in (178, 206, 236))
    write("arka_col_uzak.svg", layer_svg(420, grad("a", "#EDB894", "#F4CFAE") + f'<clipPath id="k"><path d="{silhouette(mesa, 420)}"/></clipPath>',
          f'<path d="{silhouette(mesa, 420)}" fill="url(#a)"/><g clip-path="url(#k)">{stripes}</g>'))
    # Orta: kum tepeleri
    dune = lambda x: 170 + waves(x, [(2, 40, 1.2), (3, 20, 0.1), (7, 6, 2.0)])
    ripples = ""
    for i in range(10):
        x = i * W / 10 + rng.uniform(-40, 40)
        for xx in wrapped(x, 90):
            y = dune(xx) + rng.uniform(30, 70)
            ripples += f'<path d="M {xx - 80:.1f} {y:.1f} Q {xx:.1f} {y - 12:.1f} {xx + 80:.1f} {y:.1f}" fill="none" stroke="#FFE2B0" stroke-width="5" stroke-linecap="round" opacity="0.55"/>'
    write("arka_col_orta.svg", layer_svg(340, grad("a", "#F4C685", "#EAB26C"),
          f'<path d="{silhouette(dune, 340)}" fill="url(#a)"/>{ripples}'))
    # Yakın: daha koyu kum ve yuvarlak kayalar
    near = lambda x: 140 + waves(x, [(3, 22, 0.6), (8, 8, 1.1)])
    rocks = ""
    for i in range(8):
        x = i * W / 8 + rng.uniform(-60, 60)
        w = rng.uniform(40, 70)
        for xx in wrapped(x, w):
            y = near(xx) + 10
            rocks += f'<ellipse cx="{xx:.1f}" cy="{y:.1f}" rx="{w:.1f}" ry="{w * 0.55:.1f}" fill="#C98B5E"/>'
            rocks += f'<ellipse cx="{xx - w * 0.25:.1f}" cy="{y - w * 0.2:.1f}" rx="{w * 0.35:.1f}" ry="{w * 0.18:.1f}" fill="#DDA476"/>'
    write("arka_col_yakin.svg", layer_svg(260, grad("a", "#E0A566", "#D39658"),
          f'{rocks}<path d="{silhouette(near, 260)}" fill="url(#a)"/>'))


def snow() -> None:
    rng = random.Random(37)
    items = [(120, 190, 230), (470, 240, 280), (860, 170, 220), (1200, 225, 270), (1500, 160, 200)]
    mountain = lambda x: 300 - peaks(x, items) + waves(x, [(9, 4, 0.8)])
    caps = ""
    for cx, ph, half in items:
        for xx in wrapped(cx, half):
            top = 300 - ph
            d = 62
            caps += (f'<path d="M {xx - half * 0.5:.1f} {top + d + 10:.1f} L {xx - half * 0.3:.1f} {top + d - 6:.1f} '
                     f'L {xx - half * 0.14:.1f} {top + d + 8:.1f} L {xx:.1f} {top + d - 8:.1f} L {xx + half * 0.16:.1f} {top + d + 6:.1f} '
                     f'L {xx + half * 0.32:.1f} {top + d - 4:.1f} L {xx + half * 0.5:.1f} {top + d + 10:.1f} L {xx:.1f} {top - 20:.1f} Z" fill="#F7FAFF"/>')
    write("arka_kar_uzak.svg", layer_svg(420, grad("a", "#A9BCDD", "#C6D3EA") + f'<clipPath id="k"><path d="{silhouette(mountain, 420)}"/></clipPath>',
          f'<path d="{silhouette(mountain, 420)}" fill="url(#a)"/><g clip-path="url(#k)">{caps}</g>'))
    hill = lambda x: 160 + waves(x, [(2, 30, 2.2), (3, 18, 0.7), (6, 7, 1.4)])
    trees = ""
    for i in range(16):
        x = i * W / 16 + rng.uniform(-30, 30)
        for xx in wrapped(x, 40):
            trees += pine(xx, hill(xx) + 14, rng.uniform(80, 120), "#6A96A0", "#F4F8FD", "#7A6A66")
    write("arka_kar_orta.svg", layer_svg(340, grad("a", "#EAF2FA", "#D8E4F2"),
          f'{trees}<path d="{silhouette(hill, 340)}" fill="url(#a)"/>'))
    drift = lambda x: 130 + waves(x, [(4, 14, 1.0), (7, 8, 0.2), (13, 4, 2.4)])
    small = ""
    for i in range(9):
        x = i * W / 9 + rng.uniform(-50, 50)
        for xx in wrapped(x, 30):
            small += pine(xx, drift(xx) + 18, rng.uniform(60, 85), "#4F7F8A", "#FFFFFF", "#6A5A58")
    write("arka_kar_yakin.svg", layer_svg(260, grad("a", "#FBFDFF", "#E9F1F9"),
          f'{small}<path d="{silhouette(drift, 260)}" fill="url(#a)"/>'))


def buildings(rng: random.Random, count: int, ground: float, hmin: float, hmax: float, wmin: float, wmax: float,
              fill: str, lit: str, dark_win: str, lit_ratio: float, win: float) -> str:
    out = ""
    x = 0.0
    while x < W:
        w = rng.uniform(wmin, wmax)
        h = rng.uniform(hmin, hmax)
        roof = rng.choice(["flat", "flat", "step", "point", "round"])
        cx = x + w / 2
        for xx in wrapped(cx, w / 2 + 20):
            left = xx - w / 2
            top = ground - h
            shape = f'<rect x="{left:.1f}" y="{top:.1f}" width="{w:.1f}" height="{h + 40:.1f}" rx="6" fill="{fill}"/>'
            if roof == "step":
                shape += f'<rect x="{left + w * 0.2:.1f}" y="{top - 26:.1f}" width="{w * 0.6:.1f}" height="40" rx="5" fill="{fill}"/>'
            elif roof == "point":
                shape += f'<path d="M {left + 4:.1f} {top + 2:.1f} L {xx:.1f} {top - w * 0.35:.1f} L {left + w - 4:.1f} {top + 2:.1f} Z" fill="{fill}"/>'
            elif roof == "round":
                shape += f'<ellipse cx="{xx:.1f}" cy="{top + 2:.1f}" rx="{w * 0.36:.1f}" ry="{w * 0.24:.1f}" fill="{fill}"/>'
            # Pencereler: ızgara, bazıları yanık
            wr = random.Random(int(cx * 7))
            cols = max(1, int((w - 16) / (win * 2.1)))
            rows = max(1, int((h - 24) / (win * 2.4)))
            gx = (w - cols * win * 2.1) / 2 + win * 0.55
            for r in range(rows):
                for c in range(cols):
                    on = wr.random() < lit_ratio
                    shape += (f'<rect x="{left + gx + c * win * 2.1:.1f}" y="{top + 16 + r * win * 2.4:.1f}" width="{win:.1f}" height="{win * 1.3:.1f}" '
                              f'rx="2" fill="{lit if on else dark_win}"/>')
            out += shape
        x += w + rng.uniform(4, 30)
    return out


def city() -> None:
    rng = random.Random(53)
    far = buildings(rng, 0, 400, 120, 260, 70, 130, "#353D7A", "#E9CF8E", "#383F7E", 0.12, 9)
    write("arka_sehir_uzak.svg", layer_svg(420, "", f'<rect x="0" y="390" width="{W}" height="40" fill="#353D7A"/>{far}'))
    mid = buildings(rng, 0, 330, 110, 210, 90, 160, "#2A3066", "#FFD27A", "#2F356D", 0.3, 12)
    write("arka_sehir_orta.svg", layer_svg(340, "", f'<rect x="0" y="320" width="{W}" height="30" fill="#2A3066"/>{mid}'))
    # Yakın: alçak evler ve yuvarlak ağaçlar
    near = ""
    x = 0.0
    while x < W:
        if rng.random() < 0.55:
            w = rng.uniform(110, 170)
            h = rng.uniform(70, 110)
            for xx in wrapped(x + w / 2, w / 2 + 40):
                left = xx - w / 2
                top = 250 - h
                near += (f'<rect x="{left:.1f}" y="{top:.1f}" width="{w:.1f}" height="{h + 20:.1f}" rx="6" fill="#20254F"/>'
                         f'<path d="M {left - 8:.1f} {top + 4:.1f} L {xx:.1f} {top - w * 0.3:.1f} L {left + w + 8:.1f} {top + 4:.1f} Z" fill="#20254F"/>')
                for k in range(2):
                    near += (f'<rect x="{left + w * (0.22 + k * 0.4):.1f}" y="{top + h * 0.3:.1f}" width="{w * 0.18:.1f}" height="{h * 0.3:.1f}" rx="3" '
                             f'fill="{"#FFCF70" if rng.random() < 0.6 else "#2C3262"}"/>')
            x += w + rng.uniform(20, 60)
        else:
            s = rng.uniform(70, 95)
            for xx in wrapped(x + 30, 50):
                near += round_tree(xx, 262, s, "#1E2A4E", "#27355E", "#1A1E40")
            x += 80
    write("arka_sehir_yakin.svg", layer_svg(260, "", f'{near}<rect x="0" y="240" width="{W}" height="30" fill="#20254F"/>'))


def make_backgrounds() -> None:
    forest()
    desert()
    snow()
    city()


if __name__ == "__main__":
    make_car()
    make_backgrounds()
