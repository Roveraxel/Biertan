# sheet2rot.py <sheet.png> <out_dir> : a PixelLab workbench 8-column rotation sheet (south, east, north, west,
# south-east, north-east, north-west, south-west) -> rotation_<dir>.png with the flat background keyed out
import sys, os
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
DIRS = ["south", "east", "north", "west", "south-east", "north-east", "north-west", "south-west"]
im = Image.open(src).convert("RGBA")
w, h = im.size; cell = w // 8; top = h - cell
bg = im.getpixel((0, h - 1))
os.makedirs(out, exist_ok=True)
for i, d in enumerate(DIRS):
    c = im.crop((i * cell, top, (i + 1) * cell, h))
    px = c.load()
    for y in range(cell):
        for x in range(cell):
            if px[x, y][:3] == bg[:3]: px[x, y] = (0, 0, 0, 0)
    c.save(os.path.join(out, "rotation_%s.png" % d))
print("bg", bg, "cell", cell)
