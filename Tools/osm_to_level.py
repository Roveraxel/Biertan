"""Builds Assets/Scripts/Levels/SighisoaraMap.cs from OpenStreetMap data (_packs/osm/sighisoara.osm,
(c) OpenStreetMap contributors, ODbL). Real metres are halved for play; output is in Godot units (50 = 1 m)."""
import xml.etree.ElementTree as ET, math, random, sys
SRC, OUT = sys.argv[1], sys.argv[2]
K = 0.5                      # game metres per real metre
XMIN, XMAX, YMIN, YMAX = -175, 235, -290, 215
root = ET.parse(SRC).getroot()
lat0 = 46.2196; ck = math.cos(math.radians(lat0))
N = {n.get('id'): ((float(n.get('lon')) - 24.7917) * 111320 * ck, (float(n.get('lat')) - lat0) * 110540) for n in root.iter('node')}
def G(p): return ((p[0] - XMIN) * K * 50, (YMAX - p[1]) * K * 50)
ways = []
for w in root.iter('way'):
    t = {x.get('k'): x.get('v') for x in w.findall('tag')}
    pts = [N[nd.get('ref')] for nd in w.findall('nd') if nd.get('ref') in N]
    if pts: ways.append((t, pts))

def inside_box(p, m=0): return XMIN - m < p[0] < XMAX + m and YMIN - m < p[1] < YMAX + m
def pip(p, poly):
    x, y = p; c = False
    for i in range(len(poly)):
        x1, y1 = poly[i]; x2, y2 = poly[i - 1]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1: c = not c
    return c
def area(poly):
    return abs(sum(poly[i][0] * poly[i - 1][1] - poly[i - 1][0] * poly[i][1] for i in range(len(poly)))) / 2
def obb(poly):
    """minimum-area oriented box: centre, (w, d), angle in degrees (real metres, y north)"""
    best = None
    for i in range(len(poly) - 1):
        a, b = poly[i], poly[i + 1]
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        c, s = math.cos(-ang), math.sin(-ang)
        xs = [p[0] * c - p[1] * s for p in poly]; ys = [p[0] * s + p[1] * c for p in poly]
        A = (max(xs) - min(xs)) * (max(ys) - min(ys))
        if best is None or A < best[0]:
            mx, my = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
            c2, s2 = math.cos(ang), math.sin(ang)
            best = (A, (mx * c2 - my * s2, mx * s2 + my * c2), (max(xs) - min(xs), max(ys) - min(ys)), math.degrees(ang))
    _, cen, (w, d), ang = best
    ang = (ang + 180) % 180
    if ang > 135: ang -= 180            # keep angles small so each house faces its street
    if ang > 45: ang -= 90; w, d = d, w
    return cen, (w, d), ang

# --- the wall ring, from the OSM city wall pieces, with the two missing links drawn in
walls = [pts for t, pts in ways if t.get('barrier') == 'city_wall']
CLOCK_SW, CLOCK_NE = (121.0, -52.0), (148.4, -32.7)
walls.append([(94.7, -72.6), CLOCK_SW])              # Tanners' Tower up to the Clock Tower
walls.append([(-56.0, -225.0), (-1.9, -200.9)])       # round the south of the church hill
def piece(a, b): return [p for p in walls if p[0] == a][0]
ring = []
order = [(148.4, -32.7), (173.2, 3.1), (164.8, 89.6), (-41.4, 58.9)]
for w in walls:
    if len(w) > 3 and w[0] != w[-1]: ring += w
ring_poly = None
def chain():
    # citadel outline for the inside test, walked clockwise from the Clock Tower
    seq = []
    for start in [(148.4, -32.7), (173.2, 3.1), (164.8, 89.6), (-41.4, 58.9), (-56.0, -225.0), (-1.9, -200.9)]:
        for w in walls:
            if abs(w[0][0] - start[0]) < 0.5 and abs(w[0][1] - start[1]) < 0.5: seq += w
    seq.append(CLOCK_SW)
    return seq
ring_poly = chain()

# --- towers (name, gate?) and buildings
TOWER_H = {"Turnul cu Ceas": 0}
buildings, towers = [], []
for t, pts in ways:
    if 'building' not in t or len(pts) < 4: continue
    c = (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))
    if not inside_box(c): continue
    name = t.get('name', '')
    A = area(pts)
    inner = pip(c, ring_poly)
    lower = c[0] > 135 and -175 < c[1] < 60 and not inner     # the lower town under the Clock Tower
    named = any(k in name for k in ('Turnul', 'Biserica', 'Capela', 'Școala'))
    if not (inner or lower or named): continue
    if not named and (A > 900 or t.get('building') in ('apartments', 'garage', 'garages', 'roof', 'shed')): continue
    cen, (w, d), ang = obb(pts)
    if w < 2.5 or d < 2.5: continue
    style, h = 'house', None
    if name.startswith('Turnul'): style = 'clocktower' if 'Ceas' in name else 'tower'
    elif 'Biserica' in name or 'Capela' in name: style = 'church'
    rec = dict(name=name, c=cen, w=w, d=d, a=ang, style=style, area=A)
    (towers if style in ('tower', 'clocktower') else buildings).append(rec)

# --- streets and the covered stair
roads, stairs = [], None
WID = {'residential': 140, 'pedestrian': 140, 'living_street': 130, 'service': 100, 'tertiary': 170, 'secondary': 170, 'unclassified': 130, 'footway': 60, 'steps': 70, 'path': 50}
for t, pts in ways:
    hw = t.get('highway')
    if hw not in WID: continue
    if t.get('name') == 'Scara Acoperită': stairs = pts; continue
    if not any(inside_box(p, -2) for p in pts): continue
    keep = [p for p in pts]
    mid = keep[len(keep) // 2]
    if not (pip(mid, ring_poly) or (mid[0] > 120 and -175 < mid[1] < 60) or any(pip(p, ring_poly) for p in keep)): continue
    roads.append((WID[hw], keep))

# --- green areas: woods on the church hill, the hillside cemetery
woods = [pts for t, pts in ways if t.get('landuse') == 'forest' or t.get('natural') == 'wood']
cems = [pts for t, pts in ways if t.get('landuse') == 'cemetery']

def f(v): return f"{v:.0f}f"
def gp(p): x, y = G(p); return f"new Vector2({f(x)}, {f(y)})"
out = []
out.append("// <auto-generated> by Tools/osm_to_level.py from OpenStreetMap data, (c) OpenStreetMap contributors, ODbL.")
out.append("// Real Sighișoara halved for play. Godot units (50 = 1 m, y down). Do not edit by hand.</auto-generated>")
out.append("using UnityEngine;\nnamespace Biertan.Levels\n{\n    public static class SighisoaraMap\n    {")
out.append(f"        public static readonly Vector2 Size = new Vector2({f((XMAX - XMIN) * K * 50)}, {f((YMAX - YMIN) * K * 50)});")
out.append("        /// <summary>Real place to Godot-space point.</summary>")
out.append(f"        public static Vector2 At(float realX, float realY) => new Vector2((realX - ({XMIN}f)) * {K * 50}f, ({YMAX}f - realY) * {K * 50}f);")
out.append("        public struct B { public string name, style; public Vector2 c, size; public float angle; public float area; }")
def blist(name, items):
    out.append(f"        public static readonly B[] {name} = {{")
    for b in items:
        x, y = G(b['c'])
        out.append(f"            new B {{ name = \"{b['name']}\", style = \"{b['style']}\", c = new Vector2({f(x)}, {f(y)}), size = new Vector2({b['w'] * K * 50:.0f}f, {b['d'] * K * 50:.0f}f), angle = {b['a']:.1f}f, area = {b['area']:.0f}f }},")
    out.append("        };")
blist("Towers", towers); blist("Houses", buildings)
def plist(name, polys):
    out.append(f"        public static readonly Vector2[][] {name} = {{")
    for poly in polys: out.append("            new[] { " + ", ".join(gp(p) for p in poly) + " },")
    out.append("        };")
plist("Walls", walls)
out.append("        public static readonly float[] RoadWidth = { " + ", ".join(f"{w}f" for w, _ in roads) + " };")
plist("Roads", [p for _, p in roads])
plist("Stairs", [stairs] if stairs else [])
plist("Woods", woods); plist("Cemeteries", cems)
plist("Citadel", [ring_poly])
out.append("    }\n}")
open(OUT, 'w').write("\n".join(out) + "\n")
print(len(towers), 'towers', len(buildings), 'houses', len(walls), 'walls', len(roads), 'roads', 'stairs' if stairs else 'no stairs')
for t in towers: print(t['name'], [round(v) for v in t['c']], round(t['w']), round(t['d']), round(t['a']))
