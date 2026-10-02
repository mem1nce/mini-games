# Uçan Kuş görsellerini üretir. Proje kökünden:  python oyunlar/ucan_kus/gorseller/svg_uret.py
# Sonra Godot'ta içe aktar (yildiz, bulut_engel, gunes, ay: 2x + mipmap; diğerleri 1x).
#
# 1) Sütunlar: direk_<bolge>_<ince|orta|kalin>.svg  (her bölgenin kendi sütunu; ucu yuvarlak, başlıksız)
#    Genişlikler ucan_kus.gd PIPE_WIDTHS ile aynı olmalı (dokunun yanlarında KENAR px pay var).
# 2) Kayan arka plan katmanları: katman_<bolge>_<uzak|orta|yakin>.svg  (KARO px genişlikte, yatayda dikişsiz)
# 3) bulut_engel.svg (uykulu bulut engel), yildiz.svg (toplanan yıldız), gunes.svg, ay.svg
#
# Bölgeler: orman, sehir, kar, sahil, gece. Arka plan katmanları çerçevesiz ve soluk (derinlik hissi),
# engeller koyu çerçeveli ve canlı renkli çizilir ki öne çıksın.

import math
import os
import random

BURASI = os.path.dirname(os.path.abspath(__file__))
KARO = 1280                       # katman karosunun genişliği
GENISLIKLER = {"ince": 84, "orta": 120, "kalin": 164}
KENAR = 6                         # sütunun iki yanındaki çerçeve payı
BOY = 1400                        # sütun dokusunun yüksekliği (uç yukarıda)


def yaz(ad, icerik):
    with open(os.path.join(BURASI, ad), "w", encoding="utf-8", newline="\n") as f:
        f.write(icerik)


def svg(w, h, govde, defs=""):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n'
            '%s%s</svg>\n' % (w, h, w, h, ("<defs>%s</defs>\n" % defs) if defs else "", govde))


def degrade(kimlik, ust, alt, yatay=False):
    x2, y2 = ("1", "0") if yatay else ("0", "1")
    return ('<linearGradient id="%s" x1="0" y1="0" x2="%s" y2="%s"><stop offset="0" stop-color="%s"/>'
            '<stop offset="1" stop-color="%s"/></linearGradient>' % (kimlik, x2, y2, ust, alt))


# --- Sütunlar ---

def sutun(bolge, kalinlik):
    w = GENISLIKLER[kalinlik]
    tw = w + 2 * KENAR
    x0, x1 = KENAR, KENAR + w
    cizim = SUTUNLAR[bolge](x0, x1, w)
    return svg(tw, BOY, cizim["govde"], cizim.get("defs", ""))


def _govde_yolu(x0, x1, r, ust=5):
    """Ucu yuvarlak, aşağı doğru dokunun dışına taşan gövde"""
    return ("M%d %d L%d %d Q%d %d %d %d L%d %d Q%d %d %d %d L%d %d Z"
            % (x0, BOY + 20, x0, ust + r, x0, ust, x0 + r, ust, x1 - r, ust, x1, ust, x1, ust + r, x1, BOY + 20))


def sutun_orman(x0, x1, w):
    # Ağaç gövdesi: kahverengi, kabuk çizgileri, uçta yosun
    rnd = random.Random(w)
    r = min(34, w // 2 - 4)
    g = ['<path d="%s" fill="url(#g)"/>' % _govde_yolu(x0, x1, r)]
    g.append('<rect x="%d" y="40" width="%d" height="%d" rx="6" fill="#D9A470" opacity="0.55"/>' % (x0 + 10, max(8, w // 7), BOY))
    y = 110
    while y < BOY:
        cx = x0 + rnd.uniform(0.25, 0.75) * w
        uz = rnd.uniform(0.18, 0.34) * w
        g.append('<path d="M%.0f %.0f q%.0f %.0f %.0f 0" fill="none" stroke="#7A4D2A" stroke-width="5" stroke-linecap="round" opacity="0.75"/>'
                 % (cx - uz / 2, y, uz / 2, rnd.uniform(8, 16), uz))
        y += rnd.uniform(46, 78)
    for by in range(210, BOY, 300):
        g.append('<ellipse cx="%.0f" cy="%d" rx="%.0f" ry="11" fill="#7A4D2A" opacity="0.5"/>' % (x0 + w * 0.62, by, w * 0.13))
        g.append('<ellipse cx="%.0f" cy="%d" rx="%.0f" ry="6" fill="#5B3A1E" opacity="0.6"/>' % (x0 + w * 0.62, by, w * 0.07))
    # uçta yosun
    g.append('<path d="M%d %d Q%d 5 %d 5 L%d 5 Q%d 5 %d %d L%d 58 q-%.0f 16 -%.0f 0 q-%.0f 14 -%.0f 0 q-%.0f 16 -%.0f 0 Z" fill="#7CCB6A"/>'
             % (x0, 5 + r, x0, x0 + r, x1 - r, x1, x1, 5 + r, x1, w / 3, w / 3, w / 3, w / 3, w / 3, w / 3))
    g.append('<path d="M%d 22 q%.0f -12 %.0f -2" fill="none" stroke="#C9F2B0" stroke-width="6" stroke-linecap="round"/>' % (x0 + 16, w * 0.3, w * 0.5))
    g.append('<path d="%s" fill="none" stroke="#5B3A1E" stroke-width="6"/>' % _govde_yolu(x0, x1, r))
    return {"defs": degrade("g", "#C68B55", "#A56D3C", True), "govde": "\n".join(g) + "\n"}


def sutun_sehir(x0, x1, w):
    # Renkli bina: açık gri çizilir, oyunda pastel renklerle boyanır; pencereler ve çatı korkuluğu
    r = 12
    g = ['<path d="%s" fill="#F6F4FA"/>' % _govde_yolu(x0, x1, r)]
    g.append('<rect x="%d" y="5" width="%d" height="34" rx="%d" fill="#DCD8E6"/>' % (x0, w, r))
    g.append('<rect x="%d" y="34" width="%d" height="8" fill="#C4BFD2"/>' % (x0, w))
    sutun_sayisi = 2 if w < 100 else 3 if w < 150 else 4
    pw = (w - 16 * (sutun_sayisi + 1)) / sutun_sayisi
    y = 66
    satir = 0
    while y < BOY:
        for k in range(sutun_sayisi):
            px = x0 + 16 + k * (pw + 16)
            acik = (satir * 3 + k * 5) % 7 in (0, 3)
            g.append('<rect x="%.0f" y="%d" width="%.0f" height="40" rx="6" fill="%s"/>' % (px, y, pw, "#FFF3B8" if acik else "#BFE3FF"))
            g.append('<rect x="%.0f" y="%d" width="%.0f" height="7" rx="3" fill="#FFFFFF" opacity="0.7"/>' % (px + 3, y + 4, pw - 6))
        y += 68
        satir += 1
    g.append('<rect x="%d" y="46" width="12" height="%d" fill="#FFFFFF" opacity="0.45"/>' % (x0 + 4, BOY))
    g.append('<path d="%s" fill="none" stroke="#8A85A0" stroke-width="6"/>' % _govde_yolu(x0, x1, r))
    return {"govde": "\n".join(g) + "\n"}


def sutun_kar(x0, x1, w):
    # Buz sütunu: açık mavi, çapraz parlak yüzeyler, uçta kar
    rnd = random.Random(w + 7)
    r = min(26, w // 2 - 4)
    g = ['<path d="%s" fill="url(#g)"/>' % _govde_yolu(x0, x1, r)]
    y = 90
    while y < BOY:
        a = rnd.uniform(0.1, 0.5) * w
        b = rnd.uniform(0.25, 0.45) * w
        g.append('<path d="M%.0f %.0f l%.0f %.0f l%.0f %.0f l-%.0f -%.0f Z" fill="#FFFFFF" opacity="0.38"/>'
                 % (x0 + a, y, b, 70, 10, 50, b * 0.6, 60))
        y += rnd.uniform(150, 230)
    g.append('<rect x="%d" y="60" width="10" height="%d" rx="5" fill="#FFFFFF" opacity="0.6"/>' % (x0 + 12, BOY))
    g.append('<rect x="%d" y="60" width="12" height="%d" fill="#6FB2E3" opacity="0.4"/>' % (x1 - 20, BOY))
    # uçta kar örtüsü
    g.append('<path d="M%d %d Q%d 5 %d 5 L%d 5 Q%d 5 %d %d L%d 46 q-%.0f 20 -%.0f 2 q-%.0f 18 -%.0f 0 q-%.0f 20 -%.0f -2 Z" fill="#FFFFFF"/>'
             % (x0, 5 + r, x0, x0 + r, x1 - r, x1, x1, 5 + r, x1, w / 3, w / 3, w / 3, w / 3, w / 3, w / 3))
    g.append('<path d="%s" fill="none" stroke="#4E86B8" stroke-width="6"/>' % _govde_yolu(x0, x1, r))
    return {"defs": degrade("g", "#D4EEFF", "#9FD2F5", True), "govde": "\n".join(g) + "\n"}


def sutun_sahil(x0, x1, w):
    # Palmiye gövdesi: açık kahve, V biçimli halkalar, uçta küçük yeşil filizler
    r = min(30, w // 2 - 4)
    g = ['<path d="%s" fill="url(#g)"/>' % _govde_yolu(x0, x1, r)]
    for y in range(96, BOY, 64):
        g.append('<path d="M%d %d L%.0f %d L%d %d" fill="none" stroke="#A9743C" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" opacity="0.8"/>'
                 % (x0 + 4, y, x0 + w / 2, y + 22, x1 - 4, y))
    g.append('<rect x="%d" y="60" width="%d" height="%d" rx="6" fill="#F6D9A8" opacity="0.5"/>' % (x0 + 10, max(8, w // 8), BOY))
    for k, (dx, eg) in enumerate(((0.26, -24), (0.5, 0), (0.74, 24))):
        cx = x0 + w * dx
        g.append('<path d="M%.0f 62 Q%.0f 30 %.0f 14 Q%.0f 34 %.0f 62 Z" fill="#6BC46D" stroke="#3E8E4A" stroke-width="4" stroke-linejoin="round"/>'
                 % (cx - 12, cx - 10 + eg * 0.3, cx + eg * 0.5, cx + 12 + eg * 0.3, cx + 12))
    g.append('<path d="%s" fill="none" stroke="#8A5A2B" stroke-width="6"/>' % _govde_yolu(x0, x1, r))
    return {"defs": degrade("g", "#E3B477", "#C99455", True), "govde": "\n".join(g) + "\n"}


def sutun_gece(x0, x1, w):
    # Ay ışığında parlayan sütun: lacivert, parlak kenar, ışıldayan yıldızlar ve halkalar
    rnd = random.Random(w + 21)
    r = min(34, w // 2 - 4)
    g = ['<path d="%s" fill="url(#g)"/>' % _govde_yolu(x0, x1, r)]
    g.append('<rect x="%d" y="40" width="9" height="%d" rx="4" fill="#C9CCFF" opacity="0.75"/>' % (x0 + 9, BOY))
    for y in range(150, BOY, 260):
        g.append('<rect x="%d" y="%d" width="%d" height="14" fill="#FFE9A6" opacity="0.8"/>' % (x0, y, w))
        g.append('<rect x="%d" y="%d" width="%d" height="30" fill="#FFE9A6" opacity="0.14"/>' % (x0, y - 8, w))
    y = 70
    while y < BOY:
        cx = x0 + rnd.uniform(0.25, 0.8) * w
        s = rnd.uniform(7, 12)
        g.append('<path d="M%.0f %.0f l%.1f %.1f l%.1f %.1f l-%.1f %.1f l-%.1f %.1f l-%.1f -%.1f l-%.1f -%.1f l%.1f -%.1f Z" fill="#FFF4C2"/>'
                 % (cx, y - s, s * 0.3, s * 0.7, s * 0.7, s * 0.3, s * 0.7, s * 0.3, s * 0.3, s * 0.7, s * 0.3, s * 0.7, s * 0.7, s * 0.3, s * 0.7, s * 0.3))
        y += rnd.uniform(70, 130)
    g.append('<path d="M%d 26 q%.0f -14 %.0f -3" fill="none" stroke="#C9CCFF" stroke-width="6" stroke-linecap="round"/>' % (x0 + 18, w * 0.28, w * 0.48))
    g.append('<path d="%s" fill="none" stroke="#23265C" stroke-width="6"/>' % _govde_yolu(x0, x1, r))
    return {"defs": degrade("g", "#6468C8", "#4347A0", True), "govde": "\n".join(g) + "\n"}


SUTUNLAR = {"orman": sutun_orman, "sehir": sutun_sehir, "kar": sutun_kar, "sahil": sutun_sahil, "gece": sutun_gece}


# --- Arka plan katmanları (yatayda dikişsiz karo) ---

def sarili(parca_fonk, x, genislik):
    """Karonun kenarından taşan şekli öbür kenarda da çizer (dikişsiz olsun diye)"""
    cikti = parca_fonk(x)
    if x - genislik / 2 < 0:
        cikti += parca_fonk(x + KARO)
    if x + genislik / 2 > KARO:
        cikti += parca_fonk(x - KARO)
    return cikti


def dalga_yolu(h, taban, genlik, tur, faz=0.0, adim=20):
    """Karo boyunca dikişsiz (tam sayıda tur) sinüs tepeleri; altı dolu"""
    noktalar = []
    for x in range(0, KARO + adim, adim):
        y = taban - genlik * (0.5 + 0.5 * math.sin(2 * math.pi * tur * x / KARO + faz)) \
            - genlik * 0.35 * (0.5 + 0.5 * math.sin(2 * math.pi * (tur * 2 + 1) * x / KARO + faz * 1.7))
        noktalar.append("%d %.1f" % (x, y))
    return "M0 %d L%s L%d %d Z" % (h, " L".join(noktalar), KARO, h)


def yuvarlak_agac(x, y, r, govde_renk, yaprak, yaprak2):
    return ('<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" rx="4" fill="%s"/>'
            '<circle cx="%.0f" cy="%.0f" r="%.0f" fill="%s"/><circle cx="%.0f" cy="%.0f" r="%.0f" fill="%s"/>'
            '<circle cx="%.0f" cy="%.0f" r="%.0f" fill="%s"/>\n'
            % (x - r * 0.12, y - r * 0.9, r * 0.24, r * 0.95, govde_renk,
               x - r * 0.45, y - r * 1.25, r * 0.62, yaprak, x + r * 0.45, y - r * 1.3, r * 0.66, yaprak,
               x, y - r * 1.75, r * 0.7, yaprak2))


def cam(x, y, boy, renk, kar=None):
    s = ""
    for k in range(3):
        w = boy * (0.62 - k * 0.14)
        ust = y - boy * (0.45 + k * 0.28)
        alt = y - boy * (0.1 + k * 0.24)
        s += '<path d="M%.0f %.0f L%.0f %.0f L%.0f %.0f Z" fill="%s"/>' % (x - w / 2, alt, x, ust - boy * 0.1, x + w / 2, alt, renk)
        if kar:
            s += '<path d="M%.0f %.0f L%.0f %.0f L%.0f %.0f Z" fill="%s"/>' % (x - w * 0.2, ust + boy * 0.08, x, ust - boy * 0.1, x + w * 0.2, ust + boy * 0.08, kar)
    s += '<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" fill="%s"/>\n' % (x - boy * 0.04, y - boy * 0.12, boy * 0.08, boy * 0.12, renk)
    return s


def palmiye(x, y, boy, govde_renk, yaprak):
    s = '<path d="M%.0f %.0f Q%.0f %.0f %.0f %.0f" fill="none" stroke="%s" stroke-width="%.0f" stroke-linecap="round"/>' \
        % (x, y, x + boy * 0.12, y - boy * 0.5, x + boy * 0.05, y - boy, govde_renk, boy * 0.07)
    tx, ty = x + boy * 0.05, y - boy
    for aci in (-150, -110, -70, -30, 170, 10):
        ex = tx + math.cos(math.radians(aci)) * boy * 0.42
        ey = ty + math.sin(math.radians(aci)) * boy * 0.3 + boy * 0.1
        s += '<path d="M%.0f %.0f Q%.0f %.0f %.0f %.0f Q%.0f %.0f %.0f %.0f Z" fill="%s"/>' \
            % (tx, ty, (tx + ex) / 2, ty - boy * 0.2, ex, ey, (tx + ex) / 2, ty - boy * 0.05, tx, ty, yaprak)
    return s + "\n"


def katman_orman(tur):
    rnd = random.Random("orman" + tur)
    if tur == "uzak":
        h = 340
        g = '<path d="%s" fill="#CDEBD6"/>\n' % dalga_yolu(h, 250, 150, 2, 0.6)
        g += '<path d="%s" fill="#B5E2C4"/>\n' % dalga_yolu(h, 300, 110, 3, 2.1)
        return h, g
    if tur == "orta":
        h = 250
        g = '<path d="%s" fill="#9ED9A8"/>\n' % dalga_yolu(h, 225, 46, 4, 1.0)
        for i in range(13):
            x = (i + rnd.uniform(0.15, 0.85)) * KARO / 13
            r = rnd.uniform(46, 70)
            g += sarili(lambda xx: yuvarlak_agac(xx, 212, r, "#8FB98A", "#8ED39A", "#A5E0AC"), x, r * 2.4)
        return h, g
    h = 130
    g = ""
    for i in range(16):
        x = (i + rnd.uniform(0.1, 0.9)) * KARO / 16
        r = rnd.uniform(26, 44)
        g += sarili(lambda xx: '<circle cx="%.0f" cy="%.0f" r="%.0f" fill="#6CC47A"/><circle cx="%.0f" cy="%.0f" r="%.0f" fill="#7DD08A"/>\n'
                    % (xx, h - r * 0.2, r, xx + r * 0.7, h - r * 0.05, r * 0.75), x, r * 3.4)
    for i in range(18):
        x = rnd.uniform(0, KARO)
        renk = rnd.choice(["#FF9CC6", "#FFE27A", "#FFFFFF", "#C9B6FF"])
        g += '<circle cx="%.0f" cy="%.0f" r="6" fill="%s"/>\n' % (x, h - rnd.uniform(14, 52), renk)
    return h, g


def katman_sehir(tur):
    rnd = random.Random("sehir" + tur)
    if tur == "uzak":
        h = 340
        g = ""
        x = 0
        while x < KARO:
            w = rnd.uniform(60, 120)
            if x + w > KARO:
                w = KARO - x
            bh = rnd.uniform(110, 290)
            g += '<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" rx="6" fill="%s"/>\n' % (x, h - bh, w + 1, bh, rnd.choice(["#D5D9F5", "#CBD0F0", "#DDE0F8"]))
            if w > 70 and rnd.random() < 0.4:
                g += '<rect x="%.0f" y="%.0f" width="6" height="34" fill="#CBD0F0"/>\n' % (x + w / 2, h - bh - 30)
            x += w
        return h, g
    if tur == "orta":
        h = 250
        g = ""
        x = 0
        renkler = ["#FFC9DC", "#FFE3A8", "#BFEBD9", "#D6CBFF", "#FFD2B0", "#BFE0FF"]
        i = 0
        while x < KARO:
            w = rnd.uniform(90, 150)
            if KARO - (x + w) < 60:
                w = KARO - x
            bh = rnd.uniform(110, 215)
            renk = renkler[i % len(renkler)]
            g += '<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" rx="8" fill="%s"/>\n' % (x + 4, h - bh, w - 8, bh, renk)
            g += '<rect x="%.0f" y="%.0f" width="%.0f" height="12" rx="6" fill="#FFFFFF" opacity="0.5"/>\n' % (x + 4, h - bh, w - 8)
            kolon = max(2, int((w - 20) // 34))
            aralik = (w - 20) / kolon
            for s in range(int((bh - 40) // 42)):
                for k in range(kolon):
                    g += '<rect x="%.0f" y="%.0f" width="%.0f" height="22" rx="4" fill="#FFFFFF" opacity="%s"/>\n' \
                        % (x + 14 + k * aralik, h - bh + 28 + s * 42, aralik - 10, "0.85" if rnd.random() < 0.3 else "0.5")
            x += w
            i += 1
        return h, g
    h = 130
    g = ""
    for i in range(9):
        x = (i + rnd.uniform(0.2, 0.8)) * KARO / 9
        r = rnd.uniform(34, 46)
        g += sarili(lambda xx: yuvarlak_agac(xx, h + 6, r, "#9A8FB8", "#8FD3B0", "#A6E0C2"), x, r * 2.4)
    for i in range(5):
        x = (i + 0.5) * KARO / 5
        g += '<rect x="%.0f" y="%d" width="6" height="86" rx="3" fill="#8F8AA8"/><circle cx="%.0f" cy="%d" r="11" fill="#FFF3B8"/>\n' % (x - 3, h - 86, x, h - 90)
    return h, g


def katman_kar(tur):
    rnd = random.Random("kar" + tur)
    if tur == "uzak":
        h = 360
        g = ""
        for i, (cx, tepe, w) in enumerate(((150, 60, 520), (520, 120, 460), (880, 30, 600), (1200, 110, 440))):
            def dag(xx, tepe=tepe, w=w):
                s = '<path d="M%.0f %d L%.0f %d L%.0f %d Z" fill="#C3D9F5"/>' % (xx - w / 2, h, xx, tepe, xx + w / 2, h)
                kh = (h - tepe) * 0.3
                kw = w * 0.3 / 2
                s += '<path d="M%.0f %.0f L%.0f %d L%.0f %.0f L%.0f %.0f L%.0f %.0f L%.0f %.0f Z" fill="#FFFFFF"/>\n' \
                    % (xx - kw, tepe + kh, xx, tepe, xx + kw, tepe + kh, xx + kw * 0.45, tepe + kh * 0.78, xx, tepe + kh * 1.12, xx - kw * 0.5, tepe + kh * 0.8)
                return s
            g += sarili(dag, cx, w)
        return h, g
    if tur == "orta":
        h = 250
        g = '<path d="%s" fill="#E3EEFB"/>\n' % dalga_yolu(h, 215, 60, 3, 0.4)
        for i in range(12):
            x = (i + rnd.uniform(0.15, 0.85)) * KARO / 12
            boy = rnd.uniform(90, 140)
            g += sarili(lambda xx: cam(xx, 205, boy, "#7FB8B0", "#FFFFFF"), x, boy * 0.7)
        return h, g
    h = 130
    g = '<path d="%s" fill="#F4F9FF"/>\n' % dalga_yolu(h, 118, 42, 5, 1.3)
    for i in range(7):
        x = (i + rnd.uniform(0.2, 0.8)) * KARO / 7
        boy = rnd.uniform(56, 84)
        g += sarili(lambda xx: cam(xx, h - 6, boy, "#5FA39B", "#FFFFFF"), x, boy * 0.7)
    return h, g


def katman_sahil(tur):
    rnd = random.Random("sahil" + tur)
    if tur == "uzak":
        # deniz: ufuk çizgisi ve parıltılar
        h = 300
        g = '<rect x="0" y="120" width="%d" height="%d" fill="#F7A98F"/>\n' % (KARO, h - 120)
        g += '<rect x="0" y="120" width="%d" height="60" fill="#FFC7A1" opacity="0.7"/>\n' % KARO
        for i in range(34):
            x = rnd.uniform(0, KARO)
            y = rnd.uniform(134, h - 20)
            w = rnd.uniform(40, 130)
            g += sarili(lambda xx: '<rect x="%.0f" y="%.0f" width="%.0f" height="5" rx="2.5" fill="#FFE9C9" opacity="0.7"/>\n' % (xx - w / 2, y, w), x, w)
        for cx, w, ah in ((260, 300, 56), (900, 380, 72)):
            g += sarili(lambda xx: '<path d="M%.0f 122 Q%.0f %.0f %.0f 122 Z" fill="#D98DA0"/>\n' % (xx - w / 2, xx, 122 - ah * 2, xx + w / 2), cx, w)
        return h, g
    if tur == "orta":
        h = 250
        g = '<path d="%s" fill="#F2C48E"/>\n' % dalga_yolu(h, 232, 34, 2, 0.9)
        for i in range(7):
            x = (i + rnd.uniform(0.2, 0.8)) * KARO / 7
            boy = rnd.uniform(130, 190)
            g += sarili(lambda xx: palmiye(xx, 222, boy, "#B9805A", "#C56A7C"), x, boy)
        return h, g
    h = 130
    g = '<path d="%s" fill="#F8D9A2"/>\n' % dalga_yolu(h, 122, 30, 4, 2.2)
    for i in range(5):
        x = (i + rnd.uniform(0.2, 0.8)) * KARO / 5
        boy = rnd.uniform(86, 112)
        g += sarili(lambda xx: palmiye(xx, h - 4, boy, "#A8734A", "#5FB57A"), x, boy)
    for i in range(7):
        x = rnd.uniform(30, KARO - 30)
        g += '<path d="M%.0f %d l8 -10 l8 10 l-3 9 h-10 Z" fill="#FF9CB1"/>\n' % (x, h - 16)
    return h, g


def katman_gece(tur):
    rnd = random.Random("gece" + tur)
    if tur == "uzak":
        h = 360
        g = ""
        for i in range(70):
            x, y = rnd.uniform(0, KARO), rnd.uniform(0, 250)
            g += '<circle cx="%.0f" cy="%.0f" r="%.1f" fill="#FFF6D0" opacity="%.2f"/>\n' % (x, y, rnd.uniform(1.6, 3.6), rnd.uniform(0.5, 1.0))
        g += '<path d="%s" fill="#3F4592"/>\n' % dalga_yolu(h, 300, 120, 2, 1.4)
        return h, g
    if tur == "orta":
        h = 250
        g = '<path d="%s" fill="#343A84"/>\n' % dalga_yolu(h, 225, 50, 3, 0.2)
        for i in range(11):
            x = (i + rnd.uniform(0.15, 0.85)) * KARO / 11
            r = rnd.uniform(46, 66)
            g += sarili(lambda xx: yuvarlak_agac(xx, 214, r, "#2B3074", "#30367C", "#3A4190"), x, r * 2.4)
        return h, g
    h = 130
    g = ""
    for i in range(15):
        x = (i + rnd.uniform(0.1, 0.9)) * KARO / 15
        r = rnd.uniform(26, 42)
        g += sarili(lambda xx: '<circle cx="%.0f" cy="%.0f" r="%.0f" fill="#262B6A"/>\n' % (xx, h - r * 0.2, r), x, r * 2)
    for i in range(16):
        x, y = rnd.uniform(0, KARO), rnd.uniform(20, h - 16)
        g += '<circle cx="%.0f" cy="%.0f" r="9" fill="#FFF3A0" opacity="0.22"/><circle cx="%.0f" cy="%.0f" r="3.5" fill="#FFF8C8"/>\n' % (x, y, x, y)
    return h, g


KATMANLAR = {"orman": katman_orman, "sehir": katman_sehir, "kar": katman_kar, "sahil": katman_sahil, "gece": katman_gece}


# --- Tek parçalar ---

def bulut_engel():
    # Uykulu bulut: direk değil, üstünden ya da altından geçilen yumuşak engel
    defs = degrade("b", "#F3F1FF", "#C9C6EE")
    g = ('<path d="M52 122 C20 122 12 86 40 76 C36 44 76 30 96 52 C108 18 166 18 176 54 C206 40 236 66 220 92 '
         'C244 100 236 124 212 122 Z" fill="url(#b)" stroke="#5C5F9E" stroke-width="7" stroke-linejoin="round"/>\n'
         '<path d="M70 62 C78 50 92 48 100 56" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round" opacity="0.8"/>\n'
         '<path d="M96 88 q12 10 24 0" fill="none" stroke="#3B2F6B" stroke-width="6" stroke-linecap="round"/>\n'
         '<path d="M144 88 q12 10 24 0" fill="none" stroke="#3B2F6B" stroke-width="6" stroke-linecap="round"/>\n'
         '<path d="M124 104 q8 7 16 0" fill="none" stroke="#3B2F6B" stroke-width="5" stroke-linecap="round"/>\n'
         '<ellipse cx="88" cy="102" rx="10" ry="6" fill="#FF9CC6" opacity="0.7"/><ellipse cx="176" cy="102" rx="10" ry="6" fill="#FF9CC6" opacity="0.7"/>\n'
         '<path d="M198 34 l12 0 l-12 14 l12 0" fill="none" stroke="#5C5F9E" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>\n'
         '<path d="M222 12 l8 0 l-8 10 l8 0" fill="none" stroke="#5C5F9E" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>\n')
    return svg(256, 140, g, defs)


def yildiz_yolu(cx, cy, dis, ic):
    n = []
    for k in range(10):
        r = dis if k % 2 == 0 else ic
        a = -math.pi / 2 + k * math.pi / 5
        n.append("%.1f %.1f" % (cx + r * math.cos(a), cy + r * math.sin(a)))
    return "M" + " L".join(n) + " Z"


def yildiz():
    defs = degrade("y", "#FFE98A", "#FFB81F")
    g = ('<path d="%s" fill="url(#y)" stroke="#C47E00" stroke-width="6" stroke-linejoin="round"/>\n'
         '<path d="M34 34 C38 28 44 26 49 26" fill="none" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" opacity="0.85"/>\n'
         % yildiz_yolu(48, 50, 40, 19))
    return svg(96, 96, g, defs)


def gunes():
    defs = ('<radialGradient id="h" cx="0.5" cy="0.5" r="0.5"><stop offset="0.45" stop-color="#FFFFFF" stop-opacity="0.55"/>'
            '<stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>')
    g = '<circle cx="120" cy="120" r="120" fill="url(#h)"/>\n<circle cx="120" cy="120" r="62" fill="#FFFFFF"/>\n'
    return svg(240, 240, g, defs)


def ay():
    defs = ('<radialGradient id="h" cx="0.5" cy="0.5" r="0.5"><stop offset="0.4" stop-color="#FFF6C8" stop-opacity="0.35"/>'
            '<stop offset="1" stop-color="#FFF6C8" stop-opacity="0"/></radialGradient>')
    g = ('<circle cx="120" cy="120" r="120" fill="url(#h)"/>\n'
         '<path d="M150 62 A64 64 0 1 0 150 178 A50 50 0 1 1 150 62 Z" fill="#FFF3B8"/>\n'
         '<circle cx="96" cy="104" r="8" fill="#F2DE8E"/><circle cx="110" cy="144" r="6" fill="#F2DE8E"/>\n')
    return svg(240, 240, g, defs)


if __name__ == "__main__":
    for bolge in SUTUNLAR:
        for kalinlik in GENISLIKLER:
            yaz("direk_%s_%s.svg" % (bolge, kalinlik), sutun(bolge, kalinlik))
        for tur in ("uzak", "orta", "yakin"):
            h, govde = KATMANLAR[bolge](tur)
            yaz("katman_%s_%s.svg" % (bolge, tur), svg(KARO, h, govde))
    yaz("bulut_engel.svg", bulut_engel())
    yaz("yildiz.svg", yildiz())
    yaz("gunes.svg", gunes())
    yaz("ay.svg", ay())
    print("%d sütun, %d katman, 4 tek parça yazıldı" % (len(SUTUNLAR) * len(GENISLIKLER), len(KATMANLAR) * 3))
