#!/usr/bin/env python3
"""Downloads one photo of each fortified village from Wikimedia Commons, with
its author and licence, into assets/photos/. Run by the 'Fetch village photos'
workflow (the dev sandbox has no access to Wikimedia)."""
import json
import os
import re
import urllib.parse
import urllib.request

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "photos")
UA = {"User-Agent": "BiertanGame/1.0 (https://github.com/Roveraxel/Biertan; game asset fetch)"}
VILLAGES = {
    "saschiz": ["Saschiz fortified church", "Saschiz"],
    "richis": ["Richiș fortified church", "Richiș"],
    "mosna": ["Moșna fortified church", "Moșna, Sibiu"],
    "biertan": ["Biertan fortified church", "Biertan"],
}
SEARCH = {
    "saschiz": "Saschiz fortified church",
    "richis": "Richis church",
    "mosna": "Mosna fortified church",
    "biertan": "Biertan fortified church",
}


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        return r.read()


def strip(html):
    return re.sub(r"<[^>]+>", "", html or "").strip()


def file_from_summary(title):
    try:
        d = json.loads(get("https://en.wikipedia.org/api/rest_v1/page/summary/" + urllib.parse.quote(title.replace(" ", "_"))))
    except Exception as e:
        print("  summary failed", title, e)
        return None
    src = (d.get("originalimage") or {}).get("source", "")
    if not src.lower().endswith((".jpg", ".jpeg")):
        return None
    return urllib.parse.unquote(src.rsplit("/", 1)[1])


def file_from_search(q):
    url = ("https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srlimit=10&format=json&srsearch="
           + urllib.parse.quote(q + " filetype:bitmap"))
    d = json.loads(get(url))
    for hit in d.get("query", {}).get("search", []):
        t = hit["title"]
        if t.lower().endswith((".jpg", ".jpeg")):
            return t.split(":", 1)[1]
    return None


def info(fname):
    url = ("https://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=1280&format=json&titles="
           + urllib.parse.quote("File:" + fname))
    d = json.loads(get(url))
    page = next(iter(d["query"]["pages"].values()))
    ii = page["imageinfo"][0]
    md = ii.get("extmetadata", {})
    return {
        "file": fname,
        "thumb": ii.get("thumburl") or ii["url"],
        "page": ii.get("descriptionurl", ""),
        "artist": strip(md.get("Artist", {}).get("value", "")) or "Unknown",
        "license": strip(md.get("LicenseShortName", {}).get("value", "")),
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    credits = {}
    for vid, titles in VILLAGES.items():
        fname = None
        for t in titles:
            fname = file_from_summary(t)
            if fname:
                break
        if not fname:
            fname = file_from_search(SEARCH[vid])
        if not fname:
            print("no photo for", vid)
            continue
        meta = info(fname)
        with open(os.path.join(OUT, vid + ".jpg"), "wb") as f:
            f.write(get(meta["thumb"]))
        credits[vid] = meta
        print(vid, "->", fname, "|", meta["artist"], "|", meta["license"])
    with open(os.path.join(OUT, "credits.json"), "w") as f:
        json.dump(credits, f, indent=1, ensure_ascii=False)


main()
