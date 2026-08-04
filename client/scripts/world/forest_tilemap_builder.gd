extends Node
## ForestTilemapBuilder.gd - Populates the Mosswood Forest TileMap at runtime.
## Forest layout: organic paths, tree clusters, clearings, monster spawn zones

## Tile atlas coordinates (matches forest_tileset.png layout - 32x32 tiles)
const T_GRASS_LIGHT  := Vector2i(0, 0)
const T_GRASS_DARK   := Vector2i(1, 0)
const T_GRASS_MOSS   := Vector2i(2, 0)
const T_PATH_DIRT    := Vector2i(3, 0)
const T_PATH_STONE   := Vector2i(4, 0)
const T_WATER_SHALLOW:= Vector2i(5, 0)
const T_WATER_DEEP   := Vector2i(6, 0)
const T_TREE_OAK     := Vector2i(7, 0)
const T_TREE_PINE    := Vector2i(8, 0)
const T_TREE_DEAD    := Vector2i(9, 0)
const T_BUSH         := Vector2i(0, 1)
const T_FLOWERS      := Vector2i(1, 1)
const T_MUSHROOM     := Vector2i(2, 1)
const T_ROCK         := Vector2i(3, 1)
const T_LOG          := Vector2i(4, 1)
const T_STUMP        := Vector2i(5, 1)
const T_CLEARING     := Vector2i(6, 1)
const T_FERN         := Vector2i(7, 1)
const T_ROOTS        := Vector2i(8, 1)
const T_CAVE_ENTRANCE:= Vector2i(9, 1)

const COLS := 64
const ROWS := 48
const SOURCE_ID := 0

## Legend:
##  . = grass_light    g = grass_dark      m = grass_moss
##  p = path_dirt      s = path_stone      w = water_shallow
##  W = water_deep     O = oak_tree        P = pine_tree
##  D = dead_tree      b = bush            f = flowers
##  M = mushroom       R = rock            L = log
##  T = stump          C = clearing        e = fern
##  r = roots          X = cave_entrance

## Forest layout - 64 cols x 48 rows
## Left side (cols 0-5) connects to Oakrest Village
## Right side (cols 58-63) connects to Whispering Caverns
const LAYOUT: Array[String] = [
	# 0123456789012345678901234567890123456789012345678901234567890123
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 0  dense canopy top
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 1
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 2
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 3
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 4  transition
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 5
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 6
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 7
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 8
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 9
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 10
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 11
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 12
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 13
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 14
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 15
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 16
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 17
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 18
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 19
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 20
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 21
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 22
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 23
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 24
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 25
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 26
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 27
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 28
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 29
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 30
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 31
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 32
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 33
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 34
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 35
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 36
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 37
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 38
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 39
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 40
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 41
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 42
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 43
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 44
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 45
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 46
	"OOOOggggggggggggggggggggggggggggggggggggggggggggggggggggggggOOOO",  # 47
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 48
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 49
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 50
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 51
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 52
	"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",  # 53
]

## Character legend to atlas coords mapping
const CHAR_MAP: Dictionary = {
	".": T_GRASS_LIGHT,
	"g": T_GRASS_DARK,
	"m": T_GRASS_MOSS,
	"p": T_PATH_DIRT,
	"s": T_PATH_STONE,
	"w": T_WATER_SHALLOW,
	"W": T_WATER_DEEP,
	"O": T_TREE_OAK,
	"P": T_TREE_PINE,
	"D": T_TREE_DEAD,
	"b": T_BUSH,
	"f": T_FLOWERS,
	"M": T_MUSHROOM,
	"R": T_ROCK,
	"L": T_LOG,
	"T": T_STUMP,
	"C": T_CLEARING,
	"e": T_FERN,
	"r": T_ROOTS,
	"X": T_CAVE_ENTRANCE,
}


func build(tilemap: TileMap) -> void:
	if tilemap == null:
		push_error("[ForestTilemapBuilder] TileMap is null")
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

	print("[ForestTilemapBuilder] Painted %d rows x %d cols tilemap" % [ROWS, COLS])


## Procedural detail layer - called after base build
func add_forest_details(tilemap: TileMap) -> void:
	if tilemap == null:
		return
	
	# Add random trees, bushes, details in grass areas
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for row in range(10, ROWS - 10):
		for col in range(10, COLS - 10):
			# Only decorate grass tiles
			var cell = tilemap.get_cell_atlas_coords(0, Vector2i(col, row), 0)
			if cell == T_GRASS_DARK or cell == T_GRASS_LIGHT or cell == T_GRASS_MOSS:
				var roll = rng.randi() % 100
				
				# Trees (sparse)
				if roll < 3:
					var tree_type = rng.randi() % 3
					if tree_type == 0:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_TREE_OAK, 0)
					elif tree_type == 1:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_TREE_PINE, 0)
					else:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_TREE_DEAD, 0)
				
				# Bushes
				elif roll < 8:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_BUSH, 0)
				
				# Flowers/mushrooms
				elif roll < 12:
					var detail = rng.randi() % 2
					if detail == 0:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_FLOWERS, 0)
					else:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_MUSHROOM, 0)
				
				# Rocks/logs/stumps
				elif roll < 15:
					var prop = rng.randi() % 4
					if prop == 0:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_ROCK, 0)
					elif prop == 1:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_LOG, 0)
					elif prop == 2:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_STUMP, 0)
					else:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_ROOTS, 0)
				
				# Ferns/roots
				elif roll < 18:
					var ground = rng.randi() % 2
					if ground == 0:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_FERN, 0)
					else:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_ROOTS, 0)