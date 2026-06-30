#!/usr/bin/env python3
# meta: id=build-index kind=script group="Index & navigation" status=ready tags=index,maintenance intent="Regenerate index.json + CATALOG.md + research/INDEX.md from asset metadata and the research ledger"
"""
build-index.py — the single source of the project's index.

Scans every asset for inline metadata, reads the research ledger, and regenerates:
  - index.json          (machine: what agents query with jq)
  - CATALOG.md          (human view, body between the GENERATED markers)
  - research/INDEX.md    (human view of the research ledger)

Metadata conventions (no external deps):
  - Markdown assets  -> YAML-ish frontmatter keys: kind, status, group, intent, tags
  - Shell/Python     -> a single line:  # meta: key=value key="value with spaces" ...
  - id defaults to the filename stem; path is derived.

Run it after changing any asset (the cron and /triage-discoveries do this for you):
  python3 scripts/build-index.py
"""
import glob, json, os, re, shlex, sys
from datetime import date

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

ASSET_GLOBS = [
    "install.sh",
    "scripts/*.sh", "scripts/*.py",
    ".claude/commands/*.md", ".claude/agents/*.md",
    "docs/*.md", "hooks/*", "mcp/*.md",
]
SKIP_NAMES = {"README.md"}
# Order + friendly headers for CATALOG sections (groups not listed fall to the end).
GROUP_ORDER = [
    "Discover & adopt external agent tooling",
    "Contribute back",
    "Save tokens / work efficiently",
    "Index & navigation",
    "Reusable Claude Code assets",
]
STATUS_ICON = {"ready": "🟢", "experimental": "🟡", "research": "🔬"}


def parse_frontmatter(text):
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    meta = {}
    for line in text[3:end].splitlines():
        if not line.strip() or ":" not in line:
            continue
        k, v = line.split(":", 1)
        k, v = k.strip(), v.strip()
        if v.startswith("[") and v.endswith("]"):
            meta[k] = [t.strip().strip("'\"") for t in v[1:-1].split(",") if t.strip()]
        else:
            meta[k] = v.strip("'\"")
    return meta


def parse_meta_comment(text):
    m = re.search(r"^#\s*meta:\s*(.+)$", text, re.MULTILINE)
    if not m:
        return None
    meta = {}
    for tok in shlex.split(m.group(1)):
        if "=" not in tok:
            continue
        k, v = tok.split("=", 1)
        meta[k] = v.split(",") if (k == "tags" and "," in v) else v
    if isinstance(meta.get("tags"), str):
        meta["tags"] = [meta["tags"]] if meta["tags"] else []
    return meta


def collect_assets():
    assets, seen = [], set()
    for pattern in ASSET_GLOBS:
        for path in sorted(glob.glob(pattern)):
            if path in seen or os.path.basename(path) in SKIP_NAMES or not os.path.isfile(path):
                continue
            seen.add(path)
            text = open(path, encoding="utf-8", errors="replace").read()
            meta = parse_frontmatter(text) if path.endswith(".md") else parse_meta_comment(text)
            if not meta or "intent" not in meta:
                print(f"[build-index] no metadata, skipping: {path}", file=sys.stderr)
                continue
            tags = meta.get("tags") or []
            if isinstance(tags, str):
                tags = [t.strip() for t in tags.split(",") if t.strip()]
            assets.append({
                "id": meta.get("id", os.path.splitext(os.path.basename(path))[0]),
                "kind": meta.get("kind", "asset"),
                "path": path,
                "group": meta.get("group", "Reusable Claude Code assets"),
                "intent": meta["intent"],
                "status": meta.get("status", "ready"),
                "tags": tags,
            })
    return assets


def compute_maturity(r):
    """Separate stable from new/trending when the ledger didn't say explicitly."""
    if r.get("maturity"):
        return r["maturity"]
    sig = r.get("signals") or {}
    stars = r.get("stars") or sig.get("stars") or 0
    age = sig.get("age_days")
    nsources = len(r.get("sources") or [r.get("source")] or [])
    if stars >= 10000:
        return "stable"
    if stars >= 1000 and (age is None or age > 365):
        return "stable"
    if age is not None and age <= 45:
        return "trending"
    if "github-trending" in (r.get("sources") or []) and stars < 10000:
        return "trending"
    if nsources >= 2 or stars >= 200:
        return "emerging"
    return "experimental"


def collect_research():
    out = []
    if os.path.exists("research/ledger.jsonl"):
        for line in open("research/ledger.jsonl", encoding="utf-8"):
            line = line.strip()
            if line:
                out.append(json.loads(line))
    for r in out:
        r.setdefault("source", "github")
        r.setdefault("sources", [r["source"]])
        r["maturity"] = compute_maturity(r)
    out.sort(key=lambda r: (-r.get("stars", 0)))
    return out


def note_path(repo):
    return f"research/{repo.replace('/', '__')}.md"


def write_index_json(assets, research):
    doc = {
        "generated": date.today().isoformat(),
        "note": ("Machine index. Query with jq, e.g.: "
                 "jq -r '.assets[]|select(.tags|index(\"tokens\"))|.path' index.json ; "
                 "jq -r '.research[]|select(.maturity==\"trending\")|.repo' index.json ; "
                 "jq -r '.research[]|select((.sources|length)>1)|.repo' index.json"),
        "assets": assets,
        "research": [
            {**r, "note": note_path(r["repo"])} for r in research
        ],
    }
    with open("index.json", "w", encoding="utf-8") as f:
        json.dump(doc, f, indent=2, ensure_ascii=False)
        f.write("\n")


def render_catalog_body(assets, research):
    groups = {}
    for a in assets:
        groups.setdefault(a["group"], []).append(a)
    ordered = [g for g in GROUP_ORDER if g in groups] + [g for g in groups if g not in GROUP_ORDER]
    lines = []
    for g in ordered:
        lines.append(f"## {g}")
        for a in sorted(groups[g], key=lambda x: x["intent"].lower()):
            icon = STATUS_ICON.get(a["status"], "•")
            tags = f" · _{', '.join(a['tags'])}_" if a["tags"] else ""
            lines.append(f"- {icon} **{a['intent']}** → `{a['path']}`{tags}")
        lines.append("")
    adopt = [r for r in research if r.get("verdict") == "adopt"]
    if adopt:
        lines.append("## From research (adopt)")
        for r in adopt:
            lines.append(f"- 🔬 **{r['intent']}** → `{note_path(r['repo'])}` (`{r['repo']}` ⭐{r.get('stars','?')})")
        lines.append("")
    lines.append("See [`research/INDEX.md`](research/INDEX.md) for every analyzed repo, "
                 "and query [`index.json`](index.json) programmatically.")
    return "\n".join(lines)


def write_catalog(body):
    path = "CATALOG.md"
    begin, end = "<!-- BEGIN GENERATED -->", "<!-- END GENERATED -->"
    text = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
    block = f"{begin}\n{body}\n{end}"
    if begin in text and end in text:
        text = re.sub(re.escape(begin) + r".*?" + re.escape(end), block.replace("\\", "\\\\"), text, flags=re.DOTALL)
    else:
        text = (text.rstrip() + "\n\n" if text.strip() else "") + block + "\n"
    open(path, "w", encoding="utf-8").write(text)


def write_research_index(research):
    lines = [
        "# Research index — external agent/plugin repos we've analyzed",
        "",
        "_Generated by `scripts/build-index.py` from `research/ledger.jsonl` — do not hand-edit._",
        "",
        "_Verdicts: **adopt** (reusable now) · **watch** (promising, recheck) · **skip** (no fit)._",
        "_Maturity: **stable** · **trending** · **emerging** · **experimental**. Sources show "
        "where it was seen (multi-source = corroborated)._",
        "",
    ]

    def row(r):
        srcs = ",".join(r.get("sources", []))
        sig = r.get("signals") or {}
        buzz = sig.get("points") or sig.get("score")
        buzz = f" · {buzz}↑" if buzz else ""
        return (f"- [{r['repo']}]({note_path(r['repo'])}) ⭐{r.get('stars','?')} · "
                f"_{r.get('maturity','?')}_ · [{srcs}]{buzz} — {r['intent']}")

    # Primary view: by verdict.
    for verdict in ("adopt", "watch", "skip"):
        rows = [r for r in research if r.get("verdict") == verdict]
        if not rows:
            continue
        lines.append(f"## {verdict} ({len(rows)})")
        lines += [row(r) for r in rows]
        lines.append("")

    # Secondary view: what's trending / corroborated (quick scan for the new & hot).
    trending = [r for r in research if r.get("maturity") == "trending"]
    corrob = [r for r in research if len(r.get("sources", [])) > 1]
    if trending:
        lines.append(f"## 🔥 trending ({len(trending)})")
        lines += [row(r) for r in trending]
        lines.append("")
    if corrob:
        lines.append(f"## ✅ multi-source / corroborated ({len(corrob)})")
        lines += [row(r) for r in corrob]
        lines.append("")
    open("research/INDEX.md", "w", encoding="utf-8").write("\n".join(lines))


def main():
    assets = collect_assets()
    research = collect_research()
    write_index_json(assets, research)
    write_catalog(render_catalog_body(assets, research))
    write_research_index(research)
    print(f"[build-index] {len(assets)} assets, {len(research)} research records -> "
          f"index.json, CATALOG.md, research/INDEX.md")


if __name__ == "__main__":
    main()
