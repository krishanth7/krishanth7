#!/usr/bin/env python3
"""
gen_card.py — Render the profile status card as a self-contained SVG.

The card is drawn from live GitHub data so the numbers on the profile are
real rather than hand-maintained. If the API cannot be reached the last
successful response (profile/card/stats.json) is reused, so the build never
invents figures and never fails offline.

Design notes
  * The wordmark is drawn as explicit rectangles from a 5x7 bitmap font.
    GitHub strips web fonts from SVG served through its image proxy, so any
    text-based wordmark would render in whatever font the viewer happens to
    have. Rectangles are identical everywhere.
  * Panel frames are SVG lines rather than box-drawing characters, for the
    same reason: no dependency on a particular font's glyph coverage.
  * Data rows are single text runs with dot leaders, so the value column
    aligns using the font's own metrics rather than an assumed advance width.

Usage:
  ./scripts/gen_card.py --theme matrix --out profile/card/card-matrix.svg
  ./scripts/gen_card.py --offline          # never touch the network
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import random
import sys
import urllib.error
import urllib.request
from xml.sax.saxutils import escape

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import pixelfont  # noqa: E402

USER = "krishanth7"
API = "https://api.github.com"
ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / "profile" / "card" / "stats.json"

# --- Themes -------------------------------------------------------------------
THEMES = {
    "matrix": {
        "bg": "#000A02",
        "panel": "#03150A",
        "grid": "#0B3A18",
        "rule": "#0F6B2A",
        "dim": "#1C6B31",
        "label": "#6EE787",
        "value": "#D7FFE3",
        "accent": "#00FF41",
        "accent_soft": "#00B32D",
        "rain": "#00FF41",
        "subtitle": "#3FB950",
    },
    "cyber": {
        "bg": "#05070F",
        "panel": "#0B1020",
        "grid": "#16234A",
        "rule": "#2F5BD0",
        "dim": "#27407F",
        "label": "#79C0FF",
        "value": "#E6EDFF",
        "accent": "#2F81F7",
        "accent_soft": "#A371F7",
        "rain": "#2F81F7",
        "subtitle": "#A371F7",
    },
}

# --- Geometry -----------------------------------------------------------------
W = 700               # card width
PAD = 26              # outer padding
FS = 13               # data-row font size
LH = 20               # data-row line height
CW = FS * 0.6         # assumed monospace advance, for sizing only
ROW_CHARS = 79        # width of a data row, in characters (excluding the '> ' bullet)
SCALE = 4             # pixel-font cell size
MONO = ("ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, "
        "'DejaVu Sans Mono', 'Liberation Mono', monospace")


# --- Data ---------------------------------------------------------------------
def _get(url, token=None):
    request = urllib.request.Request(url, headers={
        "Accept": "application/vnd.github+json",
        "User-Agent": f"{USER}-profile-card",
        **({"Authorization": f"Bearer {token}"} if token else {}),
    })
    with urllib.request.urlopen(request, timeout=15) as response:
        return json.load(response)


def fetch(token=None):
    """Return live profile figures, or None if GitHub cannot be reached."""
    try:
        user = _get(f"{API}/users/{USER}", token)
        repos, page = [], 1
        while page <= 5:
            batch = _get(f"{API}/users/{USER}/repos?per_page=100&page={page}", token)
            if not batch:
                break
            repos.extend(batch)
            page += 1
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError) as err:
        print(f"[card] GitHub unreachable ({err}); falling back to cache", file=sys.stderr)
        return None

    owned = [r for r in repos if not r.get("fork")]
    languages = {}
    for repo in owned:
        language = repo.get("language")
        if language:
            languages[language] = languages.get(language, 0) + 1

    return {
        "login": user.get("login", USER),
        "name": user.get("name") or USER,
        "company": user.get("company") or "",
        "location": user.get("location") or "",
        "bio": user.get("bio") or "",
        "twitter": user.get("twitter_username") or "",
        "created_at": user.get("created_at", ""),
        "repos": user.get("public_repos", len(repos)),
        "followers": user.get("followers", 0),
        "following": user.get("following", 0),
        "stars": sum(r.get("stargazers_count", 0) for r in repos),
        "forks": sum(r.get("forks_count", 0) for r in repos),
        "languages": [k for k, _ in sorted(languages.items(), key=lambda kv: -kv[1])],
        "generated_at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


def load_cache():
    if CACHE.exists():
        return json.loads(CACHE.read_text())
    return None


def _add_months(date, count):
    """`date` shifted by `count` months, clamped to the target month's last day.

    Jan 31 plus one month is Feb 28 (or 29), not an invalid date.
    """
    total = date.year * 12 + (date.month - 1) + count
    year, month = divmod(total, 12)
    month += 1
    if month == 12:
        next_month = dt.date(year + 1, 1, 1)
    else:
        next_month = dt.date(year, month + 1, 1)
    last_day = (next_month - dt.timedelta(days=1)).day
    return dt.date(year, month, min(date.day, last_day))


def uptime(created_at, today=None):
    """Account age as 'N years, N months, N days' — the card's 'Uptime' row.

    Counts whole months first, then measures the remainder from that month
    anniversary. Subtracting the day fields directly and borrowing from the
    preceding month goes negative across short months (Jan 31 to Mar 1).
    """
    if not created_at:
        return "unknown"
    start = dt.datetime.strptime(created_at, "%Y-%m-%dT%H:%M:%SZ").date()
    today = today or dt.date.today()
    if today < start:
        return "0 years, 0 months, 0 days"

    months = (today.year - start.year) * 12 + (today.month - start.month)
    if today.day < start.day:
        months -= 1
    months = max(months, 0)
    days = (today - _add_months(start, months)).days
    years, months = divmod(months, 12)

    def plural(value, unit):
        return f"{value} {unit}" + ("" if value == 1 else "s")

    return ", ".join([plural(years, "year"), plural(months, "month"), plural(days, "day")])


# --- SVG primitives -----------------------------------------------------------
def leader(label, value, width=ROW_CHARS):
    """'label ....... value' padded so values line up in a monospace grid."""
    room = width - len(label) - len(value) - 2
    return label, "." * max(room, 1), value


def row(x, y, label, value, theme, value_color=None, width=ROW_CHARS):
    left, dots, right = leader(label, value, width)
    return (
        f'<text x="{x}" y="{y}" font-family="{MONO}" font-size="{FS}" '
        f'xml:space="preserve">'
        f'<tspan fill="{theme["accent_soft"]}">&gt; </tspan>'
        f'<tspan fill="{theme["label"]}">{escape(left)}</tspan>'
        f'<tspan fill="{theme["dim"]}"> {dots} </tspan>'
        f'<tspan fill="{value_color or theme["value"]}">{escape(right)}</tspan>'
        f'</text>'
    )


def section(x, y, title, theme, width=W - 2 * PAD):
    """A small-caps section label with a rule running to the right edge."""
    # Advance plus letter-spacing per character, then a gap before the rule.
    # Omitting the letter-spacing term makes the rule start under the label.
    letter_spacing = 2.2
    text_width = len(title) * ((FS - 2) * 0.6 + letter_spacing) + 12
    return (
        f'<text x="{x}" y="{y}" font-family="{MONO}" font-size="{FS - 2}" '
        f'letter-spacing="{letter_spacing}" fill="{theme["accent"]}" font-weight="bold">'
        f'{escape(title.upper())}</text>'
        f'<line x1="{x + text_width:.0f}" y1="{y - 4}" x2="{x + width}" y2="{y - 4}" '
        f'stroke="{theme["rule"]}" stroke-width="1" opacity="0.55"/>'
    )


def wordmark(x, y, text, theme, scale=SCALE):
    """The name, drawn cell by cell from the bitmap font."""
    parts = [f'<g fill="{theme["accent"]}">']
    for col, cell_row in pixelfont.cells(text):
        parts.append(
            f'<rect x="{x + col * scale}" y="{y + cell_row * scale}" '
            f'width="{scale}" height="{scale}"/>'
        )
    parts.append("</g>")
    return "".join(parts)


def matrix_rain(width, height, theme, seed=7):
    """Deterministic background rain.

    Seeded so repeated builds produce an identical file; a card that changed
    on every run would churn the repository and defeat CI's diff check.
    """
    rng = random.Random(seed)
    glyphs = "01ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾅﾆﾇﾈﾊﾋﾌﾍﾎABCDEFXYZ<>{}[]/\\|=+*"
    parts = [f'<g font-family="{MONO}" font-size="12" fill="{theme["rain"]}">']
    for column_x in range(8, width - 8, 15):
        length = rng.randint(3, 9)
        start_y = rng.randint(-40, height)
        for step in range(length):
            y = start_y + step * 15
            if not (0 < y < height):
                continue
            # Brightest at the head of the trail, fading upward.
            opacity = 0.05 + 0.13 * (step / max(length - 1, 1))
            parts.append(
                f'<text x="{column_x}" y="{y}" opacity="{opacity:.3f}">'
                f'{escape(rng.choice(glyphs))}</text>'
            )
    parts.append("</g>")
    return "".join(parts)


def scanlines(width, height, theme):
    parts = [f'<g stroke="{theme["grid"]}" stroke-width="1" opacity="0.16">']
    for y in range(0, height, 3):
        parts.append(f'<line x1="0" y1="{y}" x2="{width}" y2="{y}"/>')
    parts.append("</g>")
    return "".join(parts)


# --- Card ---------------------------------------------------------------------
def build(data, theme_name="matrix"):
    theme = THEMES[theme_name]
    x = PAD
    parts = []
    y = PAD + 26

    # Wordmark and tagline.
    parts.append(wordmark(x, y - 22, data["name"] or USER, theme))
    y += 18
    parts.append(
        f'<text x="{x}" y="{y}" font-family="{MONO}" font-size="{FS - 1}" '
        f'letter-spacing="1.6" fill="{theme["subtitle"]}">'
        f'AI/ML ENGINEER &#183; FULL STACK &#183; ROBOTICS</text>'
    )
    y += 12
    parts.append(
        f'<line x1="{x}" y1="{y}" x2="{W - PAD}" y2="{y}" '
        f'stroke="{theme["rule"]}" stroke-width="1" opacity="0.5"/>'
    )

    # Identity.
    y += 26
    parts.append(section(x, y, "identity", theme))
    for label, value in [
        ("Uptime", uptime(data.get("created_at", ""))),
        ("Location", data.get("location") or "—"),
        ("Company", data.get("company") or "—"),
        ("Focus", "AI / ML  ·  Autonomous Systems  ·  Compilers"),
        ("Languages", ", ".join(data.get("languages", [])[:5]) or "—"),
    ]:
        y += LH
        parts.append(row(x, y, label, value, theme))

    # Contact.
    y += 30
    parts.append(section(x, y, "contact", theme))
    contacts = [
        ("GitHub", f"github.com/{data.get('login', USER)}"),
        ("Cretes", "github.com/Cretes-lang"),
    ]
    if data.get("twitter"):
        contacts.append(("X", f"@{data['twitter']}"))
    for label, value in contacts:
        y += LH
        parts.append(row(x, y, label, value, theme))

    # Metrics, two per line.
    y += 30
    parts.append(section(x, y, "metrics", theme))
    separator = "   |   "
    half = (ROW_CHARS - len(separator) - 2) // 2
    assert 2 * half + len(separator) + 2 == ROW_CHARS, "metrics row must match ROW_CHARS"
    pairs = [
        (("Repos", str(data.get("repos", 0))), ("Stars", str(data.get("stars", 0)))),
        (("Followers", str(data.get("followers", 0))),
         ("Following", str(data.get("following", 0)))),
    ]
    for left_stat, right_stat in pairs:
        y += LH
        a_label, a_dots, a_value = leader(*left_stat, width=half)
        b_label, b_dots, b_value = leader(*right_stat, width=half)
        parts.append(
            f'<text x="{x}" y="{y}" font-family="{MONO}" font-size="{FS}" '
            f'xml:space="preserve">'
            f'<tspan fill="{theme["accent_soft"]}">&gt; </tspan>'
            f'<tspan fill="{theme["label"]}">{escape(a_label)}</tspan>'
            f'<tspan fill="{theme["dim"]}"> {a_dots} </tspan>'
            f'<tspan fill="{theme["accent"]}" font-weight="bold">{escape(a_value)}</tspan>'
            f'<tspan fill="{theme["dim"]}">{separator}</tspan>'
            f'<tspan fill="{theme["accent_soft"]}">&gt; </tspan>'
            f'<tspan fill="{theme["label"]}">{escape(b_label)}</tspan>'
            f'<tspan fill="{theme["dim"]}"> {b_dots} </tspan>'
            f'<tspan fill="{theme["accent"]}" font-weight="bold">{escape(b_value)}</tspan>'
            f'</text>'
        )

    # Prompt line with a blinking caret. If SMIL is stripped the caret simply
    # stays visible, which is the correct resting state.
    y += 34
    parts.append(
        f'<text x="{x}" y="{y}" font-family="{MONO}" font-size="{FS}" '
        f'xml:space="preserve">'
        f'<tspan fill="{theme["accent"]}">{escape(data.get("login", USER))}@github</tspan>'
        f'<tspan fill="{theme["dim"]}">:~$ </tspan>'
        f'<tspan fill="{theme["value"]}">./scripts/profile.sh --summary</tspan>'
        f'<tspan fill="{theme["accent"]}" font-weight="bold">&#9608;'
        f'<animate attributeName="opacity" values="1;1;0;0" dur="1.1s" '
        f'repeatCount="indefinite"/></tspan>'
        f'</text>'
    )

    height = y + PAD
    body = "".join(parts)

    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{height}" '
        f'viewBox="0 0 {W} {height}" role="img" '
        f'aria-label="{escape(data.get("name", USER))} — AI/ML engineer profile card">'
        f'<title>{escape(data.get("name", USER))} — AI/ML Engineer</title>'
        f'<desc>Profile status card generated from GitHub data. Render time is recorded in stats.json, not here, so the card is a pure function of the figures and only changes when they do.</desc>'
        f'<defs><clipPath id="card"><rect width="{W}" height="{height}" rx="10"/></clipPath></defs>'
        f'<g clip-path="url(#card)">'
        f'<rect width="{W}" height="{height}" fill="{theme["bg"]}"/>'
        f'{matrix_rain(W, height, theme)}'
        f'{scanlines(W, height, theme)}'
        f'{body}'
        f'</g>'
        f'<rect x="0.5" y="0.5" width="{W - 1}" height="{height - 1}" rx="10" '
        f'fill="none" stroke="{theme["rule"]}" stroke-width="1" opacity="0.8"/>'
        f'</svg>\n'
    )


def main():
    parser = argparse.ArgumentParser(description="Render the profile card as SVG.")
    parser.add_argument("--theme", choices=sorted(THEMES), default="matrix")
    parser.add_argument("--out", required=True, help="output .svg path")
    parser.add_argument("--offline", action="store_true",
                        help="use the cached stats file, never the network")
    parser.add_argument("--token", default=None, help="GitHub token (raises rate limits)")
    args = parser.parse_args()

    data = None if args.offline else fetch(args.token)
    if data is not None:
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    else:
        data = load_cache()
        if data is None:
            print("[card] no live data and no cache; cannot render", file=sys.stderr)
            return 1

    out = pathlib.Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(build(data, args.theme), encoding="utf-8")
    print(f"[card] wrote {out} ({out.stat().st_size} bytes, theme={args.theme})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
