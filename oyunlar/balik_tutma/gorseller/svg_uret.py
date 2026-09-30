# Balık Tutma SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre ve baliklar/, ikonlar/ alt klasörlerine yazar)
# Tarz hafıza oyunuyla uyumlu: yumuşak gradyanlar, parlama noktaları, yumuşak koyu dış çizgi, büyük parlak gözler.
# Penguen hafıza oyunundaki penguenden (temalar/hayvanlar/penguen.svg) türetildi: oltalı, mutlu, şaşkın halleri.
# Not: Godot'nun SVG çizicisi iki kontrol noktası aynı yükseklikte olan kübik eğrinin degrade dolgusunu çizmiyor
# ve eğri kırpma içindeki ince çizgileri kaybedebiliyor; bu yüzden desenler dolu şekillerle, ağ örgüsü kırpmasız
# (hesaplanmış çizgi parçalarıyla) çizilir.

import math
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
INK = "#2E2A4F"


class Svg:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.defs = []
        self.body = []
        self.n = 0

    def _id(self):
        self.n += 1
        return f"g{self.n}"

    def _stops(self, colors, opacities=None):
        out = ""
        for i, c in enumerate(colors):
            op = f' stop-opacity="{opacities[i]}"' if opacities else ""
            out += f'<stop offset="{i / max(1, len(colors) - 1):.2f}" stop-color="{c}"{op}/>'
        return out

    def rgrad(self, colors, cx=0.4, cy=0.32, r=0.75, opacities=None):
        gid = self._id()
        self.defs.append(f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}">{self._stops(colors, opacities)}</radialGradient>')
        return f"url(#{gid})"

    def lgrad(self, colors, x1=0.0, y1=0.0, x2=0.0, y2=1.0, opacities=None):
        gid = self._id()
        self.defs.append(f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{self._stops(colors, opacities)}</linearGradient>')
        return f"url(#{gid})"

    def clip(self, inner):
        gid = self._id()
        self.defs.append(f'<clipPath id="{gid}">{inner}</clipPath>')
        return f"url(#{gid})"

    def add(self, s):
        self.body.append(s)

    def text(self):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}">\n'
                f'  <defs>{"".join(self.defs)}</defs>\n  ' + "\n  ".join(self.body) + "\n</svg>\n")


def write(rel, text):
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


def pline(s, pts, color, sw, extra=""):
    p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    s.add(f'<polyline points="{p}" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" {extra}/>')


def shine(s, cx, cy, rx, ry, angle=-30, opacity=0.55):
    s.add(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" transform="rotate({angle} {cx:.1f} {cy:.1f})" fill="#FFFFFF" opacity="{opacity}"/>')


def shadow(s, cx, cy, rx, ry, opacity=0.28):
    g = s.rgrad(["#1A1633", "#1A1633"], 0.5, 0.5, 0.5, opacities=[opacity, 0])
    s.add(f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{g}"/>')


def star_pts(cx, cy, ro, ri, n=5, rot=-90.0):
    pts = []
    for k in range(n * 2):
        r = ro if k % 2 == 0 else ri
        a = math.radians(rot + k * 180.0 / n)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def ell_pts(cx, cy, rx, ry, a0=0, a1=360, steps=36):
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / steps)),
             cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / steps))) for i in range(steps + 1)]


def eye(s, cx, cy, r, look=(1, 0)):
    """Büyük parlak göz (hafıza tarzı)"""
    circle(s, cx, cy, r, s.rgrad(["#FFFFFF", "#EEF0FA"], 0.4, 0.35, 0.8), INK, max(1.6, r * 0.16))
    ir = r * 0.72
    ix, iy = cx + look[0] * r * 0.18, cy + look[1] * r * 0.18
    circle(s, ix, iy, ir, s.rgrad(["#6A5A96", "#2A1F45", "#150F26"], 0.4, 0.35, 0.7))
    circle(s, ix - ir * 0.32, iy - ir * 0.36, ir * 0.36, "#FFFFFF")
    circle(s, ix + ir * 0.35, iy + ir * 0.35, ir * 0.16, "#FFFFFF", extra='opacity="0.85"')


# --- Penguen (hafıza oyunundaki penguenden) -------------------------------------------------------------

PEN_DEFS = {}


def _penguen_base(s, kanat_sol, kanat_sag):
    ten = s.rgrad(["#7686CC", "#4656A0", "#2A346C"], 0.35, 0.25, 0.8)
    beyaz = s.rgrad(["#FFFFFF", "#E3E9F7"], 0.45, 0.35, 0.75)
    # kanatlar (açı: ellipse dönüşü)
    for cx, cy, a in (kanat_sol, kanat_sag):
        ellipse(s, cx, cy, 14, 34, ten, "#1E2448", 6, a)
    # gövde ve kafa tek dış hat
    s.add(f'<g fill="{ten}" stroke="#1E2448" stroke-width="14"><ellipse cx="128" cy="110" rx="70" ry="64"/><ellipse cx="128" cy="190" rx="62" ry="46"/></g>')
    s.add(f'<g fill="{ten}"><ellipse cx="128" cy="110" rx="70" ry="64"/><ellipse cx="128" cy="190" rx="62" ry="46"/></g>')
    ellipse(s, 128, 200, 44, 34, beyaz)
    s.add(f'<path d="M128 86 C108 60 64 70 66 116 C68 154 100 170 128 170 C156 170 188 154 190 116 C192 70 148 60 128 86 Z" fill="{beyaz}"/>')
    ellipse(s, 92, 66, 18, 7, "#FFFFFF", angle=-25, extra='opacity="0.35"')
    return ten


def _sapka(s):
    # Sarı balıkçı şapkası
    sari = s.rgrad(["#FFF1A6", "#FFD23F", "#E0A000"], 0.4, 0.3, 0.8)
    ellipse(s, 128, 58, 84, 16, sari, "#8A5A00", 5)
    s.add(f'<path d="M78 58 Q80 16 128 14 Q176 16 178 58 Z" fill="{sari}" stroke="#8A5A00" stroke-width="5" stroke-linejoin="round"/>')
    s.add('<path d="M84 50 Q128 40 172 50" fill="none" stroke="#FF8A5A" stroke-width="8" stroke-linecap="round"/>')
    shine(s, 104, 28, 16, 6, -20, 0.5)


def _yanak(s):
    y = s.rgrad(["#FF7FA3", "#FF7FA3"], 0.5, 0.5, 0.5, opacities=[0.85, 0])
    ellipse(s, 84, 140, 15, 10, y)
    ellipse(s, 172, 140, 15, 10, y)


def _gaga(s, acik=False):
    tur = s.rgrad(["#FFD98A", "#F5921F"], 0.4, 0.3, 0.8)
    if acik:
        s.add(f'<path d="M112 132 Q128 122 144 132 L136 138 Q128 134 120 138 Z" fill="{tur}" stroke="#A85A0A" stroke-width="3.5" stroke-linejoin="round"/>')
        s.add(f'<path d="M118 141 Q128 137 138 141 Q134 156 128 157 Q122 156 118 141 Z" fill="#E86A5A" stroke="#A85A0A" stroke-width="3.5" stroke-linejoin="round"/>')
        s.add(f'<path d="M120 142 Q128 139 136 142 L134 147 Q128 144 122 147 Z" fill="{tur}"/>')
    else:
        s.add(f'<path d="M114 134 Q128 124 142 134 Q136 148 128 150 Q120 148 114 134 Z" fill="{tur}" stroke="#A85A0A" stroke-width="3.5" stroke-linejoin="round"/>')
        ellipse(s, 123, 133, 5, 2.5, "#FFFFFF", extra='opacity="0.7"')


def _gozler(s, hal):
    if hal == "mutlu":
        for x in (102, 154):
            s.add(f'<path d="M{x - 14} 118 Q{x} 98 {x + 14} 118" fill="none" stroke="#1E1733" stroke-width="7" stroke-linecap="round"/>')
    elif hal == "saskin":
        for x in (102, 154):
            ellipse(s, x, 112, 17, 20, "#FFFFFF", "#1E1733", 3)
            circle(s, x, 114, 8, s.rgrad(["#6A5A96", "#150F26"], 0.4, 0.35, 0.7))
            circle(s, x - 3, 110, 3, "#FFFFFF")
    else:
        goz = s.rgrad(["#6A5A96", "#2A1F45", "#150F26"], 0.4, 0.35, 0.7)
        for x in (102, 154):
            ellipse(s, x + 3, 116, 15, 18, goz)       # suya (sağ aşağı) bakıyor
            ellipse(s, x - 2, 108, 6, 7, "#FFFFFF")
            circle(s, x + 8, 123, 3, "#FFFFFF", extra='opacity="0.85"')


def penguins():
    for hal, sol, sag in (
        ("olta", (62, 176, 28), (196, 158, -62)),        # sağ kanat öne uzanmış (oltayı tutar)
        ("mutlu", (52, 140, 150), (204, 140, -150)),     # kanatlar havada
        ("saskin", (56, 170, 60), (200, 170, -60)),
    ):
        s = Svg(256, 256)
        _penguen_base(s, sol, sag)
        _gozler(s, hal)
        _yanak(s)
        _gaga(s, acik=hal != "olta")
        _sapka(s)
        write(f"penguen_{hal}.svg", s.text())


# --- Kayık, kova, geri dönüşüm, olta, ağ ------------------------------------------------------------------

def boat():
    # 320x140. Arka iç duvar ayrı (penguen ve kova arasına girer), ön gövde ayrı.
    s = Svg(320, 140)
    s.add(f'<path d="M24 40 L296 40 L286 60 L34 60 Z" fill="{s.lgrad(["#9A5E32", "#6E4020"])}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    write("kayik_arka.svg", s.text())
    s = Svg(320, 140)
    hull = "M14 44 L306 44 Q300 100 250 120 L70 120 Q20 100 14 44 Z"
    s.add(f'<path d="{hull}" fill="{s.lgrad(["#FF8A6A", "#E8534A", "#B7353A"])}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')
    # tahta şeritler
    for y in (70, 92):
        s.add(f'<path d="M{24 + (y - 44) * 0.2:.0f} {y} L{296 - (y - 44) * 0.2:.0f} {y}" stroke="#9C2E33" stroke-width="3" opacity="0.6"/>')
    # beyaz şerit ve kenar
    s.add(f'<rect x="10" y="38" width="300" height="14" rx="7" fill="{s.lgrad(["#FFFFFF", "#E3E6F2"])}" stroke="{INK}" stroke-width="4"/>')
    s.add('<path d="M40 104 Q160 112 280 104" stroke="#FFFFFF" stroke-width="7" fill="none" stroke-linecap="round" opacity="0.8"/>')
    circle(s, 262, 76, 10, s.rgrad(["#FFFFFF", "#CFE6FF"], 0.4, 0.35, 0.8), INK, 3)
    circle(s, 262, 76, 5, "#6AB6FF")
    shine(s, 80, 60, 30, 5, 0, 0.35)
    write("kayik_on.svg", s.text())


def bucket():
    s = Svg(90, 100)
    s.add(f'<path d="M20 34 Q45 -4 70 34" fill="none" stroke="#6E7496" stroke-width="5" stroke-linecap="round"/>')
    s.add(f'<path d="M12 34 L78 34 L70 94 L20 94 Z" fill="{s.lgrad(["#6AB6FF", "#3E8EEB", "#2466C2"], 0, 0, 1, 0)}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    ellipse(s, 45, 34, 33, 9, s.lgrad(["#BDE8FF", "#6ACAF5"]), INK, 4)
    rect(s, 16, 56, 58, 8, 4, "#FFFFFF", extra='opacity="0.35"')
    shine(s, 28, 70, 5, 14, 0, 0.35)
    write("kova.svg", s.text())
    s = Svg(90, 100)
    s.add(f'<path d="M10 22 L80 22 L72 96 L18 96 Z" fill="{s.lgrad(["#8FE08A", "#4FC45F", "#2A8A3E"], 0, 0, 1, 0)}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    rect(s, 4, 12, 82, 14, 6, s.lgrad(["#6FD07A", "#2F9A48"]), INK, 4)
    # geri dönüşüm okları (üç ok, üçgen)
    cx, cy, r = 45, 60, 18
    for k in range(3):
        a = math.radians(-90 + k * 120)
        b = math.radians(-90 + k * 120 + 95)
        pts = [(cx + r * math.cos(a + (b - a) * t / 10), cy + r * math.sin(a + (b - a) * t / 10)) for t in range(11)]
        pline(s, pts, "#FFFFFF", 6)
        ex, ey = pts[-1]
        tx, ty = -math.sin(b), math.cos(b)
        nx, ny = math.cos(b), math.sin(b)
        poly(s, [(ex + tx * 9, ey + ty * 9), (ex + nx * 7 - tx * 2, ey + ny * 7 - ty * 2), (ex - nx * 7 - tx * 2, ey - ny * 7 - ty * 2)], "#FFFFFF")
    shine(s, 22, 44, 4, 14, 0, 0.35)
    write("geri_donusum.svg", s.text())


def rod():
    # 260x36, sap solda (0,18), uç sağda (256,18)
    s = Svg(260, 36)
    s.add(f'<path d="M6 12 L256 16 L256 20 L6 24 Z" fill="{s.lgrad(["#F2D38A", "#C9965A", "#A0703A"])}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
    for x in (70, 140, 200):
        rect(s, x - 3, 11, 6, 14, 2, "#8A5A34")
    rect(s, 2, 8, 50, 20, 8, s.lgrad(["#6E7496", "#3E3856"]), INK, 3)
    circle(s, 40, 26, 9, s.rgrad(["#FFFFFF", "#C9CFDC", "#7E86A0"], 0.35, 0.3, 0.8), INK, 2.4)
    circle(s, 254, 18, 4, "#E8534A", INK, 1.6)
    write("olta.svg", s.text())


def _ellipse_chords(cx, cy, rx, ry, y_min, direction, spacing):
    """Elips içinde kalan (y >= y_min) eğik çizgi parçaları: ağ örgüsü (kırpmasız)"""
    segs = []
    for k in range(-12, 13):
        off = k * spacing
        pts = []
        for i in range(200):
            t = -1.0 + 2.0 * i / 199
            x = cx + t * rx * 1.4
            y = cy + (x - cx) * direction + off
            inside = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 and y >= y_min
            if inside:
                pts.append((x, y))
            elif pts:
                if len(pts) > 1:
                    segs.append(pts)
                pts = []
        if len(pts) > 1:
            segs.append(pts)
    return segs


def net(lantern=False):
    # 120x150: ipin bağlandığı nokta (60, 6); halka (60, 50); torba aşağıda
    s = Svg(120, 150)
    for x in (22, 98):
        pline(s, [(60, 6), (x, 48)], "#6E7496", 2.4)
    pline(s, [(60, 6), (60, 44)], "#6E7496", 2.4)
    bag_c, bag_rx, bag_ry = (60, 50), 40, 92
    bag = ell_pts(60, 50, bag_rx, bag_ry, 0, 180, 30)
    poly(s, bag, "#FFFFFF", None, extra='opacity="0.28"')
    for d in (1.0, -1.0):
        for seg in _ellipse_chords(60, 50, bag_rx - 1, bag_ry - 1, 52, d, 11):
            pline(s, seg, "#E9F4FF", 1.8, 'opacity="0.95"')
    pline(s, bag, "#B9CCE6", 2.4)
    # halka (şamandıra renkli)
    ellipse(s, 60, 50, 44, 12, "none", INK, 10)
    ellipse(s, 60, 50, 44, 12, "none", "#FF8A5A", 6)
    for a in (0, 90, 180, 270):
        x = 60 + 44 * math.cos(math.radians(a + 45))
        y = 50 + 12 * math.sin(math.radians(a + 45))
        circle(s, x, y, 3.4, "#FFFFFF")
    if lantern:
        rect(s, 52, 10, 16, 20, 5, s.lgrad(["#FFF6B0", "#FFD23F"]), INK, 2.4)
        rect(s, 50, 6, 20, 6, 3, "#6E7496", INK, 2)
        circle(s, 60, 20, 5, "#FFFFFF", extra='opacity="0.9"')
    write("ag_fener.svg" if lantern else "ag.svg", s.text())


# --- Balıklar -----------------------------------------------------------------------------------------------

RENKLER = {
    # açık, orta, koyu, dış çizgi
    "kirmizi": ("#FFA8A8", "#F2545E", "#B82E3C", "#5E1422"),
    "mavi": ("#AEDBFF", "#4AA3FF", "#2466C2", "#12305E"),
    "sari": ("#FFF3A6", "#FFD23F", "#E0A000", "#6E4E00"),
    "yesil": ("#B6F2B4", "#4FC45F", "#2A8A3E", "#12451E"),
    "turuncu": ("#FFD0A0", "#FF8A3D", "#D05A10", "#5E2A08"),
    "mor": ("#DCC6FF", "#A66BFF", "#6E3EC2", "#321A5E"),
    "pembe": ("#FFC6DE", "#FF7FB5", "#D04A86", "#5E1A3A"),
    "herhangi": ("#FFFFFF", "#DDE6F2", "#AEBBD0", "#4A5470"),
    "altin": ("#FFF6C2", "#FFD23F", "#C99A0E", "#5E4200"),
    "lacivert": ("#9EB0FF", "#3E4FB8", "#232C78", "#10143E"),
    "gece": ("#5A6496", "#2E3666", "#1A1F44", "#0C0F24"),
}
DESEN_RENGI = {"kirmizi": "#FFFFFF", "mavi": "#FFFFFF", "sari": "#FF8A3D", "yesil": "#FFF3A6", "turuncu": "#FFFFFF",
               "mor": "#FFF3A6", "pembe": "#FFFFFF", "herhangi": "#8C98B4", "lacivert": "#FFE066", "altin": "#FFFFFF"}

# ad: (renk, desen, boyut, gövde, ışık rengi)
TURLER = {
    "mavi_minik": ("mavi", "duz", "kucuk", "uzun", None),
    "kirmizi_top": ("kirmizi", "duz", "orta", "yuvarlak", None),
    "sari_minik": ("sari", "duz", "kucuk", "yuvarlak", None),
    "yesil_uzun": ("yesil", "duz", "orta", "uzun", None),
    "mavi_cizgili": ("mavi", "cizgili", "orta", "yuvarlak", None),
    "kirmizi_benekli": ("kirmizi", "benekli", "orta", "yuvarlak", None),
    "sari_cizgili": ("sari", "cizgili", "orta", "uzun", None),
    "yesil_benekli": ("yesil", "benekli", "kucuk", "yuvarlak", None),
    "palyaco": ("turuncu", "cizgili", "kucuk", "yuvarlak", None),
    "mor_yassi": ("mor", "duz", "orta", "yassi", None),
    "pembe_benekli": ("pembe", "benekli", "kucuk", "yuvarlak", None),
    "mavi_dev": ("mavi", "duz", "buyuk", "uzun", None),
    "kirmizi_dev": ("kirmizi", "cizgili", "buyuk", "yuvarlak", None),
    "balon": ("sari", "benekli", "buyuk", "balon", None),
    "yesil_dev": ("yesil", "cizgili", "buyuk", "uzun", None),
    "mor_benekli": ("mor", "benekli", "kucuk", "yassi", None),
    "turuncu_dev": ("turuncu", "benekli", "buyuk", "yuvarlak", None),
    "pembe_cizgili": ("pembe", "cizgili", "orta", "yassi", None),
    "altin": ("altin", "duz", "orta", "yuvarlak", None),
    "gokkusagi": ("gokkusagi", "gokkusagi", "orta", "uzun", None),
    "yildizli": ("lacivert", "yildiz", "orta", "yuvarlak", None),
    "fener": ("gece", "isikli", "buyuk", "fener", "#FFE066"),
    "isikli_mavi": ("gece", "isikli", "kucuk", "uzun", "#7FF0FF"),
    "isikli_pembe": ("gece", "isikli", "kucuk", "yuvarlak", "#FF9CE0"),
    "isikli_yesil": ("gece", "isikli", "orta", "yassi", "#A8FF8A"),
}

GOVDE = {
    # merkez x, y, yarıçaplar
    "yuvarlak": (86, 62, 48, 36),
    "uzun": (88, 62, 58, 25),
    "yassi": (88, 62, 38, 36),
    "balon": (88, 62, 44, 42),
    "fener": (90, 66, 46, 38),
}
GOKKUSAGI = ["#FF6B6B", "#FFB347", "#FFE066", "#7ED67E", "#6AB6FF", "#A98BFF"]


def fish_svg(renk, desen, govde, isik=None, icon=False):
    s = Svg(160, 124)
    cx, cy, rx, ry = GOVDE[govde]
    if renk == "gokkusagi":
        light, mid, dark, out = "#FFFFFF", "#FFB347", "#D05A10", "#4A2A5E"
        body = s.lgrad(GOKKUSAGI, 0, 0, 1, 0)
    else:
        light, mid, dark, out = RENKLER[renk]
        body = s.rgrad([light, mid, dark], 0.42, 0.3, 0.8)
    fin = s.lgrad([mid, dark], 0, 0, 1, 1)
    tail_x = cx - rx + 8
    # kuyruk
    poly(s, [(tail_x, cy), (tail_x - 40, cy - 30), (tail_x - 28, cy), (tail_x - 40, cy + 30)], fin, out, 4)
    # sırt ve karın yüzgeci
    if govde == "yassi":
        poly(s, [(cx - 22, cy - ry + 6), (cx - 6, cy - ry - 20), (cx + 16, cy - ry + 4)], fin, out, 4)
        poly(s, [(cx - 22, cy + ry - 6), (cx - 6, cy + ry + 20), (cx + 16, cy + ry - 4)], fin, out, 4)
    else:
        poly(s, [(cx - rx * 0.45, cy - ry + 5), (cx - rx * 0.05, cy - ry - 18), (cx + rx * 0.3, cy - ry + 3)], fin, out, 4)
        poly(s, [(cx - rx * 0.2, cy + ry - 5), (cx, cy + ry + 12), (cx + rx * 0.2, cy + ry - 4)], fin, out, 3.4)
    if govde == "balon":
        for k in range(14):
            a = math.radians(k * 360 / 14 + 8)
            x, y = cx + rx * math.cos(a), cy + ry * math.sin(a)
            poly(s, [(x + 7 * math.cos(a), y + 7 * math.sin(a)), (x + 4 * math.cos(a + 1.3), y + 4 * math.sin(a + 1.3)),
                     (x + 4 * math.cos(a - 1.3), y + 4 * math.sin(a - 1.3))], mid, out, 2)
    if govde == "fener":
        pline(s, [(cx + 10, cy - ry + 4), (cx + 22, cy - ry - 22), (cx + 44, cy - ry - 26), (cx + 56, cy - ry - 14)], out, 5)
        pline(s, [(cx + 10, cy - ry + 4), (cx + 22, cy - ry - 22), (cx + 44, cy - ry - 26), (cx + 56, cy - ry - 14)], "#6E7496", 2.4)
        circle(s, cx + 57, cy - ry - 10, 14, isik, extra='opacity="0.3"')
        circle(s, cx + 57, cy - ry - 10, 8, s.rgrad(["#FFFFFF", isik], 0.4, 0.35, 0.8), out, 2)
    # gövde
    ellipse(s, cx, cy, rx, ry, body, out, 4)
    # desen (gövdeye kırpılı dolu şekiller)
    clip = s.clip(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx - 2}" ry="{ry - 2}"/>')
    dc = DESEN_RENGI.get(renk, "#FFFFFF")
    if desen == "cizgili":
        parts = "".join(f'<polygon points="{x - 5},{cy - ry - 4} {x + 5},{cy - ry - 4} {x + 1},{cy + ry + 4} {x - 9},{cy + ry + 4}" fill="{dc}"/>'
                        for x in (cx - rx * 0.45, cx - rx * 0.05, cx + rx * 0.3))
        s.add(f'<g clip-path="{clip}" opacity="0.8">{parts}</g>')
    elif desen == "benekli":
        rng = random.Random(renk + govde)
        parts = ""
        for x, y, r in ((cx - rx * 0.5, cy - ry * 0.3, 6), (cx - rx * 0.1, cy + ry * 0.35, 7), (cx - rx * 0.15, cy - ry * 0.5, 5),
                        (cx + rx * 0.2, cy + ry * 0.1, 5), (cx - rx * 0.55, cy + ry * 0.35, 4.5), (cx + rx * 0.05, cy - ry * 0.05, 4)):
            parts += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r * (ry / 34.0) ** 0.5:.1f}" fill="{dc}"/>'
        s.add(f'<g clip-path="{clip}" opacity="0.85">{parts}</g>')
    elif desen == "yildiz":
        parts = ""
        for x, y, r in ((cx - rx * 0.45, cy - ry * 0.2, 8), (cx - rx * 0.05, cy + ry * 0.4, 7), (cx - rx * 0.1, cy - ry * 0.5, 6), (cx + rx * 0.2, cy + ry * 0.05, 6)):
            parts += f'<polygon points="{" ".join(f"{px:.1f},{py:.1f}" for px, py in star_pts(x, y, r, r * 0.45))}" fill="{dc}"/>'
        s.add(f'<g clip-path="{clip}">{parts}</g>')
    elif desen == "isikli":
        for x, y in ((cx - rx * 0.45, cy + ry * 0.2), (cx - rx * 0.05, cy + ry * 0.45), (cx - rx * 0.2, cy - ry * 0.35), (cx + rx * 0.2, cy + ry * 0.35)):
            circle(s, x, y, 7, isik, extra='opacity="0.35"')
            circle(s, x, y, 3.6, isik)
    # karın ışığı ve parlama
    ellipse(s, cx + 4, cy + ry * 0.45, rx * 0.62, ry * 0.3, "#FFFFFF", extra='opacity="0.25"')
    shine(s, cx - rx * 0.25, cy - ry * 0.55, rx * 0.35, ry * 0.12, -12, 0.55)
    # yan yüzgeç (gözün arkasında, açık renkli)
    ellipse(s, cx + rx * 0.1, cy + ry * 0.28, 10, 5.5, s.lgrad([light, mid], 0, 0, 1, 1), out, 2.2, -25)
    # göz, ağız, yanak
    er = max(9.0, min(15.0, ry * 0.36)) if not icon else max(8.0, ry * 0.3)
    eye(s, cx + rx * 0.52, cy - ry * 0.18, er, (0.6, 0.2))
    mx, my = cx + rx * 0.86, cy + ry * 0.2
    s.add(f'<path d="M{mx - 7:.1f} {my:.1f} Q{mx - 2:.1f} {my + 5:.1f} {mx + 3:.1f} {my - 1:.1f}" fill="none" stroke="{out}" stroke-width="2.6" stroke-linecap="round"/>')
    ellipse(s, cx + rx * 0.5, cy + ry * 0.32, 7, 4, "#FF7FA3", extra='opacity="0.5"')
    return s.text()


def fishes():
    for ad, (renk, desen, boyut, govde, isik) in TURLER.items():
        write(f"baliklar/{ad}.svg", fish_svg(renk, desen, govde, isik))


def icons():
    # Görev siluetleri: renk × desen (renk istenmeyince "herhangi"), ışıklı balık simgesi
    for renk in ["kirmizi", "mavi", "sari", "yesil", "turuncu", "mor", "pembe", "herhangi"]:
        for desen in ["duz", "cizgili", "benekli"]:
            write(f"ikonlar/ikon_{renk}_{desen}.svg", fish_svg(renk, desen, "yuvarlak", icon=True))
    write("ikonlar/ikon_isikli.svg", fish_svg("gece", "isikli", "uzun", "#7FF0FF", icon=True))


# --- Çöpler, denizanası -----------------------------------------------------------------------------------

def trash():
    s = Svg(60, 120)   # plastik şişe
    rect(s, 22, 4, 16, 14, 4, s.lgrad(["#6AB6FF", "#2466C2"]), INK, 3)
    s.add(f'<path d="M20 18 L40 18 L44 34 Q52 40 52 52 L52 108 Q52 116 44 116 L16 116 Q8 116 8 108 L8 52 Q8 40 16 34 Z" fill="{s.lgrad(["#E8FAFF", "#B8E4F2", "#8CC8DE"], 0, 0, 1, 0)}" stroke="{INK}" stroke-width="3.4" stroke-linejoin="round" opacity="0.95"/>')
    rect(s, 8, 62, 44, 22, 3, s.lgrad(["#FF8A6A", "#E8534A"]), INK, 2.4)
    s.add('<path d="M16 72 L44 72" stroke="#FFFFFF" stroke-width="3" opacity="0.8"/>')
    shine(s, 18, 48, 3, 10, 0, 0.7)
    write("cop_sise.svg", s.text())
    s = Svg(100, 110)  # poşet
    s.add(f'<path d="M18 30 L82 30 L90 100 Q90 106 84 106 L16 106 Q10 106 10 100 Z" fill="{s.lgrad(["#FFFFFF", "#E6ECF4"])}" stroke="{INK}" stroke-width="3.4" stroke-linejoin="round" opacity="0.9"/>')
    s.add('<path d="M22 30 Q22 6 38 8 Q46 10 42 30" fill="none" stroke="#4A5470" stroke-width="7" stroke-linecap="round"/>')
    s.add('<path d="M22 30 Q22 6 38 8 Q46 10 42 30" fill="none" stroke="#FFFFFF" stroke-width="3.4" stroke-linecap="round"/>')
    s.add('<path d="M58 30 Q56 6 72 8 Q80 10 78 30" fill="none" stroke="#4A5470" stroke-width="7" stroke-linecap="round"/>')
    s.add('<path d="M58 30 Q56 6 72 8 Q80 10 78 30" fill="none" stroke="#FFFFFF" stroke-width="3.4" stroke-linecap="round"/>')
    for x in (34, 52, 70):
        s.add(f'<path d="M{x} 44 L{x - 4} 96" stroke="#C6D0E0" stroke-width="2.4" stroke-linecap="round"/>')
    circle(s, 50, 66, 12, "#6FCF7A", extra='opacity="0.7"')
    write("cop_poset.svg", s.text())
    s = Svg(64, 100)   # teneke kutu
    rect(s, 8, 12, 48, 80, 8, s.lgrad(["#C9CFDC", "#FFFFFF", "#AEB6C6", "#7E86A0"], 0, 0, 1, 0), INK, 3.4)
    rect(s, 8, 34, 48, 36, 2, s.lgrad(["#FFD23F", "#FF8A3D"], 0, 0, 1, 0))
    ellipse(s, 32, 12, 24, 7, s.lgrad(["#FFFFFF", "#AEB6C6"]), INK, 3)
    ellipse(s, 38, 11, 7, 3, "#6E7496")
    s.add('<path d="M12 42 L52 42 M12 62 L52 62" stroke="#FFFFFF" stroke-width="2.4" opacity="0.6"/>')
    write("cop_teneke.svg", s.text())


def jelly():
    s = Svg(120, 170)
    pink = s.rgrad(["#FFE0F0", "#FF9CCB", "#E86AA8"], 0.4, 0.3, 0.8)
    for k, x in enumerate((30, 46, 60, 74, 90)):
        pts = [(x + 6 * math.sin(t / 6.0 + k), 70 + t) for t in range(0, 90, 6)]
        pline(s, pts, "#C85A94", 7, 'opacity="0.8"')
        pline(s, pts, "#FFC6E2", 3.4)
    s.add(f'<path d="M12 72 Q12 12 60 10 Q108 12 108 72 Q96 80 84 72 Q72 80 60 72 Q48 80 36 72 Q24 80 12 72 Z" fill="{pink}" stroke="#8A2A5E" stroke-width="4" stroke-linejoin="round" opacity="0.95"/>')
    shine(s, 40, 30, 16, 7, -30, 0.6)
    for x in (46, 74):
        circle(s, x, 50, 7, "#3A1F45")
        circle(s, x - 2, 47, 2.6, "#FFFFFF")
    s.add('<path d="M52 60 Q60 66 68 60" fill="none" stroke="#3A1F45" stroke-width="3" stroke-linecap="round"/>')
    ellipse(s, 34, 60, 7, 4, "#FF7FA3", extra='opacity="0.6"')
    ellipse(s, 86, 60, 7, 4, "#FF7FA3", extra='opacity="0.6"')
    write("denizanasi.svg", s.text())


# --- Dip ve yüzey süsleri -----------------------------------------------------------------------------------

def decor():
    # Yosun (uzun, dalgalı)
    for ad, renkler in (("yosun", ["#8FE08A", "#3FA85A", "#1E6B3C"]), ("yosun_koyu", ["#6FB88A", "#2F6E58", "#1B4238"])):
        s = Svg(80, 220)
        for k, (x0, h, ph) in enumerate(((26, 200, 0.0), (48, 170, 1.4), (60, 130, 2.6))):
            pts_l, pts_r = [], []
            for i in range(21):
                t = i / 20
                y = 216 - h * t
                x = x0 + 9 * math.sin(t * 5 + ph) * t
                w = 9 * (1 - t) + 2
                pts_l.append((x - w, y))
                pts_r.append((x + w, y))
            poly(s, pts_l + pts_r[::-1], s.lgrad(renkler, 0, 0, 1, 0), "#12452A", 2.6)
        write(f"{ad}.svg", s.text())
    # Sazlık (göl)
    s = Svg(90, 220)
    for x, h in ((24, 200), (44, 180), (64, 150)):
        rect(s, x - 3, 216 - h, 6, h, 3, s.lgrad(["#9BD86A", "#4F9A3A"], 0, 0, 1, 0), "#2F5A20", 2)
        rect(s, x - 7, 216 - h - 6, 14, 40, 7, s.lgrad(["#B98A5A", "#7A4E2A"], 0, 0, 1, 0), "#4A2A12", 2.4)
    write("sazlik.svg", s.text())
    # Mercanlar
    for ad, renkler in (("mercan_pembe", ["#FFC6DE", "#FF7FB5", "#D04A86"]), ("mercan_turuncu", ["#FFD0A0", "#FF8A3D", "#D05A10"]),
                        ("mercan_mor", ["#DCC6FF", "#A66BFF", "#6E3EC2"])):
        s = Svg(140, 150)
        g = s.lgrad(renkler, 0, 0, 1, 0)

        def dal(x, y, a, ln, w, d):
            x2 = x + ln * math.cos(math.radians(a))
            y2 = y + ln * math.sin(math.radians(a))
            pline(s, [(x, y), (x2, y2)], "#4A2A4A", w + 4)
            pline(s, [(x, y), (x2, y2)], renkler[1], w)
            circle(s, x2, y2, w * 0.55, renkler[0])
            if d > 0:
                dal(x2, y2, a - 28, ln * 0.72, w * 0.75, d - 1)
                dal(x2, y2, a + 26, ln * 0.7, w * 0.75, d - 1)
        dal(70, 146, -90, 44, 14, 3)
        shine(s, 60, 90, 6, 14, 0, 0.3)
        write(f"{ad}.svg", s.text())
    # Taşlar
    s = Svg(160, 110)
    for dx, dy, rr in ((-34, 14, 30), (30, 18, 26), (0, 0, 40)):
        pts = []
        for k in range(8):
            a = math.radians(k * 45 + 10)
            q = rr * (0.85 + 0.15 * math.sin(k * 2.1))
            pts.append((80 + dx + q * math.cos(a) * 1.2, 66 + dy + q * math.sin(a) * 0.8))
        poly(s, pts, s.rgrad(["#C9CFDC", "#8A92A8", "#5C6480"], 0.35, 0.3, 0.8), INK, 3)
        shine(s, 80 + dx - rr * 0.35, 66 + dy - rr * 0.4, rr * 0.25, rr * 0.1, -20, 0.5)
    write("taslar.svg", s.text())
    # Deniz yıldızı, istiridye
    s = Svg(70, 70)
    poly(s, star_pts(35, 36, 32, 13), s.rgrad(["#FFC6A0", "#FF8A5A", "#D05A30"], 0.4, 0.35, 0.8), INK, 3)
    for x, y in ((35, 22), (24, 34), (46, 34), (30, 46), (40, 46)):
        circle(s, x, y, 2.4, "#FFF1D0")
    write("deniz_yildizi.svg", s.text())
    s = Svg(80, 60)
    s.add(f'<path d="M8 50 L40 6 L72 50 Z" fill="{s.rgrad(["#FFF1F4", "#FFC6D2", "#E88AA0"], 0.5, 0.3, 0.9)}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
    for x in (20, 30, 40, 50, 60):
        s.add(f'<line x1="40" y1="8" x2="{x}" y2="50" stroke="#D07A90" stroke-width="2"/>')
    circle(s, 40, 44, 7, s.rgrad(["#FFFFFF", "#E8E6F4"], 0.4, 0.35, 0.8), INK, 2)
    write("istiridye.svg", s.text())
    # Parlayan derin deniz bitkisi
    s = Svg(80, 200)
    for x0, h in ((24, 180), (50, 140)):
        pts = [(x0 + 6 * math.sin(i / 3.0), 196 - h * i / 20) for i in range(21)]
        pline(s, pts, "#1A2A44", 8)
        pline(s, pts, "#2E5A7A", 4)
        for i in (8, 14, 20):
            x, y = pts[i]
            circle(s, x, y, 10, "#7FF0FF", extra='opacity="0.25"')
            circle(s, x, y, 5, "#BFFAFF")
    write("isikli_bitki.svg", s.text())
    # Nilüfer yaprağı (göl yüzeyi)
    s = Svg(120, 50)
    ellipse(s, 60, 26, 54, 18, s.rgrad(["#B6F2B4", "#4FC45F", "#2A8A3E"], 0.4, 0.3, 0.8), "#12451E", 3)
    poly(s, [(60, 26), (114, 20), (112, 32)], "#6ACAF5")
    circle(s, 44, 20, 9, "#FFFFFF", "#E07AA0", 2)
    circle(s, 44, 20, 4, "#FFD35A")
    write("nilufer.svg", s.text())
    # Bulut, güneş, ay
    s = Svg(200, 100)
    for x, y, r in ((60, 62, 32), (100, 46, 40), (142, 62, 30), (100, 70, 34)):
        circle(s, x, y, r, s.rgrad(["#FFFFFF", "#F2F4FC"], 0.4, 0.3, 0.8))
    s.add('<path d="M36 90 L166 90" stroke="#D9DEF0" stroke-width="3" stroke-linecap="round"/>')
    write("bulut.svg", s.text())
    s = Svg(140, 140)
    for k in range(12):
        a = math.radians(k * 30)
        pline(s, [(70 + 44 * math.cos(a), 70 + 44 * math.sin(a)), (70 + 62 * math.cos(a), 70 + 62 * math.sin(a))], "#FFD23F", 7)
    circle(s, 70, 70, 36, s.rgrad(["#FFF6C2", "#FFD23F", "#F5A800"], 0.4, 0.35, 0.8), "#C98A00", 4)
    shine(s, 58, 56, 10, 5, -35, 0.6)
    write("gunes.svg", s.text())
    s = Svg(120, 120)
    circle(s, 60, 60, 40, s.rgrad(["#FFFFFF", "#FFF3C2", "#E8D38A"], 0.4, 0.35, 0.8), "#B8A060", 3)
    circle(s, 76, 50, 34, "#2E3666")
    write("ay.svg", s.text())


# --- Arayüz ve efektler ------------------------------------------------------------------------------------

def ui():
    s = Svg(96, 96)
    for x in (34, 62):
        rect(s, x - 9, 26, 18, 44, 7, "#6B8AF0", INK, 4)
    write("duraklat.svg", s.text())
    s = Svg(96, 96)
    poly(s, [(34, 22), (76, 48), (34, 74)], "#4FC45F", INK, 5)
    write("oynat.svg", s.text())
    # Akvaryum simgesi
    s = Svg(120, 110)
    shadow(s, 60, 102, 50, 6)
    rect(s, 10, 14, 100, 84, 16, s.lgrad(["#D8F4FF", "#8FD4F5", "#4AA3E8"]), INK, 5)
    rect(s, 14, 78, 92, 16, 8, s.lgrad(["#F7E3B0", "#E0C080"]))
    for x in (28, 90):
        pline(s, [(x, 90), (x - 4, 72), (x + 3, 56)], "#3FA85A", 5)
    poly(s, [(58, 50), (46, 42), (48, 50), (46, 58)], "#FF8A3D", INK, 2.4)
    ellipse(s, 68, 50, 14, 10, s.rgrad(["#FFD0A0", "#FF8A3D"], 0.4, 0.3, 0.8), INK, 2.6)
    circle(s, 73, 47, 3, "#1E1733")
    for x, y, r in ((86, 36, 4), (92, 26, 3), (84, 20, 2.4)):
        circle(s, x, y, r, "none", "#FFFFFF", 2)
    rect(s, 6, 8, 108, 12, 6, s.lgrad(["#8C98B4", "#5C6480"]), INK, 4)
    shine(s, 26, 34, 6, 14, 0, 0.45)
    write("akvaryum.svg", s.text())
    # Görev baloncuğu yok (kodla çizilir). Efektler:
    s = Svg(64, 64)
    circle(s, 32, 32, 26, s.rgrad(["#FFFFFF", "#DDF4FF", "#AEE0FF"], 0.35, 0.3, 0.8, opacities=[0.35, 0.18, 0.5]), "#FFFFFF", 3)
    shine(s, 24, 22, 7, 4, -35, 0.9)
    write("kabarcik.svg", s.text())
    s = Svg(40, 56)
    s.add(f'<path d="M20 4 Q36 30 34 40 Q32 52 20 52 Q8 52 6 40 Q4 30 20 4 Z" fill="{s.lgrad(["#E8FAFF", "#8FD4F5"])}" stroke="#4AA3E8" stroke-width="2.4"/>')
    write("damla.svg", s.text())
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
    # Işık huzmesi (su altında)
    s = Svg(120, 600)
    s.add(f'<polygon points="40,0 80,0 120,600 0,600" fill="{s.lgrad(["#FFFFFF", "#FFFFFF"], 0, 0, 0, 1, opacities=[0.55, 0])}"/>')
    write("huzme.svg", s.text())


if __name__ == "__main__":
    penguins()
    boat()
    bucket()
    rod()
    net(False)
    net(True)
    fishes()
    icons()
    trash()
    jelly()
    decor()
    ui()
    print("tamam")
