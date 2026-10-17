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


# ================================================================ Level 2
sprites["npc_pastor"] = human(
    "#1c1a20", "#2a2730", "#b89478",
    '<path d="M40 30 Q40 22 48 22 Q56 22 56 30 Q53 26 48 26 Q43 26 40 30Z" fill="#9a9a9a"/>'
    '<path d="M45 43 L45 50 L48 47 L51 50 L51 43Z" fill="#f3ead6"/>',
    belt="#1c1a20",
    hand="#b89478",
    held_l='<rect x="21" y="55" width="12" height="15" rx="1" fill="#3a1c14" stroke="#0b0d14" stroke-width="1"/><path d="M27 58 L27 67 M24 61 L30 61" stroke="#c9a24a" stroke-width="1.4"/>')

sprites["npc_vasile"] = human(
    "#8a8a86", "#b4b2aa", "#a98266",
    '<path d="M38 30 Q38 20 48 20 Q58 20 58 30 L60 31 L36 31Z" fill="#5a5048" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M42 40 Q48 47 54 40 Q48 44 42 40Z" fill="#cfcac0"/>',
    belt="#4a3a2c",
    front='<path d="M38 50 Q48 54 58 50" stroke="#e8e6e0" stroke-width="2" fill="none" opacity="0.7"/><circle cx="42" cy="66" r="1.5" fill="#f3f3f0"/><circle cx="55" cy="70" r="1.5" fill="#f3f3f0"/>',
    hand="#a98266",
    held_r='<rect x="67" y="40" width="3" height="34" fill="#6b4a2e"/><path d="M58 42 Q68 34 80 42 L76 44 Q68 39 62 44Z" fill="#6f747c" stroke="#0b0d14" stroke-width="1"/>')

sprites["npc_katharina"] = human(
    "#24324e", "#34466a", "#c09c80",
    '<path d="M38 32 L38 20 L58 20 L58 32 Q56 26 48 26 Q40 26 38 32Z" fill="#141018" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M38 22 L58 22" stroke="#b3372f" stroke-width="2.5"/><path d="M42 20 L41 14 M48 20 L48 13 M54 20 L55 14" stroke="#c9a24a" stroke-width="1.5"/>',
    belt="#b3372f",
    front='<path d="M39 52 L57 52 L58 79 Q48 83 38 79Z" fill="#7a2a2a" opacity="0.9"/><path d="M40 60 L56 60 M40 68 L56 68" stroke="#c9a24a" stroke-width="1.2"/>',
    hand="#c09c80",
    held_l='<path d="M20 60 Q28 72 36 60Z" fill="#8a6a3a" stroke="#0b0d14" stroke-width="1"/><path d="M23 59 L21 49 M27 59 L28 47 M32 59 L35 50" stroke="#8aa070" stroke-width="2" stroke-linecap="round"/>')

sprites["npc_rozalia"] = human(
    "#e8e2d2", "#f4efe2", "#b89478",
    '<path d="M37 37 Q36 20 48 20 Q60 20 59 37 Q57 27 48 26 Q39 27 37 37Z" fill="#7a1e22" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M39 30 L36 46 L42 40Z M57 30 L60 46 L54 40Z" fill="#7a1e22"/>',
    belt="#7a1e22",
    front='<path d="M40 44 L56 44 M40 48 L56 48" stroke="#b3372f" stroke-width="1.8"/><path d="M37 60 L59 60 L61 80 Q48 84 35 80Z" fill="#1a1414"/><path d="M38 64 L58 64" stroke="#b3372f" stroke-width="1.5"/>',
    hand="#b89478")

# ---- Iele: pale dancing maidens of the meadow
def iele(sway):
    s = sway
    return f'''<svg {W}><defs><radialGradient id="ig"><stop offset="0" stop-color="#ffffff" stop-opacity="0.95"/><stop offset="1" stop-color="#cfd8ff" stop-opacity="0.25"/></radialGradient>
<radialGradient id="ih"><stop offset="0" stop-color="#e8f0ff" stop-opacity="0.5"/><stop offset="1" stop-color="#e8f0ff" stop-opacity="0"/></radialGradient></defs>
<ellipse cx="48" cy="88" rx="14" ry="3.5" fill="#cfd8ff" opacity="0.25"/><circle cx="48" cy="50" r="40" fill="url(#ih)"/>
<path d="M{38+s} 22 Q{30+s} 40 {26+s*2} 58 Q{34+s} 52 40 46Z M{58+s} 22 Q{66+s} 40 {70+s*2} 58 Q{62+s} 52 56 46Z" fill="#f0ead8" opacity="0.85"/>
<path d="M38 40 Q48 34 58 40 L{66+s*2} 80 Q{58+s} 74 {54+s} 82 Q{48} 76 {42-s} 82 Q{38-s} 74 {30-s*2} 80Z" fill="url(#ig)" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6"/>
<path d="M40 44 Q{26-s} {40-s} {18-s} {30-s*2}" stroke="#f4f0ff" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.8"/>
<path d="M56 44 Q{70+s} {40+s} {78+s} {30+s*2}" stroke="#f4f0ff" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.8"/>
<ellipse cx="48" cy="28" rx="8" ry="9" fill="#efe6e0" stroke="#9aa6c8" stroke-width="1"/>
<path d="M40 26 Q42 15 48 15 Q54 15 56 26 Q52 20 48 20 Q44 20 40 26Z" fill="#f0ead8"/>
<path d="M41 22 L45 20 L48 23 L51 20 L55 22" stroke="#d8c8ff" stroke-width="1.6" fill="none"/>
<ellipse cx="45" cy="29" rx="1.6" ry="2.2" fill="#6a7aff"/><ellipse cx="51" cy="29" rx="1.6" ry="2.2" fill="#6a7aff"/>
<path d="M46 34 Q48 35 50 34" stroke="#9a6a7a" stroke-width="1" fill="none"/></svg>'''

sprites["iele_a"] = iele(0)
sprites["iele_b"] = iele(3)

# ---- Moroi: salt-crusted dead that rise from the cave floor
def moroi(awake):
    if not awake:
        return f'''<svg {W}><ellipse cx="48" cy="80" rx="30" ry="9" fill="#2a2a30"/><ellipse cx="48" cy="76" rx="28" ry="8" fill="#6a6a70" stroke="#0b0d14" stroke-width="1.5"/>
<path d="M28 74 Q36 66 46 70 Q56 64 68 74" fill="#d8d8de" opacity="0.7"/><circle cx="34" cy="72" r="2" fill="#f4f4f8"/><circle cx="60" cy="70" r="2.4" fill="#f4f4f8"/>
<path d="M54 72 L58 62 L60 64 L62 58 L63 66" stroke="#9a9aa4" stroke-width="2.4" fill="none" stroke-linecap="round"/></svg>'''
    return f'''<svg {W}><ellipse cx="48" cy="86" rx="20" ry="5" fill="#000" opacity="0.45"/>
<path d="M36 84 L40 66 M58 84 L55 66" stroke="#7a7a82" stroke-width="6" stroke-linecap="round"/>
<path d="M30 70 Q28 44 44 36 Q62 32 66 50 L66 72 Q48 78 30 70Z" fill="#8a8a92" stroke="#0b0d14" stroke-width="2"/>
<path d="M32 66 L36 50 L40 64 L46 48 L50 66 L56 50 L62 68" stroke="#4a4a52" stroke-width="1.5" fill="none" opacity="0.6"/>
<path d="M34 46 Q22 56 20 70 L16 74 M20 70 L22 76 M20 70 L25 74" stroke="#9a9aa2" stroke-width="4.5" fill="none" stroke-linecap="round"/>
<path d="M62 46 Q74 56 76 70 L80 74 M76 70 L74 76 M76 70 L71 74" stroke="#9a9aa2" stroke-width="4.5" fill="none" stroke-linecap="round"/>
<ellipse cx="54" cy="34" rx="10" ry="11" fill="#b8b8c0" stroke="#0b0d14" stroke-width="1.8"/>
<path d="M45 30 Q54 22 63 30" stroke="#e8e8ee" stroke-width="2" fill="none"/>
<circle cx="50" cy="34" r="5" fill="#ff3a2a" opacity="0.25"/><circle cx="58" cy="34" r="5" fill="#ff3a2a" opacity="0.25"/>
<circle cx="50" cy="34" r="1.8" fill="#ff3a2a"/><circle cx="58" cy="34" r="1.8" fill="#ff3a2a"/>
<path d="M49 41 L51 44 L53 41 L55 44 L57 41" stroke="#1a1410" stroke-width="1.2" fill="none"/>
<circle cx="38" cy="54" r="1.6" fill="#ffffff"/><circle cx="58" cy="60" r="1.8" fill="#ffffff"/><circle cx="44" cy="40" r="1.4" fill="#ffffff"/></svg>'''

sprites["moroi_dormant"] = moroi(False)
sprites["moroi_awake"] = moroi(True)

# ---- Muma Pădurii: the Forest Mother
MDEFS = ('<defs><radialGradient id="ge"><stop offset="0" stop-color="#9aff6a" stop-opacity="0.9"/><stop offset="1" stop-color="#9aff6a" stop-opacity="0"/></radialGradient>'
         '<linearGradient id="bk" x1="0" x2="1"><stop offset="0" stop-color="#2a2016"/><stop offset="0.5" stop-color="#4a3a28"/><stop offset="1" stop-color="#241a12"/></linearGradient></defs>')

def muma(pose):
    if pose == "cast":
        arms = ('<path d="M76 58 Q60 30 50 8 M50 8 L44 2 M50 8 L48 -1 M50 8 L56 2" stroke="#3a2c1e" stroke-width="7" fill="none" stroke-linecap="round"/>'
                '<path d="M116 58 Q132 30 142 8 M142 8 L148 2 M142 8 L144 -1 M142 8 L136 2" stroke="#3a2c1e" stroke-width="7" fill="none" stroke-linecap="round"/>'
                '<circle cx="50" cy="6" r="10" fill="url(#ge)"/><circle cx="142" cy="6" r="10" fill="url(#ge)"/>')
    elif pose == "sweep":
        arms = ('<path d="M76 60 Q52 70 30 64 M30 64 L22 58 M30 64 L20 66 M30 64 L24 72" stroke="#3a2c1e" stroke-width="7" fill="none" stroke-linecap="round"/>'
                '<path d="M116 60 Q144 56 168 44 M168 44 L176 38 M168 44 L178 46 M168 44 L172 52" stroke="#3a2c1e" stroke-width="7" fill="none" stroke-linecap="round"/>')
    else:
        arms = ('<path d="M76 58 Q58 76 54 100 M54 100 L48 108 M54 100 L54 110 M54 100 L60 108" stroke="#3a2c1e" stroke-width="7" fill="none" stroke-linecap="round"/>'
                '<path d="M116 58 Q134 76 138 100 M138 100 L132 108 M138 100 L138 110 M138 100 L144 108" stroke="#3a2c1e" stroke-width="7" fill="none" stroke-linecap="round"/>')
    return f'''<svg {BW}>{MDEFS}<g transform="translate(0 6)"><ellipse cx="96" cy="132" rx="50" ry="8" fill="#000" opacity="0.5"/>
<path d="M70 128 Q74 116 80 112 M122 128 Q118 116 112 112 M60 134 Q70 126 84 120 M132 134 Q122 126 108 120" stroke="#2a2016" stroke-width="5" fill="none" stroke-linecap="round"/>
<path d="M74 56 Q72 30 96 26 Q120 30 118 56 L124 124 Q96 134 68 124Z" fill="url(#bk)" stroke="#0b0d14" stroke-width="2.5"/>
<path d="M82 60 Q86 90 80 120 M96 54 Q98 90 94 126 M110 60 Q106 90 112 120" stroke="#1a120c" stroke-width="2" fill="none" opacity="0.8"/>
<ellipse cx="100" cy="88" rx="7" ry="11" fill="#0b0d14"/>
<path d="M80 100 Q76 96 72 100 Q76 102 80 100Z M114 76 Q118 70 124 74 Q118 78 114 76Z" fill="#b3372f"/><circle cx="76" cy="100" r="1" fill="#f3ead6"/>
{arms}
<path d="M70 40 Q60 70 64 110 L70 106 Q66 76 76 50Z M122 40 Q132 70 128 110 L122 106 Q126 76 116 50Z" fill="#3e5a2a" opacity="0.95"/>
<path d="M72 30 Q96 4 120 30 Q122 44 116 52 Q96 40 76 52 Q70 44 72 30Z" fill="#4a6a30" stroke="#0b0d14" stroke-width="1.5"/>
<path d="M80 46 Q96 36 112 46 L110 58 Q96 64 82 58Z" fill="#6a5a44" stroke="#0b0d14" stroke-width="1.5"/>
<path d="M95 50 L91 60 L97 58Z" fill="#4a3a28"/>
<circle cx="88" cy="50" r="7" fill="url(#ge)"/><circle cx="104" cy="50" r="7" fill="url(#ge)"/>
<circle cx="88" cy="50" r="2" fill="#c8ff8a"/><circle cx="104" cy="50" r="2" fill="#c8ff8a"/>
<path d="M88 61 L90 64 L92 61 L94 65 L96 61 L98 64 L100 61" stroke="#f3ead6" stroke-width="1.2" fill="none"/>
<path d="M78 24 Q74 10 66 8 M114 24 Q118 10 126 8 M96 20 L96 6" stroke="#2a2016" stroke-width="3" stroke-linecap="round"/>
<circle cx="66" cy="8" r="3" fill="#8a2a1c"/><circle cx="126" cy="8" r="3" fill="#8a2a1c"/></g></svg>'''

for p in ("idle", "cast", "sweep"):
    sprites[f"muma_{p}"] = muma(p)


# ================================================================ Level 3
sprites["npc_konrad"] = human(
    "#3a3028", "#4e4034", "#a98266",
    '<path d="M41 37 Q48 56 55 37 Q48 46 41 37Z" fill="#6a6a6a"/><ellipse cx="48" cy="27" rx="7" ry="3" fill="#a98266"/>',
    belt="#2a1c12",
    front='<path d="M38 44 L58 44 L60 80 Q48 84 36 80Z" fill="#5a3a22" opacity="0.95"/><circle cx="44" cy="58" r="2" fill="#1a1410" opacity="0.6"/><circle cx="53" cy="66" r="2.5" fill="#1a1410" opacity="0.6"/>',
    hand="#a98266",
    held_l='<path d="M21 66 Q21 54 28 52 Q35 54 35 66Z" fill="#b08a3a" stroke="#0b0d14" stroke-width="1"/><circle cx="28" cy="67" r="2" fill="#6a4a1a"/>')

sprites["npc_hannes"] = human(
    "#6a4a2a", "#86603a", "#c09c80",
    '<path d="M38 30 Q38 20 48 20 Q58 20 58 30Z" fill="#2a2420" stroke="#0b0d14" stroke-width="1.5"/><path d="M36 30 L60 30" stroke="#2a2420" stroke-width="3"/>'
    '<path d="M42 40 Q48 44 54 40" stroke="#5a3a22" stroke-width="2.5" fill="none"/>',
    belt="#2a1c12",
    front='<path d="M36 46 L60 46 L60 62 L36 62Z" fill="#d8d2c0" opacity="0.85"/>',
    hand="#c09c80",
    held_r='<ellipse cx="72" cy="66" rx="8" ry="11" fill="#8a3a2a" stroke="#0b0d14" stroke-width="1"/><ellipse cx="72" cy="66" rx="5" ry="7" fill="#c06a4a"/><rect x="70" y="52" width="4" height="6" fill="#e8e0cc"/>')

sprites["npc_veta"] = human(
    "#16141a", "#24202a", "#b0907a",
    '<path d="M37 38 Q36 19 48 19 Q60 19 59 38 Q56 27 48 26 Q40 27 37 38Z" fill="#0e0c10" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M38 34 L35 50 L42 42Z M58 34 L61 50 L54 42Z" fill="#0e0c10"/>',
    belt="#3a2a2a",
    hand="#b0907a",
    held_l='<path d="M28 46 L28 76" stroke="#8a7a5a" stroke-width="2"/><circle cx="28" cy="52" r="4" fill="#f0eadc" stroke="#0b0d14" stroke-width="0.8"/><circle cx="28" cy="60" r="4" fill="#f0eadc" stroke="#0b0d14" stroke-width="0.8"/><circle cx="28" cy="68" r="4" fill="#f0eadc" stroke="#0b0d14" stroke-width="0.8"/>')

# ---- Strigoi: the restless dead, leaping blood-drinkers
def strigoi(pose):
    if pose == "leap":
        return f'''<svg {W}><ellipse cx="48" cy="88" rx="12" ry="3" fill="#000" opacity="0.3"/>
<path d="M22 50 Q48 20 74 50 L66 62 Q48 48 30 62Z" fill="#1a1418" stroke="#0b0d14" stroke-width="2"/>
<path d="M30 50 L12 40 L8 46 M66 50 L84 40 L88 46" stroke="#c8c0c8" stroke-width="4" stroke-linecap="round" fill="none"/>
<path d="M36 60 L30 76 M60 60 L66 76" stroke="#2a2228" stroke-width="6" stroke-linecap="round"/>
<ellipse cx="48" cy="38" rx="9" ry="10" fill="#d0c8d0" stroke="#0b0d14" stroke-width="1.5"/>
<path d="M39 34 Q48 22 57 34 Q52 28 48 28 Q44 28 39 34Z" fill="#1a1418"/>
<circle cx="44" cy="38" r="5" fill="#ff2a1a" opacity="0.3"/><circle cx="52" cy="38" r="5" fill="#ff2a1a" opacity="0.3"/>
<circle cx="44" cy="38" r="1.8" fill="#ff2a1a"/><circle cx="52" cy="38" r="1.8" fill="#ff2a1a"/>
<path d="M44 44 Q48 48 52 44" fill="#3a0a0a"/><path d="M45 44 L46 48 L47 44 M49 44 L50 48 L51 44" fill="#f3ead6"/></svg>'''
    return f'''<svg {W}><ellipse cx="48" cy="86" rx="18" ry="5" fill="#000" opacity="0.45"/>
<rect x="39" y="70" width="7" height="14" rx="2" fill="#2a2228"/><rect x="50" y="70" width="7" height="14" rx="2" fill="#2a2228"/>
<path d="M30 80 L36 40 Q48 30 60 40 L66 80 Q56 76 48 82 Q40 76 30 80Z" fill="#1a1418" stroke="#0b0d14" stroke-width="2"/>
<path d="M36 40 L30 30 L42 36Z M60 40 L66 30 L54 36Z" fill="#3a1418"/>
<path d="M36 46 Q24 58 26 70 M60 46 Q72 58 70 70" stroke="#1a1418" stroke-width="7" fill="none" stroke-linecap="round"/>
<path d="M26 70 L22 76 M26 70 L26 77 M26 70 L30 76 M70 70 L66 76 M70 70 L70 77 M70 70 L74 76" stroke="#c8c0c8" stroke-width="1.6" stroke-linecap="round"/>
<ellipse cx="48" cy="32" rx="8" ry="10" fill="#d0c8d0" stroke="#0b0d14" stroke-width="1.5"/>
<path d="M39 30 Q40 16 48 16 Q56 16 57 30 Q54 22 48 22 Q42 22 39 30Z" fill="#1a1418"/>
<circle cx="45" cy="32" r="4.5" fill="#ff2a1a" opacity="0.3"/><circle cx="51" cy="32" r="4.5" fill="#ff2a1a" opacity="0.3"/>
<circle cx="45" cy="32" r="1.6" fill="#ff2a1a"/><circle cx="51" cy="32" r="1.6" fill="#ff2a1a"/>
<path d="M46 38 L46.5 41 L47 38 M49 38 L49.5 41 L50 38" fill="#f3ead6" stroke="#f3ead6" stroke-width="0.8"/>
<path d="M47 42 L47 45" stroke="#8a1a1a" stroke-width="1"/></svg>'''

sprites["strigoi_stand"] = strigoi("stand")
sprites["strigoi_leap"] = strigoi("leap")

def bat(up):
    w = 'M48 50 Q36 30 18 34 Q26 40 24 48 Q32 44 36 52 Q40 48 48 54 Q56 48 60 52 Q64 44 72 48 Q70 40 78 34 Q60 30 48 50Z' if up else \
        'M48 48 Q36 52 18 64 Q28 62 30 58 Q34 64 38 58 Q42 62 48 54 Q54 62 58 58 Q62 64 66 58 Q68 62 78 64 Q60 52 48 48Z'
    return f'''<svg {W}><ellipse cx="48" cy="86" rx="8" ry="2" fill="#000" opacity="0.3"/>
<path d="{w}" fill="#2a2228" stroke="#0b0d14" stroke-width="1.5"/>
<ellipse cx="48" cy="50" rx="6" ry="8" fill="#3a3038" stroke="#0b0d14" stroke-width="1.2"/>
<path d="M44 44 L43 38 L46 42 M52 44 L53 38 L50 42" fill="#3a3038" stroke="#0b0d14" stroke-width="1"/>
<circle cx="46" cy="48" r="1.3" fill="#ff3a2a"/><circle cx="50" cy="48" r="1.3" fill="#ff3a2a"/></svg>'''

sprites["bat_a"] = bat(True)
sprites["bat_b"] = bat(False)

# ---- Balaur: three-headed serpent of the old quarry
sprites["balaur_body"] = f'''<svg {BW}><defs><radialGradient id="sc"><stop offset="0" stop-color="#3a5a3a"/><stop offset="1" stop-color="#16261a"/></radialGradient></defs>
<ellipse cx="96" cy="118" rx="80" ry="16" fill="#0a1418" opacity="0.7"/>
<path d="M20 110 Q30 70 70 78 Q110 86 120 60 Q130 40 160 52 Q184 64 172 100 Q160 124 120 118 Q90 114 60 122 Q30 128 20 110Z" fill="url(#sc)" stroke="#0b0d14" stroke-width="2.5"/>
<path d="M40 104 Q70 92 100 100 Q130 106 160 92" stroke="#c8b46a" stroke-width="5" fill="none" opacity="0.55"/>
<path d="M36 100 L44 92 L50 101 L58 93 L64 102 L72 94 L78 103 M120 64 L128 54 L134 64 L142 55 L148 66 L156 58 L162 70" stroke="#0e1a12" stroke-width="3" fill="none"/>
<g fill="#2a4a2e" opacity="0.8"><circle cx="60" cy="110" r="3"/><circle cx="76" cy="106" r="3"/><circle cx="92" cy="108" r="3"/><circle cx="140" cy="84" r="3"/><circle cx="154" cy="78" r="3"/><circle cx="130" cy="96" r="3"/></g>
<path d="M170 96 Q186 108 182 124 Q176 114 168 110Z" fill="#16261a" stroke="#0b0d14" stroke-width="2"/></svg>'''

HW = 'xmlns="http://www.w3.org/2000/svg" width="192" height="104" viewBox="0 -4 96 52"'
def bhead(open_jaw, col):
    jaw = ('<path d="M30 28 L82 34 L76 42 Q50 44 30 34Z" fill="#1e3220" stroke="#0b0d14" stroke-width="1.5"/>'
           '<path d="M40 27 L42 33 L45 27 M54 28 L56 34 L59 28 M68 30 L70 35 L72 30" fill="#f3ead6"/>'
           '<path d="M38 30 Q60 34 80 32" stroke="#8a1a1a" stroke-width="3"/>') if open_jaw else \
          '<path d="M30 26 L84 26 L78 32 Q52 36 30 30Z" fill="#1e3220" stroke="#0b0d14" stroke-width="1.5"/><path d="M70 26 L72 30 L74 26" fill="#f3ead6"/>'
    return f'''<svg {HW}><path d="M8 24 Q20 10 46 12 L86 18 Q92 22 86 26 L30 28 Q16 30 8 24Z" fill="{col}" stroke="#0b0d14" stroke-width="2"/>{jaw}
<path d="M28 12 L20 0 L36 10 M40 11 L36 -2 L48 11" fill="#16261a" stroke="#0b0d14" stroke-width="1.2"/>
<circle cx="52" cy="17" r="6" fill="#ffcc3a" opacity="0.3"/><circle cx="52" cy="17" r="2.6" fill="#ffcc3a"/><path d="M52 14.5 L52 19.5" stroke="#0b0d14" stroke-width="1.2"/>
<circle cx="84" cy="21" r="1.2" fill="#0b0d14"/></svg>'''

sprites["balaur_head"] = bhead(False, "#2e4a30")
sprites["balaur_head_open"] = bhead(True, "#2e4a30")

# ================================================================ Level 4: Biertan
sprites["npc_sexton"] = human(
    "#2a2a30", "#3a3a42", "#a98a72",
    '<path d="M40 28 Q40 20 48 20 Q56 20 56 28 Q52 24 48 24 Q44 24 40 28Z" fill="#d8d8d8"/>'
    '<path d="M42 40 Q48 50 54 40 Q48 45 42 40Z" fill="#d8d8d8"/>',
    belt="#1a1a1e",
    hand="#a98a72",
    held_r='<path d="M70 52 L70 76" stroke="#6b4a2e" stroke-width="2"/><circle cx="70" cy="50" r="5" fill="#c9a24a" opacity="0.4"/><rect x="66" y="46" width="8" height="9" rx="1" fill="#3a2a1c" stroke="#c9a24a" stroke-width="1"/><circle cx="70" cy="50" r="2" fill="#ffcc6a"/>',
    held_l='<path d="M24 60 L32 60 M28 60 L28 68 M26 66 L30 66" stroke="#c9a24a" stroke-width="2"/><circle cx="28" cy="58" r="3" fill="none" stroke="#c9a24a" stroke-width="1.5"/>')

sprites["npc_andreas"] = human(
    "#3a4a5a", "#4a5e72", "#b89478",
    '<path d="M38 30 Q38 20 48 20 Q58 20 58 30Z" fill="#3a2a1c" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M42 40 Q48 43 54 40" stroke="#5a3a22" stroke-width="2.5" fill="none"/>',
    belt="#2a1c12", hand="#b89478")

sprites["npc_sofia"] = human(
    "#7a2a36", "#9a3e4c", "#c09c80",
    '<path d="M38 34 Q36 19 48 19 Q60 19 58 34 Q56 26 48 25 Q40 26 38 34Z" fill="#4a2a18" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M40 30 Q34 44 40 54 M56 30 Q62 44 56 54" stroke="#4a2a18" stroke-width="4" fill="none" stroke-linecap="round"/>',
    belt="#c9a24a",
    front='<path d="M39 52 L57 52 L58 79 Q48 83 38 79Z" fill="#e8e2d2" opacity="0.9"/><path d="M40 58 L56 58 M40 64 L56 64" stroke="#b3372f" stroke-width="1.4"/>',
    hand="#c09c80")

# ---- Strigoi Vlad
VDEFS = ('<defs><radialGradient id="vr"><stop offset="0" stop-color="#ff2a1a" stop-opacity="0.9"/><stop offset="1" stop-color="#ff2a1a" stop-opacity="0"/></radialGradient>'
         '<linearGradient id="cl" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#1a1418"/><stop offset="1" stop-color="#08060a"/></linearGradient></defs>')

def vlad(pose):
    if pose == "cast":
        cloak = ('<path d="M96 40 L30 30 Q20 80 40 130 L96 120 L152 130 Q172 80 162 30Z" fill="url(#cl)" stroke="#0b0d14" stroke-width="2"/>'
                 '<path d="M96 46 L42 38 Q34 80 48 122 L96 114 L144 122 Q158 80 150 38Z" fill="#6a0e14"/>'
                 '<path d="M50 36 L28 22 L36 40 M142 36 L164 22 L156 40" stroke="#d8d0d8" stroke-width="4" stroke-linecap="round"/>'
                 '<circle cx="96" cy="16" r="16" fill="url(#vr)"/><circle cx="96" cy="16" r="6" fill="#ff4a3a"/>')
        arms = ''
    elif pose == "claw":
        cloak = '<path d="M80 44 Q60 80 58 134 L120 130 Q126 86 112 44Z" fill="url(#cl)" stroke="#0b0d14" stroke-width="2"/>'
        arms = ('<path d="M108 54 Q130 60 150 52 L160 46 M150 52 L162 56 M150 52 L158 62" stroke="#1a1418" stroke-width="7" stroke-linecap="round" fill="none"/>'
                '<path d="M156 46 L168 40 M158 54 L172 54 M156 62 L168 68" stroke="#d8d0d8" stroke-width="2.4" stroke-linecap="round"/>')
    else:
        cloak = ('<path d="M74 44 Q58 90 62 134 L130 134 Q134 90 118 44Z" fill="url(#cl)" stroke="#0b0d14" stroke-width="2"/>'
                 '<path d="M92 50 L96 130 L100 50Z" fill="#6a0e14" opacity="0.8"/>')
        arms = '<path d="M78 60 Q74 84 80 100 M114 60 Q118 84 112 100" stroke="#08060a" stroke-width="7" fill="none" stroke-linecap="round"/>'
    return f'''<svg {BW}>{VDEFS}<g transform="translate(0 4)"><ellipse cx="96" cy="136" rx="34" ry="6" fill="#000" opacity="0.5"/>
{cloak}
<path d="M76 46 L70 26 L88 42Z M116 46 L122 26 L104 42Z" fill="#6a0e14" stroke="#0b0d14" stroke-width="1.5"/>
{arms}
<ellipse cx="96" cy="38" rx="11" ry="13" fill="#d8d0d8" stroke="#0b0d14" stroke-width="1.8"/>
<path d="M84 36 Q84 20 96 20 Q108 20 108 36 Q104 26 96 27 Q88 26 84 36Z M84 34 Q80 48 84 58 M108 34 Q112 48 108 58" fill="#0e0a0e" stroke="#0e0a0e" stroke-width="3"/>
<path d="M88 44 Q96 49 104 44" stroke="#2a1a1a" stroke-width="2.4" fill="none"/>
<circle cx="91" cy="37" r="5" fill="url(#vr)"/><circle cx="101" cy="37" r="5" fill="url(#vr)"/>
<circle cx="91" cy="37" r="1.8" fill="#ff3a2a"/><circle cx="101" cy="37" r="1.8" fill="#ff3a2a"/>
<path d="M93 47 L94 51 L95 47 M97 47 L98 51 L99 47" fill="#f3ead6" stroke="#f3ead6" stroke-width="0.6"/>
<circle cx="96" cy="58" r="3" fill="#c9a24a"/></g></svg>'''

for p in ("idle", "cast", "claw"):
    sprites[f"vlad_{p}"] = vlad(p)

# ---- the forest hermit (side quest)
sprites["npc_hermit"] = human(
    "#4a3a28", "#5e4a34", "#a98a72",
    '<path d="M38 34 Q36 18 48 18 Q60 18 58 34 Q56 24 48 24 Q40 24 38 34Z" fill="#3a2c1e" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M41 38 Q48 66 55 38 Q48 46 41 38Z" fill="#e8e6e0"/>',
    belt="#8a7a5a", hand="#a98a72",
    held_r='<path d="M70 20 L70 80" stroke="#6b4a2e" stroke-width="3" stroke-linecap="round"/><path d="M66 20 L74 20 M70 16 L70 26" stroke="#c9a24a" stroke-width="2"/>')

# ---- the Vârcolac, after Romanian folklore: a lean hound-like creature
# "born of the air", climbing threads spun at night to bite the moon
VDEF = ('<defs><linearGradient id="vb" x1="0" x2="1"><stop offset="0" stop-color="#2a2a3a" stop-opacity="0.35"/><stop offset="0.5" stop-color="#1c1c28"/><stop offset="1" stop-color="#14141e"/></linearGradient>'
        '<radialGradient id="ve"><stop offset="0" stop-color="#ff3a2a" stop-opacity="0.9"/><stop offset="1" stop-color="#ff3a2a" stop-opacity="0"/></radialGradient>'
        '<radialGradient id="vm"><stop offset="0.6" stop-color="#b3372f" stop-opacity="0.9"/><stop offset="1" stop-color="#7a1a14" stop-opacity="0.9"/></radialGradient></defs>')

def threads(x, y):
    return ''.join(f'<path d="M{x + dx} {y} Q{x + dx * 2 + 6} {y - 40} {x + dx * 3} -4" stroke="#e8e0cc" stroke-width="0.9" opacity="0.55" fill="none"/>' for dx in (-6, 0, 6))

def varcolac(pose):
    if pose == "howl":
        head = ('<g transform="rotate(-50 116 58)"><path d="M108 50 Q122 40 146 48 L150 54 L128 62 Q114 64 108 60Z" fill="#1c1c28" stroke="#0b0d14" stroke-width="1.5"/>'
                '<path d="M128 60 L152 64 L144 70 Q132 70 126 64Z" fill="#14141e" stroke="#0b0d14" stroke-width="1.2"/>'
                '<circle cx="126" cy="51" r="6" fill="url(#ve)"/><circle cx="126" cy="51" r="1.8" fill="#ff3a2a"/>'
                '<path d="M112 46 L110 32 L120 44Z" fill="#14141e"/>'
                '<circle cx="160" cy="58" r="13" fill="url(#vm)"/><circle cx="153" cy="56" r="8" fill="#08080d"/></g>')
        legs = ('<path d="M58 80 L50 104 M70 80 L72 106 M104 76 L100 104 M114 74 L120 102" stroke="#14141e" stroke-width="5" stroke-linecap="round"/>')
    elif pose == "charge":
        head = ('<path d="M112 60 Q128 52 150 60 L156 66 L132 72 Q118 72 112 68Z" fill="#1c1c28" stroke="#0b0d14" stroke-width="1.5"/>'
                '<path d="M134 70 L158 72 L150 78 Q138 78 132 74Z" fill="#14141e"/><path d="M138 70 L140 74 L142 70 M146 70 L148 74 L150 70" fill="#f3ead6"/>'
                '<circle cx="132" cy="62" r="6" fill="url(#ve)"/><circle cx="132" cy="62" r="1.8" fill="#ff3a2a"/>'
                '<path d="M116 58 L110 44 L124 56Z" fill="#14141e"/>')
        legs = ('<path d="M56 82 L36 98 M68 82 L60 104 M102 80 L120 100 M112 78 L134 92" stroke="#14141e" stroke-width="5" stroke-linecap="round"/>')
    else:
        head = ('<path d="M110 56 Q124 46 146 54 L152 60 L130 68 Q116 68 110 64Z" fill="#1c1c28" stroke="#0b0d14" stroke-width="1.5"/>'
                '<circle cx="155" cy="62" r="11" fill="url(#vm)"/><circle cx="160" cy="58" r="6" fill="#08080d"/>'
                '<circle cx="128" cy="57" r="6" fill="url(#ve)"/><circle cx="128" cy="57" r="1.8" fill="#ff3a2a"/>'
                '<path d="M114 52 L110 38 L122 50Z" fill="#14141e"/>')
        legs = ('<path d="M58 82 L54 106 M70 82 L72 106 M104 78 L102 106 M114 76 L118 104" stroke="#14141e" stroke-width="5" stroke-linecap="round"/>')
    body = ('<ellipse cx="90" cy="110" rx="48" ry="5" fill="#000" opacity="0.4"/>'
            '<path d="M48 76 Q24 70 14 54 Q6 40 18 30 Q10 46 24 58 Q36 66 50 68Z" fill="#14141e" opacity="0.85"/>'
            '<path d="M14 54 Q4 50 2 40" stroke="#2a2a3a" stroke-width="3" fill="none" opacity="0.6"/>'
            '<path d="M46 72 Q60 60 86 62 Q110 62 118 62 Q116 80 102 84 Q80 88 58 86 Q44 84 46 72Z" fill="url(#vb)" stroke="#0b0d14" stroke-width="1.5"/>'
            '<path d="M62 70 Q66 78 62 84 M72 68 Q76 78 72 86 M82 68 Q86 78 82 86 M92 68 Q96 78 92 86" stroke="#4a4a5a" stroke-width="1.4" fill="none" opacity="0.7"/>'
            '<g fill="#3a3a4e" opacity="0.5"><circle cx="40" cy="64" r="5"/><circle cx="30" cy="70" r="3"/><circle cx="52" cy="92" r="4"/></g>')
    return f'<svg {BW}>{VDEF}<g transform="translate(6 18)">{threads(84, 64)}{legs}{body}{head}</g></svg>'

for p in ("idle", "howl", "charge"):
    sprites[f"boss_{p}"] = varcolac(p)

# ---- the Bear of the Garden (Grădina Ursului, from Harap-Alb)
BRD = ('<defs><radialGradient id="bf"><stop offset="0" stop-color="#6a4a30"/><stop offset="1" stop-color="#3a2618"/></radialGradient>'
       '<radialGradient id="be"><stop offset="0" stop-color="#ffb02a" stop-opacity="0.8"/><stop offset="1" stop-color="#ffb02a" stop-opacity="0"/></radialGradient></defs>')

def bear(pose):
    if pose == "stand":
        return f'''<svg {BW}>{BRD}<g transform="translate(0 6)"><ellipse cx="96" cy="132" rx="36" ry="6" fill="#000" opacity="0.5"/>
<path d="M78 130 L80 108 M114 130 L112 108" stroke="#2a1a10" stroke-width="14" stroke-linecap="round"/>
<path d="M70 112 Q60 70 74 44 Q96 28 118 44 Q132 70 122 112 Q96 124 70 112Z" fill="url(#bf)" stroke="#0b0d14" stroke-width="2.5"/>
<path d="M84 70 Q96 80 108 70 Q104 96 96 100 Q88 96 84 70Z" fill="#8a6a48" opacity="0.6"/>
<path d="M74 52 Q50 40 40 20 M118 52 Q142 40 152 20" stroke="#3a2618" stroke-width="14" stroke-linecap="round"/>
<path d="M36 18 L30 8 M40 16 L38 4 M44 18 L46 6 M148 18 L146 6 M152 16 L154 4 M156 18 L162 8" stroke="#e8e0cc" stroke-width="2.4" stroke-linecap="round"/>
<circle cx="96" cy="34" r="17" fill="url(#bf)" stroke="#0b0d14" stroke-width="2"/>
<circle cx="82" cy="20" r="6" fill="#3a2618" stroke="#0b0d14" stroke-width="1.5"/><circle cx="110" cy="20" r="6" fill="#3a2618" stroke="#0b0d14" stroke-width="1.5"/>
<ellipse cx="96" cy="44" rx="9" ry="7" fill="#8a6a48"/><path d="M90 46 Q96 54 102 46" fill="#5a0a0a"/><path d="M91 46 L92 50 L93 46 M99 46 L100 50 L101 46" fill="#f3ead6"/>
<circle cx="89" cy="32" r="5" fill="url(#be)"/><circle cx="103" cy="32" r="5" fill="url(#be)"/><circle cx="89" cy="32" r="1.6" fill="#1a1008"/><circle cx="103" cy="32" r="1.6" fill="#1a1008"/></g></svg>'''
    run = pose == "charge"
    legs = ('<path d="M52 104 L36 124 M64 106 L60 128 M128 104 L146 122 M138 102 L156 112" stroke="#2a1a10" stroke-width="12" stroke-linecap="round"/>' if run else
            '<path d="M54 104 L52 128 M68 106 L68 128 M124 104 L124 128 M138 102 L140 126" stroke="#2a1a10" stroke-width="12" stroke-linecap="round"/>')
    jaw = '<path d="M154 78 Q166 84 172 80 L170 88 Q160 92 152 86Z" fill="#5a0a0a"/><path d="M156 80 L158 85 L160 80 M164 80 L166 85 L168 80" fill="#f3ead6"/>' if run else ''
    return f'''<svg {BW}>{BRD}<g transform="translate(0 6)"><ellipse cx="96" cy="130" rx="62" ry="7" fill="#000" opacity="0.5"/>
{legs}
<path d="M40 96 Q34 66 64 56 Q96 44 128 56 Q150 62 152 84 Q148 106 124 110 Q90 116 58 112 Q42 108 40 96Z" fill="url(#bf)" stroke="#0b0d14" stroke-width="2.5"/>
<path d="M70 58 Q96 48 120 58" stroke="#2a1a10" stroke-width="3" fill="none" opacity="0.6"/>
<path d="M136 62 Q150 52 166 62 L174 76 Q164 86 148 84 Q136 80 136 62Z" fill="url(#bf)" stroke="#0b0d14" stroke-width="2"/>
<circle cx="142" cy="54" r="6" fill="#3a2618" stroke="#0b0d14" stroke-width="1.5"/>
<ellipse cx="166" cy="76" rx="8" ry="6" fill="#8a6a48"/><circle cx="172" cy="73" r="2.4" fill="#0b0d14"/>
<circle cx="154" cy="66" r="5" fill="url(#be)"/><circle cx="154" cy="66" r="1.6" fill="#1a1008"/>{jaw}</g></svg>'''

for p in ("idle", "stand", "charge"):
    sprites[f"bear_{p}"] = bear(p)

# ---- Magda of Moșna, permanently unimpressed
sprites["npc_magda"] = human(
    "#3a2a3a", "#4e3a4e", "#c09c80",
    '<path d="M37 38 Q35 19 48 19 Q61 19 59 38 Q57 27 48 26 Q39 27 37 38Z" fill="#6a1a2a" stroke="#0b0d14" stroke-width="1.5"/>'
    '<path d="M40 28 L36 46 L43 40Z M56 28 L60 46 L53 40Z" fill="#6a1a2a"/><circle cx="46" cy="22" r="1.5" fill="#e8c070"/><circle cx="52" cy="23" r="1.5" fill="#e8c070"/>'
    '<path d="M42 31 L47 33 M54 31 L49 33" stroke="#1a1410" stroke-width="1.6" stroke-linecap="round"/>'
    '<path d="M44 40 Q48 37 52 40" stroke="#5a2a1a" stroke-width="1.8" fill="none" stroke-linecap="round"/>',
    belt="#2a1a1a",
    front='<path d="M34 52 Q48 60 62 52 Q48 56 34 52Z" fill="#2a1e2a" stroke="#0b0d14" stroke-width="1"/><path d="M36 50 Q48 46 60 50 L60 56 Q48 52 36 56Z" fill="#4e3a4e" stroke="#0b0d14" stroke-width="1"/>'
          '<path d="M37 60 L59 60 L61 80 Q48 84 35 80Z" fill="#1a1414"/>',
    hand="#c09c80")

os.makedirs(OUT, exist_ok=True)
for name, svg in sprites.items():
    with open(os.path.join(OUT, name + ".svg"), "w") as f:
        f.write(svg)
print("wrote", len(sprites), "sprites")
