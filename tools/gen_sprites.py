#!/usr/bin/env python3
"""Generates the NPC, scarecrow, shade and Varcolac SVG sprites (Biertan style test palette)."""
import os
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
W = 'xmlns="http://www.w3.org/2000/svg" width="192" height="192" viewBox="0 0 96 96"'


def human(body, hl, skin, hat, belt="#6b4a2e", front="", hand="#c9a58a", held_r="", held_l="", back=""):
    return f'''<svg {W}><ellipse cx="48" cy="85" rx="22" ry="6" fill="#000" opacity="0.45"/>
<rect x="37" y="72" width="9" height="10" rx="3" fill="#1a1410"/><rect x="50" y="72" width="9" height="10" rx="3" fill="#1a1410"/>{back}
<path d="M30 78 L36 38 Q48 28 60 38 L66 78 Q48 85 30 78Z" fill="{body}" stroke="#0b0d14" stroke-width="2"/>
<path d="M44 42 L48 80 L52 42Z" fill="{hl}"/><rect x="35" y="56" width="26" height="4" fill="{belt}"/>{front}
<path d="M62 44 L68 58" stroke="{body}" stroke-width="8" stroke-linecap="round"/><circle cx="68" cy="61" r="4" fill="{hand}"/>
<path d="M34 44 L28 58" stroke="{body}" stroke-width="8" stroke-linecap="round"/><circle cx="28" cy="61" r="4" fill="{hand}"/>{held_r}{held_l}
<ellipse cx="48" cy="34" rx="8" ry="9" fill="{skin}" stroke="#0b0d14" stroke-width="1.5"/>
<circle cx="45" cy="35" r="1.3" fill="#1a1410"/><circle cx="51" cy="35" r="1.3" fill="#1a1410"/>{hat}</svg>'''


SK = "#b89478"
sprites = {}

sprites["npc_anna"] = human(
    "#6a2a36", "#8a3e4c", SK,
    '<path d="M38 36 Q38 20 48 20 Q58 20 58 36 Q58 28 48 27 Q38 28 38 36Z" fill="#d8d2c0" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M40 36 L38 47 L44 42Z M56 36 L58 47 L52 42Z" fill="#d8d2c0"/>',
    front='<path d="M39 52 L57 52 L59 79 Q48 83 37 79Z" fill="#cfc8b4" opacity="0.92"/>',
    held_l='<rect x="23" y="58" width="9" height="9" rx="1.5" fill="#8a6a3a" stroke="#0b0d14" stroke-width="1"/>')

sprites["npc_hans"] = human(
    "#4a3a2c", "#5e4a38", "#a98266",
    '<path d="M41 37 Q48 54 55 37 Q48 45 41 37Z" fill="#3a2a1c"/><path d="M41 28 Q48 24 55 28" stroke="#2a1c12" stroke-width="2" fill="none"/>',
    belt="#2a1c12",
    front='<path d="M38 46 L58 46 L60 80 Q48 84 36 80Z" fill="#2a1c12" opacity="0.95"/>',
    hand="#a98266",
    held_r='<rect x="66" y="54" width="3" height="22" fill="#6b4a2e"/><rect x="61" y="48" width="13" height="9" rx="1.5" fill="#6f747c" stroke="#0b0d14" stroke-width="1"/>')

sprites["npc_ileana"] = human(
    "#34503a", "#48684a", "#a8886e",
    '<path d="M37 38 Q36 19 48 19 Q60 19 59 38 Q56 27 48 26 Q40 27 37 38Z" fill="#26372a" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M39 36 Q38 43 41 46 M57 36 Q58 43 55 46" stroke="#b8b8b8" stroke-width="2" fill="none" stroke-linecap="round"/>',
    held_l='<path d="M28 60 L21 45 M28 60 L28 43 M28 60 L35 45" stroke="#6a8a4a" stroke-width="2.5" stroke-linecap="round"/><circle cx="28" cy="57" r="2" fill="#b3372f"/>')

sprites["npc_gheorghe"] = human(
    "#5e5034", "#76653f", "#b08c70",
    '<ellipse cx="48" cy="25" rx="13" ry="8" fill="#4a3f36" stroke="#0b0d14" stroke-width="1.5"/><rect x="36" y="23" width="24" height="7" fill="#4a3f36"/>'
    '<path d="M43 40 Q48 43 53 40" stroke="#3a2a1c" stroke-width="2" fill="none"/>',
    front='<circle cx="40" cy="50" r="5" fill="#e0d9c4"/><circle cx="48" cy="54" r="5" fill="#e0d9c4"/><circle cx="56" cy="50" r="5" fill="#e0d9c4"/><circle cx="44" cy="62" r="5" fill="#e0d9c4"/><circle cx="53" cy="63" r="5" fill="#e0d9c4"/>',
    hand="#b08c70",
    held_r='<path d="M69 62 L69 18 Q69 10 77 12" fill="none" stroke="#6b4a2e" stroke-width="3" stroke-linecap="round"/>')

# ---- scarecrow
def scarecrow(awake):
    arms = ('<path d="M48 40 L14 22 M48 40 L82 22" stroke="#4a3320" stroke-width="5" stroke-linecap="round"/>'
            '<path d="M14 22 L8 16 M14 22 L10 28 M82 22 L88 16 M82 22 L86 28" stroke="#a8903a" stroke-width="2.5" stroke-linecap="round"/>') if awake else (
            '<path d="M48 42 L18 54 M48 42 L78 54" stroke="#4a3320" stroke-width="5" stroke-linecap="round"/>'
            '<path d="M18 54 L12 62 M18 54 L22 63 M78 54 L84 62 M78 54 L74 63" stroke="#a8903a" stroke-width="2.5" stroke-linecap="round"/>')
    tilt = "" if awake else ' transform="rotate(14 48 34)"'
    eyes = ('<circle cx="43" cy="32" r="3" fill="#ff8a2a"/><circle cx="53" cy="32" r="3" fill="#ff8a2a"/>'
            '<circle cx="43" cy="32" r="6" fill="#ff8a2a" opacity="0.25"/><circle cx="53" cy="32" r="6" fill="#ff8a2a" opacity="0.25"/>'
            '<path d="M41 41 Q48 46 55 41 M43 40 L43 44 M48 42 L48 46 M53 40 L53 44" stroke="#1a1410" stroke-width="1.6" fill="none" stroke-linecap="round"/>') if awake else (
            '<path d="M40 31 L46 35 M46 31 L40 35 M50 31 L56 35 M56 31 L50 35" stroke="#1a1410" stroke-width="1.6" stroke-linecap="round"/>')
    return f'''<svg {W}><ellipse cx="48" cy="86" rx="20" ry="5" fill="#000" opacity="0.45"/>
<rect x="45" y="40" width="6" height="46" rx="2" fill="#3a2818"/>
<path d="M36 50 L60 50 L64 74 Q48 80 32 74Z" fill="#6a5a34" stroke="#0b0d14" stroke-width="2"/>
<path d="M38 58 L36 66 M48 60 L48 70 M58 58 L60 66" stroke="#a8903a" stroke-width="2" stroke-linecap="round"/>
{arms}
<g{tilt}><circle cx="48" cy="32" r="12" fill="#a8903a" stroke="#0b0d14" stroke-width="2"/>{eyes}
<path d="M34 24 L62 24 L56 8 Q48 4 40 8Z" fill="#2a2118" stroke="#0b0d14" stroke-width="1.5"/><rect x="32" y="22" width="32" height="5" rx="2" fill="#3a2d20"/></g></svg>'''

sprites["scarecrow_dormant"] = scarecrow(False)
sprites["scarecrow_awake"] = scarecrow(True)

# ---- shade (Iele wraith)
def shade(shift):
    s = shift
    return f'''<svg {W}><defs><radialGradient id="sh"><stop offset="0" stop-color="#cfe6ff" stop-opacity="0.9"/><stop offset="1" stop-color="#7aa0d0" stop-opacity="0.15"/></radialGradient></defs>
<ellipse cx="48" cy="86" rx="16" ry="4" fill="#7aa0d0" opacity="0.18"/>
<path d="M30 40 Q30 14 48 14 Q66 14 66 40 L68 66 Q{62+s} 76 {58+s} 66 Q{52-s} 80 {48-s} 68 Q{42+s} 82 {38+s} 68 Q{34-s} 76 28 66Z" fill="url(#sh)" stroke="#a9c8f0" stroke-width="1.2" stroke-opacity="0.6"/>
<path d="M28 44 Q18 52 22 64 M68 44 Q78 52 74 64" stroke="#cfe6ff" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.45"/>
<ellipse cx="41" cy="34" rx="4" ry="6" fill="#0b0d1c"/><ellipse cx="55" cy="34" rx="4" ry="6" fill="#0b0d1c"/>
<ellipse cx="48" cy="48" rx="3.5" ry="5" fill="#0b0d1c" opacity="0.85"/></svg>'''

sprites["shade_a"] = shade(0)
sprites["shade_b"] = shade(4)

# ---- Varcolac boss
BW = 'xmlns="http://www.w3.org/2000/svg" width="384" height="288" viewBox="0 0 192 144"'
DEFS = ('<defs><radialGradient id="e"><stop offset="0" stop-color="#ff3a2a" stop-opacity="0.85"/><stop offset="1" stop-color="#ff3a2a" stop-opacity="0"/></radialGradient>'
        '<radialGradient id="m"><stop offset="0.62" stop-color="#b3372f" stop-opacity="0.0"/><stop offset="0.8" stop-color="#b3372f" stop-opacity="0.55"/><stop offset="1" stop-color="#b3372f" stop-opacity="0"/></radialGradient></defs>')
RIBS = '<path d="M46 44 Q51 52 46 61 M56 42 Q61 52 56 62 M66 44 Q71 52 66 61" fill="none" stroke="#cfc6b3" stroke-width="1.8" stroke-linecap="round" opacity="0.6"/>'
SPIKES = '<path d="M34 40 L40 26 L46 39 L52 24 L58 38 L64 26 L70 38 L76 28 L82 42Z" fill="#26262e"/>'


def head(ang=0, open_jaw=False):
    jaw = '<path d="M92 55 L124 50 L112 60Z" fill="#7a1c1c"/><path d="M100 54 L102 61 L105 54Z M112 52 L114 58 L117 51Z" fill="#f3ead6"/>' if open_jaw else '<path d="M106 56 L109 62 L111 56Z" fill="#f3ead6"/>'
    lower = '<path d="M84 58 Q100 66 114 70 L108 76 Q92 74 84 66Z" fill="#33333d" stroke="#0b0d14" stroke-width="2"/>' if open_jaw else ''
    return f'''<g transform="rotate({ang} 86 52)">{lower}<path d="M84 40 Q98 30 116 42 L124 52 L106 58 Q92 60 84 56Z" fill="#4a4a54" stroke="#0b0d14" stroke-width="2"/>{jaw}
<path d="M88 40 L90 22 L100 38Z" fill="#26262e" stroke="#0b0d14" stroke-width="1.5"/><circle cx="102" cy="46" r="12" fill="url(#e)"/><circle cx="102" cy="46" r="2.8" fill="#ff3a2a"/><circle cx="120" cy="49" r="2.8" fill="#0b0d14"/></g>'''


def moon(cx, cy):
    return (f'<circle cx="{cx}" cy="{cy}" r="46" fill="url(#m)"/><circle cx="{cx}" cy="{cy}" r="32" fill="#e8dcb4" opacity="0.92"/>'
            f'<circle cx="{cx-9}" cy="{cy-6}" r="6" fill="#cfc29a" opacity="0.7"/><circle cx="{cx+10}" cy="{cy+8}" r="4" fill="#cfc29a" opacity="0.7"/>'
            f'<circle cx="{cx+14}" cy="{cy-10}" r="2.6" fill="#cfc29a" opacity="0.7"/>')


def body(legs):
    return f'''<ellipse cx="62" cy="84" rx="42" ry="6" fill="#000" opacity="0.45"/>
<path d="M28 46 Q10 52 6 70 Q20 60 32 62Z" fill="#26262e" stroke="#0b0d14" stroke-width="2"/>{legs[0]}
<ellipse cx="60" cy="52" rx="36" ry="19" fill="#2e2e38" stroke="#0b0d14" stroke-width="2"/>{RIBS}{SPIKES}{legs[1]}'''


LEGS_STAND = ('<rect x="38" y="62" width="9" height="21" rx="3" fill="#1e1e25"/><rect x="80" y="62" width="9" height="21" rx="3" fill="#1e1e25"/>',
              '<rect x="46" y="64" width="10" height="20" rx="3" fill="#3a3a44" stroke="#0b0d14" stroke-width="1.5"/><rect x="72" y="64" width="10" height="20" rx="3" fill="#3a3a44" stroke="#0b0d14" stroke-width="1.5"/>')
LEGS_RUN = ('<path d="M44 62 L22 80 L30 85 L52 68Z" fill="#1e1e25"/><path d="M82 62 L104 74 L102 80 L76 68Z" fill="#1e1e25"/>',
            '<path d="M48 64 L32 82 L42 85 L58 68Z" fill="#3a3a44" stroke="#0b0d14" stroke-width="1.5"/><path d="M76 64 L96 78 L90 84 L68 70Z" fill="#3a3a44" stroke="#0b0d14" stroke-width="1.5"/>')

def boss(pose):
    if pose == "idle":
        inner = moon(108, 34) + body(LEGS_STAND) + head()
    elif pose == "howl":
        inner = moon(104, 20) + body(LEGS_STAND) + head(-38, True)
    else:  # charge
        inner = moon(104, 30) + '<g transform="rotate(-12 62 52)">' + body(LEGS_RUN) + head(0, True) + '</g>'
    return f'<svg {BW}>{DEFS}<g transform="translate(24 26)">{inner}</g></svg>'

for p in ("idle", "howl", "charge"):
    sprites[f"boss_{p}"] = boss(p)

os.makedirs(OUT, exist_ok=True)
for name, svg in sprites.items():
    with open(os.path.join(OUT, name + ".svg"), "w") as f:
        f.write(svg)
print("wrote", len(sprites), "sprites")
