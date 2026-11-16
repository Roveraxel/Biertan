"""One-off: turns the Unity build's generated *Map.cs tables into data/<village>.json."""
import re, json, sys, os
SRC = sys.argv[1]; OUT = sys.argv[2]
NAMES = {"Sighisoara": "sighisoara", "Viscri": "viscri", "Crit": "crit", "Saschiz": "saschiz", "Sapartoc": "sapartoc",
         "Apold": "apold", "Cris": "cris", "Malancrav": "malancrav", "Richis": "richisvillage"}
num = r"(-?[\d.]+)f?"
v2 = r"new Vector2\(%s, %s\)" % (num, num)
def f(x): 
    x = float(x); return int(x) if x == int(x) else x
for cs, out in NAMES.items():
    s = open(os.path.join(SRC, cs + "Map.cs"), encoding="utf-8").read()
    d = {}
    m = re.search(r"Size = " + v2, s); d["size"] = [f(m.group(1)), f(m.group(2))]
    m = re.search(r"At\(float realX, float realY\) => new Vector2\(\(realX - \(%s\)\) \* %s(?: \+ %s)?, \(%s - realY\) \* %s(?: \+ %s)?\)" % (num, num, num, num, num, num), s)
    d["at"] = {"x0": f(m.group(1)), "k": f(m.group(2)), "ox": f(m.group(3) or 0), "y0": f(m.group(4)), "oy": f(m.group(6) or 0)}
    m = re.search(r"Rect Village = new Rect\(%s, %s, %s, %s\)" % (num, num, num, num), s)
    if m: d["village"] = [f(g) for g in m.groups()]
    for m in re.finditer(r"B\[\] (\w+) = \{(.*?)\n        \};", s, re.S):
        arr = []
        for b in re.finditer(r'name = "(.*?)", style = "(.*?)", c = %s, size = %s, angle = %s, area = %s' % (v2, v2, num, num), m.group(2)):
            g = b.groups()
            arr.append({"name": g[0], "style": g[1], "c": [f(g[2]), f(g[3])], "size": [f(g[4]), f(g[5])], "angle": f(g[6]), "area": f(g[7])})
        d[m.group(1).lower()] = arr
    for m in re.finditer(r"Vector2\[\]\[\] (\w+) = \{(.*?)\n        \};", s, re.S):
        lines = []
        for ln in re.finditer(r"new\[\] \{(.*?)\},?\s*\n", m.group(2) + "\n"):
            lines.append([[f(a), f(b)] for a, b in re.findall(v2, ln.group(1))])
        d[m.group(1).lower()] = lines
    m = re.search(r"float\[\] RoadWidth = \{(.*?)\};", s, re.S)
    d["roadwidth"] = [f(x) for x in re.findall(num, m.group(1))]
    json.dump(d, open(os.path.join(OUT, out + ".json"), "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(out, {k: (len(v) if isinstance(v, list) else v) for k, v in d.items()})
