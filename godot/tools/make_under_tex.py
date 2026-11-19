"""Pixel textures (64x64, tileable) for the underground levels: python3 tools/make_under_tex.py <textures dir>"""
import sys, random, math
from PIL import Image
OUT = sys.argv[-1]
N = 64
def clamp(v): return max(0, min(255, int(v)))
def shade(c, k): return tuple(clamp(x * k) for x in c)

def brick():
    r = random.Random(7); im = Image.new("RGB", (N, N), (150, 132, 108))
    rows = 8; bh = N // rows
    base = [(128, 104, 90), (114, 94, 82), (136, 112, 96), (104, 88, 78), (122, 100, 86)]
    for ry in range(rows):
        off = (ry % 2) * 8; x = -off
        while x < N:
            bw = 14 + r.randint(0, 2) * 1
            c = r.choice(base); k = 0.85 + r.random() * 0.3
            for yy in range(ry * bh + 1, ry * bh + bh):
                for xx in range(x + 1, x + bw):
                    t = 1.0 + (0.12 if yy == ry * bh + 1 else 0) - (0.15 if yy == ry * bh + bh - 1 else 0) + (r.random() - 0.5) * 0.14
                    im.putpixel((xx % N, yy % N), shade(c, k * t))
            x += bw + 1 if bw + 1 <= 16 else 16
    # wrap mortar fix: columns at x%N already coloured by loop; good enough
    return im

def flags():
    r = random.Random(11); pts = [(r.random() * N, r.random() * N) for _ in range(11)]
    im = Image.new("RGB", (N, N)); cols = [(150, 146, 138), (140, 136, 128), (156, 152, 142), (132, 128, 120), (146, 140, 130)]
    cc = [r.choice(cols) for _ in pts]
    for y in range(N):
        for x in range(N):
            d = []
            for i, (px, py) in enumerate(pts):
                dx = min(abs(x - px), N - abs(x - px)); dy = min(abs(y - py), N - abs(y - py))
                d.append((dx * dx + dy * dy, i))
            d.sort()
            edge = math.sqrt(d[1][0]) - math.sqrt(d[0][0])
            if edge < 1.6: im.putpixel((x, y), (112, 106, 98))
            else:
                k = 0.92 + r.random() * 0.16 + (0.08 if edge < 3 else 0)
                im.putpixel((x, y), shade(cc[d[0][1]], k))
    return im

def salt():
    r = random.Random(23); im = Image.new("RGB", (N, N))
    bands = [(196, 188, 176), (176, 168, 158), (150, 140, 128), (205, 170, 132), (168, 150, 130), (210, 206, 198), (130, 122, 114)]
    for y in range(N):
        for x in range(N):
            w = math.sin(x / N * 2 * math.pi * 2 + y * 0.2) * 3 + math.sin(x / N * 2 * math.pi * 3) * 2
            b = int(((y + w) / 5.0)) % len(bands)
            c = bands[b]
            k = 0.9 + r.random() * 0.2
            im.putpixel((x, y), shade(c, k))
    for _ in range(60):   # chips and cracks
        x, y = r.randrange(N), r.randrange(N)
        for i in range(r.randint(2, 6)):
            im.putpixel(((x + i) % N, y), shade(bands[r.randrange(len(bands))], 0.55))
    return im

def gravel():
    r = random.Random(31); im = Image.new("RGB", (N, N), (74, 74, 80))
    for _ in range(230):
        x, y = r.randrange(N), r.randrange(N); s = r.choice([1, 1, 2, 2, 3])
        c = r.choice([(118, 116, 124), (96, 98, 108), (140, 134, 134), (88, 84, 84), (110, 112, 126)])
        for dx in range(s):
            for dy in range(s):
                t = 1.15 if (dx == 0 and dy == 0) else (0.8 if dx == s - 1 and dy == s - 1 else 1.0)
                im.putpixel(((x + dx) % N, (y + dy) % N), shade(c, t * (0.9 + r.random() * 0.2)))
    return im

for name, fn in [("px_brick", brick), ("px_flag", flags), ("px_salt", salt), ("px_gravel", gravel)]:
    fn().convert("RGBA").save(f"{OUT}/{name}_diff_1k.png"); print("wrote", name)
