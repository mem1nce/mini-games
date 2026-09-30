# Kule Yapma SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre ve katlar/, manzara/ alt klasörlerine yazar; hayvanlar/ hafıza oyunundan kopya)
# Tarz hafıza oyunuyla uyumlu: yumuşak gradyanlar, parlama noktaları, yumuşak koyu dış çizgi.
# Katlar iki katmanlı: *_ic (pencere içleri, arkada) ve *_on (pencere delikleri açık duvar + çerçeveler, önde);
# hayvan ikisinin arasında durur. Kat tuvali 240x120 (üst üste tam 120 px), zemin kat 260x150, çatı 270x150.
# Not: Godot'nun SVG çizicisi bazı kübik eğrilerde degrade dolguyu kaybedebiliyor ve eğri kırpma içindeki ince
# çizgileri düşürebiliyor; bu yüzden duvarlar ve delikler çokgenle (evenodd), desenler pencerelerden kaçınan
# parçalarla çizilir, kırpma kullanılmaz.

import math
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
INK = "#3A2E52"


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


def star_pts(cx, cy, ro, ri, n=5, rot=-90.0):
    pts = []
    for k in range(n * 2):
        r = ro if k % 2 == 0 else ri
        a = math.radians(rot + k * 180.0 / n)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def circ_pts(cx, cy, r, n=36):
    return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)]


def rounded_rect_pts(x, y, w, h, r, n=5):
    pts = []
    for cx, cy, a0 in ((x + w - r, y + r, -90), (x + w - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)):
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def hilal(x1, y1, r1, x2, y2, r2, n=180):
    """Büyük daireden küçük daireyi çıkaran hilal çokgeni: büyüğün dışarıda kalan yayı + küçüğün içeride kalan yayı"""
    buyuk = [(x1 + r1 * math.cos(2 * math.pi * i / n), y1 + r1 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    disari = [math.hypot(x - x2, y - y2) >= r2 for x, y in buyuk]
    bas = next(i for i in range(n) if disari[i] and not disari[i - 1])
    yay = []
    i = bas
    while disari[i % n]:
        yay.append(buyuk[i % n])
        i += 1
    kucuk = [(x2 + r2 * math.cos(2 * math.pi * i / n), y2 + r2 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    ic = [math.hypot(x - x1, y - y1) <= r1 for x, y in kucuk]
    # küçük yayı, büyük yayın bittiği uçtan başlayıp içeride kaldığı sürece daire boyunca yürüyerek ekle
    son = yay[-1]
    j = min((k for k in range(n) if ic[k]), key=lambda k: math.dist(kucuk[k], son))
    adim = 1 if ic[(j + 1) % n] else -1
    iceri = []
    while ic[j % n] and len(iceri) < n:
        iceri.append(kucuk[j % n])
        j += adim
    return yay + iceri


def path_of(*polys):
    return " ".join("M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in p) + " Z" for p in polys)


# --- Katlar -------------------------------------------------------------------------------------------------

W, H = 240, 120
KARE = [(30, 24, 68, 64), (142, 24, 68, 64)]          # x, y, w, h
YUVARLAK = [(64, 56, 31), (176, 56, 31)]               # cx, cy, r


def delikler(pencere):
    if pencere == "yuvarlak":
        return [circ_pts(cx, cy, r) for cx, cy, r in YUVARLAK]
    return [rounded_rect_pts(x, y, w, h, 8) for x, y, w, h in KARE]


def pencere_kutusu(pencere):
    if pencere == "yuvarlak":
        return [(cx - r, cy - r, 2 * r, 2 * r) for cx, cy, r in YUVARLAK]
    return KARE


def ic(pencere):
    # Pencere içleri: sıcak oda ışığı, köşelerde perde
    s = Svg(W, H)
    for x, y, w, h in pencere_kutusu(pencere):
        rect(s, x - 4, y - 4, w + 8, h + 8, 10, s.lgrad(["#FFF1C8", "#FFD58A", "#E9A95A"]))
        poly(s, [(x - 2, y - 2), (x + 18, y - 2), (x + 4, y + 34)], "#FF8FB0", extra='opacity="0.9"')
        poly(s, [(x + w + 2, y - 2), (x + w - 18, y - 2), (x + w - 4, y + 34)], "#FF8FB0", extra='opacity="0.9"')
        rect(s, x - 4, y + h - 10, w + 8, 14, 0, "#C98A4A", extra='opacity="0.6"')
    write(f"katlar/ic_{pencere}.svg", s.text())


def _parca_disari(s, x0, x1, y, kutular, renk, sw, opak=0.5):
    """Yatay çizgi: pencereleri atlayarak parça parça"""
    parcalar = [(x0, x1)]
    for bx, by, bw, bh in kutular:
        if by - 6 <= y <= by + bh + 6:
            yeni = []
            for a, b in parcalar:
                if b <= bx - 6 or a >= bx + bw + 6:
                    yeni.append((a, b))
                else:
                    if a < bx - 6:
                        yeni.append((a, bx - 6))
                    if b > bx + bw + 6:
                        yeni.append((bx + bw + 6, b))
            parcalar = yeni
    for a, b in parcalar:
        if b - a > 3:
            s.add(f'<line x1="{a:.1f}" y1="{y:.1f}" x2="{b:.1f}" y2="{y:.1f}" stroke="{renk}" stroke-width="{sw}" stroke-linecap="round" opacity="{opak}"/>')


def _pencere_disinda(x, y, kutular, pay=8):
    return all(not (bx - pay <= x <= bx + bw + pay and by - pay <= y <= by + bh + pay) for bx, by, bw, bh in kutular)


TASARIMLAR = {
    # ad: (duvar açık, duvar koyu, çerçeve, desen, pencere)
    "tugla": ("#F29A7E", "#C65A4A", "#FFF6EC", "tugla", "kare"),
    "ahsap": ("#E8B57A", "#B87A42", "#FFF1D6", "ahsap", "kare"),
    "pembe": ("#FFD3E2", "#F29AB8", "#FFFFFF", "nokta", "kare"),
    "mavi": ("#BFE2FF", "#7FB2EC", "#FFFFFF", "kenar", "kare"),
    "balkon": ("#C8F0D8", "#7FCC9E", "#FFFFFF", "balkon", "kare"),
    "yuvarlak": ("#E2D4FF", "#A98BEA", "#FFF3C2", "kabarcik", "yuvarlak"),
    "tente": ("#FFF1D0", "#E6C88A", "#FFFFFF", "tente", "kare"),
    "tas": ("#DCDDE6", "#9EA2B6", "#FFFFFF", "tas", "kare"),
    "sarmasik": ("#FFE9A0", "#E6BE4A", "#FFFFFF", "sarmasik", "kare"),
    "cizgili": ("#A8ECE6", "#4FBFB6", "#FFFFFF", "cizgi", "yuvarlak"),
    "yildizli": ("#5E6AB8", "#34397A", "#FFE9A0", "yildiz", "kare"),
}


def on(ad):
    acik, koyu, cerceve, desen, pencere = TASARIMLAR[ad]
    s = Svg(W, H)
    kutular = pencere_kutusu(pencere)
    dis = rounded_rect_pts(2, 2, W - 4, H - 6, 8)
    s.add(f'<path d="{path_of(dis, *delikler(pencere))}" fill-rule="evenodd" fill="{s.lgrad([acik, koyu])}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    rng = random.Random(ad)
    if desen == "tugla":
        for i, y in enumerate(range(16, 108, 14)):
            _parca_disari(s, 6, W - 6, y, kutular, "#9E3E36", 2.2)
            for x in range(10 + (i % 2) * 14, W - 6, 28):
                if _pencere_disinda(x, y + 7, kutular, 10):
                    s.add(f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y + 14}" stroke="#9E3E36" stroke-width="2" opacity="0.45"/>')
    elif desen == "ahsap":
        for x in range(20, W - 8, 22):
            for y0, y1 in ((6, 22), (92, 108)):
                s.add(f'<line x1="{x}" y1="{y0}" x2="{x}" y2="{y1}" stroke="#8A5226" stroke-width="2.2" opacity="0.5"/>')
        for x in (16, 120, 224):
            s.add(f'<line x1="{x}" y1="10" x2="{x}" y2="106" stroke="#8A5226" stroke-width="2.2" opacity="0.4"/>')
    elif desen == "nokta":
        for _ in range(60):
            x, y = rng.uniform(10, W - 10), rng.uniform(10, H - 14)
            if _pencere_disinda(x, y, kutular, 10):
                circle(s, x, y, rng.uniform(2.5, 4.5), "#FFFFFF", extra='opacity="0.6"')
    elif desen == "kenar":
        rect(s, 4, 4, W - 8, 10, 4, "#FFFFFF", extra='opacity="0.7"')
    elif desen == "kabarcik":
        for _ in range(26):
            x, y = rng.uniform(12, W - 12), rng.uniform(12, H - 16)
            if _pencere_disinda(x, y, kutular, 12):
                circle(s, x, y, rng.uniform(3, 7), "none", "#FFFFFF", 2, 'stroke-opacity="0.6"')
    elif desen == "tas":
        for y in (22, 46, 70, 94):
            _parca_disari(s, 6, W - 6, y, kutular, "#6E7290", 2.2)
    elif desen == "cizgi":
        for x in range(14, W - 8, 24):
            if _pencere_disinda(x, 60, kutular, 4):
                rect(s, x - 5, 8, 10, H - 20, 5, "#FFFFFF", extra='opacity="0.35"')
    elif desen == "yildiz":
        for _ in range(26):
            x, y = rng.uniform(12, W - 12), rng.uniform(12, H - 16)
            if _pencere_disinda(x, y, kutular, 12):
                poly(s, star_pts(x, y, rng.uniform(3.5, 6), 2, 5), "#FFE9A0", extra='opacity="0.85"')
    # Pencere çerçeveleri ve denizlikler
    if pencere == "yuvarlak":
        for cx, cy, r in YUVARLAK:
            circle(s, cx, cy, r + 2, "none", INK, 9)
            circle(s, cx, cy, r + 2, "none", cerceve, 5)
    else:
        for x, y, w, h in KARE:
            rect(s, x - 1, y - 1, w + 2, h + 2, 9, "none", INK, 9)
            rect(s, x - 1, y - 1, w + 2, h + 2, 9, "none", cerceve, 5)
            rect(s, x - 8, y + h + 3, w + 16, 9, 4, s.lgrad([cerceve, "#D8D2E6"]), INK, 2.6)
    if desen == "balkon":
        for x, y, w, h in KARE:
            rect(s, x - 8, y + h - 20, w + 16, 7, 3, "#FFFFFF", INK, 2.4)
            for bx in range(int(x - 2), int(x + w + 6), 10):
                rect(s, bx, y + h - 14, 4, 17, 2, "#FFFFFF", INK, 1.6)
            for k, fx in enumerate((x + 6, x + w - 6)):
                rect(s, fx - 7, y + h - 30, 14, 11, 3, "#E0845A", INK, 1.8)
                for a in range(5):
                    ang = math.radians(a * 72)
                    circle(s, fx + 4.5 * math.cos(ang), y + h - 34 + 4.5 * math.sin(ang), 3.6, ["#FF7FA8", "#FFE066"][k], INK, 1.2)
    if desen == "tente":
        for x, y, w, h in KARE:
            for i in range(6):
                renk = "#FF6B6B" if i % 2 == 0 else "#FFFFFF"
                x0 = x - 8 + i * (w + 16) / 6
                x1 = x - 8 + (i + 1) * (w + 16) / 6
                poly(s, [(x0 + 4, y - 16), (x1 + 4, y - 16), (x1, y + 6), (x0, y + 6)], renk)
            poly(s, [(x - 4, y - 16), (x + w + 12, y - 16), (x + w + 8, y + 6), (x - 8, y + 6)], "none", INK, 2.6)
            for i in range(6):
                cx = x - 8 + (i + 0.5) * (w + 16) / 6
                circle(s, cx, y + 8, 4, "#FF6B6B" if i % 2 == 0 else "#FFFFFF", INK, 1.4)
    if desen == "sarmasik":
        for x0 in (8, 120, 226):
            pts = [(x0 + 5 * math.sin(t / 7.0), 8 + t) for t in range(0, 100, 5)]
            pline(s, pts, "#2F8A3E", 3)
            for i, (px, py) in enumerate(pts[::3]):
                ellipse(s, px + (6 if i % 2 else -6), py, 6, 3.6, "#5CC46A", "#2F8A3E", 1.4, 30 if i % 2 else -30)
    # Kat tabanı (katları birbirinden ayıran silme)
    rect(s, 0, H - 12, W, 12, 4, s.lgrad([koyu, "#6E5A70"]), INK, 3)
    shine(s, 40, 12, 26, 3.5, 0, 0.45)
    write(f"katlar/kat_{ad}.svg", s.text())


def zemin_kat():
    # 260x150: ortada kapı, iki yanda pencere, basamaklar
    s = Svg(260, 150)
    kutular = [(22, 30, 64, 60), (174, 30, 64, 60)]
    dis = rounded_rect_pts(2, 2, 256, 138, 8)
    delik = [rounded_rect_pts(x, y, w, h, 8) for x, y, w, h in kutular]
    s.add(f'<path d="{path_of(dis, *delik)}" fill-rule="evenodd" fill="{s.lgrad(["#FFE3B8", "#E8B26A"])}" stroke="{INK}" stroke-width="4"/>')
    for y in (20, 44, 68, 92, 116):
        _parca_disari(s, 6, 254, y, kutular + [(100, 40, 60, 110)], "#C48A4A", 2, 0.35)
    for x, y, w, h in kutular:
        rect(s, x - 1, y - 1, w + 2, h + 2, 9, "none", INK, 9)
        rect(s, x - 1, y - 1, w + 2, h + 2, 9, "none", "#FFFFFF", 5)
        rect(s, x - 8, y + h + 3, w + 16, 9, 4, "#FFFFFF", INK, 2.6)
    # kapı
    s.add(f'<path d="M100 140 L100 70 Q100 42 130 42 Q160 42 160 70 L160 140 Z" fill="{s.lgrad(["#6FB8FF", "#3A7ED8"], 0, 0, 1, 0)}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    rect(s, 108, 76, 44, 58, 6, "none", "#FFFFFF", 2.4, 'stroke-opacity="0.5"')
    circle(s, 148, 104, 4.5, "#FFD23F", INK, 1.6)
    circle(s, 130, 58, 8, "#FFF1C8", INK, 2)
    # basamak ve temel
    rect(s, 92, 136, 76, 10, 3, "#C9CFDC", INK, 2.4)
    rect(s, 0, 138, 260, 12, 4, s.lgrad(["#A8A2B8", "#7E7894"]), INK, 3)
    # çalılar
    for x in (10, 250):
        for dx, r in ((-8, 12), (8, 12), (0, 16)):
            circle(s, x + dx, 128, r, s.rgrad(["#9BE27A", "#3FA85A"], 0.4, 0.3, 0.8), "#2A6E3A", 2)
    shine(s, 50, 14, 30, 4, 0, 0.45)
    write("katlar/kat_zemin.svg", s.text())
    s = Svg(260, 150)
    for x, y, w, h in kutular:
        rect(s, x - 4, y - 4, w + 8, h + 8, 10, s.lgrad(["#FFF1C8", "#FFD58A", "#E9A95A"]))
        poly(s, [(x - 2, y - 2), (x + 18, y - 2), (x + 4, y + 30)], "#8FD4FF", extra='opacity="0.9"')
        poly(s, [(x + w + 2, y - 2), (x + w - 18, y - 2), (x + w - 4, y + 30)], "#8FD4FF", extra='opacity="0.9"')
    write("katlar/ic_zemin.svg", s.text())


def cati():
    # 270x150: kiremit çatı, baca, yuvarlak çatı penceresi, bayrak
    s = Svg(270, 150)
    delik = circ_pts(135, 96, 24)
    dis = [(6, 146), (135, 26), (264, 146)]
    rect(s, 196, 30, 26, 60, 4, s.lgrad(["#E8866A", "#B8503E"], 0, 0, 1, 0), INK, 3.4)
    rect(s, 190, 24, 38, 12, 4, "#8A3A2E", INK, 3)
    s.add(f'<path d="{path_of(dis, delik)}" fill-rule="evenodd" fill="{s.lgrad(["#FF8A6A", "#D8483E"])}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')
    for i, y in enumerate(range(52, 146, 18)):
        genislik = (y - 26) / 120 * 129
        _parca_disari(s, 135 - genislik + 8, 135 + genislik - 8, y, [(111, 72, 48, 48)], "#A8352E", 2.4, 0.55)
    circle(s, 135, 96, 26, "none", INK, 9)
    circle(s, 135, 96, 26, "none", "#FFF3C2", 5)
    rect(s, 0, 138, 270, 12, 5, s.lgrad(["#8A5A70", "#5E3E52"]), INK, 3)
    pline(s, [(135, 26), (135, 2)], INK, 3)
    poly(s, [(136, 3), (160, 9), (136, 16)], "#FFD23F", INK, 2.4)
    shine(s, 110, 60, 26, 5, -43, 0.35)
    write("katlar/kat_cati.svg", s.text())
    s = Svg(270, 150)
    circle(s, 135, 96, 28, s.lgrad(["#FFF1C8", "#FFD58A", "#E9A95A"]))
    write("katlar/ic_cati.svg", s.text())


# --- Vinç -------------------------------------------------------------------------------------------------

def crane():
    # 760x250: solda direk ve kabin, ekran boyunca kol (kafes), sol uçta karşı ağırlık
    s = Svg(760, 250)
    sari = s.lgrad(["#FFE27A", "#FFC23A", "#F29A1E"])
    # direk (üstten iner)
    rect(s, 70, -10, 40, 150, 10, sari, INK, 4)
    for y in range(0, 130, 24):
        pline(s, [(74, y + 4), (106, y + 20)], "#C9780E", 3)
    # askı halatları
    pline(s, [(90, 0), (740, 118)], "#6E6888", 3)
    pline(s, [(90, 0), (10, 118)], "#6E6888", 3)
    # kol: iki çubuk + zikzak
    rect(s, 0, 112, 760, 20, 10, sari, INK, 4)
    rect(s, 0, 148, 760, 20, 10, sari, INK, 4)
    zik = [(10 + i * 30, 130 if i % 2 == 0 else 150) for i in range(26)]
    pline(s, zik, INK, 7)
    pline(s, zik, "#FFC23A", 4)
    # karşı ağırlık
    rect(s, 2, 164, 70, 50, 10, s.lgrad(["#A8A2B8", "#6E6888"]), INK, 4)
    for x in (18, 36, 54):
        pline(s, [(x, 172), (x, 206)], "#FFFFFF", 3, 'opacity="0.4"')
    # kabin
    rect(s, 92, 164, 96, 70, 16, s.lgrad(["#FF9A5A", "#F2702E"]), INK, 4)
    rect(s, 106, 176, 68, 34, 10, s.lgrad(["#E8F8FF", "#9FD8F5"]), INK, 3)
    shine(s, 124, 184, 12, 4, -20, 0.8)
    circle(s, 140, 222, 5, "#FFD23F", INK, 1.8)
    shine(s, 120, 120, 60, 3, 0, 0.55)
    shine(s, 400, 154, 80, 3, 0, 0.4)
    write("vinc.svg", s.text())
    # makara arabası + kanca (100x110): arabanın tepesi kolun alt çubuğunda, kanca ucu (50, 104)
    s = Svg(100, 110)
    rect(s, 14, 4, 72, 26, 10, s.lgrad(["#FF9A5A", "#F2702E"]), INK, 3.4)
    for x in (30, 70):
        circle(s, x, 6, 7, s.rgrad(["#FFFFFF", "#A8A2B8", "#6E6888"], 0.4, 0.35, 0.8), INK, 2.4)
    pline(s, [(50, 30), (50, 62)], "#6E6888", 3)
    circle(s, 50, 70, 14, s.rgrad(["#FFE27A", "#F29A1E"], 0.4, 0.35, 0.8), INK, 3)
    circle(s, 50, 70, 5, "#8A5A20")
    s.add(f'<path d="M50 84 L50 94 Q50 104 60 104" fill="none" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>')
    s.add('<path d="M50 84 L50 94 Q50 104 60 104" fill="none" stroke="#C9CFDC" stroke-width="3.4" stroke-linecap="round"/>')
    write("makara.svg", s.text())


# --- Manzara ------------------------------------------------------------------------------------------------

def scenery():
    rng = random.Random(3)
    # Tepeler ve köy (900x320)
    s = Svg(900, 320)
    pts = [(x, 150 + 40 * math.sin(x / 150.0) + 20 * math.sin(x / 57.0)) for x in range(0, 901, 20)] + [(900, 320), (0, 320)]
    poly(s, pts, s.lgrad(["#B8E39A", "#8FCC6E"]))
    pts = [(x, 220 + 30 * math.sin(x / 120.0 + 2.0)) for x in range(0, 901, 20)] + [(900, 320), (0, 320)]
    poly(s, pts, s.lgrad(["#9BD87A", "#6FB84E"]))
    for x, y in ((120, 190), (330, 165), (560, 200), (760, 170)):
        rect(s, x - 26, y - 30, 52, 36, 4, rng.choice(["#FFE3B8", "#FFD3E2", "#DDEBFF"]), INK, 2.6)
        poly(s, [(x - 32, y - 28), (x, y - 54), (x + 32, y - 28)], rng.choice(["#E8534A", "#6FA8FF", "#8A5A70"]), INK, 2.6)
        rect(s, x - 8, y - 16, 16, 22, 3, "#8A5A34", INK, 2)
    for x, y in ((60, 230), (230, 210), (450, 235), (660, 225), (850, 215)):
        rect(s, x - 4, y, 8, 22, 3, "#8A5A34", INK, 2)
        circle(s, x, y - 6, 22, s.rgrad(["#9BE27A", "#3FA85A"], 0.4, 0.3, 0.8), "#2A6E3A", 2.4)
    write("manzara/tepeler.svg", s.text())
    # Şehir çatıları (900x360)
    s = Svg(900, 360)
    x = 0
    renkler = ["#FFB3A0", "#A8D8FF", "#FFE08A", "#C8B6FF", "#A8EEC8", "#FFC6DE"]
    i = 0
    while x < 900:
        w = rng.randint(80, 130)
        h = rng.randint(140, 320)
        rect(s, x + 3, 360 - h, w - 6, h + 10, 8, renkler[i % len(renkler)], INK, 3)
        for wy in range(360 - h + 22, 350, 34):
            for wx in range(int(x + 16), int(x + w - 20), 26):
                rect(s, wx, wy, 14, 18, 3, "#FFF3C2" if rng.random() < 0.6 else "#6E7496", INK, 1.4)
        if rng.random() < 0.5:
            poly(s, [(x + 3, 362 - h), (x + w / 2, 362 - h - 36), (x + w - 3, 362 - h)], "#E8534A", INK, 3)
        else:
            rect(s, x + w - 34, 360 - h - 26, 16, 28, 3, "#8A92A8", INK, 2)
        x += w
        i += 1
    write("manzara/sehir.svg", s.text())
    # Bulut
    s = Svg(220, 110)
    for cx, cy, r in ((66, 66, 34), (110, 48, 42), (156, 66, 32), (110, 76, 36)):
        circle(s, cx, cy, r, s.rgrad(["#FFFFFF", "#EEF1FB"], 0.4, 0.3, 0.8))
    write("manzara/bulut.svg", s.text())
    # Kuş (kanatlar açık)
    s = Svg(80, 50)
    ellipse(s, 40, 30, 14, 10, s.rgrad(["#FFFFFF", "#9FD0FF"], 0.4, 0.3, 0.8), INK, 2.4)
    poly(s, [(34, 26), (10, 10), (22, 30)], "#9FD0FF", INK, 2.2)
    poly(s, [(46, 26), (70, 10), (58, 30)], "#9FD0FF", INK, 2.2)
    poly(s, [(52, 30), (62, 32), (52, 35)], "#FFB020", INK, 1.6)
    circle(s, 46, 27, 2.4, INK)
    write("manzara/kus.svg", s.text())
    # Sıcak hava balonu: gövde, renkli dikey şeritler, halatlar, sepet
    s = Svg(140, 200)
    balon = []
    for t in range(41):
        a = math.radians(360 * t / 40)
        balon.append((70 + 60 * math.cos(a), 66 + 60 * math.sin(a) * (1.1 if math.sin(a) > 0 else 1.0)))
    poly(s, balon, s.rgrad(["#FFB0A8", "#FF6B6B", "#D8483E"], 0.4, 0.3, 0.8), INK, 3)
    for i, k in enumerate((-0.66, -0.2, 0.2, 0.66)):
        pts = [(70 + 60 * k * math.cos(math.radians(90 - 180 * t / 20)), 66 - 60 * math.sin(math.radians(90 - 180 * t / 20)) * (1.1 if t > 10 else 1.0)) for t in range(21)]
        pline(s, pts, ["#FFD23F", "#4FA8FF", "#5CC95C", "#FFFFFF"][i], 7)
    for x0, x1 in ((24, 56), (116, 84)):
        pline(s, [(x0, 118), (x1, 162)], "#6E5A40", 2)
    rect(s, 50, 158, 40, 30, 6, s.lgrad(["#D9A56A", "#8A5A34"]), INK, 3)
    shine(s, 44, 40, 14, 8, -30, 0.5)
    write("manzara/balon.svg", s.text())
    # Gün batımı güneşi
    s = Svg(240, 240)
    circle(s, 120, 120, 112, s.rgrad(["#FFE9A0", "#FFE9A0"], 0.5, 0.5, 0.5, opacities=[0.6, 0]))
    circle(s, 120, 120, 70, s.rgrad(["#FFF3C2", "#FFB347", "#FF7A45"], 0.45, 0.4, 0.8))
    write("manzara/gunes.svg", s.text())
    # Ay (hilal) ve parıltı
    s = Svg(160, 160)
    circle(s, 80, 80, 76, s.rgrad(["#FFF6C2", "#FFF6C2"], 0.5, 0.5, 0.5, opacities=[0.45, 0]))
    poly(s, hilal(80, 80, 48, 100, 66, 40), s.rgrad(["#FFFFFF", "#FFF1B0", "#EED27A"], 0.4, 0.35, 0.8), "#B8A060", 3)
    write("manzara/ay.svg", s.text())
    # Gezegen
    s = Svg(200, 140)
    ellipse(s, 100, 76, 90, 20, "none", "#FFD3A0", 8, -12)
    circle(s, 100, 70, 44, s.rgrad(["#FFC6DE", "#FF7FB5", "#C84A86"], 0.4, 0.3, 0.8), INK, 3)
    s.add(f'<path d="M14 90 Q100 110 186 58" fill="none" stroke="#FFD3A0" stroke-width="8" stroke-linecap="round"/>')
    shine(s, 86, 50, 12, 6, -30, 0.5)
    write("manzara/gezegen.svg", s.text())
    # Zemin şeritleri (temaya göre, 900x240)
    for ad, renkler in (("cayir", ["#9BE27A", "#5FB84A"]), ("sahil", ["#FBE7B5", "#E8C88A"]),
                        ("kar", ["#FFFFFF", "#D6E6F7"]), ("sehir", ["#B8BCD0", "#8A8FA8"])):
        s = Svg(900, 240)
        rect(s, 0, 20, 900, 220, 0, s.lgrad(renkler), INK, 0)
        pline(s, [(x, 20 + 4 * math.sin(x / 30.0)) for x in range(0, 901, 10)], INK, 4)
        r2 = random.Random(ad)
        for _ in range(40):
            x, y = r2.uniform(10, 890), r2.uniform(40, 230)
            if ad == "cayir":
                c = r2.choice(["#FFFFFF", "#FFE066", "#FF9CC2"])
                for k in range(5):
                    a = math.radians(k * 72)
                    circle(s, x + 4 * math.cos(a), y + 4 * math.sin(a), 3, c)
                circle(s, x, y, 2.4, "#FFB020")
            elif ad == "sahil":
                circle(s, x, y, 2.4, r2.choice(["#FFFFFF", "#F7B7A3"]))
            elif ad == "kar":
                poly(s, star_pts(x, y, 4, 1.4, 4, 0), "#FFFFFF")
            else:
                rect(s, x, y, 26, 4, 2, "#FFFFFF", extra='opacity="0.4"')
        write(f"manzara/zemin_{ad}.svg", s.text())


# --- Hayvan işleri, efektler, arayüz ---------------------------------------------------------------------------

def props():
    s = Svg(80, 80)   # Zzz
    for x, y, k in ((20, 60, 16), (40, 40, 20), (60, 18, 24)):
        pline(s, [(x - k / 2, y - k / 2), (x + k / 2, y - k / 2), (x - k / 2, y + k / 2), (x + k / 2, y + k / 2)], INK, 7)
        pline(s, [(x - k / 2, y - k / 2), (x + k / 2, y - k / 2), (x - k / 2, y + k / 2), (x + k / 2, y + k / 2)], "#8FD4FF", 3.6)
    write("isler/zzz.svg", s.text())
    s = Svg(90, 90)   # tencere
    for x in (34, 50, 62):
        pline(s, [(x, 30), (x - 4, 20), (x + 2, 10)], "#FFFFFF", 5, 'opacity="0.9"')
    rect(s, 12, 38, 66, 40, 12, s.lgrad(["#FF8A6A", "#D8483E"]), INK, 3.4)
    rect(s, 8, 32, 74, 10, 5, "#8A92A8", INK, 3)
    rect(s, 2, 46, 12, 8, 4, "#8A92A8", INK, 2.4)
    rect(s, 76, 46, 12, 8, 4, "#8A92A8", INK, 2.4)
    write("isler/tencere.svg", s.text())
    s = Svg(90, 70)   # kitap
    poly(s, [(45, 16), (8, 8), (8, 58), (45, 64)], s.lgrad(["#FFFFFF", "#EEE8F8"], 0, 0, 1, 0), INK, 3)
    poly(s, [(45, 16), (82, 8), (82, 58), (45, 64)], s.lgrad(["#EEE8F8", "#FFFFFF"], 0, 0, 1, 0), INK, 3)
    for y in (22, 32, 42):
        pline(s, [(14, y - 2), (38, y + 2)], "#A8A2C8", 2.4)
        pline(s, [(52, y + 2), (76, y - 2)], "#A8A2C8", 2.4)
    rect(s, 42, 14, 6, 52, 3, "#FF6B6B", INK, 2)
    write("isler/kitap.svg", s.text())
    s = Svg(100, 80)  # sulama kabı
    rect(s, 20, 30, 50, 40, 10, s.lgrad(["#8FE08A", "#3FA85A"]), INK, 3.4)
    poly(s, [(68, 44), (94, 22), (98, 28), (72, 56)], "#6FCF7A", INK, 3)
    s.add(f'<path d="M30 30 Q44 6 60 30" fill="none" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>')
    s.add('<path d="M30 30 Q44 6 60 30" fill="none" stroke="#6FCF7A" stroke-width="3.4" stroke-linecap="round"/>')
    write("isler/sulama.svg", s.text())
    s = Svg(60, 70)   # müzik notası
    rect(s, 38, 8, 7, 44, 3, "#A66BFF", INK, 2.4)
    ellipse(s, 30, 54, 13, 10, "#A66BFF", INK, 2.6, -20)
    poly(s, [(40, 8), (56, 16), (56, 26), (42, 20)], "#A66BFF", INK, 2.4)
    write("isler/nota.svg", s.text())
    s = Svg(60, 60)   # çiçek
    for k in range(5):
        a = math.radians(k * 72 - 90)
        circle(s, 30 + 11 * math.cos(a), 26 + 11 * math.sin(a), 9, "#FF7FA8", INK, 2)
    circle(s, 30, 26, 7, "#FFD23F", INK, 2)
    pline(s, [(30, 36), (30, 58)], "#3FA85A", 4)
    write("isler/cicek.svg", s.text())


def fx_ui():
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
    s = Svg(128, 128)
    circle(s, 64, 64, 54, "none", "#FFFFFF", 12)
    write("halka.svg", s.text())
    s = Svg(96, 96)
    for cx, cy, r in ((34, 56, 24), (60, 50, 28), (48, 36, 22)):
        circle(s, cx, cy, r, s.rgrad(["#FFFFFF", "#EEE6DA", "#D8CDB8"], 0.4, 0.35, 0.8))
    write("toz.svg", s.text())
    s = Svg(96, 96)
    for x in (34, 62):
        rect(s, x - 9, 26, 18, 44, 7, "#6B8AF0", INK, 4)
    write("duraklat.svg", s.text())
    s = Svg(96, 96)
    poly(s, [(34, 22), (76, 48), (34, 74)], "#4FC45F", INK, 5)
    write("oynat.svg", s.text())
    # Apartman simgesi (galeri, apartmanım)
    s = Svg(120, 120)
    rect(s, 26, 34, 68, 80, 8, s.lgrad(["#FFD3E2", "#F29AB8"]), INK, 4)
    poly(s, [(18, 38), (60, 8), (102, 38)], "#E8534A", INK, 4)
    for x, y in ((38, 48), (64, 48), (38, 74), (64, 74)):
        rect(s, x, y, 18, 18, 4, "#FFF1C8", INK, 2.4)
    rect(s, 50, 96, 20, 18, 4, "#6FB8FF", INK, 2.4)
    write("apartman.svg", s.text())
    # İlerleme çubuğunun tepesindeki kule simgesi
    s = Svg(80, 100)
    rect(s, 18, 34, 44, 60, 6, s.lgrad(["#FFE3B8", "#E8B26A"]), INK, 3.4)
    poly(s, [(12, 38), (40, 10), (68, 38)], "#FF6B6B", INK, 3.4)
    for y in (46, 66):
        for x in (26, 44):
            rect(s, x, y, 10, 12, 3, "#FFF1C8", INK, 2)
    write("kule_ikon.svg", s.text())
    # Taç (rekor işareti)
    s = Svg(80, 64)
    poly(s, [(8, 54), (8, 18), (26, 36), (40, 8), (54, 36), (72, 18), (72, 54)], s.lgrad(["#FFF1A6", "#FFC23A", "#E09A00"]), INK, 4)
    for x in (8, 40, 72):
        circle(s, x, 14 if x != 40 else 6, 5, "#FF6B6B", INK, 2)
    write("tac.svg", s.text())


if __name__ == "__main__":
    ic("kare")
    ic("yuvarlak")
    for ad in TASARIMLAR:
        on(ad)
    zemin_kat()
    cati()
    crane()
    scenery()
    props()
    fx_ui()
    print("tamam")
