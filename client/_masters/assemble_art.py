#!/usr/bin/env python3
"""Assemble Eclipse Realms HUD sheet + portraits from in-style _masters (no style drift).
Style lock: 2.5D hybrid, cel-shaded, rim-light. Derived from Mio-generated masters."""
import os
from PIL import Image

CLIENT = os.path.dirname(os.path.abspath(__file__))  # .../client/_masters
ROOT = os.path.dirname(CLIENT)  # .../client
MASTERS = CLIENT  # _masters is this dir
ASSETS_UI = os.path.join(ROOT, "assets", "ui")
ASSETS_PORTRAITS = os.path.join(ROOT, "assets", "characters", "portraits")

TILE = 32
PORTRAIT = 96

def center_crop(im, size):
    im = im.convert("RGBA")
    w, h = im.size
    s = min(w, h)
    left = (w - s) // 2
    top = (h - s) // 2
    im = im.crop((left, top, left + s, top + s))
    return im.resize((size, size), Image.LANCZOS)

# --- HUD sheet: 8 tiles x 32 = 256x32 (matches engine ui_icons.png) ---
# equip icons 6 + status 2 (health=red, mana=blue)
hud_order = ["icon_sword", "icon_leather", "icon_chainmail", "icon_amulet",
             "icon_health", "icon_mana", "icon_antidote", "icon_quest"]
sheet = Image.new("RGBA", (TILE * len(hud_order), TILE), (0, 0, 0, 0))
for i, name in enumerate(hud_order):
    p = os.path.join(MASTERS, name + ".png")
    if os.path.exists(p):
        tile = center_crop(Image.open(p), TILE)
        sheet.paste(tile, (i * TILE, 0), tile)
os.makedirs(ASSETS_UI, exist_ok=True)
sheet.save(os.path.join(ASSETS_UI, "ui_icons.png"))
print("HUD sheet ->", sheet.size)

# --- Portraits: 5 NPCs + hero (96x96) ---
portrait_order = ["hero", "elder", "blacksmith", "ranger", "merchant", "innkeeper"]
os.makedirs(ASSETS_PORTRAITS, exist_ok=True)
for name in portrait_order:
    p = os.path.join(MASTERS, name + ".png")
    if os.path.exists(p):
        por = center_crop(Image.open(p), PORTRAIT)
        out = os.path.join(ASSETS_PORTRAITS, "por_" + name + ".png")
        por.save(out)
        print("portrait ->", out, por.size)
print("DONE")
