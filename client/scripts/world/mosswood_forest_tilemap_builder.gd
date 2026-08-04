extends Node
## MosswoodForestTilemapBuilder.gd - Populates the Mosswood Forest TileMap at runtime.
##
## Attach this to a Node child of the TileMap (or call build(tilemap) directly).
## Reads a compact string-based layout and paints tiles + collision.

## Tile atlas coordinates (matches forest_tileset.png layout)
## Uses same tileset as village but with different layout
const T_GRASS_LIGHT  := Vector2i(0, 0)
const T_GRASS_DARK   := Vector2i(1, 0)
const T_PATH         := Vector2i(2, 0)
const T_DIRT         := Vector2i(3, 0)
const T_STONE_FLOOR  := Vector2i(4, 0)
const T_WATER        := Vector2i(5, 0)
const T_TREE         := Vector2i(6, 0)
const T_TREE_DARK    := Vector2i(7, 0)
const T_TREE_THIN    := Vector2i(8, 0)
const T_FENCE        := Vector2i(9, 0)
const T_ROCK         := Vector2i(0, 1)
const T_ROCK_LARGE   := Vector2i(1, 1)
const T_MUSHROOM     := Vector2i(2, 1)
const T_LOG          := Vector2i(3, 1)
const T_STUMP        := Vector2i(4, 1)
const T_BUSH         := Vector2i(5, 1)
const T_FLOWERS      := Vector2i(6, 1)
const T_SIGN_POST    := Vector2i(7, 1)
const T_CAMPFIRE     := Vector2i(8, 1)
const T_CHEST        := Vector2i(9, 1)

const COLS := 40
const ROWS := 28
const SOURCE_ID := 0

## Legend:
##  . = grass_light    g = grass_dark      p = path
##  d = dirt           s = stone_floor     w = water
##  T = tree           t = tree_dark       H = tree_thin
##  F = fence          R = rock            L = rock_large
##  m = mushroom       o = log             S = stump
##  B = bush           f = flowers         P = sign_post
##  C = campfire       X = chest           G = dark_grass
##  ~ = water_deep     P = portal (left side)

## Mosswood Forest layout - 40 columns x 28 rows
## Left side (cols 0-7) is the transition from Oakrest Village
## Right side has deeper forest with more enemies
const LAYOUT: Array[String] = [
	#0123456789012345678901234567890123456789
	"TTTgGGGgTTTTTTTTgGGGGgTTTTTTTTTTTTTTTTT",  # 0  Dense tree canopy
	"TTgggGGgTgTTTTTgGggGGggTTTTTTTTTTTTTTT",  # 1  Forest edge
	"THgggggGgTTTTTggggggGGgTTTTTTTTTTTTTTT",  # 2  Forest interior
	"HTgRRggggTTTgggggggggggTTTTTTTTTTTTTTT",  # 3  Rocky area
	"TggRRRggggggggggggmmbbTTTTTTTTTTTTTTTT",  # 4  Rocky area + mushrooms
	"TgggGGgggppppppppppppppggGGGGTTTTTTTTT",  # 5  Main path begins
	"TTgGGGggppppppppppppppggggGGGGGGTTTTTT",  # 6  Path through forest
	"TTTgggGgppfffgggfffggggggGgggGGGGTTTTT",  # 7  Path + flowers
	"TTTTgggpfggRRRgggfggggmggGgggGGgGTTTT",  # 8  Path + rocks
	"TTTTTggppggRRRRRgggggggggGgggGGggGTTTT",  # 9  Path near rocks
	"TTTTTggppgggRRRgggppppppppgggGggggGTTT",  # 10 Path junction
	"TTTTTggppgggggggggppppppppgggggggggGTT",  # 11 Path continues
	"TTTTTggppffggggfffgppgggggGgggggggGGTT",  # 12 Path + flowers
	"TTTTggppggggmmbbfggppgggggGGggggggGGTT",  # 13 Mushrooms + bush
	"TTTgggppggggBmmmmbbgppgggGGGgggggGGGTT",  # 14 Dense mushrooms area
	"TTTgggppggggBBmmmBBggppggGGGgggGGGGGTT",  # 15 Mushroom grove
	"TTTgggppffggBBBmmBffgppggGGGggGGGGGgTT",  # 16 Mushroom grove + flowers
	"TTTgggppggggBBmmBBgggppppgggGGGGGGggTT",  # 17 Path through grove
	"TTTgggppgggggBBBBggggppppggGGGGGGgggTT",  # 18 Path continues
	"TTTTggppRRgggggggggggppCCpgGGGGggggGTT",  # 19 Campfire area
	"TTTTggppRRRgggoggggggppCCpgGGGGgggGGTT",  # 20 Campfire + log
	"TTTTggppRRRgggSSSggggppggpgGGGGGgGGGTT",  # 21 Stumps area
	"TTTTggppppggggSSSSSggppggggGGGGGGGGGTT",  # 22 Path to deeper forest
	"TTTTTggppggggggSSSggppfffggGGGGGGGGgTT",  # 23 Stumps + flowers
	"TTTTTggppXXgggggggggppgggggGGGGGGGgGTT",  # 24 Chest location
	"TTTTTggppppgggggggggppgggGggGGGGGGgGTT",  # 25 Path continues
	"TTTTTTggpppPPgggggggppppppggGGGGGGgGTT",  # 26 Sign post
	"TTTTTTTgppPPgggggggggpppppgGGGGGGgGGTT",  # 27 Path to cave (future)
]

## Character legend to atlas coords mapping
const CHAR_MAP: Dictionary = {
	".": T_GRASS_LIGHT,
	"g": T_GRASS_DARK,
	"p": T_PATH,
	"d": T_DIRT,
	"s": T_STONE_FLOOR,
	"w": T_WATER,
	"T": T_TREE,
	"t": T_TREE_DARK,
	"H": T_TREE_THIN,
	"F": T_FENCE,
	"R": T_ROCK,
	"L": T_ROCK_LARGE,
	"m": T_MUSHROOM,
	"o": T_LOG,
	"S": T_STUMP,
	"B": T_BUSH,
	"f": T_FLOWERS,
	"P": T_SIGN_POST,
	"C": T_CAMPFIRE,
	"X": T_CHEST,
	"G": T_GRASS_DARK,  # Alias for dense forest
	"~": T_WATER,
}


func build(tilemap: TileMap) -> void:
	if tilemap == null:
		push_error("[MosswoodForestTilemapBuilder] TileMap is null")
		return

	for row in range(ROWS):
		if row >= LAYOUT.size():
			break
		var line: String = LAYOUT[row]
		for col in range(min(line.length(), COLS)):
			var ch: String = line[col]
			if ch == " ":
				continue
			var atlas_coords: Vector2i = CHAR_MAP.get(ch, T_GRASS_LIGHT)
			tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, atlas_coords, 0)

	# Set collision for solid tiles (trees, rocks, stumps, bushes)
	_set_collisions(tilemap)

	print("[MosswoodForestTilemapBuilder] Painted %d rows x %d cols tilemap" % [ROWS, COLS])


func _set_collisions(tilemap: TileMap) -> void:
	"""Set collision polygons for solid tiles"""
	for row in range(ROWS):
		if row >= LAYOUT.size():
			break
		var line: String = LAYOUT[row]
		for col in range(min(line.length(), COLS)):
			var ch: String = line[col]
			# Solid tiles get collision
			if ch in ["T", "t", "H", "L", "o", "S", "B"]:
				# Collision is handled by the TileSet itself
				# Just ensure the tile has physics layer set up
				pass
