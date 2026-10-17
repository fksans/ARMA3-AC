#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把脚本里定义的图标形状同时生成 Arma 配置 include 和白色透明缩略图（64x64 PNG）。
用法（只需要 Pillow）：
    python3 tools/make_shapes.py <png 输出目录>

会写出 addons/briefing/CfgShapes.hpp（相对仓库根目录，仓库根目录 = 脚本所在目录的上一级），
以及 <png 输出目录>/<shape>_ca.png（每个形状一张缩略图）。

拿到缩略图后，再用 hemtt 转成 PAA：

    for f in <png 输出目录>/*.png; do
        hemtt utils paa convert "$f" addons/briefing/ui/shapes/$(basename "${f%.png}").paa
    done

坐标：所有形状都以 h（图标半边长）为单位，x 向右、y 向上，可见范围约为 [-1.1, 1.1]。
图元（形状 = 一个 dict，可含 "lines" 和 "fills"）：
    line: (closed, [(x, y), ...])   折线；closed=True 时最后一个点连回第一个点。
    fill: (x, y, size, angle_deg)   以 (x, y) 为中心、边长 size 的正方形，顺时针旋转 angle_deg 度（45 = 菱形）。
"""

import math
import os
import sys

from PIL import Image, ImageDraw

# 仓库根目录 = 脚本所在目录的上一级
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HPP_PATH = os.path.join(REPO_ROOT, "addons", "briefing", "CfgShapes.hpp")

# 缩略图参数
SUPERSAMPLE = 256            # 先按 4 倍尺寸渲染
OUTPUT_SIZE = 64             # 再降采样到 64x64
LINE_WIDTH = 14              # 256x256 下的线宽（像素）
SCALE = SUPERSAMPLE / 2.5    # h 单位 -> 像素，±1.25 h 正好铺满
CENTER = SUPERSAMPLE / 2.0   # 原点在图像中心


# ---------------------------------------------------------------- 图元构造辅助

def circle(r, n=20):
    """整圆：n 个点的闭合折线。"""
    pts = []
    for i in range(n):
        a = math.radians(360.0 * i / n)
        pts.append((round(math.cos(a) * r, 3), round(math.sin(a) * r, 3)))
    return pts


def arc(r, a0, a1, n):
    """开口圆弧：从 a0 到 a1（度，0 = +x 轴，逆时针，y 向上），n 个点。"""
    pts = []
    for i in range(n):
        a = math.radians(a0 + (a1 - a0) * i / (n - 1))
        pts.append((round(math.cos(a) * r, 3), round(math.sin(a) * r, 3)))
    return pts


def tick(r0, r1, angle_deg):
    """从半径 r0 到 r1、方向为 angle_deg 的短线。"""
    a = math.radians(angle_deg)
    return (False, [(round(math.cos(a) * r0, 3), round(math.sin(a) * r0, 3)),
                    (round(math.cos(a) * r1, 3), round(math.sin(a) * r1, 3))])


def question_hook():
    """问号上半部分：一段圆弧整体上移，再收尾到 (0, -0.25)，连成一条开口折线。"""
    pts = [(x, round(y + 0.25, 3)) for (x, y) in arc(0.32, 160, -60, 8)]
    pts.append((0, -0.25))
    return pts


# ---------------------------------------------------------------- 形状定义（唯一数据源）

SHAPES = {
    "diamond": {
        "fills": [(0, 0, 1.4, 45)],
    },
    "box": {
        "lines": [(True, [(-1, -1), (1, -1), (1, 1), (-1, 1)])],
        "fills": [(0, 0, 0.5, 0)],
    },
    "triangle": {
        "lines": [(True, [(0, 1), (0.9, -0.6), (-0.9, -0.6)])],
    },
    "hollowDiamond": {
        "lines": [(True, [(0, 1), (1, 0), (0, -1), (-1, 0)])],
        "fills": [(0, 0, 0.4, 45)],
    },
    "dot": {
        "fills": [(0, 0, 0.7, 0), (0, 0, 0.7, 45)],
    },
    "circle": {
        "lines": [(True, circle(0.9))],
    },
    "cross": {
        "lines": [(False, [(-0.8, -0.8), (0.8, 0.8)]),
                  (False, [(-0.8, 0.8), (0.8, -0.8)])],
    },
    "flag": {
        "lines": [(False, [(-0.6, -1), (-0.6, 1)]),
                  (True, [(-0.6, 1), (0.8, 0.65), (-0.6, 0.3)])],
    },
    "objective": {
        "lines": [(True, circle(0.65)),
                  tick(0.65, 1.1, 0), tick(0.65, 1.1, 180),
                  tick(0.65, 1.1, 90), tick(0.65, 1.1, 270)],
        "fills": [(0, 0, 0.25, 45)],
    },
    "triangleSolid": {
        "lines": [(True, [(0, 1), (0.9, -0.6), (-0.9, -0.6)])],
        "fills": [(0, -0.05, 0.55, 45)],
    },
    "boxSolid": {
        "lines": [(True, [(-0.9, -0.9), (0.9, -0.9), (0.9, 0.9), (-0.9, 0.9)])],
        "fills": [(0, 0, 1.1, 0)],
    },
    "warning": {
        "lines": [(True, [(0, 1), (1, -0.75), (-1, -0.75)]),
                  (False, [(0, 0.45), (0, -0.2)])],
        "fills": [(0, -0.45, 0.18, 0)],
    },
    "unknown": {
        "lines": [(True, circle(0.95)),
                  (False, question_hook())],
        "fills": [(0, -0.55, 0.16, 0)],
    },
    "start": {
        "lines": [(True, [(-0.7, 0.8), (0.9, 0), (-0.7, -0.8)])],
    },
    "end": {
        # 方格旗：方框里对角两块实心
        "lines": [(True, [(-0.9, -0.9), (0.9, -0.9), (0.9, 0.9), (-0.9, 0.9)])],
        "fills": [(-0.45, 0.45, 0.9, 0), (0.45, -0.45, 0.9, 0)],
    },
    "pickup": {
        "lines": [(True, circle(0.9)),
                  (False, [(0, -0.5), (0, 0.5)]),
                  (False, [(-0.35, 0.15), (0, 0.5), (0.35, 0.15)])],
    },
    "join": {
        "lines": [(False, [(-0.9, 0.7), (0, 0), (-0.9, -0.7)]),
                  (False, [(0, 0), (0.9, 0)]),
                  (False, [(0.55, 0.3), (0.9, 0), (0.55, -0.3)])],
    },
    "ambush": {
        "lines": [(False, arc(0.9, 60, 300, 12)),
                  tick(0.9, 1.2, 120), tick(0.9, 1.2, 180), tick(0.9, 1.2, 240)],
    },
    "marker": {
        "lines": [(True, [(0, -1), (0.65, 0.1), (0.5, 0.65), (0, 0.9),
                          (-0.5, 0.65), (-0.65, 0.1)])],
        "fills": [(0, 0.3, 0.3, 45)],
    },
}


# ---------------------------------------------------------------- 输出 1：CfgShapes.hpp

def fmt_num(v):
    """配置里的数字：最多 3 位小数，去掉末尾多余的 0，"-0" 写成 "0"。"""
    s = "%.3f" % v
    s = s.rstrip("0").rstrip(".")
    if s in ("-0", ""):
        s = "0"
    return s


def write_hpp(path):
    """写出 BRF_Shapes，CRLF 换行。"""
    lines = [
        "// 由 tools/make_shapes.py 生成，不要手改；改形状请改脚本后重新生成（同时会重新生成缩略图）。",
        "// lines[] = {{闭合 0/1, {x1, y1, x2, y2, ...}}, ...}   fills[] = {{x, y, 边长, 角度}, ...}   单位：图标半边长，y 向上",
        "class BRF_Shapes {",
    ]
    for name, prim in SHAPES.items():
        lines.append("    class %s {" % name)

        entries = []
        for closed, pts in prim.get("lines", []):
            coords = ", ".join(fmt_num(c) for p in pts for c in p)
            entries.append("{%d, {%s}}" % (1 if closed else 0, coords))
        lines.append("        lines[] = {%s};" % ", ".join(entries))

        fills = []
        for f in prim.get("fills", []):
            fills.append("{%s}" % ", ".join(fmt_num(v) for v in f))
        lines.append("        fills[] = {%s};" % ", ".join(fills))

        lines.append("    };")
    lines.append("};")

    with open(path, "w", encoding="utf-8", newline="") as fp:
        fp.write("\r\n".join(lines) + "\r\n")


# ---------------------------------------------------------------- 输出 2：缩略图

def to_pixel(x, y):
    """h 单位（y 向上）-> 图像像素（PIL 的 y 向下）。"""
    return (CENTER + x * SCALE, CENTER - y * SCALE)


def fill_polygon(x, y, size, angle_deg):
    """中心 (x, y)、边长 size、顺时针旋转 angle_deg 度的正方形 -> 4 个角点（像素）。"""
    half = size / 2.0
    a = math.radians(angle_deg)
    c, s = math.cos(a), math.sin(a)
    pts = []
    for px, py in ((half, half), (half, -half), (-half, -half), (-half, half)):
        # 在 y 向上的坐标系里顺时针旋转
        rx = px * c + py * s
        ry = -px * s + py * c
        pts.append(to_pixel(x + rx, y + ry))
    return pts


def render_png(shape, path):
    """256x256 超采样渲染，再降采样到 64x64，纯白不透明图形 + 全透明背景。"""
    img = Image.new("RGBA", (SUPERSAMPLE, SUPERSAMPLE), (255, 255, 255, 0))  # 透明白：缩放时边缘不混进黑色
    draw = ImageDraw.Draw(img)
    white = (255, 255, 255, 255)

    for closed, pts in shape.get("lines", []):
        pixel_pts = [to_pixel(x, y) for (x, y) in pts]
        if closed:
            pixel_pts.append(pixel_pts[0])
        draw.line(pixel_pts, fill=white, width=LINE_WIDTH, joint="curve")

    for f in shape.get("fills", []):
        draw.polygon(fill_polygon(*f), fill=white)

    img = img.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.LANCZOS)
    img.save(path)


# ---------------------------------------------------------------- 入口

def main(argv):
    if len(argv) != 2:
        print("用法：python3 tools/make_shapes.py <png 输出目录>")
        return 2

    png_dir = argv[1]
    os.makedirs(os.path.dirname(HPP_PATH), exist_ok=True)
    os.makedirs(png_dir, exist_ok=True)

    write_hpp(HPP_PATH)
    for name, shape in SHAPES.items():
        render_png(shape, os.path.join(png_dir, "%s_ca.png" % name))

    print("已写出 %d 个形状：%s，以及 %d 张缩略图到 %s。"
          % (len(SHAPES), HPP_PATH, len(SHAPES), png_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))