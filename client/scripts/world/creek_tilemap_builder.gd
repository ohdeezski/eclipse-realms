extends Node
## CreekTilemapBuilder.gd - Populates the Silver Creek TileMap at runtime.
## River zone with water, bridge, riverbanks, fishing spots

## Tile atlas coordinates (matches creek_tileset.png layout - 32x32 tiles)
const T_GRASS_LIGHT  := Vector2i(0, 0)
const T_GRASS_DARK   := Vector2i(1, 0)
const T_DIRT         := Vector2i(2, 0)
const T_SAND         := Vector2i(3, 0)
const T_WATER_SHALLOW:= Vector2i(4, 0)
const T_WATER_DEEP   := Vector2i(5, 0)
const T_WATER_FLOW   := Vector2i(6, 0)
const T_ROCK         := Vector2i(7, 0)
const T_REEDS        := Vector2i(8, 0)
const T_LILY_PAD     := Vector2i(9, 0)
const T_BRIDGE_WOOD  := Vector2i(0, 1)
const T_BRIDGE_RAIL  := Vector2i(1, 1)
const T_BRIDGE_POST  := Vector2i(2, 1)
const T_FISHING_SPOT := Vector2i(3, 1)
const T_STEPPING_STONE:= Vector2i(4, 1)
const T_MOSS_ROCK    := Vector2i(5, 1)
const T_CATTLE       := Vector2i(6, 1)
const T_FALLEN_LOG   := Vector2i(7, 1)
const T_FERN         := Vector2i(8, 1)
const T_FLOWERS      := Vector2i(9, 1)

const COLS := 40
const ROWS := 30
const SOURCE_ID := 0

## Legend:
##  . = grass_light    g = grass_dark      d = dirt
##  s = sand           w = water_shallow   W = water_deep
##  f = water_flow     R = rock            r = reeds
##  l = lily_pad       B = bridge_wood     b = bridge_rail
##  p = bridge_post    F = fishing_spot    S = stepping_stone
##  M = moss_rock      c = cattail         L = fallen_log
##  e = fern           F = flowers

## Creek layout - 40 cols x 30 rows
## River flows horizontally through center (rows 12-17)
## Bridge at cols 18-21
const LAYOUT: Array[String] = [
	# 0123456789012345678901234567890123456789
	"gggggggggggggggggggggggggggggggggggggggg",  # 0  top grass
	"gggggggggggggggggggggggggggggggggggggggg",  # 1
	"gggggggggggggggggggggggggggggggggggggggg",  # 2
	"gggggggggggggggggggggggggggggggggggggggg",  # 3
	"gggggggggggggggggggggggggggggggggggggggg",  # 4
	"gggggggggggggggggggggggggggggggggggggggg",  # 5
	"gggggggggggggggggggggggggggggggggggggggg",  # 6
	"gggggggggggggggggggggggggggggggggggggggg",  # 7
	"gggggggggggggggggggggggggggggggggggggggg",  # 8
	"gggggggggggggggggggggggggggggggggggggggg",  # 9
	"gggggggggggggggggggggggggggggggggggggggg",  # 10
	"ggggggggggssssssssssssssssssgggggggggggg",  # 11  riverbank sand
	"ggggggggggWWWWWWWWWWWWWWWWWWgggggggggggg",  # 12  water deep
	"ggggggggggWWWWWWWWWWWWWWWWWWgggggggggggg",  # 13  water deep
	"ggggggggggWWWWWWWWWWWWWWWWWWgggggggggggg",  # 14  water deep
	"ggggggggggWWWWWWWWWWWWWWWWWWgggggggggggg",  # 15  water deep
	"ggggggggggWWWWWWWWWWWWWWWWWWgggggggggggg",  # 16  water deep
	"ggggggggggssssssssssssssssssgggggggggggg",  # 17  riverbank sand
	"gggggggggggggggggggggggggggggggggggggggg",  # 18  bottom grass
	"gggggggggggggggggggggggggggggggggggggggg",  # 19
	"gggggggggggggggggggggggggggggggggggggggg",  # 20
	"gggggggggggggggggggggggggggggggggggggggg",  # 21
	"gggggggggggggggggggggggggggggggggggggggg",  # 22
	"gggggggggggggggggggggggggggggggggggggggg",  # 23
	"gggggggggggggggggggggggggggggggggggggggg",  # 24
	"gggggggggggggggggggggggggggggggggggggggg",  # 25
	"gggggggggggggggggggggggggggggggggggggggg",  # 26
	"gggggggggggggggggggggggggggggggggggggggg",  # 27
	"gggggggggggggggggggggggggggggggggggggggg",  # 28
	"gggggggggggggggggggggggggggggggggggggggg",  # 29
]

## Character legend to atlas coords mapping
const CHAR_MAP: Dictionary = {
	".": T_GRASS_LIGHT,
	"g": T_GRASS_DARK,
	"d": T_DIRT,
	"s": T_SAND,
	"w": T_WATER_SHALLOW,
	"W": T_WATER_DEEP,
	"f": T_WATER_FLOW,
	"R": T_ROCK,
	"r": T_REEDS,
	"l": T_LILY_PAD,
	"B": T_BRIDGE_WOOD,
	"b": T_BRIDGE_RAIL,
	"p": T_BRIDGE_POST,
	"F": T_FISHING_SPOT,
	"S": T_STEPPING_STONE,
	"M": T_MOSS_ROCK,
	"c": T_CATTLE,
	"L": T_FALLEN_LOG,
	"e": T_FERN,
	"F": T_FLOWERS,
}


func build(tilemap: TileMap) -> void:
	if tilemap == null:
		push_error("[CreekTilemapBuilder] TileMap is null")
		return

	for row in range(ROWS):
		if row >= LAYOUT.size():
			break
		var line: String = LAYOUT[row]
		for col in range(min(line.length(), COLS)):
			var ch: String = line[col]
			if ch == " ":
				continue
			var atlas_coords: Vector2i = CHAR_MAP.get(ch, T_GRASS_DARK)
			tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, atlas_coords, 0)

	print("[CreekTilemapBuilder] Painted %d rows x %d cols tilemap" % [ROWS, COLS])


## Add bridge and river details after base build
func add_creek_details(tilemap: TileMap) -> void:
	if tilemap == null:
		return
	
	# Bridge at cols 18-21, rows 12-16 (spanning river)
	for row in range(12, 17):
		for col in range(18, 22):
			if col == 18 or col == 21:
				# Bridge posts
				tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_BRIDGE_POST, 0)
			elif row == 12 or row == 16:
				# Bridge rails
				tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_BRIDGE_RAIL, 0)
			else:
				# Bridge wood
				tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_BRIDGE_WOOD, 0)
	
	# Add reeds along riverbanks
	for row in [11, 17]:
		for col in range(10, 30):
			if tilemap.get_cell_atlas_coords(0, Vector2i(col, row), 0) == T_SAND:
				if randi() % 3 == 0:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_REEDS, 0)
	
	# Add lily pads in water
	for row in range(12, 17):
		for col in range(10, 30):
			if tilemap.get_cell_atlas_coords(0, Vector2i(col, row), 0) == T_WATER_DEEP:
				if randi() % 8 == 0:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_LILY_PAD, 0)
	
	# Add rocks in water
	for row in range(12, 17):
		for col in range(10, 30):
			if tilemap.get_cell_atlas_coords(0, Vector2i(col, row), 0) == T_WATER_DEEP:
				if randi() % 15 == 0:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_ROCK, 0)
	
	# Fishing spots at bridge ends
	tilemap.set_cell(0, Vector2i(17, 14), SOURCE_ID, T_FISHING_SPOT, 0)
	tilemap.set_cell(0, Vector2i(22, 14), SOURCE_ID, T_FISHING_SPOT, 0)
	
	# Stepping stones across river (alternative crossing)
	for i in range(5):
		var col = 5 + i * 6
		tilemap.set_cell(0, Vector2i(col, 14), SOURCE_ID, T_STEPPING_STONE, 0)
	
	print("[CreekTilemapBuilder] Added bridge, reeds, lily pads, rocks, fishing spots, stepping stones")