extends Node
## VillageTilemapBuilder.gd - Populates the Oakrest Village TileMap at runtime.
##
## Attach this to a Node child of the TileMap (or call build(tilemap) directly).
## Reads a compact string-based layout and paints tiles + collision.

## Tile atlas coordinates (matches tileset.png layout)
const T_GRASS_LIGHT  := Vector2i(0, 0)
const T_GRASS_DARK   := Vector2i(1, 0)
const T_PATH         := Vector2i(2, 0)
const T_DIRT         := Vector2i(3, 0)
const T_STONE_FLOOR  := Vector2i(4, 0)
const T_WATER        := Vector2i(5, 0)
const T_TREE         := Vector2i(6, 0)
const T_BUILDING_WALL:= Vector2i(7, 0)
const T_FENCE        := Vector2i(8, 0)
const T_FLOWERS      := Vector2i(9, 0)
const T_DOOR         := Vector2i(0, 1)
const T_DARK_GRASS   := Vector2i(1, 1)
const T_STONE_PATH   := Vector2i(2, 1)
const T_ROOF         := Vector2i(3, 1)
const T_WELL         := Vector2i(4, 1)
const T_SIGN_POST    := Vector2i(5, 1)

const COLS := 40
const ROWS := 23
const SOURCE_ID := 0

## Legend:
##  . = grass_light    g = grass_dark      p = path
##  d = dirt           s = stone_floor     w = water
##  T = tree           B = building_wall   F = fence
##  f = flowers        D = door            G = dark_grass
##  S = stone_path     R = roof            W = well
##  L = sign_post      ~ = water_deep

## Village layout - 40 columns x 23 rows
## Right side (cols 32-39) is the Forest zone transition
const LAYOUT: Array[String] = [
	#0123456789012345678901234567890123456789
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFTTTTTTTT",  # 0  top fence + forest trees
	"FggggggggggggggggggggggggggggTTTTTTTTTT",  # 1  fence + forest
	"FggRRRRRggRRRRRgggBBBgggggTTTTTTTTTTTT",  # 2  building roofs + forest
	"FggBBBBBggBBBBBgggBBBgggggTTTTTTTTTTTT",  # 3  building walls
	"FggBDBBBggBDBBBgggBDBgggggTTGTTTTGTTTT",  # 4  building doors
	"FggppppppppppppppppppppppppppGTTTTGTTTT",  # 5  path row
	"FggppppppppppppppppppppppppppGGGGGGGGGT",  # 6  path row
	"FggSSSSSSSSSSSSSSSSSSSSSSSSSGGGGGGGGGT",  # 7  stone village square
	"FggSSSSSSSSSSSSSSSSSSSSSSSSSGGGGGGGGGT",  # 8  stone village square
	"FggppppppppppppppppppppppppppGGGGGGGGGT",  # 9  path row
	"FggdddddddddddppppppppppppppGGGGGGGGGT",  # 10 training grounds + path
	"FggdddddddddddppppppppppppppGGGGGGGGGT",  # 11 training grounds
	"FggdddddddddddppppppppppppppGGGGGGGGGT",  # 12 training grounds
	"FgggfffgggfffgggppppppppppppGGGGGGGGGT",  # 13 flowers + path
	"FgggggggggggggggppppppppppppGGGGGGGGGT",  # 14 open grass
	"FggfffgggLggfffggpppppppppppGGGGGGGGGT",  # 15 sign post
	"FgggggggggggggggppppppppppppGGGGGGGGGT",  # 16 open grass
	"FggfffggggggfffgppppppppWpppGGGGGGGGGT",  # 17 flowers + well
	"FgggggggggggggggppppppppppppGGGGGGGGGT",  # 18 open grass
	"FggfffgggfffggggppppppppppppGGGGGGGGGT",  # 19 flowers
	"FgggggggggggggggppppppppppppGGGGGGGGGT",  # 20 open grass
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFGGGGGGGGGT",  # 21 fence + forest
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFGGGGGGGGGT",  # 22 bottom fence + forest
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
	"B": T_BUILDING_WALL,
	"F": T_FENCE,
	"f": T_FLOWERS,
	"D": T_DOOR,
	"G": T_DARK_GRASS,
	"S": T_STONE_PATH,
	"R": T_ROOF,
	"W": T_WELL,
	"L": T_SIGN_POST,
	"~": T_WATER,
}


func build(tilemap: TileMap) -> void:
	if tilemap == null:
		push_error("[VillageTilemapBuilder] TileMap is null")
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

	print("[VillageTilemapBuilder] Painted %d rows x %d cols tilemap" % [ROWS, COLS])
