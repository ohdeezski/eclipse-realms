#!/usr/bin/env python3
"""Create sprites for Eclipse Realms — player character with proper walk cycle.

Style lock: 2.5D hybrid, cel-shaded, rim-light. 32x32 tiles, 4 frames per strip.
player_idle.png: 4 frames of idle (subtle breathing/bobbing)
player_walk.png: 4 frames of walk cycle (arms/legs alternate, NOT identical to idle)
"""

from PIL import Image, ImageDraw
import os
import hashlib

BASE_DIR = "/home/ssmartnycbase/Desktop/StreetSmartNYC-BusinessBase/Obsidian-Vault/game-projects-(to monetize)/project-eclipse-realms"
CLIENT_ASSETS = os.path.join(BASE_DIR, "client/assets")


def draw_player_frame(img, x_offset, frame_idx, is_walk=False):
    """Draw a single 32x32 player frame at x_offset.

    Idle frames: subtle bob, slight arm swing
    Walk frames: full walk cycle with leg/arm alternation
    """
    draw = ImageDraw.Draw(img)

    # Colors
    skin = (255, 218, 185, 255)      # Peach
    hair = (139, 69, 19, 255)        # Brown
    shirt = (70, 130, 180, 255)      # Steel blue
    pants = (47, 79, 79, 255)        # Dark slate gray
    outline = (0, 0, 0, 255)

    # Head position (subtle vertical bob for walk, static for idle)
    if is_walk:
        # Walk: bob up/down slightly per frame
        head_y_offset = [0, -1, 0, 1][frame_idx]
    else:
        # Idle: subtle breathing
        head_y_offset = [0, 0, 0, 0][frame_idx]

    head_x = x_offset + 4
    head_y = 2 + head_y_offset

    # --- HEAD ---
    draw.rectangle([head_x, head_y, head_x + 8, head_y + 8], fill=skin, outline=outline)
    # Hair
    draw.rectangle([head_x, head_y, head_x + 8, head_y + 3], fill=hair)
    # Eyes (slight variation for walk frames)
    eye_x_off = [0, 0, -1, 0][frame_idx] if is_walk else 0
    draw.point([head_x + 4 + eye_x_off, head_y + 4], fill=outline)
    draw.point([head_x + 8 + eye_x_off, head_y + 4], fill=outline)

    # Body (chest/shirt)
    body_y = head_y + 8
    draw.rectangle([x_offset + 3, body_y, x_offset + 13, body_y + 12], fill=shirt, outline=outline)

    # Arms — different position per frame for walk cycle
    if is_walk:
        # Frame-by-frame arm positions for walk cycle
        arm_data = [
            # Frame 0: arms center
            {'left': (1, body_y, 4, body_y + 10), 'right': (13, body_y, 16, body_y + 10)},
            # Frame 1: left arm back, right arm forward
            {'left': (0, body_y - 1, 3, body_y + 9), 'right': (14, body_y + 1, 17, body_y + 11)},
            # Frame 2: arms center (neutral)
            {'left': (1, body_y, 4, body_y + 10), 'right': (13, body_y, 16, body_y + 10)},
            # Frame 3: left arm forward, right arm back
            {'left': (2, body_y + 1, 5, body_y + 11), 'right': (12, body_y - 1, 15, body_y + 9)},
        ]
        # Legs — different position per frame
        leg_data = [
            # Frame 0: legs together
            {'left': (5, body_y + 12, 8, body_y + 16), 'right': (9, body_y + 12, 12, body_y + 16)},
            # Frame 1: left leg forward, right leg back
            {'left': (4, body_y + 12, 7, body_y + 16), 'right': (10, body_y + 12, 13, body_y + 16)},
            # Frame 2: legs together (neutral)
            {'left': (5, body_y + 12, 8, body_y + 16), 'right': (9, body_y + 12, 12, body_y + 16)},
            # Frame 3: left leg back, right leg forward
            {'left': (5, body_y + 12, 8, body_y + 16), 'right': (8, body_y + 12, 11, body_y + 16)},
        ]
    else:
        # Idle: static arms/legs, slight variation
        arm_data = [{
            'left': (1, body_y, 4, body_y + 10),
            'right': (13, body_y, 16, body_y + 10)
        }] * 4
        leg_data = [{
            'left': (5, body_y + 12, 8, body_y + 16),
            'right': (9, body_y + 12, 12, body_y + 16)
        }] * 4

    # Draw arms
    draw.rectangle([x_offset + arm_data[frame_idx]['left'][0], arm_data[frame_idx]['left'][1],
                    x_offset + arm_data[frame_idx]['left'][2], arm_data[frame_idx]['left'][3]],
                   fill=skin, outline=outline)
    draw.rectangle([x_offset + arm_data[frame_idx]['right'][0], arm_data[frame_idx]['right'][1],
                    x_offset + arm_data[frame_idx]['right'][2], arm_data[frame_idx]['right'][3]],
                   fill=skin, outline=outline)

    # Draw legs
    draw.rectangle([x_offset + leg_data[frame_idx]['left'][0], leg_data[frame_idx]['left'][1],
                    x_offset + leg_data[frame_idx]['left'][2], leg_data[frame_idx]['left'][3]],
                   fill=pants, outline=outline)
    draw.rectangle([x_offset + leg_data[frame_idx]['right'][0], leg_data[frame_idx]['right'][1],
                    x_offset + leg_data[frame_idx]['right'][2], leg_data[frame_idx]['right'][3]],
                   fill=pants, outline=outline)


def create_player_walk():
    """Create player_walk.png - 192x48, 4-frame walk cycle (48x48 tiles).

    Uses 48x48 frames centered in 48-wide slots for better detail.
    Frames are DISTINCT: legs alternate, arms counter-swing.
    """
    frame_w = 48
    frame_h = 48
    n_frames = 4
    img = Image.new('RGBA', (frame_w * n_frames, frame_h), (0, 0, 0, 0))

    skin = (255, 218, 185, 255)
    hair = (139, 69, 19, 255)
    shirt = (70, 130, 180, 255)
    pants = (47, 79, 79, 255)
    outline = (0, 0, 0, 255)

    # Each frame: body at different position with leg/arm alternation
    # Frame layout (48x48 sprite): head ~14x14, body ~16x18, arms/legs ~8 wide
    frames = [
        # Frame 0: standing, weight neutral
        {'bx': 16, 'by': 20, 'legs': (8, 38, 18, 48, 22, 38, 32, 48),
         'arms': (4, 18, 10, 36, 30, 18, 36, 36)},
        # Frame 1: left leg/arms forward
        {'bx': 16, 'by': 18, 'legs': (8, 36, 18, 48, 24, 38, 32, 48),
         'arms': (2, 16, 10, 34, 32, 20, 40, 38)},
        # Frame 2: standing, weight transfer
        {'bx': 16, 'by': 19, 'legs': (7, 37, 17, 48, 23, 38, 33, 48),
         'arms': (3, 17, 9, 35, 31, 19, 37, 37)},
        # Frame 3: right leg/arms forward
        {'bx': 16, 'by': 18, 'legs': (8, 38, 18, 48, 22, 36, 30, 46),
         'arms': (4, 18, 10, 36, 28, 16, 36, 34)},
    ]

    for fi, f in enumerate(frames):
        xo = fi * frame_w
        bx, by = f['bx'] + xo, f['by']

        # Head (14x14)
        hx, hy = xo + 16, 4
        draw = ImageDraw.Draw(img)
        draw.rectangle([hx, hy, hx + 14, hy + 14], fill=skin, outline=outline)
        draw.rectangle([hx, hy, hx + 14, hy + 4], fill=hair)
        draw.point([hx + 5, hy + 7], fill=outline)
        draw.point([hx + 11, hy + 7], fill=outline)

        # Body (16x18)
        draw.rectangle([xo + bx, by, xo + bx + 16, by + 18], fill=shirt, outline=outline)

        # Arms (x1,y1,x2,y2 for left and right, relative to frame)
        lx1, ly1, lx2, ly2 = f['arms'][0], f['arms'][1], f['arms'][2], f['arms'][3]
        rx1, ry1, rx2, ry2 = f['arms'][4], f['arms'][5], f['arms'][6], f['arms'][7]
        draw.rectangle([xo + lx1, ly1, xo + lx2, ly2], fill=skin, outline=outline)
        draw.rectangle([xo + rx1, ry1, xo + rx2, ry2], fill=skin, outline=outline)

        # Legs (x1,y1,x2,y2 for left and right)
        ll = f['legs']
        draw.rectangle([xo + ll[0], ll[1], xo + ll[2], ll[3]], fill=pants, outline=outline)
        draw.rectangle([xo + ll[4], ll[5], xo + ll[6], ll[7]], fill=pants, outline=outline)

    output_path = os.path.join(CLIENT_ASSETS, "characters/player/player_walk.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    with open(output_path, 'rb') as f:
        md5 = hashlib.md5(f.read()).hexdigest()
    print(f"Created: {output_path} (md5={md5})")


def create_player_idle():
    """Create player_idle.png - 192x48, 4-frame idle (48x48 tiles).

    Subtle breathing bob, minimal movement. md5 MUST differ from walk.
    """
    frame_w = 48
    frame_h = 48
    n_frames = 4
    img = Image.new('RGBA', (frame_w * n_frames, frame_h), (0, 0, 0, 0))

    skin = (255, 218, 185, 255)
    hair = (139, 69, 19, 255)
    shirt = (70, 130, 180, 255)
    pants = (47, 79, 79, 255)
    outline = (0, 0, 0, 255)

    # Idle frames: very subtle variations (breathing, slight weight shift)
    frames = [
        # Frame 0: neutral
        {'bx': 16, 'by': 20, 'bx2': 32, 'by2': 38, 'bx3': 24, 'by3': 38,
         'arms': (4, 20, 10, 38, 30, 20, 36, 38),
         'legs': (8, 38, 18, 48, 22, 38, 32, 48)},
        # Frame 1: slight inhale (body rises 1px, arms out 1px)
        {'bx': 16, 'by': 19, 'bx2': 32, 'by2': 37, 'bx3': 24, 'by3': 37,
         'arms': (3, 19, 9, 37, 31, 19, 37, 37),
         'legs': (8, 38, 18, 48, 22, 38, 32, 48)},
        # Frame 2: neutral (same as 0)
        {'bx': 16, 'by': 20, 'bx2': 32, 'by2': 38, 'bx3': 24, 'by3': 38,
         'arms': (4, 20, 10, 38, 30, 20, 36, 38),
         'legs': (8, 38, 18, 48, 22, 38, 32, 48)},
        # Frame 3: slight exhale (body drops 1px, arms in 1px)
        {'bx': 16, 'by': 21, 'bx2': 32, 'by2': 39, 'bx3': 24, 'by3': 39,
         'arms': (5, 21, 11, 39, 29, 21, 35, 39),
         'legs': (8, 38, 18, 48, 22, 38, 32, 48)},
    ]

    for fi, f in enumerate(frames):
        xo = fi * frame_w
        bx, by = f['bx'] + xo, f['by']
        draw = ImageDraw.Draw(img)

        # Head (14x14)
        hx, hy = xo + 16, 4
        draw.rectangle([hx, hy, hx + 14, hy + 14], fill=skin, outline=outline)
        draw.rectangle([hx, hy, hx + 14, hy + 4], fill=hair)
        draw.point([hx + 5, hy + 7], fill=outline)
        draw.point([hx + 11, hy + 7], fill=outline)

        # Body
        draw.rectangle([xo + f['bx'], f['by'], xo + f['bx'] + 16, f['by'] + 18],
                       fill=shirt, outline=outline)

        # Arms
        arms = f['arms']
        draw.rectangle([xo + arms[0], arms[1], xo + arms[2], arms[3]],
                       fill=skin, outline=outline)
        draw.rectangle([xo + arms[4], arms[5], xo + arms[6], arms[7]],
                       fill=skin, outline=outline)

        # Legs
        legs = f['legs']
        draw.rectangle([xo + legs[0], legs[1], xo + legs[2], legs[3]],
                       fill=pants, outline=outline)
        draw.rectangle([xo + legs[4], legs[5], xo + legs[6], legs[7]],
                       fill=pants, outline=outline)

    output_path = os.path.join(CLIENT_ASSETS, "characters/player/player_idle.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    with open(output_path, 'rb') as f:
        md5 = hashlib.md5(f.read()).hexdigest()
    print(f"Created: {output_path} (md5={md5})")


def create_hero_avatar():
    """Create hero_human_adept.png — 128x128 character portrait/avatar."""
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    skin = (255, 218, 185, 255)
    hair = (139, 69, 19, 255)
    shirt = (70, 130, 180, 255)
    pants = (47, 79, 79, 255)
    outline = (0, 0, 0, 255)

    # Center the figure, roughly 100x100 body area
    cx = 64

    # Head (24x30)
    hx, hy = cx - 12, 16
    draw.rectangle([hx, hy, hx + 24, hy + 30], fill=skin, outline=outline)
    # Hair
    draw.rectangle([hx, hy, hx + 24, hy + 8], fill=hair)
    # Eyes
    draw.point([hx + 6, hy + 12], fill=outline)
    draw.point([hx + 18, hy + 12], fill=outline)
    # Nose
    draw.line([hx + 12, hy + 16, hx + 12, hy + 20], fill=outline)
    # Mouth
    draw.arc([hx + 8, hy + 22, hx + 16, hy + 26], 0, 180, fill=outline)

    # Body (28x34)
    bx, by = cx - 14, hy + 30
    draw.rectangle([bx, by, bx + 28, by + 34], fill=shirt, outline=outline)
    # Shoulder details
    draw.line([bx, by, bx - 6, by + 8], fill=outline)
    draw.line([bx + 28, by, bx + 34, by + 8], fill=outline)

    # Arms
    draw.rectangle([bx - 8, by + 4, bx - 2, by + 30], fill=skin, outline=outline)
    draw.rectangle([bx + 30, by + 4, bx + 36, by + 30], fill=skin, outline=outline)

    # Legs
    draw.rectangle([bx + 4, by + 34, bx + 14, by + 58], fill=pants, outline=outline)
    draw.rectangle([bx + 16, by + 34, bx + 26, by + 58], fill=pants, outline=outline)

    output_path = os.path.join(CLIENT_ASSETS, "characters/player/hero_human_adept.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created: {output_path}")


if __name__ == "__main__":
    print("Creating player character sprites for Eclipse Realms...")
    print()

    create_player_idle()
    create_player_walk()
    create_hero_avatar()

    # Verify md5 difference
    import hashlib as hl
    with open(os.path.join(CLIENT_ASSETS, "characters/player/player_idle.png"), 'rb') as f:
        idle_md5 = hl.md5(f.read()).hexdigest()
    with open(os.path.join(CLIENT_ASSETS, "characters/player/player_walk.png"), 'rb') as f:
        walk_md5 = hl.md5(f.read()).hexdigest()

    print()
    if idle_md5 == walk_md5:
        print("ERROR: player_idle and player_walk have identical md5!")
    else:
        print(f"OK: player_idle ({idle_md5}) != player_walk ({walk_md5})")

    print()
    print("Created files:")
    print(f"  - {CLIENT_ASSETS}/characters/player/player_idle.png (192x48, 4 frames, 48x48 each)")
    print(f"  - {CLIENT_ASSETS}/characters/player/player_walk.png (192x48, 4 frames, 48x48 each)")
    print(f"  - {CLIENT_ASSETS}/characters/player/hero_human_adept.png (128x128 avatar)")
