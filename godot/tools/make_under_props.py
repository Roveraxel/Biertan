"""Pixel props for cellars and cells: python3 tools/make_under_props.py <sprites/Props dir>"""
import sys, random
from PIL import Image, ImageDraw
OUT = sys.argv[-1]
def rect(d, x0, y0, x1, y1, c): d.rectangle([x0, y0, x1, y1], fill=c)

def jar(d, x, y, w, h, body, lid):
    rect(d, x, y + 3, x + w, y + h, body); rect(d, x + 1, y + 4, x + 1, y + h - 1, tuple(min(255, int(v * 1.35)) for v in body))
    rect(d, x + 1, y, x + w - 1, y + 3, lid); rect(d, x, y + h, x + w, y + h, (40, 28, 20))

def jar_shelf():
    im = Image.new("RGBA", (120, 96), (0, 0, 0, 0)); d = ImageDraw.Draw(im); r = random.Random(3)
    wood, dark = (122, 66, 48), (78, 40, 30)
    rect(d, 4, 6, 116, 92, dark); rect(d, 8, 10, 112, 88, (40, 26, 22))
    cols = [(150, 40, 48), (232, 150, 40), (110, 150, 52), (200, 70, 36), (210, 190, 80), (96, 130, 60), (170, 60, 90)]
    for i, y in enumerate((12, 40, 66)):
        for j in range(8):
            c = r.choice(cols); jar(d, 12 + j * 12, y + 4, 9, 16, c, r.choice([(210, 80, 40), (190, 190, 180), (150, 150, 140)]))
        rect(d, 4, y + 21, 116, y + 25, wood)
    rect(d, 4, 4, 116, 8, wood); rect(d, 4, 88, 116, 93, wood); rect(d, 2, 4, 5, 93, wood); rect(d, 115, 4, 118, 93, wood)
    im.save(f"{OUT}/jar_shelf.png")

def stump_stool():
    im = Image.new("RGBA", (56, 56), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    rect(d, 12, 24, 44, 50, (110, 78, 52)); rect(d, 12, 24, 15, 50, (140, 102, 70)); rect(d, 41, 24, 44, 50, (80, 56, 38))
    for y in range(28, 50, 5): rect(d, 17, y, 39, y, (92, 64, 44))
    d.ellipse([8, 44, 48, 54], fill=(70, 50, 36)); rect(d, 12, 24, 44, 46, (110, 78, 52))
    d.ellipse([9, 14, 47, 30], fill=(190, 50, 46)); d.ellipse([14, 17, 42, 27], fill=(240, 230, 220)); d.ellipse([19, 19, 37, 25], fill=(190, 50, 46))
    im.save(f"{OUT}/stump_stool.png")

def pallet_table():
    im = Image.new("RGBA", (104, 76), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    wood, dark = (76, 52, 40), (48, 32, 26)
    for x in (10, 88): rect(d, x, 46, x + 6, 72, dark)
    rect(d, 6, 40, 98, 48, wood); rect(d, 6, 48, 98, 50, dark)
    for x in range(8, 98, 14): rect(d, x, 40, x + 1, 48, dark)
    jar(d, 14, 8, 20, 32, (96, 130, 50), (220, 130, 40)); jar(d, 38, 14, 18, 26, (110, 150, 56), (220, 130, 40))
    jar(d, 60, 6, 22, 34, (92, 126, 48), (210, 90, 40)); jar(d, 84, 18, 14, 22, (210, 150, 50), (190, 190, 180))
    im.save(f"{OUT}/pallet_table.png")

def iron_grate():
    W, H = 160, 112
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im); iron = (34, 30, 30); hi = (86, 78, 74)
    import math
    for x in range(8, W - 8, 13):
        t = (x - W / 2) / (W / 2 - 8); top = int(14 + (1 - math.sqrt(max(0, 1 - t * t))) * 42)
        rect(d, x, top, x + 3, H - 6, iron); rect(d, x, top, x, H - 6, hi)
    pts = [(8 + (W - 16) * i / 40, 14 + (1 - math.sqrt(max(0, 1 - ((i / 40 - 0.5) * 2) ** 2))) * 42) for i in range(41)]
    for (a, b), (c, e) in zip(pts, pts[1:]): d.line([a, b, c, e], fill=iron, width=4)
    rect(d, 6, 98, W - 6, 108, iron); rect(d, 6, 56, W - 6, 59, iron); rect(d, 6, 30, 9, 108, iron); rect(d, W - 10, 30, W - 7, 108, iron)
    rect(d, W // 2 - 3, 12, W // 2 + 3, 108, iron)   # centre post
    im.save(f"{OUT}/iron_grate.png")

for f in (jar_shelf, stump_stool, pallet_table, iron_grate): f(); print("wrote", f.__name__)
