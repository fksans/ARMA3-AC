"""AC 简报图标库生成脚本：白色线条图标，透明底，128x128（游戏里按元素颜色着色）。

用法（需要 Pillow 和 hemtt）：
    python3 tools/make_icons.py <png 输出目录>
    for f in <png 输出目录>/*.png; do
        hemtt utils paa convert "$f" addons/briefing/ui/icons/$(basename "${f%.png}").paa
    done
坐标用 0..1（y 向下），先在 4 倍大小上画再缩小，边缘平滑。
"""
import math, os, sys
from PIL import Image, ImageDraw

SIZE, SS = 128, 4
W = SIZE * SS
STROKE = 7 * SS
out = sys.argv[1]
os.makedirs(out, exist_ok=True)

def P(x, y):
    return (x * W, y * W)

class Pen:
    def __init__(self):
        self.img = Image.new('LA', (W, W), (255, 0))
        self.d = ImageDraw.Draw(self.img)
    def line(self, *pts, w=1.0):
        pts = [P(*p) for p in pts]
        self.d.line(pts, fill=(255, 255), width=int(STROKE * w), joint='curve')
        r = STROKE * w / 2
        for x, y in (pts[0], pts[-1]):
            self.d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255))
    def poly(self, *pts, w=1.0):
        self.line(*(list(pts) + [pts[0]]), w=w)
    def fill(self, *pts):
        self.d.polygon([P(*p) for p in pts], fill=(255, 255))
    def ellipse(self, x0, y0, x1, y1, w=1.0, fill=False):
        box = [*P(x0, y0), *P(x1, y1)]
        if fill:
            self.d.ellipse(box, fill=(255, 255))
        else:
            self.d.ellipse(box, outline=(255, 255), width=int(STROKE * w))
    def arc(self, cx, cy, r, a0, a1, w=1.0, n=48):
        pts = [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
                cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
        self.line(*pts, w=w)
    def save(self, name):
        alpha = self.img.resize((SIZE, SIZE), Image.LANCZOS).getchannel('A')
        # 颜色通道全白、只靠透明度出形状：缩小的 mipmap 边缘不会混进黑色
        rgba = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
        rgba.putalpha(alpha)
        rgba.save(os.path.join(out, f'{name}_ca.png'))

# 北约式单位框（横向矩形）
FX0, FY0, FX1, FY1 = 0.12, 0.27, 0.88, 0.73
def frame(p):
    p.poly((FX0, FY0), (FX1, FY0), (FX1, FY1), (FX0, FY1))
def cross(p):
    p.line((FX0, FY0), (FX1, FY1)); p.line((FX0, FY1), (FX1, FY0))
def oval(p):
    p.ellipse(0.27, 0.38, 0.73, 0.62)

ICONS = {}
def icon(name):
    def deco(fn):
        ICONS[name] = fn
        return fn
    return deco

# ---- 地面单位 ----
@icon('inf')
def _(p): frame(p); cross(p)
@icon('armor')
def _(p): frame(p); oval(p)
@icon('mech')
def _(p): frame(p); cross(p); oval(p)
@icon('motor')
def _(p): frame(p); cross(p); p.line((0.5, FY0), (0.5, FY1))
@icon('art')
def _(p): frame(p); p.ellipse(0.43, 0.43, 0.57, 0.57, fill=True)
@icon('mortar')
def _(p):
    frame(p); p.ellipse(0.44, 0.56, 0.56, 0.68)
    p.line((0.5, 0.56), (0.5, 0.36)); p.line((0.42, 0.44), (0.5, 0.35), (0.58, 0.44))
@icon('aa')
def _(p): frame(p); p.arc(0.5, FY1, 0.25, 180, 360)
@icon('recon')
def _(p): frame(p); p.line((FX0, FY1), (FX1, FY0))
@icon('sniper')
def _(p):
    p.ellipse(0.22, 0.22, 0.78, 0.78)
    for a, b in [((0.5, 0.08), (0.5, 0.36)), ((0.5, 0.64), (0.5, 0.92)), ((0.08, 0.5), (0.36, 0.5)), ((0.64, 0.5), (0.92, 0.5))]:
        p.line(a, b)
    p.ellipse(0.47, 0.47, 0.53, 0.53, fill=True)

# ---- 空中 / 海上 ----
@icon('heli')
def _(p):
    p.line((0.14, 0.24), (0.86, 0.24)); p.line((0.5, 0.24), (0.5, 0.36))
    p.ellipse(0.26, 0.36, 0.62, 0.62)
    p.line((0.62, 0.48), (0.88, 0.44)); p.line((0.86, 0.36), (0.88, 0.52))
    p.line((0.32, 0.72), (0.6, 0.72)); p.line((0.36, 0.62), (0.34, 0.72)); p.line((0.54, 0.62), (0.56, 0.72))
@icon('plane')
def _(p):
    p.line((0.5, 0.1), (0.5, 0.9))
    p.line((0.12, 0.6), (0.5, 0.38), (0.88, 0.6))
    p.line((0.34, 0.88), (0.5, 0.78), (0.66, 0.88))
@icon('uav')
def _(p):
    p.poly((0.5, 0.3), (0.9, 0.62), (0.76, 0.66), (0.5, 0.5), (0.24, 0.66), (0.1, 0.62))
    p.line((0.5, 0.5), (0.5, 0.72))
@icon('ship')
def _(p):
    p.poly((0.08, 0.6), (0.92, 0.6), (0.8, 0.76), (0.2, 0.76))
    p.poly((0.32, 0.6), (0.32, 0.46), (0.6, 0.46), (0.6, 0.6))
    p.line((0.46, 0.46), (0.46, 0.26)); p.line((0.38, 0.34), (0.54, 0.34))
@icon('landing')
def _(p):
    p.line((0.2, 0.42), (0.2, 0.68), (0.72, 0.68), (0.72, 0.42))
    p.line((0.72, 0.68), (0.9, 0.5))
    p.arc(0.27, 0.86, 0.09, 180, 360, w=0.7); p.arc(0.5, 0.86, 0.09, 180, 360, w=0.7); p.arc(0.73, 0.86, 0.09, 180, 360, w=0.7)

# ---- 设施 ----
@icon('hq')
def _(p):
    p.line((0.3, 0.9), (0.3, 0.1))
    p.poly((0.3, 0.14), (0.78, 0.14), (0.78, 0.46), (0.3, 0.46))
@icon('supply')
def _(p):
    p.poly((0.16, 0.3), (0.84, 0.3), (0.84, 0.78), (0.16, 0.78))
    p.line((0.16, 0.44), (0.84, 0.44)); p.line((0.5, 0.3), (0.5, 0.78))
@icon('med')
def _(p):
    a, b = 0.38, 0.62
    p.poly((a, 0.14), (b, 0.14), (b, a), (0.86, a), (0.86, b), (b, b), (b, 0.86), (a, 0.86), (a, b), (0.14, b), (0.14, a), (a, a))
@icon('radar')
def _(p):
    p.arc(0.42, 0.34, 0.3, 30, 210)
    p.line((0.16, 0.5), (0.68, 0.18))
    p.line((0.42, 0.34), (0.42, 0.74)); p.line((0.24, 0.88), (0.42, 0.74), (0.6, 0.88))
    p.arc(0.62, 0.3, 0.14, -80, 0, w=0.7); p.arc(0.62, 0.3, 0.26, -75, -5, w=0.7)
@icon('bridge')
def _(p):
    p.line((0.06, 0.42), (0.94, 0.42))
    p.arc(0.5, 0.84, 0.36, 200, 340)
    p.line((0.2, 0.42), (0.2, 0.84)); p.line((0.8, 0.42), (0.8, 0.84))
@icon('airfield')
def _(p):
    p.poly((0.2, 0.86), (0.4, 0.14), (0.6, 0.14), (0.8, 0.86))
    for i in range(3):
        y0 = 0.24 + i * 0.22
        p.line((0.5, y0), (0.5, y0 + 0.1), w=0.7)
@icon('fuel')
def _(p):
    # 水滴：下半是圆弧，上面两条切线收成尖
    cx, cy, r = 0.5, 0.62, 0.25
    p.arc(cx, cy, r, -30, 210)
    left = (cx + r * math.cos(math.radians(210)), cy + r * math.sin(math.radians(210)))
    right = (cx + r * math.cos(math.radians(-30)), cy + r * math.sin(math.radians(-30)))
    p.line(left, (0.5, 0.12), right)
@icon('comms')
def _(p):
    p.line((0.28, 0.9), (0.5, 0.3), (0.72, 0.9)); p.line((0.36, 0.68), (0.64, 0.68))
    p.ellipse(0.45, 0.2, 0.55, 0.3, fill=True)
    p.arc(0.5, 0.25, 0.16, 200, 340, w=0.7); p.arc(0.5, 0.25, 0.28, 205, 335, w=0.7)

# ---- 战术标记 ----
@icon('rally')
def _(p):
    p.ellipse(0.4, 0.4, 0.6, 0.6, fill=True)
    for dx, dy in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
        x0, y0 = 0.5 + dx * 0.42, 0.5 + dy * 0.42
        x1, y1 = 0.5 + dx * 0.2, 0.5 + dy * 0.2
        p.line((x0, y0), (x1, y1))
        px, py = -dy, dx
        p.line((x1 + dx * 0.1 + px * 0.08, y1 + dy * 0.1 + py * 0.08), (x1, y1), (x1 + dx * 0.1 - px * 0.08, y1 + dy * 0.1 - py * 0.08))
@icon('extract')
def _(p):
    p.line((0.2, 0.5), (0.5, 0.22), (0.8, 0.5))
    p.line((0.2, 0.74), (0.5, 0.46), (0.8, 0.74))
    p.line((0.14, 0.9), (0.86, 0.9))
@icon('danger')
def _(p):
    p.poly((0.5, 0.12), (0.9, 0.84), (0.1, 0.84))
    p.line((0.5, 0.38), (0.5, 0.6)); p.ellipse(0.46, 0.68, 0.54, 0.76, fill=True)
@icon('op')
def _(p):
    p.arc(0.5, 0.82, 0.48, 225, 315); p.arc(0.5, 0.18, 0.48, 45, 135)
    p.ellipse(0.38, 0.38, 0.62, 0.62); p.ellipse(0.46, 0.46, 0.54, 0.54, fill=True)
@icon('checkpoint')
def _(p):
    p.line((0.18, 0.86), (0.18, 0.36)); p.line((0.82, 0.86), (0.82, 0.36))
    p.poly((0.1, 0.36), (0.9, 0.36), (0.9, 0.5), (0.1, 0.5))
    for i in range(3):
        x = 0.26 + i * 0.22
        p.fill((x, 0.36), (x + 0.1, 0.36), (x + 0.04, 0.5), (x - 0.06, 0.5))
@icon('vip')
def _(p):
    pts = []
    for i in range(10):
        r = 0.4 if i % 2 == 0 else 0.17
        a = math.radians(-90 + 36 * i)
        pts.append((0.5 + r * math.cos(a), 0.54 + r * math.sin(a)))
    p.poly(*pts)
@icon('ied')
def _(p):
    pts = []
    for i in range(16):
        r = 0.42 if i % 2 == 0 else 0.22
        a = math.radians(-90 + 22.5 * i + (6 if i % 4 == 0 else 0))
        pts.append((0.5 + r * math.cos(a), 0.5 + r * math.sin(a)))
    p.poly(*pts)
    p.ellipse(0.44, 0.44, 0.56, 0.56, fill=True)
@icon('ambush')
def _(p):
    p.arc(0.5, 0.72, 0.36, 200, 340)
    for a in (215, 245, 270, 295, 325):
        r = math.radians(a)
        x0, y0 = 0.5 + 0.36 * math.cos(r), 0.72 + 0.36 * math.sin(r)
        x1, y1 = 0.5 + 0.22 * math.cos(r), 0.72 + 0.22 * math.sin(r)
        p.line((x0, y0), (x1, y1), w=0.8)
    p.line((0.5, 0.86), (0.5, 0.6)); p.line((0.42, 0.68), (0.5, 0.58), (0.58, 0.68))

for name, fn in ICONS.items():
    pen = Pen(); fn(pen); pen.save(name)
print(len(ICONS), 'icons')
