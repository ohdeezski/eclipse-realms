#!/usr/bin/env python3
"""Generate the 9 missing icon PNGs for Eclipse Realms.

The existing create_sprites.py only generates player sprites and hero avatar.
This script generates the missing item and skill icons (64x64, cel-shaded style
matching the existing icon art).

Missing icons:
  Items:  wooden_sword, rope, torch, wolf_pelt, moss_essence, thorn
  Skills: basic_attack, heal, fire_bolt
"""

from PIL import Image, ImageDraw
import hashlib
import os

BASE_DIR = "/home/ssmartnycbase/Desktop/StreetSmartNYC-BusinessBase/Obsidian-Vault/game-projects-(to monetize)/project-eclipse-realms"
ICONS_DIR = os.path.join(BASE_DIR, "client/assets/ui/icons")

ICON_SIZE = 64
OUTLINE = (30, 30, 30, 255)


def _new_canvas(bg=True):
    """Create a 64x64 transparent canvas."""
    return Image.new('RGBA', (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))


def _rounded_bg(img, color=(40, 40, 55, 255), radius=10, margin=4):
    """Draw a subtle rounded-rectangle background (matches existing icon style)."""
    draw = ImageDraw.Draw(img)
    margin = margin
    bx = margin
    by = margin
    bw = ICON_SIZE - margin * 2
    bh = ICON_SIZE - margin * 2
    # Use a subtle inner shadow for depth
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius, fill=color)
    # Inner highlight
    draw.rounded_rectangle([bx + 3, by + 3, bx + bw - 3, by + bh - 3], radius - 3,
                           fill=(60, 60, 75, 255))


def _add_outline(draw, shape_func, coords, outline_color, width=1):
    """Draw a shape with an outline."""
    shape_func(coords, fill=outline_color, width=width)


def gen_wooden_sword():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (50, 40, 30, 240), 10)

    # Sword blade (wooden brown)
    blade_color = (139, 69, 19, 255)
    blade_dark = (100, 50, 12, 255)
    # Blade shape
    blade_pts = [(26, 18), (28, 18), (32, 40), (30, 40), (26, 20)]
    draw.polygon(blade_pts, fill=blade_color, outline=OUTLINE)
    # Blade edge highlight
    draw.line([(28, 20), (31, 38)], fill=(160, 90, 30, 255), width=1)

    # Handle
    handle_color = (101, 67, 33, 255)
    handle_pts = [(29, 38), (31, 38), (32, 50), (28, 50)]
    draw.polygon(handle_pts, fill=handle_color, outline=OUTLINE)
    # Handle grip details
    draw.line([(29, 42), (31, 42)], fill=(80, 50, 25, 255), width=1)
    draw.line([(29, 46), (31, 46)], fill=(80, 50, 25, 255), width=1)

    # Pommel
    draw.ellipse([27, 49, 33, 55], fill=(80, 50, 25, 255), outline=OUTLINE)

    return img


def gen_rope():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (50, 40, 30, 240), 10)

    rope_color = (139, 69, 19, 255)
    rope_dark = (100, 50, 12, 255)

    # Coiled rope - draw spiral
    cx, cy = 32, 32
    # Draw multiple coil loops
    for i in range(4):
        offset = i * 6
        y_pos = cy - 12 + offset
        # Left side
        draw.ellipse([16, y_pos, 24, y_pos + 8], fill=rope_color, outline=OUTLINE)
        # Right side
        draw.ellipse([40, y_pos, 48, y_pos + 8], fill=rope_color, outline=OUTLINE)
        # Top connector (left to right)
        draw.line([16, y_pos + 4, 24, y_pos + 4], fill=rope_color, width=3)
        draw.line([24, y_pos + 4, 40, y_pos + 4], fill=rope_dark, width=3)
        draw.line([40, y_pos + 4, 48, y_pos + 4], fill=rope_color, width=3)

    # Rope end hanging
    draw.ellipse([30, 50, 34, 58], fill=rope_color, outline=OUTLINE)
    draw.line([32, 40, 32, 50], fill=rope_dark, width=4)

    return img


def gen_torch():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (50, 40, 30, 240), 10)

    # Torch handle
    handle_color = (101, 67, 33, 255)
    draw.rectangle([28, 30, 36, 52], fill=handle_color, outline=OUTLINE)
    # Handle grip
    draw.line([28, 38, 36, 38], fill=(80, 50, 25, 255), width=1)
    draw.line([28, 44, 36, 44], fill=(80, 50, 25, 255), width=1)

    # Flame
    flame_yellow = (255, 220, 100, 255)
    flame_orange = (255, 140, 30, 255)
    flame_red = (200, 50, 30, 255)

    # Flame shape (triangle-ish)
    flame_pts = [(32, 28), (42, 38), (32, 34), (22, 38)]
    draw.polygon(flame_pts, fill=flame_orange, outline=OUTLINE)
    # Inner flame (yellow)
    inner_pts = [(28, 32), (36, 37), (32, 33), (26, 36)]
    draw.polygon(inner_pts, fill=flame_yellow)
    # Core (red tips)
    draw.polygon([(30, 33), (34, 36), (32, 34)], fill=flame_red)

    # Torch head/iron band
    draw.ellipse([26, 28, 38, 32], fill=(120, 120, 120, 255), outline=OUTLINE)

    return img


def gen_wolf_pelt():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (50, 40, 30, 240), 10)

    # Pelt colors (gray/brown wolf fur)
    fur_gray = (128, 128, 128, 255)
    fur_brown = (101, 67, 33, 255)
    fur_dark = (80, 50, 20, 255)

    # Pelt body (rounded rectangular shape)
    pelt_pts = [(16, 20), (48, 20), (52, 48), (48, 52), (16, 52), (12, 48)]
    draw.polygon(pelt_pts, fill=fur_gray, outline=OUTLINE)

    # Fur texture - draw individual fur tufts
    for x in range(18, 48, 6):
        for y in range(22, 50, 6):
            fur_c = fur_brown if (x + y) % 2 == 0 else fur_dark
            tuft = [(x, y), (x + 2, y - 4), (x + 4, y)]
            draw.polygon(tuft, fill=fur_c)

    # Inner lining
    draw.ellipse([26, 30, 38, 42], fill=(200, 200, 200, 255))

    return img


def gen_moss_essence():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (30, 50, 30, 240), 10)

    # Glowing green essence (like wisp_essence but green)
    glow_color = (80, 200, 80, 255)
    inner_color = (120, 255, 120, 255)
    core_color = (60, 150, 60, 255)

    # Outer glow (large soft circle)
    for radius in range(24, 6, -2):
        alpha = min(255, 100 - (24 - radius) * 15)
        glow = (80, 200, 80, alpha)
        r = 14 + (24 - radius)
        draw.ellipse([32 - r, 32 - r, 32 + r, 32 + r], fill=glow)

    # Core swirl
    draw.ellipse([24, 24, 40, 40], fill=glow_color, outline=OUTLINE)
    # Swirl details
    draw.arc([26, 26, 38, 38], 30, 200, fill=inner_color, width=2)
    draw.arc([28, 28, 42, 42], 0, 160, fill=inner_color, width=2)
    # Core
    draw.ellipse([28, 28, 36, 36], fill=core_color, outline=OUTLINE)

    return img


def gen_thorn():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (40, 50, 30, 240), 10)

    thorn_color = (34, 139, 34, 255)
    thorn_dark = (20, 80, 20, 255)
    stem_color = (100, 150, 80, 255)

    # Stem
    draw.rectangle([28, 20, 36, 50], fill=stem_color, outline=OUTLINE)

    # Thorns (pointing outward)
    thorns = [
        # Left thorns
        [(28, 24), (20, 22), (26, 30)],
        [(28, 32), (18, 30), (26, 38)],
        [(28, 40), (19, 38), (26, 46)],
        # Right thorns
        [(36, 24), (44, 22), (38, 30)],
        [(36, 32), (46, 30), (38, 38)],
        [(36, 40), (45, 38), (38, 46)],
    ]

    for thorn_pts in thorns:
        draw.polygon(thorn_pts, fill=thorn_color, outline=OUTLINE)
        # Highlight on each thorn
        mid_x = sum(p[0] for p in thorn_pts) / 3
        mid_y = sum(p[1] for p in thorn_pts) / 3
        tip_idx = 0 if thorn_pts[0][0] < thorn_pts[1][0] else 1
        draw.line([thorn_pts[tip_idx][0], thorn_pts[tip_idx][1], int(mid_x), int(mid_y)],
                  fill=thorn_dark, width=1)

    # Base where stem meets
    draw.ellipse([26, 48, 38, 52], fill=stem_color, outline=OUTLINE)

    return img


def gen_basic_attack():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (50, 40, 30, 240), 10)

    # Sword icon for basic attack
    blade_color = (180, 180, 190, 255)
    blade_dark = (140, 140, 150, 255)
    handle_color = (101, 67, 33, 255)

    # Blade (cross shape)
    draw.rectangle([26, 22, 38, 38], fill=blade_color, outline=OUTLINE)

    # Blade edge highlights
    draw.rectangle([28, 24, 30, 36], fill=blade_dark)
    draw.rectangle([32, 24, 34, 36], fill=blade_dark)

    # Cross guard
    draw.rectangle([24, 36, 40, 38], fill=handle_color, outline=OUTLINE)

    # Handle
    draw.rectangle([28, 38, 36, 50], fill=handle_color, outline=OUTLINE)
    # Pommel
    draw.ellipse([27, 49, 37, 55], fill=(80, 50, 25, 255), outline=OUTLINE)

    # Motion lines (attack indicator)
    draw.line([12, 20, 20, 20], fill=(120, 120, 130, 255), width=2)
    draw.line([44, 32, 52, 32], fill=(120, 120, 130, 255), width=2)

    return img


def gen_heal():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (30, 50, 50, 240), 10)  # Bluish background

    # Red cross on a heart/shield shape
    heart_color = (180, 30, 30, 255)
    cross_color = (255, 255, 255, 255)
    highlight = (200, 100, 100, 255)

    # Heart shape (two circles + triangle bottom)
    draw.ellipse([18, 20, 34, 36], fill=heart_color, outline=OUTLINE)
    draw.ellipse([30, 20, 46, 36], fill=heart_color, outline=OUTLINE)
    heart_bottom = [(14, 36), (48, 36), (32, 52)]
    draw.polygon(heart_bottom, fill=heart_color, outline=OUTLINE)

    # White cross in center
    draw.rectangle([28, 30, 36, 34], fill=cross_color, outline=OUTLINE)
    draw.rectangle([28, 36, 36, 44], fill=cross_color, outline=OUTLINE)

    # Sparkle particles around
    draw.ellipse([14, 16, 16, 18], fill=(200, 220, 255, 255))
    draw.ellipse([48, 14, 50, 16], fill=(200, 220, 255, 255))
    draw.ellipse([20, 50, 22, 52], fill=(200, 220, 255, 255))
    draw.ellipse([44, 50, 46, 52], fill=(200, 220, 255, 255))

    return img


def gen_fire_bolt():
    img = _new_canvas()
    draw = ImageDraw.Draw(img)
    _rounded_bg(img, (50, 30, 20, 240), 10)  # Warm background

    flame_orange = (255, 140, 30, 255)
    flame_yellow = (255, 220, 60, 255)
    flame_red = (200, 30, 30, 255)

    # Fire bolt - flame streak
    bolt_pts = [
        (20, 12),  # top left
        (44, 12),  # top right
        (40, 28),  # right curve
        (44, 30),  # tip
        (36, 28),  # inner
        (50, 34),  # tip extension
        (32, 40),  # bottom left
        (28, 26),  # inner bottom
        (22, 28),  # left curve
        (20, 18),  # back to start
    ]
    draw.polygon(bolt_pts, fill=flame_orange, outline=OUTLINE)

    # Inner flame (yellow)
    inner_pts = [
        (24, 16), (40, 16), (37, 28), (40, 30), (34, 28),
        (44, 32), (28, 38), (26, 26), (23, 28), (20, 20),
    ]
    draw.polygon(inner_pts, fill=flame_yellow)

    # Core (red tip)
    draw.polygon([(34, 28), (40, 32), (37, 29)], fill=flame_red)

    # Spark particles
    draw.ellipse([16, 10, 18, 12], fill=flame_yellow)
    draw.ellipse([50, 20, 52, 22], fill=flame_yellow)
    draw.ellipse([30, 48, 33, 51], fill=flame_red)
    draw.ellipse([20, 42, 23, 45], fill=flame_orange)

    return img


def main():
    os.makedirs(ICONS_DIR, exist_ok=True)

    generators = {
        "wooden_sword": gen_wooden_sword,
        "rope": gen_rope,
        "torch": gen_torch,
        "wolf_pelt": gen_wolf_pelt,
        "moss_essence": gen_moss_essence,
        "thorn": gen_thorn,
        "basic_attack": gen_basic_attack,
        "heal": gen_heal,
        "fire_bolt": gen_fire_bolt,
    }

    print("Generating 9 missing icon PNGs for Eclipse Realms...\n")
    for name, func in generators.items():
        img = func()
        output_path = os.path.join(ICONS_DIR, f"{name}.png")
        img.save(output_path)
        with open(output_path, 'rb') as f:
            md5 = hashlib.md5(f.read()).hexdigest()
        print(f"  Created: {name}.png (64x64, md5={md5})")

    print("\nAll 9 icons generated successfully.")


if __name__ == "__main__":
    main()
