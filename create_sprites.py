#!/usr/bin/env python3
"""Create placeholder sprites for Eclipse Realms."""

from PIL import Image, ImageDraw
import os

# Base directories
BASE_DIR = "/home/ssmartnycbase/Desktop/StreetSmartNYC-BusinessBase/Obsidian-Vault/game-projects-(to monetize)/project-eclipse-realms"
CLIENT_ASSETS = os.path.join(BASE_DIR, "client/assets")

def create_player_idle():
    """Create player_idle.png - 32x32 with 4-frame walk cycle (128x32 total)."""
    # Create a 128x32 image for 4 frames side by side
    img = Image.new('RGBA', (128, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    skin = (255, 218, 185, 255)      # Peach
    hair = (139, 69, 19, 255)        # Brown
    shirt = (70, 130, 180, 255)      # Steel blue
    pants = (47, 79, 79, 255)        # Dark slate gray
    outline = (0, 0, 0, 255)
    
    # 4-frame walk cycle positions
    frame_positions = [
        # Frame 0: idle/standing
        {
            'head': (4, 2, 12, 10),
            'body': (3, 10, 13, 22),
            'left_arm': (1, 10, 4, 20),
            'right_arm': (13, 10, 16, 20),
            'left_leg': (5, 22, 8, 28),
            'right_leg': (9, 22, 12, 28),
        },
        # Frame 1: left leg forward
        {
            'head': (4, 2, 12, 10),
            'body': (3, 10, 13, 22),
            'left_arm': (1, 10, 4, 20),
            'right_arm': (13, 10, 16, 20),
            'left_leg': (4, 22, 7, 28),
            'right_leg': (10, 22, 13, 28),
        },
        # Frame 2: idle/standing (mirror)
        {
            'head': (4, 2, 12, 10),
            'body': (3, 10, 13, 22),
            'left_arm': (1, 10, 4, 20),
            'right_arm': (13, 10, 16, 20),
            'left_leg': (5, 22, 8, 28),
            'right_leg': (9, 22, 12, 28),
        },
        # Frame 3: right leg forward
        {
            'head': (4, 2, 12, 10),
            'body': (3, 10, 13, 22),
            'left_arm': (1, 10, 4, 20),
            'right_arm': (13, 10, 16, 20),
            'left_leg': (5, 22, 8, 28),
            'right_leg': (9, 22, 12, 28),
        },
    ]
    
    for frame_idx, pos in enumerate(frame_positions):
        x_offset = frame_idx * 32
        
        # Head
        draw.rectangle([x_offset + pos['head'][0], pos['head'][1], 
                       x_offset + pos['head'][2], pos['head'][3]], fill=skin, outline=outline)
        # Hair
        draw.rectangle([x_offset + pos['head'][0], pos['head'][1], 
                       x_offset + pos['head'][2], pos['head'][1] + 3], fill=hair)
        # Eyes
        draw.point([x_offset + 6, 5], fill=outline)
        draw.point([x_offset + 10, 5], fill=outline)
        
        # Body
        draw.rectangle([x_offset + pos['body'][0], pos['body'][1], 
                       x_offset + pos['body'][2], pos['body'][3]], fill=shirt, outline=outline)
        
        # Arms
        draw.rectangle([x_offset + pos['left_arm'][0], pos['left_arm'][1], 
                       x_offset + pos['left_arm'][2], pos['left_arm'][3]], fill=skin, outline=outline)
        draw.rectangle([x_offset + pos['right_arm'][0], pos['right_arm'][1], 
                       x_offset + pos['right_arm'][2], pos['right_arm'][3]], fill=skin, outline=outline)
        
        # Legs
        draw.rectangle([x_offset + pos['left_leg'][0], pos['left_leg'][1], 
                       x_offset + pos['left_leg'][2], pos['left_leg'][3]], fill=pants, outline=outline)
        draw.rectangle([x_offset + pos['right_leg'][0], pos['right_leg'][1], 
                       x_offset + pos['right_leg'][2], pos['right_leg'][3]], fill=pants, outline=outline)
    
    # Save
    output_path = os.path.join(CLIENT_ASSETS, "characters/player/player_idle.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created: {output_path}")


def create_npc_villager():
    """Create npc_villager.png - 32x32."""
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors - villager look (apron, different colors)
    skin = (255, 218, 185, 255)
    hair = (160, 82, 45, 255)        # Sienna
    apron = (178, 34, 34, 255)       # Firebrick
    shirt = (210, 180, 140, 255)     # Tan
    pants = (101, 67, 33, 255)       # Dark brown
    outline = (0, 0, 0, 255)
    
    # Head
    draw.rectangle([8, 2, 24, 14], fill=skin, outline=outline)
    draw.rectangle([8, 2, 24, 6], fill=hair)
    draw.point([12, 5], fill=outline)
    draw.point([20, 5], fill=outline)
    
    # Body (apron)
    draw.rectangle([6, 14, 26, 26], fill=apron, outline=outline)
    # Shirt visible at neck
    draw.rectangle([10, 14, 22, 16], fill=shirt)
    
    # Arms
    draw.rectangle([3, 14, 7, 24], fill=skin, outline=outline)
    draw.rectangle([25, 14, 29, 24], fill=skin, outline=outline)
    
    # Legs
    draw.rectangle([9, 26, 14, 31], fill=pants, outline=outline)
    draw.rectangle([18, 26, 23, 31], fill=pants, outline=outline)
    
    output_path = os.path.join(CLIENT_ASSETS, "npcs/npc_villager.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created: {output_path}")


def create_monster_slime():
    """Create monster_slime.png - 28x28."""
    img = Image.new('RGBA', (28, 28), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Slime colors
    slime_body = (50, 205, 50, 255)    # Lime green
    slime_dark = (34, 139, 34, 255)    # Forest green
    slime_light = (144, 238, 144, 255) # Light green
    outline = (0, 100, 0, 255)
    
    # Main slime body (rounded blob)
    # Draw as overlapping circles/ellipses for organic look
    draw.ellipse([4, 6, 24, 26], fill=slime_body, outline=outline)
    draw.ellipse([6, 4, 22, 20], fill=slime_body, outline=outline)
    draw.ellipse([8, 8, 20, 22], fill=slime_light)
    
    # Eyes
    draw.ellipse([10, 10, 13, 13], fill=(0, 0, 0, 255))
    draw.ellipse([15, 10, 18, 13], fill=(0, 0, 0, 255))
    # Eye highlights
    draw.point([11, 11], fill=(255, 255, 255, 255))
    draw.point([16, 11], fill=(255, 255, 255, 255))
    
    # Mouth (simple curve)
    draw.arc([11, 15, 17, 19], 0, 180, fill=(0, 0, 0, 255))
    
    # Highlight/bubble
    draw.ellipse([16, 6, 19, 9], fill=(144, 238, 144, 180))
    
    output_path = os.path.join(CLIENT_ASSETS, "monsters/monster_slime.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created: {output_path}")


def create_tileset_oakrest():
    """Create tileset_oakrest.png - 16 tiles at 32x32 (arranged 4x4 = 128x128)."""
    img = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Tile definitions (4x4 grid)
    tiles = [
        # Row 0: Ground tiles
        ("grass", (34, 139, 34)),      # Grass
        ("dirt", (139, 69, 19)),       # Dirt
        ("stone", (128, 128, 128)),    # Stone
        ("path", (210, 180, 140)),     # Dirt path
        
        # Row 1: Water/transition
        ("water", (30, 144, 255)),     # Water
        ("water_shore", (34, 139, 34)), # Grass-water transition
        ("sand", (237, 201, 175)),     # Sand
        ("gravel", (169, 169, 169)),   # Gravel
        
        # Row 2: Objects/structures
        ("tree_trunk", (101, 67, 33)),  # Tree trunk
        ("tree_leaves", (34, 139, 34)), # Tree leaves
        ("bush", (0, 100, 0)),          # Bush
        ("flower", (255, 105, 180)),    # Flower patch
        
        # Row 3: Buildings/man-made
        ("wood_floor", (139, 90, 43)),   # Wood floor
        ("wood_wall", (160, 82, 45)),    # Wood wall
        ("roof", (178, 34, 34)),         # Red roof
        ("cobblestone", (105, 105, 105)), # Cobblestone
    ]
    
    for idx, (name, color) in enumerate(tiles):
        tx = (idx % 4) * 32
        ty = (idx // 4) * 32
        
        # Base tile
        draw.rectangle([tx, ty, tx + 32, ty + 32], fill=color, outline=(0, 0, 0, 255))
        
        # Add pattern details based on tile type
        if "grass" in name:
            # Grass blades
            for i in range(5):
                bx = tx + 4 + i * 6
                by = ty + 4 + (i % 2) * 10
                draw.line([bx, by + 8, bx, by], fill=(0, 100, 0, 255), width=1)
        elif "water" in name:
            # Water waves
            for i in range(3):
                draw.arc([tx + 4 + i * 10, ty + 8 + i * 6, tx + 14 + i * 10, ty + 18 + i * 6], 
                        0, 180, fill=(0, 100, 200, 255), width=1)
        elif "tree" in name:
            if "trunk" in name:
                draw.rectangle([tx + 10, ty + 16, tx + 22, ty + 32], fill=(80, 50, 20, 255))
            else:
                draw.ellipse([tx + 4, ty + 2, tx + 28, ty + 26], fill=(0, 100, 0, 255))
        elif "bush" in name:
            draw.ellipse([tx + 4, ty + 8, tx + 28, ty + 28], fill=(0, 80, 0, 255))
        elif "flower" in name:
            # Small flowers
            for fx, fy in [(tx+6, ty+8), (tx+18, ty+6), (tx+10, ty+20), (tx+22, ty+18)]:
                draw.ellipse([fx, fy, fx+4, fy+4], fill=(255, 105, 180, 255))
        elif "wood" in name:
            # Wood grain lines
            for i in range(3):
                draw.line([tx, ty + 8 + i * 8, tx + 32, ty + 8 + i * 8], 
                         fill=(100, 60, 20, 255), width=1)
        elif "roof" in name:
            # Roof tiles pattern
            for i in range(4):
                for j in range(4):
                    if (i + j) % 2 == 0:
                        draw.rectangle([tx + i * 8, ty + j * 8, tx + (i+1) * 8, ty + (j+1) * 8], 
                                      fill=(139, 0, 0, 255))
        elif "cobblestone" in name:
            # Cobblestone pattern
            for i in range(4):
                for j in range(4):
                    draw.rectangle([tx + i * 8, ty + j * 8, tx + (i+1) * 8 - 1, ty + (j+1) * 8 - 1], 
                                  fill=(105 - i*5, 105 - j*5, 105 - (i+j)*3, 255),
                                  outline=(80, 80, 80, 255))
    
    output_path = os.path.join(CLIENT_ASSETS, "environment/oakrest_village/tileset_oakrest.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created: {output_path}")


def create_ui_icons():
    """Create ui_icons.png - 16x16 icons for sword/shield/potion/coin (64x16 total)."""
    img = Image.new('RGBA', (64, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    icons = [
        # Sword (0-15)
        {
            'name': 'sword',
            'draw': lambda d, x: [
                # Blade
                d.line([x + 7, 2, x + 7, 12], fill=(192, 192, 192, 255), width=2),
                d.line([x + 6, 3, x + 8, 3], fill=(220, 220, 220, 255), width=1),
                d.line([x + 6, 4, x + 8, 4], fill=(200, 200, 200, 255), width=1),
                d.line([x + 6, 10, x + 8, 10], fill=(160, 160, 160, 255), width=1),
                # Crossguard
                d.line([x + 4, 12, x + 10, 12], fill=(139, 69, 19, 255), width=2),
                # Handle
                d.line([x + 7, 12, x + 7, 15], fill=(101, 67, 33, 255), width=2),
                # Pommel
                d.ellipse([x + 5, 14, x + 9, 16], fill=(160, 160, 160, 255)),
            ]
        },
        # Shield (16-31)
        {
            'name': 'shield',
            'draw': lambda d, x: [
                # Shield shape
                d.polygon([(x + 8, 2), (x + 14, 5), (x + 14, 11), (x + 8, 14), (x + 2, 11), (x + 2, 5)], 
                         fill=(70, 130, 180, 255), outline=(25, 25, 112, 255)),
                # Center boss
                d.ellipse([x + 6, 6, x + 10, 10], fill=(100, 149, 237, 255)),
                # Border accent
                d.polygon([(x + 8, 3), (x + 13, 6), (x + 13, 10), (x + 8, 13), (x + 3, 10), (x + 3, 6)], 
                         outline=(135, 206, 250, 255)),
            ]
        },
        # Potion (32-47)
        {
            'name': 'potion',
            'draw': lambda d, x: [
                # Bottle neck
                d.rectangle([x + 6, 2, x + 10, 6], fill=(100, 100, 100, 255), outline=(50, 50, 50, 255)),
                # Cork
                d.rectangle([x + 5, 1, x + 11, 3], fill=(139, 69, 19, 255), outline=(100, 50, 20, 255)),
                # Bottle body
                d.polygon([(x + 4, 6), (x + 12, 6), (x + 11, 14), (x + 5, 14)], 
                         fill=(255, 0, 100, 255), outline=(139, 0, 50, 255)),
                # Liquid highlight
                d.polygon([(x + 5, 7), (x + 10, 7), (x + 9, 13), (x + 6, 13)], 
                         fill=(255, 100, 150, 180)),
                # Bubbles
                d.ellipse([x + 7, 9, x + 8, 10], fill=(255, 255, 255, 200)),
                d.ellipse([x + 9, 11, x + 10, 12], fill=(255, 255, 255, 150)),
            ]
        },
        # Coin (48-63)
        {
            'name': 'coin',
            'draw': lambda d, x: [
                # Coin circle
                d.ellipse([x + 2, 2, x + 14, 14], fill=(255, 215, 0, 255), outline=(218, 165, 32, 255)),
                # Inner circle
                d.ellipse([x + 4, 4, x + 12, 12], fill=(255, 225, 50, 255)),
                # $ symbol
                d.line([x + 8, 5, x + 8, 11], fill=(180, 140, 0, 255), width=2),
                d.line([x + 5, 7, x + 11, 7], fill=(180, 140, 0, 255), width=1),
                d.line([x + 5, 9, x + 11, 9], fill=(180, 140, 0, 255), width=1),
                # Highlight
                d.ellipse([x + 4, 4, x + 7, 7], fill=(255, 255, 200, 100)),
            ]
        },
    ]
    
    for idx, icon in enumerate(icons):
        x_offset = idx * 16
        for draw_func in icon['draw'](draw, x_offset):
            pass  # Functions execute immediately
    
    output_path = os.path.join(CLIENT_ASSETS, "ui/ui_icons.png")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created: {output_path}")


if __name__ == "__main__":
    print("Creating placeholder sprites for Eclipse Realms...")
    print()
    
    create_player_idle()
    create_npc_villager()
    create_monster_slime()
    create_tileset_oakrest()
    create_ui_icons()
    
    print()
    print("All sprites created successfully!")
    print()
    print("Created files:")
    print(f"  - {CLIENT_ASSETS}/characters/player/player_idle.png (128x32, 4 frames)")
    print(f"  - {CLIENT_ASSETS}/npcs/npc_villager.png (32x32)")
    print(f"  - {CLIENT_ASSETS}/monsters/monster_slime.png (28x28)")
    print(f"  - {CLIENT_ASSETS}/environment/oakrest_village/tileset_oakrest.png (128x128, 16 tiles)")
    print(f"  - {CLIENT_ASSETS}/ui/ui_icons.png (64x16, 4 icons)")