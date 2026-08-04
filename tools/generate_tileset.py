#!/usr/bin/env python3
"""Generate Oakrest Village tileset spritesheet for Eclipse Realms.

Outputs a 320x320 PNG (10 cols x 10 rows of 32x32 tiles) to:
  client/assets/environment/oakrest_village/tileset.png

Tile IDs (row-major, 0-based):
  0  grass_light      1  grass_dark        2  path
  3  dirt             4  stone_floor       5  water
  6  tree             7  building_wall     8  fence
  9  flowers         10  door             11  dark_grass
 12  stone_path      13  roof             14  well
 15  sign_post
"""

from __future__ import annotations
import os
import random
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Pillow is required: pip install Pillow")
    raise SystemExit(1)

TILE_SIZE = 32
COLS = 10
ROWS = 10
WIDTH = TILE_SIZE * COLS   # 320
HEIGHT = TILE_SIZE * ROWS  # 320

# Deterministic seed for reproducibility
random.seed(42)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _hex(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def _noise(draw: ImageDraw.ImageDraw, x0: int, y0: int,
           base: tuple[int, int, int], spread: int = 12) -> None:
    """Fill a 32x32 tile with subtle per-pixel colour noise."""
    for dy in range(TILE_SIZE):
        for dx in range(TILE_SIZE):
            r = max(0, min(255, base[0] + random.randint(-spread, spread)))
            g = max(0, min(255, base[1] + random.randint(-spread, spread)))
            b = max(0, min(255, base[2] + random.randint(-spread, spread)))
            draw.point((x0 + dx, y0 + dy), fill=(r, g, b))


def _draw_tree(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw a simple top-down tree tile."""
    # Ground grass underneath
    _noise(draw, x0, y0, _hex("#3a5a30"), 8)
    # Trunk (center)
    draw.rectangle([x0 + 13, y0 + 18, x0 + 18, y0 + 28], fill=_hex("#5a3a1a"))
    # Canopy (circle-ish)
    for dy in range(-10, 11):
        for dx in range(-10, 11):
            if dx * dx + dy * dy <= 100:
                px, py = x0 + 16 + dx, y0 + 12 + dy
                if 0 <= px < WIDTH and 0 <= py < HEIGHT:
                    r = max(0, min(255, 30 + random.randint(-8, 8)))
                    g = max(0, min(255, 80 + random.randint(-10, 10)))
                    b = max(0, min(255, 25 + random.randint(-5, 5)))
                    draw.point((px, py), fill=(r, g, b))


def _draw_water(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw water tile with wave highlights."""
    _noise(draw, x0, y0, _hex("#2a5a8a"), 10)
    # Wave highlights
    for i in range(3):
        wy = y0 + 8 + i * 10
        for dx in range(TILE_SIZE):
            wave_y = wy + int(2 * (dx / 6.0))
            if 0 <= wave_y < HEIGHT:
                draw.point((x0 + dx, y0 + wave_y),
                           fill=(80, 160, 220, 255))


def _draw_building_wall(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw brick wall tile."""
    base = _hex("#5a4a3a")
    for dy in range(TILE_SIZE):
        for dx in range(TILE_SIZE):
            r = max(0, min(255, base[0] + random.randint(-6, 6)))
            g = max(0, min(255, base[1] + random.randint(-6, 6)))
            b = max(0, min(255, base[2] + random.randint(-6, 6)))
            draw.point((x0 + dx, y0 + dy), fill=(r, g, b))
    mortar = _hex("#4a3a2a")
    # Horizontal mortar lines
    for row_y in [0, 8, 16, 24]:
        draw.line([x0, y0 + row_y, x0 + 31, y0 + row_y], fill=mortar, width=1)
    # Vertical mortar (staggered)
    for row_i, offset in enumerate([0, 16, 0, 16]):
        row_y = row_i * 8
        for col_x in [offset, offset + 16]:
            if col_x < TILE_SIZE:
                draw.line([x0 + col_x, y0 + row_y, x0 + col_x, y0 + row_y + 8],
                          fill=mortar, width=1)


def _draw_fence(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw wooden fence on grass."""
    _noise(draw, x0, y0, _hex("#4a6e3c"), 8)
    wood = _hex("#6a5040")
    dark_wood = _hex("#4a3828")
    # Horizontal bars
    draw.rectangle([x0, y0 + 10, x0 + 31, y0 + 13], fill=wood)
    draw.rectangle([x0, y0 + 19, x0 + 31, y0 + 22], fill=wood)
    # Vertical posts
    for px in [4, 14, 24]:
        draw.rectangle([x0 + px, y0 + 6, x0 + px + 3, y0 + 26], fill=dark_wood)
        draw.rectangle([x0 + px, y0 + 5, x0 + px + 3, y0 + 7], fill=wood)


def _draw_flowers(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw grass with small flowers."""
    _noise(draw, x0, y0, _hex("#4a6e3c"), 10)
    colors = [(220, 60, 60), (240, 220, 60), (200, 100, 200), (255, 255, 255)]
    for _ in range(6):
        fx = random.randint(2, 28)
        fy = random.randint(2, 28)
        c = random.choice(colors)
        draw.rectangle([x0 + fx, y0 + fy, x0 + fx + 2, y0 + fy + 2], fill=c)


def _draw_door(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw a wooden door on stone."""
    base = _hex("#7a7a7a")
    for dy in range(TILE_SIZE):
        for dx in range(TILE_SIZE):
            r = max(0, min(255, base[0] + random.randint(-4, 4)))
            draw.point((x0 + dx, y0 + dy), fill=(r, r, r))
    door = _hex("#8b6530")
    draw.rectangle([x0 + 8, y0 + 4, x0 + 23, y0 + 28], fill=door)
    # Door handle
    draw.ellipse([x0 + 18, y0 + 16, x0 + 21, y0 + 19], fill=_hex("#c0a030"))


def _draw_roof(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw roof tile."""
    base = _hex("#7a3020")
    for dy in range(TILE_SIZE):
        for dx in range(TILE_SIZE):
            r = max(0, min(255, base[0] + random.randint(-8, 8)))
            g = max(0, min(255, base[1] + random.randint(-5, 5)))
            b = max(0, min(255, base[2] + random.randint(-5, 5)))
            draw.point((x0 + dx, y0 + dy), fill=(r, g, b))
    # Shingle lines
    for row_i in range(4):
        ry = y0 + row_i * 8
        draw.line([x0, ry, x0 + 31, ry], fill=_hex("#5a2010"), width=1)
        offset = 8 if row_i % 2 else 0
        for sx in range(offset, TILE_SIZE, 16):
            draw.line([x0 + sx, ry, x0 + sx, ry + 8], fill=_hex("#5a2010"), width=1)


def _draw_well(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw a stone well."""
    _noise(draw, x0, y0, _hex("#4a6e3c"), 8)
    # Stone base
    draw.ellipse([x0 + 4, y0 + 10, x0 + 27, y0 + 28], fill=_hex("#6a6a6a"),
                 outline=_hex("#4a4a4a"))
    # Water center
    draw.ellipse([x0 + 9, y0 + 14, x0 + 22, y0 + 24], fill=_hex("#2a5a8a"))
    # Wooden frame
    draw.rectangle([x0 + 10, y0 + 4, x0 + 12, y0 + 14], fill=_hex("#5a3a1a"))
    draw.rectangle([x0 + 19, y0 + 4, x0 + 21, y0 + 14], fill=_hex("#5a3a1a"))
    draw.rectangle([x0 + 10, y0 + 4, x0 + 21, y0 + 6], fill=_hex("#5a3a1a"))


def _draw_sign_post(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw a signpost on grass."""
    _noise(draw, x0, y0, _hex("#4a6e3c"), 8)
    wood = _hex("#6a5040")
    # Post
    draw.rectangle([x0 + 14, y0 + 14, x0 + 17, y0 + 28], fill=wood)
    # Sign board
    draw.rectangle([x0 + 5, y0 + 6, x0 + 26, y0 + 14], fill=_hex("#8b7355"),
                   outline=wood, width=1)


def _draw_stone_path(draw: ImageDraw.ImageDraw, x0: int, y0: int) -> None:
    """Draw stone path tiles."""
    _noise(draw, x0, y0, _hex("#6a6a6a"), 6)
    mortar = _hex("#505050")
    # Stone slab lines
    draw.line([x0, y0 + 15, x0 + 31, y0 + 15], fill=mortar, width=1)
    draw.line([x0 + 15, y0, x0 + 15, y0 + 15], fill=mortar, width=1)
    draw.line([x0 + 7, y0 + 15, x0 + 7, y0 + 31], fill=mortar, width=1)
    draw.line([x0 + 23, y0 + 15, x0 + 23, y0 + 31], fill=mortar, width=1)


# ---------------------------------------------------------------------------
# Main generation
# ---------------------------------------------------------------------------

def generate() -> None:
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    tiles: list[tuple[str, callable]] = [
        ("grass_light",   lambda x, y: _noise(draw, x, y, _hex("#4a6e3c"), 12)),
        ("grass_dark",    lambda x, y: _noise(draw, x, y, _hex("#3a5a30"), 10)),
        ("path",          lambda x, y: _noise(draw, x, y, _hex("#8b7355"), 8)),
        ("dirt",          lambda x, y: _noise(draw, x, y, _hex("#6b5b3a"), 10)),
        ("stone_floor",   lambda x, y: (
            _noise(draw, x, y, _hex("#7a7a7a"), 5),
            draw.line([x, y + 15, x + 31, y + 15], fill=_hex("#606060"), width=1),
            draw.line([x + 15, y, x + 15, y + 31], fill=_hex("#606060"), width=1),
        )),
        ("water",         lambda x, y: _draw_water(draw, x, y)),
        ("tree",          lambda x, y: _draw_tree(draw, x, y)),
        ("building_wall", lambda x, y: _draw_building_wall(draw, x, y)),
        ("fence",         lambda x, y: _draw_fence(draw, x, y)),
        ("flowers",       lambda x, y: _draw_flowers(draw, x, y)),
        ("door",          lambda x, y: _draw_door(draw, x, y)),
        ("dark_grass",    lambda x, y: _noise(draw, x, y, _hex("#2d4a25"), 10)),
        ("stone_path",    lambda x, y: _draw_stone_path(draw, x, y)),
        ("roof",          lambda x, y: _draw_roof(draw, x, y)),
        ("well",          lambda x, y: _draw_well(draw, x, y)),
        ("sign_post",     lambda x, y: _draw_sign_post(draw, x, y)),
    ]

    for idx, (name, fn) in enumerate(tiles):
        col = idx % COLS
        row = idx // COLS
        x0 = col * TILE_SIZE
        y0 = row * TILE_SIZE
        print(f"  Tile {idx:2d} ({name:16s}) -> ({x0}, {y0})")
        fn(x0, y0)

    # Fill remaining slots with grass
    for idx in range(len(tiles), COLS * ROWS):
        col = idx % COLS
        row = idx // COLS
        x0 = col * TILE_SIZE
        y0 = row * TILE_SIZE
        _noise(draw, x0, y0, _hex("#4a6e3c"), 12)

    out = Path(__file__).resolve().parent.parent / "client" / "assets" / "environment" / "oakrest_village" / "tileset.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(str(out))
    print(f"\nSaved tileset to: {out}")
    print(f"  Size: {WIDTH}x{HEIGHT}, {len(tiles)} unique tiles")


if __name__ == "__main__":
    generate()
