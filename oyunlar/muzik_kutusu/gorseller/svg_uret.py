# Müzik Kutusu SVG üreticisi (sadece Python standart kütüphanesi).
# Çalıştırma: python svg_uret.py   (bu klasöre yazar)
# Stil öbür oyunlarla aynı: koyu mor kalın hat, yuvarlak köşeler, radyal gradyanlı parlak dolgular,
# gradyanlı gözler ve beyaz parıltılar, pembe yanaklar, altta yumuşak gölge.
#
# - Ksilofon: tus_1..8.svg (her tuş kendi boyunda), cerceve.svg (ksilofonun tasarım alanının tamamı:
#   XYLO_W x XYLO_H; tuş konumları ksilofon.gd ile aynı sabitlerden), tokmak, defter, şarkı simgeleri.
# - Davul seti: bas_davul, trampet, tom_mavi, tom_yesil, zil, marakas.
# - Hayvanlar (256 tuval, önden): <ad>.svg (ağız kapalı) ve <ad>_ses.svg (ağız açık) aynı çizimden.
# - Sahne: perde_ust (yatayda döşenir), perde_yan (sağdaki yatay çevrilir), sahne_tabani (döşenir),
#   isiklar (döşenir). Efektler: nota, nota_cift, isik. Enstrüman simgeleri: ikon_*.

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = "#3B2F6B"
SW = 7

# Ksilofon geometrisi (ksilofon.gd ile aynı olmalı)
XYLO_W, XYLO_H = 1040, 470
BAR_W, BAR_STEP, BAR_X0 = 96, 122, 88       # tuş genişliği, tuş merkezleri arası, ilk tuşun merkezi
BAR_CY = 260
BAR_TALL, BAR_SHORT = 390, 250
NAIL = 0.36                                  # çivi: tuş merkezinden yukarı/aşağı tuş boyunun bu oranı
BAR_COLORS = ["#FF5B5B", "#FF9A3D", "#FFD23F", "#7BD85A", "#36CFC9", "#4AA3FF", "#8B6CF6", "#FF6FB5"]


def bar_height(i: int) -> float:
    return BAR_TALL - (BAR_TALL - BAR_SHORT) * i / 7.0


def bar_x(i: int) -> float:
    return BAR_X0 + BAR_STEP * i


# --- Yardımcılar ---

def write(name: str, w: float, h: float, body: str, defs: str = "") -> None:
    text = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:g}" height="{h:g}" viewBox="0 0 {w:g} {h:g}">\n'
    if defs:
        text += "  <defs>\n" + defs + "  </defs>\n"
    text += body + "</svg>\n"
    with open(os.path.join(HERE, name), "w", encoding="utf-8", newline="\n") as f:
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


EYE_DEFS = (
    radial("goz", [(0, "#6A5A96"), (0.55, "#2A1F45"), (1, "#150F26")], 0.4, 0.35, 0.7)
    + '    <radialGradient id="yanak" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FF7FA3" stop-opacity="0.85"/>'
    '<stop offset="1" stop-color="#FF7FA3" stop-opacity="0"/></radialGradient>\n'
    + '    <radialGradient id="golge" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#3A2A4A" stop-opacity="0.3"/>'
    '<stop offset="1" stop-color="#3A2A4A" stop-opacity="0"/></radialGradient>\n'
)


def st(width: float = SW) -> str:
    return f'stroke="{OUT}" stroke-width="{width:g}" stroke-linejoin="round" stroke-linecap="round"'


def eyes(y: float = 128, dx: float = 26, rx: float = 14, ry: float = 17) -> str:
    out = ""
    for x in (128 - dx, 128 + dx):
        out += f'  <ellipse cx="{x:g}" cy="{y:g}" rx="{rx:g}" ry="{ry:g}" fill="url(#goz)"/>\n'
        out += f'  <ellipse cx="{x - rx * 0.35:g}" cy="{y - ry * 0.45:g}" rx="{rx * 0.42:g}" ry="{ry * 0.4:g}" fill="#FFFFFF"/>\n'
        out += f'  <circle cx="{x + rx * 0.35:g}" cy="{y + ry * 0.4:g}" r="{rx * 0.2:g}" fill="#FFFFFF" opacity="0.85"/>\n'
    return out


def cheeks(y: float = 152, dx: float = 48) -> str:
    return "".join(f'  <ellipse cx="{x:g}" cy="{y:g}" rx="17" ry="10" fill="url(#yanak)"/>\n' for x in (128 - dx, 128 + dx))


def shine(x: float, y: float, rx: float = 18, ry: float = 8, angle: float = -25, opacity: float = 0.8) -> str:
    return f'  <ellipse cx="{x:g}" cy="{y:g}" rx="{rx:g}" ry="{ry:g}" transform="rotate({angle:g} {x:g} {y:g})" fill="#FFFFFF" opacity="{opacity:g}"/>\n'


def open_mouth(x: float = 128, y: float = 158, w: float = 18, h: float = 28) -> str:
    # Ağzı açık hali: koyu ağız içi ve pembe dil
    return (
        f'  <path d="M{x - w:g} {y:g} Q{x:g} {y - 3:g} {x + w:g} {y:g} Q{x + w - 2:g} {y + h:g} {x:g} {y + h:g} '
        f'Q{x - w + 2:g} {y + h:g} {x - w:g} {y:g} Z" fill="#8A2A4A" {st(5)}/>\n'
        f'  <path d="M{x - w * 0.62:g} {y + h * 0.7:g} Q{x:g} {y + h * 0.4:g} {x + w * 0.62:g} {y + h * 0.7:g} '
        f'Q{x + w * 0.4:g} {y + h - 3:g} {x:g} {y + h - 3:g} Q{x - w * 0.4:g} {y + h - 3:g} {x - w * 0.62:g} {y + h * 0.7:g} Z" fill="#FF8FB0"/>\n'
    )


def smile(x: float = 128, y: float = 158, w: float = 14) -> str:
    # Ağız kapalı: küçük "w" gülümseme
    return (f'  <path d="M{x - w:g} {y:g} Q{x - w / 2:g} {y + 8:g} {x:g} {y:g} Q{x + w / 2:g} {y + 8:g} {x + w:g} {y:g}" '
            f'fill="none" {st(5)}/>\n')


def note_shape(x: float, y: float, s: float, fill: str, outline: bool = True, double: bool = False) -> str:
    # ♪ (double=True: ♫). (x, y) sol alt nota başının merkezi, s ölçek (1 = 128'lik tuvale göre)
    heads = [(0.0, 0.0)] if not double else [(0.0, 0.0), (52.0, -12.0)]
    shapes = []
    for hx, hy in heads:
        cx, cy = x + hx * s, y + hy * s
        shapes.append(f'<ellipse cx="{cx:g}" cy="{cy:g}" rx="{21 * s:g}" ry="{15 * s:g}" transform="rotate(-22 {cx:g} {cy:g})"/>')
        shapes.append(f'<rect x="{cx + 12 * s:g}" y="{cy - 70 * s:g}" width="{9 * s:g}" height="{72 * s:g}" rx="{4 * s:g}"/>')
    if double:
        sx, sy = x + 12 * s, y - 70 * s
        shapes.append(f'<path d="M{sx:g} {sy:g} L{sx + 61 * s:g} {sy - 12 * s:g} L{sx + 61 * s:g} {sy + 8 * s:g} L{sx:g} {sy + 20 * s:g} Z"/>')
    else:
        sx, sy = x + 16 * s, y - 70 * s
        shapes.append(f'<path d="M{sx:g} {sy:g} Q{sx + 8 * s:g} {sy + 22 * s:g} {sx + 32 * s:g} {sy + 32 * s:g} '
                      f'Q{sx + 42 * s:g} {sy + 42 * s:g} {sx + 32 * s:g} {sy + 58 * s:g} Q{sx + 30 * s:g} {sy + 36 * s:g} '
                      f'{sx:g} {sy + 28 * s:g} Z"/>')
    inner = "".join(shapes)
    out = ""
    if outline:
        out += f'  <g fill="{OUT}" {st(12 * s)}>{inner}</g>\n'
    out += f'  <g fill="{fill}">{inner}</g>\n'
    return out


# --- Ksilofon ---

def xylophone_bars() -> None:
    for i in range(8):
        h = bar_height(i)
        base = BAR_COLORS[i]
        defs = linear("g", [(0, light(base, 0.5)), (0.35, base), (1, dark(base, 0.12))], 1, 0)
        w_canvas, h_canvas = BAR_W + 16, h + 24
        x, y = 8, 12
        cx = x + BAR_W / 2
        body = (
            f'  <rect x="{x}" y="{y + 8}" width="{BAR_W}" height="{h:g}" rx="24" fill="{dark(base, 0.35)}" {st()}/>\n'
            f'  <rect x="{x}" y="{y}" width="{BAR_W}" height="{h:g}" rx="24" fill="url(#g)" {st()}/>\n'
            f'  <rect x="{x + 12}" y="{y + 18}" width="15" height="{h * 0.42:g}" rx="7.5" fill="#FFFFFF" opacity="0.55"/>\n'
            f'  <circle cx="{x + 19.5}" cy="{y + 30 + h * 0.46:g}" r="6" fill="#FFFFFF" opacity="0.45"/>\n'
        )
        for sign in (-1, 1):
            ny = y + h / 2 + sign * NAIL * h
            body += f'  <circle cx="{cx:g}" cy="{ny:g}" r="10" fill="#F4F1FF" {st(4)}/>\n'
            body += f'  <circle cx="{cx - 3:g}" cy="{ny - 3:g}" r="3" fill="#FFFFFF"/>\n'
        write(f"tus_{i + 1}.svg", w_canvas, h_canvas, body, defs)


def xylophone_frame() -> None:
    # İki ahşap ray (tuşların çivilerinden geçer), uçlarda yuvarlak tokmak başları ve altta gölge
    defs = '    <radialGradient id="golge" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#3A2A4A" stop-opacity="0.28"/><stop offset="1" stop-color="#3A2A4A" stop-opacity="0"/></radialGradient>\n'
    defs += radial("uc", [(0, "#FFE0A8"), (0.6, "#E9A25A"), (1, "#B86F2E")], 0.35, 0.3, 0.8)
    x0, x7 = bar_x(0), bar_x(7)
    body = f'  <ellipse cx="{XYLO_W / 2:g}" cy="{BAR_CY + BAR_TALL / 2 + 22:g}" rx="{XYLO_W * 0.47:g}" ry="16" fill="url(#golge)"/>\n'
    for sign in (-1, 1):
        ya = BAR_CY + sign * NAIL * bar_height(0)
        yb = BAR_CY + sign * NAIL * bar_height(7)
        slope = (yb - ya) / (x7 - x0)
        xa, xb = x0 - 58, x7 + 58
        pa, pb = ya - slope * 58, yb + slope * 58
        body += f'  <path d="M{xa:g} {pa:g} L{xb:g} {pb:g}" stroke="{OUT}" stroke-width="40" stroke-linecap="round"/>\n'
        body += f'  <path d="M{xa:g} {pa:g} L{xb:g} {pb:g}" stroke="#C98A4B" stroke-width="27" stroke-linecap="round"/>\n'
        body += f'  <path d="M{xa + 6:g} {pa - 5:g} L{xb - 6:g} {pb - 5:g}" stroke="#E8B77A" stroke-width="8" stroke-linecap="round"/>\n'
        for px, py in ((xa, pa), (xb, pb)):
            body += f'  <circle cx="{px:g}" cy="{py:g}" r="22" fill="url(#uc)" {st(6)}/>\n'
            body += f'  <circle cx="{px - 6:g}" cy="{py - 6:g}" r="6" fill="#FFFFFF" opacity="0.6"/>\n'
    write("cerceve.svg", XYLO_W, XYLO_H, body, defs)


def mallet() -> None:
    # Tokmak: kırmızı top ve ahşap sap. Top merkezi (60, 56)
    defs = radial("top", [(0, "#FFB3B3"), (0.5, "#FF5B6E"), (1, "#C8324A")], 0.35, 0.3, 0.8)
    defs += linear("sap", [(0, "#F2C48A"), (1, "#C98A4B")], 1, 0)
    body = (
        f'  <rect x="51" y="84" width="18" height="206" rx="9" fill="url(#sap)" {st(6)}/>\n'
        f'  <circle cx="60" cy="56" r="44" fill="url(#top)" {st()}/>\n'
        + shine(46, 40, 13, 7, -35, 0.85)
    )
    write("tokmak.svg", 120, 300, body, defs)


def notebook() -> None:
    # Nota defteri: pembe kapak, spiral, beyaz etikette nota
    defs = radial("kap", [(0, "#FFC9E2"), (0.6, "#FF8CC0"), (1, "#E0609E")], 0.35, 0.25, 0.9)
    body = f'  <rect x="52" y="30" width="172" height="200" rx="28" fill="#D6488A" {st()} transform="translate(8 8)"/>\n'
    body += f'  <rect x="52" y="30" width="172" height="200" rx="28" fill="url(#kap)" {st()}/>\n'
    body += f'  <rect x="92" y="66" width="104" height="128" rx="20" fill="#FFFFFF" {st(5)}/>\n'
    for k in range(5):
        y = 58 + k * 36
        body += f'  <rect x="36" y="{y}" width="34" height="14" rx="7" fill="#EDE9FF" {st(5)}/>\n'
    body += note_shape(130, 162, 0.9, "#8B6CF6", outline=False)
    body += shine(78, 46, 12, 5, 0, 0.7)
    write("defter.svg", 256, 256, body, defs)


def song_icons() -> None:
    # Yıldız (Küçük Yıldız), çan (Tembel Çocuk), kuzu (Kuzucuk)
    defs = radial("y", [(0, "#FFF6B0"), (0.55, "#FFD23F"), (1, "#F2A81D")], 0.4, 0.3, 0.8)
    pts = []
    for k in range(10):
        r = 58 if k % 2 == 0 else 26
        a = -math.pi / 2 + k * math.pi / 5
        pts.append(f"{64 + r * math.cos(a):.1f} {68 + r * math.sin(a):.1f}")
    body = f'  <path d="M{" L".join(pts)} Z" fill="url(#y)" {st(6)}/>\n'
    body += f'  <circle cx="54" cy="68" r="4.5" fill="{OUT}"/><circle cx="74" cy="68" r="4.5" fill="{OUT}"/>\n'
    body += f'  <path d="M56 80 Q64 87 72 80" fill="none" {st(4)}/>\n' + shine(50, 44, 7, 4, -30, 0.8)
    write("sarki_yildiz.svg", 128, 128, body, defs)

    defs = radial("c", [(0, "#FFF0B8"), (0.55, "#FFC43D"), (1, "#E0941E")], 0.4, 0.3, 0.8)
    body = f'  <circle cx="64" cy="100" r="12" fill="#FF8A5B" {st(5)}/>\n'
    body += f'  <path d="M64 18 C38 18 32 44 30 66 C28 82 20 88 16 96 H112 C108 88 100 82 98 66 C96 44 90 18 64 18 Z" fill="url(#c)" {st(6)}/>\n'
    body += f'  <circle cx="64" cy="16" r="8" fill="url(#c)" {st(5)}/>\n'
    body += f'  <rect x="14" y="92" width="100" height="12" rx="6" fill="#F2A81D" {st(5)}/>\n'
    body += shine(46, 42, 6, 12, 15, 0.7)
    write("sarki_can.svg", 128, 128, body, defs)

    defs = radial("yun", [(0, "#FFFFFF"), (0.6, "#F7F1FF"), (1, "#DCD0EE")], 0.4, 0.3, 0.8)
    body = ""
    ring = [(64 + 38 * math.cos(a), 66 + 34 * math.sin(a)) for a in [k * math.pi / 4 for k in range(8)]]
    body += f'  <g fill="{OUT}" {st(10)}>' + "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="17"/>' for x, y in ring) + '</g>\n'
    body += '  <g fill="url(#yun)">' + "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="17"/>' for x, y in ring) + f'<circle cx="64" cy="66" r="38"/></g>\n'
    body += f'  <ellipse cx="22" cy="74" rx="14" ry="8" fill="#F2C9A8" {st(4)}/><ellipse cx="106" cy="74" rx="14" ry="8" fill="#F2C9A8" {st(4)}/>\n'
    body += f'  <ellipse cx="64" cy="76" rx="30" ry="28" fill="#FFE3CF" {st(5)}/>\n'
    body += f'  <circle cx="53" cy="72" r="5" fill="{OUT}"/><circle cx="75" cy="72" r="5" fill="{OUT}"/>\n'
    body += f'  <path d="M58 88 Q64 93 70 88" fill="none" {st(4)}/>\n'
    body += '  <g fill="url(#yun)" stroke="#3B2F6B" stroke-width="4"><circle cx="52" cy="46" r="11"/><circle cx="64" cy="42" r="12"/><circle cx="76" cy="46" r="11"/></g>\n'
    write("sarki_kuzu.svg", 128, 128, body, defs)


# --- Davul seti ---

def bass_drum() -> None:
    defs = ten("kab", "#FF5B6E")
    defs += radial("deri", [(0, "#FFFFFF"), (0.7, "#FFF6EA"), (1, "#F0DEC8")], 0.4, 0.35, 0.75)
    defs += radial("y", [(0, "#FFF6B0"), (0.55, "#FFD23F"), (1, "#F2A81D")], 0.4, 0.3, 0.8)
    body = f'  <path d="M78 262 L52 312 M242 262 L268 312" {st(16)} fill="none"/>\n'
    body += '  <path d="M78 262 L52 312 M242 262 L268 312" stroke="#CFC8E6" stroke-width="7" stroke-linecap="round" fill="none"/>\n'
    body += f'  <circle cx="160" cy="160" r="148" fill="url(#kab)" {st(8)}/>\n'
    for k in range(10):
        a = k * math.tau / 10 + 0.3
        x, y = 160 + 136 * math.cos(a), 160 + 136 * math.sin(a)
        body += f'  <rect x="{x - 9:.1f}" y="{y - 9:.1f}" width="18" height="18" rx="6" transform="rotate({math.degrees(a):.0f} {x:.1f} {y:.1f})" fill="#EDE9FF" {st(4)}/>\n'
    body += f'  <circle cx="160" cy="160" r="116" fill="#DCD6F0" {st(6)}/>\n'
    body += f'  <circle cx="160" cy="160" r="104" fill="url(#deri)" {st(5)}/>\n'
    pts = []
    for k in range(10):
        r = 62 if k % 2 == 0 else 28
        a = -math.pi / 2 + k * math.pi / 5
        pts.append(f"{160 + r * math.cos(a):.1f} {166 + r * math.sin(a):.1f}")
    body += f'  <path d="M{" L".join(pts)} Z" fill="url(#y)" {st(6)}/>\n'
    body += shine(92, 70, 30, 12, -40, 0.55) + shine(120, 110, 18, 7, -40, 0.7)
    write("bas_davul.svg", 320, 320, body, defs)


def cylinder_drum(name: str, color: str, w: float, top_ry: float, depth: float, legs: bool) -> None:
    # 3/4 bakışlı davul: üstte beyaz deri (elips), yanda renkli gövde ve gerdirme çubukları
    pad = 12
    rx = w / 2
    cx = pad + rx
    top = pad + top_ry
    bottom = top + depth
    canvas_h = bottom + top_ry + pad + (70 if legs else 0)
    defs = linear("kab", [(0, light(color, 0.35)), (0.3, color), (1, dark(color, 0.25))], 1, 0)
    defs += radial("deri", [(0, "#FFFFFF"), (0.7, "#FFF6EA"), (1, "#EADBC8")], 0.4, 0.35, 0.75)
    body = ""
    if legs:
        for x1, x2 in ((cx - rx * 0.5, cx - rx * 0.8), (cx + rx * 0.5, cx + rx * 0.8), (cx, cx)):
            body += f'  <path d="M{x1:g} {bottom:g} L{x2:g} {canvas_h - pad:g}" {st(14)} fill="none"/>\n'
            body += f'  <path d="M{x1:g} {bottom:g} L{x2:g} {canvas_h - pad:g}" stroke="#CFC8E6" stroke-width="6" stroke-linecap="round" fill="none"/>\n'
    body += (f'  <path d="M{cx - rx:g} {top:g} V{bottom:g} A{rx:g} {top_ry:g} 0 0 0 {cx + rx:g} {bottom:g} V{top:g} Z" '
             f'fill="url(#kab)" {st(8)}/>\n')
    # Alt çember
    body += (f'  <path d="M{cx - rx:g} {bottom - 10:g} A{rx:g} {top_ry:g} 0 0 0 {cx + rx:g} {bottom - 10:g}" '
             f'fill="none" stroke="#EDE9FF" stroke-width="9"/>\n')
    # Gerdirme çubukları
    for k in range(5):
        t = (k + 0.5) / 5
        x = cx - rx + t * 2 * rx
        yo = top_ry * math.sqrt(max(0.0, 1 - ((x - cx) / rx) ** 2))
        body += f'  <rect x="{x - 5:g}" y="{top + yo + 4:g}" width="10" height="{depth - 18:g}" rx="5" fill="#EDE9FF" stroke="{OUT}" stroke-width="3.5"/>\n'
    body += shine(cx - rx * 0.72, top + depth * 0.55, 7, depth * 0.28, 0, 0.45)
    body += f'  <ellipse cx="{cx:g}" cy="{top:g}" rx="{rx:g}" ry="{top_ry:g}" fill="#DCD6F0" {st(7)}/>\n'
    body += f'  <ellipse cx="{cx:g}" cy="{top:g}" rx="{rx - 12:g}" ry="{top_ry - 8:g}" fill="url(#deri)" {st(4)}/>\n'
    body += shine(cx - rx * 0.4, top - top_ry * 0.3, rx * 0.22, top_ry * 0.2, -10, 0.8)
    write(name, w + 2 * pad, canvas_h, body, defs)


def cymbal() -> None:
    defs = radial("zil", [(0, "#FFF4B8"), (0.45, "#FFD04A"), (0.8, "#F0A824"), (1, "#C98018")], 0.45, 0.35, 0.8)
    body = ""
    for x2 in (60, 220):
        body += f'  <path d="M140 200 L{x2} 290" {st(14)} fill="none"/><path d="M140 200 L{x2} 290" stroke="#CFC8E6" stroke-width="6" stroke-linecap="round" fill="none"/>\n'
    body += f'  <path d="M140 96 V292" {st(16)} fill="none"/><path d="M140 96 V292" stroke="#CFC8E6" stroke-width="7" stroke-linecap="round" fill="none"/>\n'
    body += '  <g transform="rotate(-8 140 96)">\n'
    body += f'  <ellipse cx="140" cy="96" rx="128" ry="36" fill="url(#zil)" {st(7)}/>\n'
    for r in (0.72, 0.48):
        body += f'  <ellipse cx="140" cy="94" rx="{128 * r:g}" ry="{36 * r:g}" fill="none" stroke="#FFF4B8" stroke-width="4" opacity="0.8"/>\n'
    body += f'  <ellipse cx="140" cy="88" rx="26" ry="12" fill="#FFD04A" {st(5)}/>\n'
    body += f'  <circle cx="140" cy="84" r="7" fill="#EDE9FF" {st(4)}/>\n'
    body += shine(92, 84, 26, 6, 0, 0.8)
    body += '  </g>\n'
    write("zil.svg", 280, 300, body, defs)


def maracas() -> None:
    defs = ten("m1", "#FF6FB5") + ten("m2", "#36CFC9")
    body = ""
    for gid, angle, dots in (("m2", 24, "#FFD23F"), ("m1", -24, "#FFFFFF")):
        body += f'  <g transform="rotate({angle} 130 150)">\n'
        body += f'  <rect x="119" y="130" width="22" height="118" rx="11" fill="#F2C48A" {st(6)}/>\n'
        body += f'  <rect x="112" y="226" width="36" height="22" rx="11" fill="#C98A4B" {st(6)}/>\n'
        body += f'  <ellipse cx="130" cy="84" rx="54" ry="64" fill="url(#{gid})" {st(7)}/>\n'
        body += f'  <path d="M82 80 L96 66 L110 80 L124 66 L138 80 L152 66 L166 80 L178 70" fill="none" stroke="{dots}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>\n'
        for dx, dy in ((-24, 108), (0, 116), (24, 108), (-12, 40), (12, 40)):
            body += f'  <circle cx="{130 + dx}" cy="{dy}" r="6" fill="{dots}"/>\n'
        body += shine(106, 50, 12, 18, 20, 0.6)
        body += '  </g>\n'
    write("marakas.svg", 260, 260, body, defs)


# --- Hayvanlar (256 tuval, önden) ---

def animal_base(color: str, belly: str = "", feet: str = "") -> str:
    body = '  <ellipse cx="128" cy="246" rx="80" ry="10" fill="url(#golge)"/>\n'
    body += f'  <ellipse cx="128" cy="210" rx="54" ry="34" fill="url(#ten)" {st()}/>\n'
    if belly:
        body += f'  <ellipse cx="128" cy="216" rx="30" ry="20" fill="{belly}"/>\n'
    fc = feet or "url(#ten)"
    for x in (102, 154):
        body += f'  <ellipse cx="{x}" cy="238" rx="21" ry="11" fill="{fc}" {st(6)}/>\n'
    return body


def head(rx: float = 70, ry: float = 60, cy: float = 132) -> str:
    return f'  <ellipse cx="128" cy="{cy:g}" rx="{rx:g}" ry="{ry:g}" fill="url(#ten)" {st()}/>\n'


def cat(open_: bool) -> tuple:
    defs = ten("ten", "#FFA84D") + EYE_DEFS
    body = f'  <path d="M176 224 C226 222 236 170 206 150" fill="none" stroke="{OUT}" stroke-width="26" stroke-linecap="round"/>\n'
    body += '  <path d="M176 224 C226 222 236 170 206 150" fill="none" stroke="#FFA84D" stroke-width="13" stroke-linecap="round"/>\n'
    body += animal_base("#FFA84D", "#FFE0B8")
    for s in (1, -1):
        body += f'  <path d="M{128 - s * 58} 112 L{128 - s * 64} 42 L{128 - s * 12} 80 Z" fill="url(#ten)" {st()}/>\n'
        body += f'  <path d="M{128 - s * 52} 96 L{128 - s * 56} 58 L{128 - s * 26} 80 Z" fill="#FF9FBF"/>\n'
    body += head()
    body += f'  <path d="M114 80 Q118 92 114 100 M128 78 V96 M142 80 Q138 92 142 100" fill="none" stroke="#E07B28" stroke-width="6" stroke-linecap="round"/>\n'
    body += eyes(124) + cheeks(150)
    body += f'  <path d="M120 142 H136 L128 151 Z" fill="#FF7FA3" {st(4)}/>\n'
    body += f'  <path d="M88 146 L62 140 M88 154 L64 160 M168 146 L194 140 M168 154 L192 160" {st(4)}/>\n'
    body += open_mouth(128, 155, 21, 34) if open_ else smile(128, 154, 12)
    body += shine(92, 96, 16, 7, -30)
    return defs, body


def dog(open_: bool) -> tuple:
    defs = ten("ten", "#E8A45C") + EYE_DEFS + ten("kulak", "#9B5E3A")
    body = f'  <path d="M180 206 C214 196 222 170 214 150" fill="none" stroke="{OUT}" stroke-width="24" stroke-linecap="round"/>\n'
    body += '  <path d="M180 206 C214 196 222 170 214 150" fill="none" stroke="#E8A45C" stroke-width="11" stroke-linecap="round"/>\n'
    body += animal_base("#E8A45C", "#F9DDB4")
    body += head(72, 60)
    body += f'  <ellipse cx="154" cy="124" rx="26" ry="24" fill="#B87A45"/>\n'
    body += f'  <ellipse cx="128" cy="160" rx="38" ry="26" fill="#F9DDB4" {st(5)}/>\n'
    for s in (1, -1):
        x = 128 - s * 68
        body += f'  <ellipse cx="{x}" cy="130" rx="22" ry="46" transform="rotate({s * 18} {x} 130)" fill="url(#kulak)" {st()}/>\n'
    body += eyes(120) + cheeks(156, 52)
    body += f'  <ellipse cx="128" cy="146" rx="14" ry="10" fill="{OUT}"/><ellipse cx="124" cy="142" rx="5" ry="3" fill="#FFFFFF" opacity="0.7"/>\n'
    body += f'  <path d="M128 155 V160" {st(4)}/>\n'
    body += open_mouth(128, 160, 21, 32) if open_ else smile(128, 160, 13)
    body += shine(92, 94, 16, 7, -30)
    return defs, body


def cow(open_: bool) -> tuple:
    defs = ten("ten", "#F4EEF8") + EYE_DEFS + ten("burun", "#FFB3C6") + ten("boynuz", "#FFF1C8")
    defs += '    <clipPath id="kafa"><ellipse cx="128" cy="132" rx="70" ry="60"/></clipPath>\n'
    body = animal_base("#F4EEF8")
    body += f'  <ellipse cx="160" cy="206" rx="16" ry="12" fill="#5A4A6E"/>\n'
    for s in (1, -1):
        body += f'  <path d="M{128 - s * 34} 84 Q{128 - s * 44} 50 {128 - s * 60} 48 Q{128 - s * 54} 66 {128 - s * 50} 90 Z" fill="url(#boynuz)" {st(6)}/>\n'
        x = 128 - s * 76
        body += f'  <ellipse cx="{x}" cy="108" rx="28" ry="13" transform="rotate({s * 20} {x} 108)" fill="url(#ten)" {st(6)}/>\n'
        body += f'  <ellipse cx="{x}" cy="108" rx="15" ry="6" transform="rotate({s * 20} {x} 108)" fill="#FFB3C6"/>\n'
    body += head()
    body += '  <g clip-path="url(#kafa)" fill="#5A4A6E"><ellipse cx="82" cy="92" rx="30" ry="24"/><ellipse cx="176" cy="150" rx="22" ry="30"/></g>\n'
    body += head().replace('fill="url(#ten)"', 'fill="none"')
    body += eyes(114, 28, 13, 16) + cheeks(142, 54)
    body += f'  <ellipse cx="128" cy="164" rx="46" ry="28" fill="url(#burun)" {st(6)}/>\n'
    body += f'  <ellipse cx="112" cy="158" rx="6" ry="8" fill="#B8577A"/><ellipse cx="144" cy="158" rx="6" ry="8" fill="#B8577A"/>\n'
    if open_:
        body += f'  <ellipse cx="128" cy="178" rx="21" ry="13" fill="#8A2A4A" {st(4)}/>\n'
    else:
        body += f'  <path d="M114 176 Q128 184 142 176" fill="none" {st(4)}/>\n'
    body += shine(96, 150, 12, 5, -20, 0.6) + shine(154, 90, 14, 6, 30, 0.7)
    return defs, body


def duck(open_: bool) -> tuple:
    defs = ten("ten", "#FFD93D") + EYE_DEFS + ten("gaga", "#FF9A3D")
    body = animal_base("#FFD93D", "", "#FF9A3D")
    for s in (1, -1):
        x = 128 - s * 50
        body += f'  <ellipse cx="{x}" cy="206" rx="18" ry="26" transform="rotate({s * 30} {x} 206)" fill="url(#ten)" {st(6)}/>\n'
    body += f'  <path d="M122 80 Q114 58 124 50 M130 78 Q134 54 146 50" fill="none" stroke="{OUT}" stroke-width="16" stroke-linecap="round"/>\n'
    body += '  <path d="M122 80 Q114 58 124 50 M130 78 Q134 54 146 50" fill="none" stroke="#FFD93D" stroke-width="7" stroke-linecap="round"/>\n'
    body += head(68, 58)
    body += eyes(118, 28) + cheeks(148, 54)
    if open_:
        body += f'  <path d="M96 150 Q128 124 160 150 Q128 144 96 150 Z" fill="url(#gaga)" {st(5)}/>\n'
        body += f'  <path d="M100 152 Q128 146 156 152 Q150 184 128 184 Q106 184 100 152 Z" fill="#8A2A4A" {st(5)}/>\n'
        body += f'  <path d="M104 166 Q128 160 152 166 Q146 190 128 192 Q110 190 104 166 Z" fill="url(#gaga)" {st(5)}/>\n'
    else:
        body += f'  <path d="M94 152 Q128 128 162 152 Q162 168 128 170 Q94 168 94 152 Z" fill="url(#gaga)" {st(5)}/>\n'
        body += f'  <path d="M98 154 Q128 160 158 154" fill="none" {st(4)}/>\n'
    body += f'  <circle cx="118" cy="144" r="2.5" fill="{OUT}"/><circle cx="138" cy="144" r="2.5" fill="{OUT}"/>\n'
    body += shine(94, 96, 16, 7, -30)
    return defs, body


def sheep(open_: bool) -> tuple:
    defs = ten("ten", "#FFE6D2") + EYE_DEFS + radial("yun", [(0, "#FFFFFF"), (0.6, "#FBF6FF"), (1, "#E2D6F0")], 0.4, 0.3, 0.8)
    body = '  <ellipse cx="128" cy="246" rx="80" ry="10" fill="url(#golge)"/>\n'
    for x in (102, 154):
        body += f'  <rect x="{x - 10}" y="214" width="20" height="30" rx="10" fill="#6B5A7A" {st(5)}/>\n'
    wool = [(128 + 54 * math.cos(a), 198 + 24 * math.sin(a)) for a in [k * math.tau / 9 for k in range(9)]]
    wool += [(128 + 72 * math.cos(a), 124 + 64 * math.sin(a)) for a in [k * math.tau / 12 for k in range(12)]]
    circles = "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="24"/>' for x, y in wool)
    body += f'  <g fill="{OUT}" {st(14)}>{circles}</g>\n'
    body += f'  <g fill="url(#yun)">{circles}<ellipse cx="128" cy="198" rx="54" ry="24"/><ellipse cx="128" cy="124" rx="72" ry="64"/></g>\n'
    for s in (1, -1):
        x = 128 - s * 66
        body += f'  <ellipse cx="{x}" cy="124" rx="24" ry="12" transform="rotate({s * 16} {x} 124)" fill="#E9BFA0" {st(6)}/>\n'
    body += f'  <ellipse cx="128" cy="136" rx="50" ry="50" fill="url(#ten)" {st()}/>\n'
    tuft = "".join(f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y, r in ((104, 94, 17), (128, 86, 19), (152, 94, 17)))
    body += f'  <g fill="url(#yun)" {st(6)}>{tuft}</g>\n'
    body += eyes(130, 22, 12, 15) + cheeks(154, 38)
    body += f'  <ellipse cx="128" cy="152" rx="9" ry="6" fill="#C98A8A"/>\n'
    body += open_mouth(128, 160, 17, 26) if open_ else smile(128, 162, 10)
    body += shine(92, 80, 16, 7, -30)
    return defs, body


def rooster(open_: bool) -> tuple:
    defs = ten("ten", "#FFF4E6") + EYE_DEFS + ten("ibik", "#FF4F5E") + ten("gaga", "#FFC23D")
    body = ""
    # Kuyruk: sağ arkada yelpaze gibi açılan üç renkli tüy
    for color, angle in (("#3FB57A", -6), ("#4AA3FF", 16), ("#FF9A3D", 38)):
        body += f'  <g transform="rotate({angle} 150 212)"><ellipse cx="150" cy="140" rx="20" ry="50" fill="{color}" {st(6)}/></g>\n'
    body += animal_base("#FFF4E6", "", "#FFC23D")
    for s in (1, -1):
        x = 128 - s * 50
        body += f'  <ellipse cx="{x}" cy="206" rx="18" ry="26" transform="rotate({s * 30} {x} 206)" fill="#F2E0CC" {st(6)}/>\n'
    comb = "".join(f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y, r in ((106, 72, 18), (128, 60, 22), (150, 72, 18)))
    body += f'  <g fill="url(#ibik)" {st(6)}>{comb}</g>\n'
    body += head(64, 58, 134)
    body += eyes(120, 26) + cheeks(150, 50)
    if open_:
        body += f'  <path d="M110 144 L128 128 L146 144 Z" fill="url(#gaga)" {st(5)}/>\n'
        body += f'  <path d="M112 146 H144 L128 166 Z" fill="#8A2A4A" {st(4)}/>\n'
        body += f'  <path d="M114 160 H142 L128 180 Z" fill="url(#gaga)" {st(5)}/>\n'
        body += f'  <ellipse cx="128" cy="192" rx="10" ry="12" fill="url(#ibik)" {st(5)}/>\n'
    else:
        body += f'  <path d="M110 146 L128 132 L146 146 L128 164 Z" fill="url(#gaga)" {st(5)}/>\n'
        body += f'  <path d="M111 146 H145" {st(4)}/>\n'
        body += f'  <ellipse cx="128" cy="178" rx="10" ry="13" fill="url(#ibik)" {st(5)}/>\n'
    body += shine(96, 100, 14, 6, -30)
    return defs, body


def frog(open_: bool) -> tuple:
    # Zıpla Zıpla'daki kurbağanın renkleri ve biçimi
    defs = radial("ten", [(0, "#B8F58A"), (0.5, "#6FD35A"), (1, "#3C9E44")], 0.38, 0.3, 0.8) + EYE_DEFS
    defs += linear("karin", [(0, "#FAFFD6"), (1, "#DDF3A0")])
    body = animal_base("#6FD35A", "url(#karin)")
    # Önce kalın dış hat, sonra dolgu: göz tümsekleri ve baş tek parça görünür
    shapes = '<circle cx="84" cy="98" r="36"/><circle cx="172" cy="98" r="36"/><ellipse cx="128" cy="146" rx="88" ry="54"/>'
    body += f'  <g fill="{OUT}" {st(14)}>{shapes}</g>\n'
    body += f'  <g fill="url(#ten)">{shapes}</g>\n'
    for x in (84, 172):
        body += f'  <circle cx="{x}" cy="96" r="24" fill="#FFFFFF" {st(4)}/>\n'
    body += eyes(98, 44, 13, 15) + cheeks(156, 62)
    body += f'  <circle cx="116" cy="136" r="3" fill="{OUT}"/><circle cx="140" cy="136" r="3" fill="{OUT}"/>\n'
    if open_:
        body += f'  <path d="M92 150 Q128 152 164 150 Q158 194 128 194 Q98 194 92 150 Z" fill="#8A2A4A" {st(5)}/>\n'
        body += '  <path d="M106 178 Q128 166 150 178 Q144 192 128 192 Q112 192 106 178 Z" fill="#FF8FB0"/>\n'
    else:
        body += f'  <path d="M90 154 Q128 180 166 154" fill="none" {st(5)}/>\n'
    body += shine(64, 82, 10, 5, -35) + shine(152, 82, 10, 5, -35)
    return defs, body


def lion(open_: bool) -> tuple:
    # Hafıza'daki aslanın renkleri: turuncu yele, krem yüz
    defs = radial("yele", [(0, "#FFC06A"), (0.55, "#F28A2E"), (1, "#D2601A")], 0.45, 0.4, 0.75)
    defs += radial("ten", [(0, "#FFF2CC"), (0.55, "#FFD37A"), (1, "#EFA845")], 0.4, 0.3, 0.75) + EYE_DEFS
    defs += radial("burun", [(0, "#B8704A"), (1, "#6A3013")], 0.4, 0.3, 0.8)
    body = f'  <path d="M172 224 C208 226 218 206 210 186" fill="none" stroke="{OUT}" stroke-width="16" stroke-linecap="round"/>\n'
    body += '  <path d="M172 224 C208 226 218 206 210 186" fill="none" stroke="#F6C267" stroke-width="7" stroke-linecap="round"/>\n'
    body += f'  <circle cx="209" cy="180" r="13" fill="url(#yele)" {st(6)}/>\n'
    body += animal_base("#FFD37A")
    mane = [(128 + 78 * math.cos(a), 128 + 72 * math.sin(a)) for a in [k * math.tau / 12 for k in range(12)]]
    circles = "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="30"/>' for x, y in mane)
    body += f'  <g fill="{OUT}" {st(14)}>{circles}<circle cx="128" cy="128" r="78"/></g>\n'
    body += f'  <g fill="url(#yele)">{circles}<circle cx="128" cy="128" r="78"/></g>\n'
    for x in (80, 176):
        body += f'  <circle cx="{x}" cy="80" r="18" fill="url(#ten)" {st(6)}/><circle cx="{x}" cy="80" r="8" fill="#F2A08A"/>\n'
    body += head(62, 56, 136)
    body += eyes(124, 25, 13, 16) + cheeks(152, 44)
    body += f'  <ellipse cx="116" cy="160" rx="16" ry="12" fill="#FFF8EA"/><ellipse cx="140" cy="160" rx="16" ry="12" fill="#FFF8EA"/>\n'
    body += f'  <path d="M118 144 Q128 140 138 144 Q136 154 128 156 Q120 154 118 144 Z" fill="url(#burun)" {st(4)}/>\n'
    body += open_mouth(128, 164, 20, 30) if open_ else smile(128, 164, 11)
    body += shine(96, 106, 14, 6, -30)
    return defs, body


ANIMALS = {"kedi": cat, "kopek": dog, "inek": cow, "ordek": duck, "koyun": sheep, "horoz": rooster, "kurbaga": frog, "aslan": lion}


def animals() -> None:
    for name, draw in ANIMALS.items():
        for open_, suffix in ((False, ""), (True, "_ses")):
            defs, body = draw(open_)
            write(f"{name}{suffix}.svg", 256, 256, body, defs)


# --- Sahne ---

def curtain_top() -> None:
    # Üst saçak: 320 genişlik, 80'lik kıvrımlar (yatayda döşenir), altı yarım daire dilimli, altın kenarlı
    defs = linear("kadife", [(0, "#C8325A"), (0.5, "#F0527A"), (1, "#C8325A")], 1, 0)
    body = ""
    path = "M0 0 H320 V64"
    for k in range(4):
        x = 320 - k * 80
        path += f" Q{x - 40} 118 {x - 80} 64"
    path += " Z"
    body += f'  <path d="{path}" fill="{OUT}" stroke="{OUT}" stroke-width="12" stroke-linejoin="round"/>\n'
    body += f'  <path d="{path}" fill="#E0406A"/>\n'
    for k in range(4):
        body += f'  <path d="M{k * 80} 0 H{k * 80 + 80} V64 Q{k * 80 + 40} 118 {k * 80} 64 Z" fill="url(#kadife)"/>\n'
    edge = "M0 64" + "".join(f" Q{k * 80 + 40} 118 {k * 80 + 80} 64" for k in range(4))
    body += f'  <path d="{edge}" fill="none" stroke="#FFD04A" stroke-width="9" stroke-linecap="round"/>\n'
    body += '  <path d="M0 18 H320" stroke="#FFD04A" stroke-width="8"/>\n'
    for k in range(4):
        body += f'  <circle cx="{k * 80 + 40}" cy="92" r="8" fill="#FFD04A" {st(4)}/>\n'
    write("perde_ust.svg", 320, 124, body, defs)


def curtain_side() -> None:
    # Yan perde (sol): tepede geniş, iple toplanmış, altta açılan kıvrımlı kumaş
    defs = linear("kadife", [(0, "#F45C82"), (0.25, "#C8325A"), (0.5, "#F0527A"), (0.75, "#C8325A"), (1, "#E0406A")], 1, 0)
    defs += ten("ip", "#FFD04A")
    shape = "M0 0 H150 Q146 120 70 190 Q108 232 124 300 H0 Z"
    body = f'  <path d="{shape}" fill="url(#kadife)" {st(8)}/>\n'
    body += f'  <path d="M40 0 Q46 110 30 190 M86 0 Q84 100 58 186 M30 196 Q40 250 30 300 M62 196 Q84 250 80 300" fill="none" stroke="#B0284E" stroke-width="7" stroke-linecap="round" opacity="0.7"/>\n'
    body += f'  <ellipse cx="62" cy="190" rx="44" ry="15" transform="rotate(-10 62 190)" fill="url(#ip)" {st(6)}/>\n'
    body += f'  <circle cx="102" cy="184" r="12" fill="url(#ip)" {st(5)}/>\n'
    body += shine(22, 60, 6, 30, 0, 0.35)
    write("perde_yan.svg", 160, 304, body, defs)


def stage_floor() -> None:
    # Sahne tabanı: 320 genişlik (yatayda döşenir); üstte açık tahta yüzey, önde koyu ön yüz ve altın şerit
    defs = linear("ust", [(0, "#F2C48A"), (1, "#D99A5A")])
    defs += linear("on", [(0, "#B06A34"), (1, "#8A4E24")])
    body = '  <rect x="0" y="0" width="320" height="30" fill="url(#ust)"/>\n'
    for x in (0, 80, 160, 240):
        body += f'  <path d="M{x + 40} 4 V26" stroke="#C98A4B" stroke-width="4" stroke-linecap="round"/>\n'
    body += f'  <path d="M0 3 H320" stroke="#FFE3BA" stroke-width="5"/>\n'
    body += '  <rect x="0" y="30" width="320" height="42" fill="url(#on)"/>\n'
    body += f'  <path d="M0 30 H320" stroke="{OUT}" stroke-width="7"/>\n'
    body += '  <path d="M0 44 H320" stroke="#FFD04A" stroke-width="6"/>\n'
    for x in (0, 160):
        body += f'  <circle cx="{x + 80}" cy="60" r="6" fill="#FFD04A" {st(3)}/>\n'
    body += f'  <path d="M0 72 H320" stroke="{OUT}" stroke-width="8"/>\n'
    write("sahne_tabani.svg", 320, 76, body, defs)


def lights() -> None:
    # Işık zinciri: 320 genişlik, 4 renkli ampul (yatayda döşenir)
    body = f'  <path d="M0 10 Q40 34 80 10 Q120 34 160 10 Q200 34 240 10 Q280 34 320 10" fill="none" stroke="{OUT}" stroke-width="4"/>\n'
    for k, color in enumerate(["#FFD23F", "#FF6FB5", "#4AA3FF", "#7BD85A"]):
        x = 40 + k * 80
        body += f'  <rect x="{x - 6}" y="16" width="12" height="10" rx="3" fill="#9A8FC2" {st(3)}/>\n'
        body += f'  <ellipse cx="{x}" cy="40" rx="12" ry="16" fill="{color}" {st(4)}/>\n'
        body += f'  <ellipse cx="{x - 4}" cy="35" rx="4" ry="6" fill="#FFFFFF" opacity="0.75"/>\n'
    write("isiklar.svg", 320, 64, body)


# --- Efektler ve simgeler ---

def effects() -> None:
    write("nota.svg", 128, 128, note_shape(46, 100, 1.0, "#FFFFFF"))
    write("nota_cift.svg", 160, 128, note_shape(36, 104, 1.0, "#FFFFFF", double=True))
    defs = ('    <radialGradient id="d" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="1"/>'
            '<stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.6"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>\n')
    write("isik.svg", 128, 128, '  <circle cx="64" cy="64" r="64" fill="url(#d)"/>\n', defs)


def icons() -> None:
    # Ksilofon simgesi: eğik dört tuş ve tokmak
    defs = radial("top", [(0, "#FFB3B3"), (0.5, "#FF5B6E"), (1, "#C8324A")], 0.35, 0.3, 0.8)
    body = f'  <path d="M40 96 L220 128 M40 196 L220 176" stroke="{OUT}" stroke-width="22" stroke-linecap="round"/>\n'
    body += '  <path d="M40 96 L220 128 M40 196 L220 176" stroke="#C98A4B" stroke-width="12" stroke-linecap="round"/>\n'
    for k, color in enumerate(["#FF5B5B", "#FFD23F", "#7BD85A", "#4AA3FF"]):
        x = 58 + k * 44
        h = 150 - k * 18
        body += f'  <rect x="{x}" y="{146 - h / 2:g}" width="34" height="{h}" rx="12" fill="{color}" {st(6)}/>\n'
        body += f'  <rect x="{x + 6}" y="{146 - h / 2 + 10:g}" width="7" height="{h * 0.4:g}" rx="3.5" fill="#FFFFFF" opacity="0.6"/>\n'
    body += '  <g transform="rotate(35 200 60)">'
    body += f'<rect x="193" y="60" width="14" height="110" rx="7" fill="#F2C48A" {st(5)}/><circle cx="200" cy="54" r="26" fill="url(#top)" {st(6)}/>'
    body += '</g>\n'
    write("ikon_ksilofon.svg", 256, 256, body, defs)

    # Davul simgesi: davul ve çapraz bagetler
    body = ""
    for x1, y1, x2, y2 in ((56, 30, 150, 120), (200, 30, 106, 120)):
        body += f'  <path d="M{x1} {y1} L{x2} {y2}" stroke="{OUT}" stroke-width="20" stroke-linecap="round"/>'
        body += f'<path d="M{x1} {y1} L{x2} {y2}" stroke="#F2C48A" stroke-width="10" stroke-linecap="round"/>'
        body += f'<circle cx="{x1}" cy="{y1}" r="13" fill="#FFF1C8" {st(5)}/>\n'
    color = "#FF5B6E"
    defs = linear("kab", [(0, light(color, 0.35)), (0.3, color), (1, dark(color, 0.25))], 1, 0)
    defs += radial("deri", [(0, "#FFFFFF"), (0.7, "#FFF6EA"), (1, "#EADBC8")], 0.4, 0.35, 0.75)
    body += f'  <path d="M40 132 V196 A88 30 0 0 0 216 196 V132 Z" fill="url(#kab)" {st(8)}/>\n'
    body += '  <path d="M48 150 L80 206 L112 156 L144 210 L176 156 L208 200" fill="none" stroke="#FFD23F" stroke-width="8" stroke-linejoin="round" stroke-linecap="round"/>\n'
    body += f'  <ellipse cx="128" cy="132" rx="88" ry="30" fill="#DCD6F0" {st(7)}/>\n'
    body += f'  <ellipse cx="128" cy="132" rx="76" ry="23" fill="url(#deri)" {st(4)}/>\n'
    body += shine(98, 126, 20, 6, -5)
    write("ikon_davul.svg", 256, 256, body, defs)

    # Hayvan simgesi: kedi başı ve nota
    defs, _ = cat(True)
    body = ""
    for s in (1, -1):
        body += f'  <path d="M{128 - s * 64} 118 L{128 - s * 70} 40 L{128 - s * 14} 82 Z" fill="url(#ten)" {st()}/>\n'
        body += f'  <path d="M{128 - s * 58} 100 L{128 - s * 62} 60 L{128 - s * 28} 82 Z" fill="#FF9FBF"/>\n'
    body += f'  <ellipse cx="128" cy="140" rx="84" ry="72" fill="url(#ten)" {st(8)}/>\n'
    body += eyes(128, 32, 16, 19) + cheeks(160, 58)
    body += f'  <path d="M118 150 H138 L128 160 Z" fill="#FF7FA3" {st(4)}/>\n'
    body += open_mouth(128, 166, 18, 28)
    body += note_shape(196, 76, 0.55, "#8B6CF6")
    write("ikon_hayvan.svg", 256, 256, body, defs)


if __name__ == "__main__":
    xylophone_bars()
    xylophone_frame()
    mallet()
    notebook()
    song_icons()
    bass_drum()
    cylinder_drum("trampet.svg", "#FFC23D", 230, 44, 76, True)
    cylinder_drum("tom_mavi.svg", "#4AA3FF", 180, 36, 84, False)
    cylinder_drum("tom_yesil.svg", "#5CC95C", 180, 36, 84, False)
    cymbal()
    maracas()
    animals()
    curtain_top()
    curtain_side()
    stage_floor()
    lights()
    effects()
    icons()
