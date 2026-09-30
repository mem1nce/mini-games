# Boyama Kitabı sayfa üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python sayfa_uret.py   (bu klasörün altına <kategori>/<sayfa>.svg yazar)
# Sonra derleme: godot --headless --path . -s res://oyunlar/boyama_kitabi/sayfalar/derle.gd
#
# Her sayfa 1024x768 bir SVG'dir ve iki grup içerir (derle.gd bu yapıyı okur):
#   <g id="bolgeler">  boyanabilir her bölge ayrı bir şekil (id'si benzersiz). Ressam sırası geçerlidir:
#                      sonra gelen şekil öncekinin üstündedir (göbek gövdenin üstünde gibi).
#   <g id="cizgiler">  kalın koyu hatlar, göz bebekleri gibi boyanmayan koyu dolgular.
# Bir bölgenin hattı, kendisinden sonra gelen (üstteki) bölgelerin altında kalan kısmında maskeyle gizlenir;
# böylece bölgeler üst üste çizilebilir, hatlar yine doğru görünür.
# Bölge olmayan her yer "kağıt" bölgesidir (0 numara, o da boyanabilir) ve tek parça olmalıdır: kapalı
# kalan küçük boşluklar için ayrı bölge çiz (tren tekerleklerinin arası gibi).
#
# Kurallar (derle.gd denetler): bölgeler kapalı ve birbirinden ayrı, çok küçük bölge yok.
# Küçükler için basit sayfalar 5-10 bölge, büyükler için 15-30 bölge.

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 1024, 768
OUT = "#3B2F6B"
LW = 12          # bölge hattı
DW = 9           # iç ayrıntı çizgisi


def f(v: float) -> str:
    s = "%.1f" % v
    return s[:-2] if s.endswith(".0") else s


class Shape:
    def __init__(self, svg: str, bbox: tuple):
        self.svg = svg
        self.bbox = bbox   # (x0, y0, x1, y1)

    def attr(self, extra: str) -> str:
        return self.svg.replace("/>", " %s/>" % extra, 1)


def _bbox(points: list) -> tuple:
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return min(xs), min(ys), max(xs), max(ys)


def circle(cx, cy, r) -> Shape:
    return Shape('<circle cx="%s" cy="%s" r="%s"/>' % (f(cx), f(cy), f(r)), (cx - r, cy - r, cx + r, cy + r))


def ellipse(cx, cy, rx, ry, rot=0.0) -> Shape:
    t = ' transform="rotate(%s %s %s)"' % (f(rot), f(cx), f(cy)) if rot else ""
    a = math.radians(rot)
    hw = math.hypot(rx * math.cos(a), ry * math.sin(a))
    hh = math.hypot(rx * math.sin(a), ry * math.cos(a))
    return Shape('<ellipse cx="%s" cy="%s" rx="%s" ry="%s"%s/>' % (f(cx), f(cy), f(rx), f(ry), t),
                 (cx - hw, cy - hh, cx + hw, cy + hh))


def rect(x, y, w, h, r=0.0) -> Shape:
    rr = ' rx="%s"' % f(r) if r else ""
    return Shape('<rect x="%s" y="%s" width="%s" height="%s"%s/>' % (f(x), f(y), f(w), f(h), rr), (x, y, x + w, y + h))


def poly(points: list) -> Shape:
    return Shape('<polygon points="%s"/>' % " ".join("%s,%s" % (f(x), f(y)) for x, y in points), _bbox(points))


def path(d: str, bbox: tuple = None) -> Shape:
    if bbox is None:
        nums = [float(n) for n in d.replace(",", " ").translate(str.maketrans("MLCQTSZHV", "         ")).split()]
        bbox = _bbox(list(zip(nums[0::2], nums[1::2])))
    return Shape('<path d="%s"/>' % d, bbox)


def line(d: str) -> Shape:
    return path(d)


def arc_points(cx, cy, rx, ry, a0, a1, n=32) -> list:
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * k / n)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * k / n)))
            for k in range(n + 1)]


def regular(cx, cy, r, n, rot=-90.0) -> Shape:
    return poly([(cx + r * math.cos(math.radians(rot + 360 * k / n)), cy + r * math.sin(math.radians(rot + 360 * k / n)))
                 for k in range(n)])


def star_points(cx, cy, big, small, n=5, rot=-90.0) -> list:
    pts = []
    for k in range(2 * n):
        r = big if k % 2 == 0 else small
        a = math.radians(rot + 180.0 * k / n)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def heart_points(cx, cy, s, n=90) -> list:
    # Klasik kalp eğrisi; (cx, cy) kalbin ortası, s ölçek (genişlik ~32 s)
    pts = []
    for k in range(n):
        t = 2 * math.pi * k / n
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * s, cy + (y + 2.5) * s))
    return pts


def scallop(cx, cy, rx, ry, n, bulge=0.62, a0=0.0, flat=None) -> Shape:
    # Tırtıklı (bulut, ağaç tacı) kenar: elips üstündeki noktalar arası dışa doğru yaylar.
    # flat: verilirse bu y'nin altındaki noktalar düz bir tabana (y=flat) çekilir (bulutun düz altı)
    pts = [(cx + rx * math.cos(math.radians(a0 + 360 * k / n)), cy + ry * math.sin(math.radians(a0 + 360 * k / n))) for k in range(n)]
    if flat is not None:
        pts = [(x, min(y, flat)) for x, y in pts]
    d = "M%s %s" % (f(pts[0][0]), f(pts[0][1]))
    top = cy
    for k in range(n):
        a, b = pts[k], pts[(k + 1) % n]
        chord = math.dist(a, b)
        if flat is not None and abs(a[1] - flat) < 0.1 and abs(b[1] - flat) < 0.1:
            d += " L%s %s" % (f(b[0]), f(b[1]))
            continue
        r = chord * bulge
        d += " A%s %s 0 0 1 %s %s" % (f(r), f(r), f(b[0]), f(b[1]))
        top = min(top, min(a[1], b[1]) - (r - math.sqrt(max(0.0, r * r - chord * chord / 4))))
    d += " Z"
    pad = rx * 0.25
    return Shape('<path d="%s"/>' % d, (cx - rx - pad, cy - ry - pad, cx + rx + pad, cy + ry + pad))


def band(cx, cy, rx, ry, x0, x1, n=24) -> Shape:
    # Elipsin x0..x1 arasındaki dikey şeridi (balığın çizgileri gibi)
    x0, x1 = max(x0, cx - rx), min(x1, cx + rx)
    top, bottom = [], []
    for k in range(n + 1):
        x = x0 + (x1 - x0) * k / n
        dy = ry * math.sqrt(max(0.0, 1 - ((x - cx) / rx) ** 2))
        top.append((x, cy - dy))
        bottom.append((x, cy + dy))
    return poly(top + bottom[::-1])


def _overlap(a: tuple, b: tuple, pad: float) -> bool:
    return a[0] - pad < b[2] and b[0] - pad < a[2] and a[1] - pad < b[3] and b[1] - pad < a[3]


class Page:
    def __init__(self, pid: str, category: str):
        self.pid = pid
        self.category = category
        self.regions = []      # (id, Shape)
        self.lines = []        # (kaç bölgeden sonra geldi, svg öğesi, bbox)

    def region(self, rid: str, shape: Shape, outline: bool = True, width: float = LW) -> None:
        assert rid not in [r for r, _ in self.regions], rid
        self.regions.append((rid, shape))
        if outline:
            self.lines.append((len(self.regions), shape.attr('stroke-width="%s"' % f(width)) if width != LW else shape.svg, shape.bbox))

    def detail(self, shape: Shape, width: float = DW) -> None:
        self.lines.append((len(self.regions), shape.attr('stroke-width="%s"' % f(width)), shape.bbox))

    def ink(self, shape: Shape, color: str = OUT, stroke: float = 0.0) -> None:
        # Boyanmayan dolgu (göz bebeği, burun): hat katmanında durur. stroke>0: köşeleri yuvarlatan kendi renginde hat
        edge = 'stroke="%s" stroke-width="%s"' % (color, f(stroke)) if stroke else 'stroke="none"'
        self.lines.append((len(self.regions), shape.attr('fill="%s" %s' % (color, edge)), shape.bbox))

    def eye(self, x, y, rx=22, ry=28) -> None:
        self.ink(ellipse(x, y, rx, ry))
        self.ink(circle(x - rx * 0.35, y - ry * 0.4, rx * 0.38), "#FFFFFF")

    def write(self) -> None:
        folder = os.path.join(HERE, self.category)
        os.makedirs(folder, exist_ok=True)
        defs, lines = "", ""
        for k, (after, svg, bbox) in enumerate(self.lines):
            covers = [s.svg for _, s in self.regions[after:] if _overlap(s.bbox, bbox, LW)]
            if covers:
                mid = "m%d" % k
                defs += ('    <mask id="%s" maskUnits="userSpaceOnUse" x="-100" y="-100" width="%d" height="%d">'
                         '<rect x="-100" y="-100" width="%d" height="%d" fill="#FFFFFF"/><g fill="#000000" stroke="none">%s</g></mask>\n'
                         % (mid, W + 200, H + 200, W + 200, H + 200, "".join(covers)))
                # Maske bir <g> üzerinde: öğenin kendi transform'u maskeyi döndürmesin
                svg = '<g mask="url(#%s)">%s</g>' % (mid, svg)
            lines += "    " + svg + "\n"
        regions = "".join('    %s\n' % s.svg.replace(" ", ' id="%s" ' % rid, 1) for rid, s in self.regions)
        text = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' % (W, H, W, H)
                + ("  <defs>\n" + defs + "  </defs>\n" if defs else "")
                + '  <g id="bolgeler" fill="#F6F2FB">\n' + regions + "  </g>\n"
                + '  <g id="cizgiler" fill="none" stroke="%s" stroke-width="%d" stroke-linejoin="round" stroke-linecap="round">\n'
                % (OUT, LW) + lines + "  </g>\n</svg>\n")
        with open(os.path.join(folder, self.pid + ".svg"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
        print("%-12s %-14s %2d bölge" % (self.category, self.pid, len(self.regions)))


# ============================ HAYVANLAR ============================

def kedi() -> Page:
    p = Page("kedi", "hayvanlar")
    p.region("kuyruk", path("M640 610 C800 640 870 520 826 418 C808 376 756 384 768 428 C800 510 766 572 640 556 Z"))
    p.region("govde", ellipse(512, 570, 165, 140))
    p.region("gobek", ellipse(512, 600, 95, 85))
    p.region("ayak_sol", ellipse(438, 700, 72, 38))
    p.region("ayak_sag", ellipse(586, 700, 72, 38))
    p.region("kulak_sol", poly([(352, 250), (336, 70), (480, 166)]))
    p.region("kulak_sag", poly([(672, 250), (688, 70), (544, 166)]))
    p.region("kulak_ici_sol", poly([(374, 222), (364, 116), (452, 176)]))
    p.region("kulak_ici_sag", poly([(650, 222), (660, 116), (572, 176)]))
    p.region("kafa", ellipse(512, 312, 195, 160))
    p.eye(440, 300)
    p.eye(584, 300)
    p.ink(path("M494 350 L530 350 L512 370 Z"), stroke=8)
    p.detail(line("M474 382 Q493 402 512 384 Q531 402 550 382"))
    p.detail(line("M404 356 L318 340 M404 380 L320 392 M620 356 L706 340 M620 380 L704 392"), 7)
    return p


def balik() -> Page:
    p = Page("balik", "hayvanlar")
    p.region("kabarcik_1", circle(836, 190, 40))
    p.region("kabarcik_2", circle(900, 96, 30))
    p.region("kuyruk", path("M310 384 L120 240 Q170 384 120 528 Z"))
    p.region("yuzgec_ust", path("M400 262 Q500 110 640 250 Z"))
    p.region("yuzgec_alt", path("M420 496 Q500 668 630 500 Z"))
    cuts = [260, 380, 450, 540, 610, 670, 780]
    names = ["govde_1", "serit_1", "govde_2", "serit_2", "govde_3", "bas"]
    for k, name in enumerate(names):
        p.region(name, band(520, 384, 250, 160, cuts[k], cuts[k + 1]))
    p.eye(712, 350, 20, 24)
    p.detail(line("M724 428 Q745 440 760 420"))
    p.detail(line("M170 330 Q200 384 170 438"), 7)
    return p


def tavsan() -> Page:
    p = Page("tavsan", "hayvanlar")
    p.region("yaprak_1", ellipse(772, 420, 22, 58, -28))
    p.region("yaprak_2", ellipse(846, 420, 22, 58, 28))
    p.region("yaprak_3", ellipse(810, 398, 24, 66))
    p.region("havuc", path("M744 470 Q810 440 876 470 Q846 620 808 760 Q772 620 744 470 Z"))
    p.region("cimen", path("M-20 728 Q250 700 512 724 Q780 748 1044 714 L1044 800 L-20 800 Z"))
    p.detail(line("M770 530 L800 526 M780 590 L806 586 M790 650 L810 648"), 7)
    p.region("kulak_sol", ellipse(440, 168, 48, 125, -12))
    p.region("kulak_sag", ellipse(584, 168, 48, 125, 12))
    p.region("kulak_ici_sol", ellipse(440, 180, 24, 90, -12))
    p.region("kulak_ici_sag", ellipse(584, 180, 24, 90, 12))
    p.region("govde", ellipse(512, 580, 150, 135))
    p.region("gobek", ellipse(512, 604, 85, 88))
    p.region("ayak_sol", ellipse(440, 706, 76, 36))
    p.region("ayak_sag", ellipse(584, 706, 76, 36))
    p.region("kol_sol", ellipse(430, 560, 40, 64, 28))
    p.region("kol_sag", ellipse(594, 560, 40, 64, -28))
    p.region("kafa", ellipse(512, 340, 160, 135))
    p.region("agiz", ellipse(512, 400, 64, 46))
    p.eye(452, 318)
    p.eye(572, 318)
    p.ink(path("M496 380 Q512 370 528 380 L512 396 Z"), stroke=7)
    p.detail(line("M512 396 V412 M512 412 Q498 428 484 416 M512 412 Q526 428 540 416"), 7)
    return p


def kaplumbaga() -> Page:
    p = Page("kaplumbaga", "hayvanlar")
    p.region("gunes", circle(130, 120, 70))
    p.region("bulut", scallop(820, 120, 120, 55, 9, flat=150))
    p.region("arka_bacak_1", ellipse(420, 600, 42, 64))
    p.region("arka_bacak_2", ellipse(716, 600, 42, 64))
    p.region("on_bacak_1", ellipse(330, 640, 50, 72))
    p.region("on_bacak_2", ellipse(626, 642, 50, 72))
    p.region("kuyruk", poly([(250, 566), (116, 646), (258, 612)]))
    p.region("kafa", ellipse(846, 470, 92, 78))
    p.region("kabuk", path("M240 580 C240 330 370 230 510 230 C650 230 780 330 780 580 Z"))
    hexes = [(510, 412, 78), (352, 474, 56), (668, 474, 56), (402, 322, 48), (618, 322, 48)]
    for k, (x, y, r) in enumerate(hexes):
        p.region("pul_%d" % (k + 1), regular(x, y, r, 6, 0))
    p.region("kenar", path("M222 560 L798 560 Q806 614 760 616 L262 616 Q216 614 222 560 Z"))
    p.eye(878, 442, 16, 20)
    p.detail(line("M876 504 Q904 516 922 492"))
    p.eye(106, 112, 9, 11)
    p.eye(154, 112, 9, 11)
    p.detail(line("M110 146 Q130 160 150 146"), 7)
    return p


# ============================ ARAÇLAR ============================

def araba() -> Page:
    p = Page("araba", "araclar")
    p.region("bulut", scallop(200, 150, 130, 58, 9, flat=180))
    p.region("kabin", path("M330 470 L420 332 Q440 305 480 305 L660 305 Q700 305 725 335 L820 470 Z"))
    p.region("cam_arka", path("M430 480 L482 356 Q490 338 512 338 L560 338 L560 480 Z"))
    p.region("cam_on", path("M592 480 L592 338 L652 338 Q680 338 698 362 L770 480 Z"))
    p.region("govde", path("M140 560 Q140 460 240 455 L880 455 Q960 460 960 540 L960 575 Q960 605 930 605 L170 605 Q140 605 140 575 Z"))
    p.region("far", ellipse(930, 505, 20, 30))
    p.region("lastik_arka", circle(300, 610, 88))
    p.region("jant_arka", circle(300, 610, 42))
    p.region("lastik_on", circle(790, 610, 88))
    p.region("jant_on", circle(790, 610, 42))
    p.detail(line("M576 480 V585 M620 500 H660"))
    return p


def tekne() -> Page:
    p = Page("tekne", "araclar")
    p.region("gunes", circle(140, 140, 72))
    p.region("bulut", scallop(830, 150, 120, 52, 9, flat=178))
    waves = "M-20 560 Q60 530 140 560 T300 560 T460 560 T620 560 T780 560 T940 560 T1100 560 L1100 800 L-20 800 Z"
    p.region("deniz", path(waves, (-20, 530, 1100, 800)))
    p.region("govde", path("M240 500 L810 500 Q788 612 700 634 L350 634 Q262 612 240 500 Z"))
    for k, x in enumerate((400, 525, 650)):
        p.region("pencere_%d" % (k + 1), circle(x, 560, 28))
    p.detail(line("M520 500 L520 96"), 16)
    p.region("yelken_buyuk", poly([(538, 160), (538, 470), (770, 470)]))
    p.region("yelken_kucuk", poly([(502, 206), (502, 470), (320, 470)]))
    p.region("bayrak", poly([(528, 96), (610, 122), (528, 150)]))
    p.eye(116, 130, 9, 12)
    p.eye(164, 130, 9, 12)
    p.detail(line("M116 166 Q140 182 164 166"), 7)
    return p


def ucak() -> Page:
    p = Page("ucak", "araclar")
    p.region("bulut_1", scallop(210, 610, 150, 64, 10, flat=648))
    p.region("bulut_2", scallop(820, 160, 130, 56, 9, flat=190))
    p.region("kuyruk", poly([(170, 382), (116, 196), (232, 214), (310, 382)]))
    p.region("uzak_kanat", poly([(480, 380), (570, 252), (648, 252), (620, 380)]))
    p.region("pervane_ust", ellipse(930, 362, 18, 58))
    p.region("pervane_alt", ellipse(930, 478, 18, 58))
    p.region("govde", path("M160 420 Q160 360 260 355 L790 350 Q900 355 912 420 Q900 482 790 486 L260 486 Q160 480 160 420 Z"))
    p.region("kokpit", path("M790 364 Q862 366 890 404 L790 404 Z"))
    for k, x in enumerate((390, 480, 570, 660)):
        p.region("pencere_%d" % (k + 1), circle(x, 414, 27))
    p.region("kuyruk_kanadi", ellipse(226, 452, 76, 26, -8))
    p.region("kanat", poly([(470, 452), (620, 452), (530, 616), (452, 616)]))
    p.region("pervane_gobegi", circle(916, 420, 24))
    return p


def tren() -> Page:
    p = Page("tren", "araclar")
    p.region("duman_1", scallop(170, 90, 72, 50, 8))
    p.region("duman_2", scallop(270, 160, 56, 42, 7))
    p.region("duman_3", scallop(700, 170, 46, 34, 7))
    # Tekerleklerin arasında, gövdenin altında kalan boşluklar (kapalı kaldıkları için ayrı bölge)
    p.region("bosluk_1", rect(150, 600, 90, 110))
    p.region("bosluk_2", rect(300, 590, 150, 120))
    p.region("bosluk_3", rect(520, 610, 160, 100))
    p.region("bosluk_4", rect(690, 610, 150, 100))
    p.region("ray", path("M-20 704 L1044 704 L1044 800 L-20 800 Z"))
    for x in range(10, 1024, 64):
        p.ink(rect(x, 720, 34, 16, 5))
    p.region("kubbe", ellipse(690, 426, 44, 36))
    p.region("baca", path("M786 426 L770 298 L862 298 L846 426 Z"))
    p.region("baca_ucu", rect(754, 262, 124, 44, 14))
    p.region("kabin", rect(380, 300, 220, 330, 16))
    p.region("cati", rect(356, 268, 268, 50, 16))
    p.region("kabin_cami", rect(424, 346, 132, 108, 20))
    p.region("kazan", rect(590, 420, 330, 210, 60))
    p.region("far", circle(928, 474, 30))
    p.region("mahmuz", poly([(860, 600), (990, 704), (860, 704)]))
    p.region("sasi", rect(370, 560, 540, 60, 14))
    p.region("vagon", rect(60, 420, 290, 196, 20))
    p.region("vagon_cami_1", rect(96, 458, 94, 82, 14))
    p.region("vagon_cami_2", rect(220, 458, 94, 82, 14))
    p.detail(line("M346 590 H384"), 18)
    p.region("teker_vagon_1", circle(130, 650, 50))
    p.region("teker_vagon_2", circle(270, 650, 50))
    p.region("teker_buyuk", circle(480, 668, 72))
    p.region("gobek_buyuk", circle(480, 668, 28))
    p.region("teker_1", circle(700, 670, 50))
    p.region("teker_2", circle(830, 670, 50))
    return p


# ============================ OYUNCAKLAR ============================

def top() -> Page:
    p = Page("top", "oyuncaklar")
    cx, cy, R = 512, 380, 280
    pole = 0.86 * R
    p.region("golge", ellipse(512, 684, 230, 38))

    def meridian(a, reverse=False) -> list:
        pts = [(cx + a * math.sin(math.pi * k / 40), cy - pole * math.cos(math.pi * k / 40)) for k in range(41)]
        return pts[::-1] if reverse else pts

    longs = [-54, -18, 18, 54]
    a = [R * math.sin(math.radians(v)) for v in longs]
    left = [(cx - (x - cx), y) for x, y in arc_points(cx, cy, R, R, -90, 90, 40)]   # üstten sola, alta
    right = arc_points(cx, cy, R, R, -90, 90, 40)
    p.region("dilim_1", poly(left + meridian(a[0], True)))
    for k in range(3):
        p.region("dilim_%d" % (k + 2), poly(meridian(a[k]) + meridian(a[k + 1], True)))
    p.region("dilim_5", poly(right + meridian(a[3], True)))
    p.region("tepe", ellipse(cx, cy - pole, 84, 34))
    p.region("alt", ellipse(cx, cy + pole, 84, 34))
    p.ink(ellipse(404, 236, 40, 18, -40), "#FFFFFF")
    return p


def ucurtma() -> Page:
    p = Page("ucurtma", "oyuncaklar")
    p.region("bulut", scallop(180, 170, 120, 54, 9, flat=200))
    p.region("gunes", circle(900, 110, 62))
    p.eye(880, 102, 9, 12)
    p.eye(920, 102, 9, 12)
    p.detail(line("M882 132 Q900 146 918 132"), 7)
    top_, right, bottom, left, c = (512, 80), (724, 300), (512, 566), (300, 300), (512, 300)
    p.detail(line("M512 566 Q480 600 500 636 Q520 680 460 724 Q430 748 396 752"), 7)
    p.region("parca_1", poly([top_, right, c]))
    p.region("parca_2", poly([right, bottom, c]))
    p.region("parca_3", poly([bottom, left, c]))
    p.region("parca_4", poly([left, top_, c]))
    for k, (x, y) in enumerate(((500, 636), (460, 724))):
        p.region("fiyonk_%d_sol" % (k + 1), poly([(x, y), (x - 74, y - 34), (x - 70, y + 34)]))
        p.region("fiyonk_%d_sag" % (k + 1), poly([(x, y), (x + 74, y - 34), (x + 70, y + 34)]))
    p.eye(476, 290, 16, 20)
    p.eye(548, 290, 16, 20)
    p.detail(line("M486 340 Q512 360 538 340"))
    return p


def oyuncak_ayi() -> Page:
    p = Page("oyuncak_ayi", "oyuncaklar")
    p.region("kulak_sol", circle(362, 168, 64))
    p.region("kulak_sag", circle(662, 168, 64))
    p.region("kulak_ici_sol", circle(362, 168, 34))
    p.region("kulak_ici_sag", circle(662, 168, 34))
    p.region("govde", ellipse(512, 560, 150, 150))
    p.region("gobek", ellipse(512, 596, 86, 86))
    p.region("kol_sol", ellipse(370, 520, 52, 96, 32))
    p.region("kol_sag", ellipse(654, 520, 52, 96, -32))
    p.region("bacak_sol", ellipse(436, 680, 82, 60))
    p.region("bacak_sag", ellipse(588, 680, 82, 60))
    p.region("taban_sol", ellipse(430, 690, 40, 34))
    p.region("taban_sag", ellipse(594, 690, 40, 34))
    p.region("kafa", ellipse(512, 282, 172, 150))
    p.region("burun", ellipse(512, 344, 72, 54))
    p.region("papyon_sol", poly([(512, 436), (430, 398), (430, 474)]))
    p.region("papyon_sag", poly([(512, 436), (594, 398), (594, 474)]))
    p.region("dugum", circle(512, 436, 26))
    p.eye(452, 262)
    p.eye(572, 262)
    p.ink(ellipse(512, 326, 26, 18))
    p.detail(line("M512 344 V360 M512 360 Q494 378 478 364 M512 360 Q530 378 546 364"), 7)
    return p


def robot() -> Page:
    p = Page("robot", "oyuncaklar")
    p.detail(line("M512 70 L512 124"), 14)
    p.region("anten", circle(512, 64, 30))
    p.region("boyun", rect(470, 350, 84, 60))
    p.region("kulak_sol", rect(296, 190, 44, 92, 12))
    p.region("kulak_sag", rect(684, 190, 44, 92, 12))
    p.region("kafa", rect(330, 120, 364, 240, 40))
    p.region("goz_sol", circle(440, 222, 50))
    p.region("goz_sag", circle(584, 222, 50))
    p.region("agiz", rect(430, 290, 164, 44, 16))
    p.eye(440, 222, 18, 18)
    p.eye(584, 222, 18, 18)
    for x in (470, 512, 554):
        p.ink(circle(x, 312, 6))
    p.region("kol_sol", rect(248, 420, 72, 170, 30))
    p.region("kol_sag", rect(704, 420, 72, 170, 30))
    p.region("bacak_sol", rect(386, 630, 86, 90, 16))
    p.region("bacak_sag", rect(552, 630, 86, 90, 16))
    p.region("ayak_sol", rect(360, 700, 130, 50, 20))
    p.region("ayak_sag", rect(534, 700, 130, 50, 20))
    p.region("govde", rect(310, 400, 404, 250, 36))
    p.region("pano", rect(390, 440, 244, 130, 24))
    for k, x in enumerate((442, 512, 582)):
        p.region("dugme_%d" % (k + 1), circle(x, 505, 25))
    p.region("el_sol", circle(284, 614, 46))
    p.region("el_sag", circle(740, 614, 46))
    return p


# ============================ DOĞA ============================

def gunes() -> Page:
    p = Page("gunes", "doga")
    cx, cy = 512, 384
    for k in range(8):
        a = math.radians(-90 + 45 * k)
        tip = (cx + 330 * math.cos(a), cy + 330 * math.sin(a))
        b1 = (cx + 130 * math.cos(a - 0.27), cy + 130 * math.sin(a - 0.27))
        b2 = (cx + 130 * math.cos(a + 0.27), cy + 130 * math.sin(a + 0.27))
        p.region("isin_%d" % (k + 1), poly([b1, tip, b2]))
    p.region("gunes", circle(cx, cy, 160))
    p.eye(456, 360, 22, 28)
    p.eye(568, 360, 22, 28)
    p.detail(line("M452 430 Q512 482 572 430"))
    p.ink(ellipse(420, 424, 26, 14), "#FF9AB0")
    p.ink(ellipse(604, 424, 26, 14), "#FF9AB0")
    return p


def cicek() -> Page:
    p = Page("cicek", "doga")
    p.region("sap", path("M497 360 C486 500 520 600 500 730 L532 730 C552 600 520 500 529 360 Z"))
    p.region("yaprak_sol", path("M506 600 C440 520 350 540 318 580 C372 640 450 650 506 628 Z"))
    p.region("yaprak_sag", path("M520 520 C590 440 680 460 712 500 C660 560 580 570 520 548 Z"))
    p.region("saksi", path("M388 640 L636 640 L608 762 L416 762 Z"))
    for k in range(5):
        a = 90 + 72 * k
        x, y = 512 + 118 * math.cos(math.radians(a)), 280 + 118 * math.sin(math.radians(a))
        p.region("yaprak_%d" % (k + 1), ellipse(x, y, 88, 62, a))
    p.region("orta", circle(512, 280, 76))
    p.eye(484, 266, 14, 18)
    p.eye(540, 266, 14, 18)
    p.detail(line("M484 304 Q512 326 540 304"), 7)
    return p


def agac() -> Page:
    p = Page("agac", "doga")
    p.region("govde", path("M444 744 Q470 620 458 470 L566 470 Q554 620 580 744 Z"))
    p.region("cimen", path("M-20 650 Q300 620 512 640 Q760 664 1044 630 L1044 800 L-20 800 Z"))
    p.region("kovuk", ellipse(512, 590, 26, 36))
    p.region("tac", scallop(512, 290, 300, 206, 12))
    for k, (x, y) in enumerate(((380, 230), (560, 180), (660, 300), (440, 380), (600, 410))):
        p.region("elma_%d" % (k + 1), circle(x, y, 34))
        p.detail(line("M%d %d Q%d %d %d %d" % (x, y - 34, x + 4, y - 50, x + 14, y - 58)), 7)
    for k, x in enumerate((150, 870)):
        p.region("cicek_%d" % (k + 1), scallop(x, 704, 48, 48, 6, 0.7, -90))
        p.region("cicek_orta_%d" % (k + 1), circle(x, 704, 24))
    return p


def gokkusagi() -> Page:
    p = Page("gokkusagi", "doga")
    for k in range(8):
        a = math.radians(-90 + 45 * k)
        # Işın uçları sayfa kenarına değmesin (kenarla ışınlar arasında kapalı köşe kalır)
        tip = (850 + 150 * math.cos(a), 172 + 150 * math.sin(a))
        b1 = (850 + 38 * math.cos(a - 0.72), 172 + 38 * math.sin(a - 0.72))
        b2 = (850 + 38 * math.cos(a + 0.72), 172 + 38 * math.sin(a + 0.72))
        p.region("isin_%d" % (k + 1), poly([b1, tip, b2]))
    p.region("gunes", circle(850, 172, 56))
    cx, cy = 512, 640
    radii = [430, 378, 326, 274, 222, 170, 118]
    foot = 740    # bantlar tepelerin altına kadar iner: altta kapalı boşluk kalmaz
    r = radii[-1]
    p.region("ic", poly([(cx - r, foot)] + arc_points(cx, cy, r, r, 180, 360, 48) + [(cx + r, foot)]))
    for k in range(6):
        ro, ri = radii[k], radii[k + 1]
        outer = [(cx - ro, foot)] + arc_points(cx, cy, ro, ro, 180, 360, 64) + [(cx + ro, foot)]
        inner = [(cx + ri, foot)] + arc_points(cx, cy, ri, ri, 180, 360, 64)[::-1] + [(cx - ri, foot)]
        p.region("bant_%d" % (k + 1), poly(outer + inner))
    p.region("tepe_arka", path("M-20 660 Q250 560 560 650 Q800 720 1044 640 L1044 800 L-20 800 Z"))
    p.region("tepe_on", path("M-20 740 Q300 660 620 730 Q860 780 1044 730 L1044 800 L-20 800 Z"))
    p.region("bulut_1", scallop(170, 140, 120, 54, 9, flat=170))
    p.region("bulut_2", scallop(400, 90, 90, 40, 8, flat=110))
    p.eye(830, 164, 9, 12)
    p.eye(870, 164, 9, 12)
    p.detail(line("M832 190 Q850 202 868 190"), 7)
    return p


# ============================ ŞEKİLLER ============================

def sekiller() -> Page:
    p = Page("sekiller", "sekiller")
    p.region("daire", circle(190, 220, 126))
    p.region("kare", rect(397, 105, 230, 230, 20))
    p.region("ucgen", poly([(834, 90), (964, 336), (704, 336)]))
    p.region("oval", ellipse(190, 562, 140, 100))
    p.region("baklava", poly([(512, 420), (652, 562), (512, 704), (372, 562)]))
    p.region("altigen", regular(834, 562, 132, 6, 0))
    return p


def yildiz() -> Page:
    p = Page("yildiz", "sekiller")
    pts = star_points(512, 410, 310, 134)
    for k in range(5):
        p.region("kol_%d" % (k + 1), poly([pts[(2 * k - 1) % 10], pts[2 * k], pts[2 * k + 1]]))
    p.region("orta", poly([pts[k] for k in range(1, 10, 2)]))
    for k, (x, y) in enumerate(((120, 130), (904, 130), (126, 650), (898, 650))):
        p.region("kucuk_yildiz_%d" % (k + 1), poly(star_points(x, y, 72, 32, 5, -90 + 12 * (k - 1.5))))
    p.eye(476, 404, 16, 22)
    p.eye(548, 404, 16, 22)
    p.detail(line("M486 452 Q512 474 538 452"), 8)
    return p


def kalp() -> Page:
    p = Page("kalp", "sekiller")
    for k, s in enumerate((17.5, 12.0, 6.6)):
        p.region("kalp_%d" % (k + 1), poly(heart_points(512, 392, s)))
    spots = [(118, 110, 2.9), (906, 110, 2.9), (86, 384, 2.5), (938, 384, 2.5), (130, 660, 3.1), (894, 660, 3.1),
             (300, 700, 2.2), (724, 700, 2.2)]
    for k, (x, y, s) in enumerate(spots):
        p.region("minik_kalp_%d" % (k + 1), poly(heart_points(x, y, s, 60)))
    return p


def mandala() -> Page:
    p = Page("mandala", "sekiller")
    cx, cy = 512, 384
    for k in range(8):
        a = math.radians(22.5 + 45 * k)
        tip, base = 330, 120

        def at(r, side):
            return (cx + r * math.cos(a) - side * math.sin(a), cy + r * math.sin(a) + side * math.cos(a))

        b, t, l1, l2 = at(base, 0), at(tip, 0), at(250, 64), at(250, -64)
        c1, c2 = at(180, 70), at(180, -70)
        d = "M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z" % (
            f(b[0]), f(b[1]), f(c1[0]), f(c1[1]), f(l1[0]), f(l1[1]), f(at(300, 34)[0]), f(at(300, 34)[1]), f(t[0]), f(t[1]),
            f(at(300, -34)[0]), f(at(300, -34)[1]), f(l2[0]), f(l2[1]), f(c2[0]), f(c2[1]), f(b[0]), f(b[1]))
        p.region("dis_yaprak_%d" % (k + 1), path(d, (cx - 340, cy - 340, cx + 340, cy + 340)))
    p.region("disk", circle(cx, cy, 176))
    for k in range(8):
        a = 45 * k
        p.region("ic_yaprak_%d" % (k + 1), ellipse(cx + 96 * math.cos(math.radians(a)), cy + 96 * math.sin(math.radians(a)), 50, 26, a))
    p.region("orta", circle(cx, cy, 56))
    for k in range(8):
        a = math.radians(45 * k)
        p.region("nokta_%d" % (k + 1), circle(cx + 318 * math.cos(a), cy + 318 * math.sin(a), 26))
    return p


PAGES = [kedi, balik, tavsan, kaplumbaga, araba, tekne, ucak, tren, top, ucurtma, oyuncak_ayi, robot,
         gunes, cicek, agac, gokkusagi, sekiller, yildiz, kalp, mandala]

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    for make in PAGES:
        make().write()
