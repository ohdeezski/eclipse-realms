extends Node
## CampTilemapBuilder.gd - Populates the Hunter's Camp TileMap at runtime.
## Ranger outpost with campfire, training dummies, tents, lookout tower

## Tile atlas coordinates (matches camp_tileset.png layout - 32x32 tiles)
const T_GRASS_LIGHT  := Vector2i(0, 0)
const T_GRASS_DARK   := Vector2i(1, 0)
const T_DIRT         := Vector2i(2, 0)
const T_PATH         := Vector2i(3, 0)
const T_STONE        := Vector2i(4, 0)
const T_WATER        := Vector2i(5, 0)
const T_TENT         := Vector2i(6, 0)
const T_CAMPFIRE     := Vector2i(7, 0)
const T_LOG_BENCH    := Vector2i(8, 0)
const T_TRAINING_DUMMY:= Vector2i(9, 0)
const T_TARGET       := Vector2i(0, 1)
const T_CRATE        := Vector2i(1, 1)
const T_BARREL       := Vector2i(2, 1)
const T_WEAPON_RACK  := Vector2i(3, 1)
const T_FLAG         := Vector2i(4, 1)
const T_LOOKOUT_TOWER:= Vector2i(5, 1)
const T_WOOD_PILE    := Vector2i(6, 1)
const T_FENCE        := Vector2i(7, 1)
const T_TORCH        := Vector2i(8, 1)
const T_SUPPLY_WAGON := Vector2i(9, 1)

const COLS := 32
const ROWS := 24
const SOURCE_ID := 0

## Legend:
##  . = grass_light    g = grass_dark      d = dirt
##  p = path           s = stone           w = water
##  T = tent           F = campfire        L = log_bench
##  D = training_dummy t = target          C = crate
##  B = barrel         W = weapon_rack     f = flag
##  o = lookout_tower  P = wood_pile       F = fence
##  T = torch          S = supply_wagon

## Camp layout - 32 cols x 24 rows
## Central campfire, tents around, training area, lookout tower
const LAYOUT: Array[String] = [
	# 01234567890123456789012345678901
	"gggggggggggggggggggggggggggggggg",  # 0
	"gggggggggggggggggggggggggggggggg",  # 1
	"gggggggggggggggggggggggggggggggg",  # 2
	"gggggggggggggggggggggggggggggggg",  # 3
	"gggggggggggggggggggggggggggggggg",  # 4
	"gggggggggggggggggggggggggggggggg",  # 5
	"gggggggggggggggggggggggggggggggg",  # 6
	"gggggggggggggggggggggggggggggggg",  # 7
	"ggggggggppppppppppppppgggggggggg",  # 8  path entrance
	"ggggggggppppppppppppppgggggggggg",  # 9
	"ggggggggp............ppggggggggg",  # 10 central clearing
	"ggggggggp..TT....TT..ppggggggggg",  # 11 tents
	"ggggggggp..TT....TT..ppggggggggg",  # 12 tents
	"ggggggggp..LL..FF..LL..ppggggggg",  # 13 benches + campfire
	"ggggggggp..DD..TT..DD..ppggggggg",  # 14 dummies + tent
	"ggggggggp..DD..TT..DD..ppggggggg",  # 15 dummies + tent
	"ggggggggp..WW..CC..BB..ppggggggg",  # 16 weapon rack + crates/barrels
	"ggggggggp..tt..tt..tt..ppggggggg",  # 17 targets
	"ggggggggp............ppggggggggg",  # 18
	"ggggggggppppppppppppppgggggggggg",  # 19 path
	"gggggggggggggggggggggggggggggggg",  # 20
	"gggggggggggggggggggggggggggggggg",  # 21
	"gggggggggggggggggggggggggggggggg",  # 22
	"gggggggggggggggggggggggggggggggg",  # 23
]

## Character legend to atlas coords mapping
const CHAR_MAP: Dictionary = {
	".": T_GRASS_LIGHT,
	"g": T_GRASS_DARK,
	"d": T_DIRT,
	"p": T_PATH,
	"s": T_STONE,
	"w": T_WATER,
	"T": T_TENT,
	"F": T_CAMPFIRE,
	"L": T_LOG_BENCH,
	"D": T_TRAINING_DUMMY,
	"t": T_TARGET,
	"C": T_CRATE,
	"B": T_BARREL,
	"W": T_WEAPON_RACK,
	"f": T_FLAG,
	"o": T_LOOKOUT_TOWER,
	"P": T_WOOD_PILE,
	"Z": T_FENCE,
	"R": T_TORCH,
	"S": T_SUPPLY_WAGON,
}


func build(tilemap: TileMap) -> void:
	if tilemap == null:
		push_error("[CampTilemapBuilder] TileMap is null")
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

	print("[CampTilemapBuilder] Painted %d rows x %d cols tilemap" % [ROWS, COLS])


## Add camp details after base build
func add_camp_details(tilemap: TileMap) -> void:
	if tilemap == null:
		return
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Add fence perimeter
	for row in range(8, 20):
		# Left fence
		if row != 13 and row != 14:  # Gate openings
			tilemap.set_cell(0, Vector2i(7, row), SOURCE_ID, T_FENCE, 0)
		# Right fence
		if row != 13 and row != 14:
			tilemap.set_cell(0, Vector2i(24, row), SOURCE_ID, T_FENCE, 0)
	
	# Top fence
	for col in range(8, 25):
		if col != 12 and col != 19:  # Gate openings
			tilemap.set_cell(0, Vector2i(col, 7), SOURCE_ID, T_FENCE, 0)
	
	# Bottom fence
	for col in range(8, 25):
		if col != 12 and col != 19:
			tilemap.set_cell(0, Vector2i(col, 20), SOURCE_ID, T_FENCE, 0)
	
	# Torches on fence posts
	for row in [8, 13, 14, 19]:
		tilemap.set_cell(0, Vector2i(7, row), SOURCE_ID, T_TORCH, 0)
		tilemap.set_cell(0, Vector2i(24, row), SOURCE_ID, T_TORCH, 0)
	for col in [8, 12, 19, 24]:
		tilemap.set_cell(0, Vector2i(col, 7), SOURCE_ID, T_TORCH, 0)
		tilemap.set_cell(0, Vector2i(col, 20), SOURCE_ID, T_TORCH, 0)
	
	# Wood piles near campfire
	tilemap.set_cell(0, Vector2i(15, 14), SOURCE_ID, T_WOOD_PILE, 0)
	tilemap.set_cell(0, Vector2i(16, 14), SOURCE_ID, T_WOOD_PILE, 0)
	
	# Supply wagon near entrance
	tilemap.set_cell(0, Vector2i(12, 9), SOURCE_ID, T_SUPPLY_WAGON, 0)
	
	# Flag on lookout tower
	tilemap.set_cell(0, Vector2i(28, 2), SOURCE_ID, T_FLAG, 0)
	
	# Random grass details in clearing
	for row in range(10, 19):
		for col in range(9, 23):
			var cell = tilemap.get_cell_atlas_coords(0, Vector2i(col, row), 0)
			if cell == T_GRASS_LIGHT or cell == T_GRASS_DARK:
				var roll = rng.randi() % 20
				if roll == 0:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_CRATE, 0)
				elif roll == 1:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_BARREL, 0)
				elif roll == 2:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_LOG_BENCH, 0)
	
	print("[CampTilemapBuilder] Added fence, torches, wood piles, wagon, flag, details")