"""
pixelfont.py — A 5x7 bitmap font, in the tradition of the IBM PC text ROM.

Each glyph is seven rows of five cells; '#' is an inked cell and any other
character is blank. Rendering glyphs as explicit rectangles rather than text
keeps the wordmark pixel-identical on every platform, which matters because
GitHub strips web fonts from SVG served through its image proxy.
"""

WIDTH = 5
HEIGHT = 7

_GLYPHS = {
    "A": ".###.|#...#|#...#|#####|#...#|#...#|#...#",
    "B": "####.|#...#|#...#|####.|#...#|#...#|####.",
    "C": ".####|#....|#....|#....|#....|#....|.####",
    "D": "####.|#...#|#...#|#...#|#...#|#...#|####.",
    "E": "#####|#....|#....|####.|#....|#....|#####",
    "F": "#####|#....|#....|####.|#....|#....|#....",
    "G": ".###.|#...#|#....|#.###|#...#|#...#|.###.",
    "H": "#...#|#...#|#...#|#####|#...#|#...#|#...#",
    "I": "#####|..#..|..#..|..#..|..#..|..#..|#####",
    "J": "..###|...#.|...#.|...#.|...#.|#..#.|.##..",
    "K": "#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#",
    "L": "#....|#....|#....|#....|#....|#....|#####",
    "M": "#...#|##.##|#.#.#|#...#|#...#|#...#|#...#",
    "N": "#...#|##..#|#.#.#|#..##|#...#|#...#|#...#",
    "O": ".###.|#...#|#...#|#...#|#...#|#...#|.###.",
    "P": "####.|#...#|#...#|####.|#....|#....|#....",
    "Q": ".###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#",
    "R": "####.|#...#|#...#|####.|#.#..|#..#.|#...#",
    "S": ".####|#....|#....|.###.|....#|....#|####.",
    "T": "#####|..#..|..#..|..#..|..#..|..#..|..#..",
    "U": "#...#|#...#|#...#|#...#|#...#|#...#|.###.",
    "V": "#...#|#...#|#...#|#...#|#...#|.#.#.|..#..",
    "W": "#...#|#...#|#...#|#...#|#.#.#|##.##|#...#",
    "X": "#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#",
    "Y": "#...#|#...#|.#.#.|..#..|..#..|..#..|..#..",
    "Z": "#####|....#|...#.|..#..|.#...|#....|#####",
    "0": ".###.|#...#|#..##|#.#.#|##..#|#...#|.###.",
    "1": "..#..|.##..|..#..|..#..|..#..|..#..|.###.",
    "2": ".###.|#...#|....#|...#.|..#..|.#...|#####",
    "3": "#####|...#.|..#..|...#.|....#|#...#|.###.",
    "4": "...#.|..##.|.#.#.|#..#.|#####|...#.|...#.",
    "5": "#####|#....|####.|....#|....#|#...#|.###.",
    "6": "..##.|.#...|#....|####.|#...#|#...#|.###.",
    "7": "#####|....#|...#.|..#..|.#...|.#...|.#...",
    "8": ".###.|#...#|#...#|.###.|#...#|#...#|.###.",
    "9": ".###.|#...#|#...#|.####|....#|...#.|.##..",
    " ": ".....|.....|.....|.....|.....|.....|.....",
    ".": ".....|.....|.....|.....|.....|.##..|.##..",
    "-": ".....|.....|.....|#####|.....|.....|.....",
    "_": ".....|.....|.....|.....|.....|.....|#####",
    "/": "....#|...#.|...#.|..#..|.#...|.#...|#....",
    "@": ".###.|#...#|#.###|#.#.#|#.###|#....|.###.",
}

# Rendered as rows of five cells for convenient indexing.
GLYPHS = {ch: pattern.split("|") for ch, pattern in _GLYPHS.items()}

for _ch, _rows in GLYPHS.items():
    assert len(_rows) == HEIGHT, f"glyph {_ch!r} has {len(_rows)} rows"
    for _row in _rows:
        assert len(_row) == WIDTH, f"glyph {_ch!r} has a row of width {len(_row)}"


def cells(text):
    """Yield (col, row) for every inked cell of `text`, in glyph-grid units.

    Glyphs advance by WIDTH + 1 so a single blank column separates letters.
    Unknown characters fall back to a space rather than raising, so a nickname
    with an unexpected symbol degrades to a gap instead of failing the build.
    """
    for index, char in enumerate(text.upper()):
        rows = GLYPHS.get(char, GLYPHS[" "])
        origin = index * (WIDTH + 1)
        for row_index, row in enumerate(rows):
            for col_index, cell in enumerate(row):
                if cell == "#":
                    yield origin + col_index, row_index


def advance(text):
    """Total width of `text` in glyph-grid columns, excluding the trailing gap."""
    return max(0, len(text) * (WIDTH + 1) - 1)
