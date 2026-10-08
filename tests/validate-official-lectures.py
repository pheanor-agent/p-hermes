#!/usr/bin/env python3
"""Fail-closed checks for the preserved official v8.2 lecture package."""
from __future__ import annotations

import hashlib
import re
from html.parser import HTMLParser
from pathlib import Path
import sys
from urllib.parse import urlsplit, unquote

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/playground/lectures/v8.2"
OFFICIAL = ROOT / "docs/lectures/v8.2"
FILES = (
    "deck-a-core-v8.2.html",
    "deck-b-knowledge-v8.2.html",
    "deck-c-skill-v8.2.html",
    "deck-d-workflow-v8.2.html",
    "slides-v8.2.css",
    "slides-v8.2.js",
)
EXPECTED = {"deck-a-core-v8.2.html": 35, "deck-b-knowledge-v8.2.html": 36,
            "deck-c-skill-v8.2.html": 38, "deck-d-workflow-v8.2.html": 47}
OLD = [f"lecture-{i:02d}-" for i in range(1, 7)]

class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.targets=[]; self.local_links=[]; self.ids=set()
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if "id" in a: self.ids.add(a["id"])
        for key in ("href", "src"):
            value=a.get(key, "")
            parts=urlsplit(value)
            if value and not parts.scheme and not parts.netloc:
                self.local_links.append(value)
            if value and not value.startswith(("https://", "http://", "data:", "mailto:", "#", "javascript:")):
                self.targets.append(value.split("?",1)[0].split("#",1)[0])

errors=[]
for name in FILES:
    src, dst=SOURCE/name, OFFICIAL/name
    if not src.is_file() or not dst.is_file():
        errors.append(f"missing source/copy: {name}"); continue
    sh=hashlib.sha256(src.read_bytes()).hexdigest(); dh=hashlib.sha256(dst.read_bytes()).hexdigest()
    print(f"SHA256 {name} {sh} {'MATCH' if sh==dh else 'MISMATCH'}")
    if sh != dh: errors.append(f"byte mismatch: {name}")
for name, count in EXPECTED.items():
    text=(OFFICIAL/name).read_text(encoding="utf-8")
    actual=len(re.findall(r'<section[^>]*class="[^"]*\bslide\b', text))
    print(f"SLIDES {name}: {actual} expected {count}")
    if actual != count: errors.append(f"slide count {name}: {actual} != {count}")
    parser=Links(); parser.feed(text)
    for target in parser.targets:
        if not (OFFICIAL/target).exists(): errors.append(f"broken asset {name}: {target}")
index=ROOT/"docs/lectures/index.html"
text=index.read_text(encoding="utf-8")
parser=Links(); parser.feed(text)
for target in parser.targets:
    if not (index.parent/target).exists(): errors.append(f"broken index link: {target}")
for i in range(1,7):
    matches=list((ROOT/"docs/lectures").glob(f"lecture-{i:02d}-*.html"))
    if len(matches)!=1: errors.append(f"old lecture {i:02d}: expected exactly one local URL, found {len(matches)}")
if "156장" not in text or "2026-07-15" not in text or "2026-10-08" not in text:
    errors.append("index missing version/date metadata")
for rel in ("docs/index.html", "docs/lectures/index.html", "docs/playground/index.html",
            "docs/playground/lectures/index.html", "docs/playground/lectures/archive/v1.9/index.html"):
    page=ROOT/rel
    parser=Links(); parser.feed(page.read_text(encoding="utf-8"))
    for link in parser.local_links:
        parts=urlsplit(link)
        target=(page.parent/unquote(parts.path)).resolve() if parts.path else page
        if target.is_dir(): target=target/"index.html"
        if not target.is_file():
            errors.append(f"broken entrypoint link {rel}: {link}"); continue
        if parts.fragment and target.suffix==".html":
            dest=Links(); dest.feed(target.read_text(encoding="utf-8"))
            if unquote(parts.fragment) not in dest.ids:
                errors.append(f"broken entrypoint fragment {rel}: {link}")
    print(f"ENTRYPOINT {rel}: {len(parser.local_links)} local links checked")
if errors:
    print("FAIL:", *errors, sep="\n- "); sys.exit(1)
print("PASS: original package, 156-slide total, local assets/links and six previous lecture URLs")
