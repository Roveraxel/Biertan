"""Generate missing Lorena narration MP3s into audio/voice/ using ElevenLabs."""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from elevenlabs_client import get_client

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NARRATION_GD = os.path.join(REPO, "scripts", "core", "narration.gd")
VOICE_DIR = os.path.join(REPO, "audio", "voice")
ENV_PATH = os.path.join(REPO, ".env.local")

# Lily (Velvety Actress - premade voice, works on free tier)
VOICE_ID = "pFZP5JQG7iQjIQuC4Bku"


def load_lines(overwrite: bool = False):
    txt = open(NARRATION_GD).read()
    m = re.search(r"const LINES := \{(.*?)\n\}", txt, re.S)
    keys = re.findall(r'"([^"]+)":\s*(\[.*?\])', m.group(1), re.S)
    existing = set(os.listdir(VOICE_DIR))
    out = []
    for k, arr_s in keys:
        lines = re.findall(r'"((?:\\.|[^"])*)"', arr_s)
        for i, line in enumerate(lines):
            fn = f"{k}_{i}.mp3"
            if overwrite or fn not in existing:
                out.append((fn, line.replace('\\"', '"')))
    return out


def main():
    client = get_client(ENV_PATH)
    overwrite = "--all" in sys.argv
    todo = load_lines(overwrite=overwrite)
    if not todo:
        print("No voice files to generate.")
        return

    for fn, text in todo:
        out_path = os.path.join(VOICE_DIR, fn)
        audio = client.text_to_speech.convert(
            voice_id=VOICE_ID,
            text=text,
            model_id="eleven_multilingual_v2",
            output_format="mp3_44100_128",
        )
        with open(out_path, "wb") as f:
            for chunk in audio:
                f.write(chunk)
        print(f"wrote {fn} ({os.path.getsize(out_path)} bytes)")


if __name__ == "__main__":
    main()
