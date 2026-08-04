extends Node
## CavernTilemapBuilder.gd - Populates the Whispering Caverns TileMap at runtime.
## Dark cave system with glowing crystals, stalactites, underground pools

## Tile atlas coordinates (matches cavern_tileset.png layout - 32x32 tiles)
const T_CAVE_FLOOR     := Vector2i(0, 0)
const T_CAVE_FLOOR_DARK:= Vector2i(1, 0)
const T_CAVE_WALL      := Vector2i(2, 0)
const T_CAVE_WALL_DARK := Vector2i(3, 0)
const T_WATER_SHALLOW  := Vector2i(4, 0)
const T_WATER_DEEP     := Vector2i(5, 0)
const T_STALACTITE     := Vector2i(6, 0)
const T_STALAGMITE     := Vector2i(7, 0)
const T_CRYSTAL_BLUE   := Vector2i(8, 0)
const T_CRYSTAL_PURPLE := Vector2i(9, 0)
const T_CRYSTAL_GREEN  := Vector2i(0, 1)
const T_MUSHROOM_GLOW  := Vector2i(1, 1)
const T_FUNGUS         := Vector2i(2, 1)
const T_BONE_PILE      := Vector2i(3, 1)
const T_WEBBING        := Vector2i(4, 1)
const T_CHAINS         := Vector2i(5, 1)
const T_RUNE           := Vector2i(6, 1)
const T_ALTAR          := Vector2i(7, 1)
const T_BOSS_FLOOR     := Vector2i(8, 1)
const T_BOSS_WALL      := Vector2i(9, 1)

const COLS := 50
const ROWS := 40
const SOURCE_ID := 0

## Legend:
##  . = cave_floor       d = cave_floor_dark    # = cave_wall
##  D = cave_wall_dark   w = water_shallow      W = water_deep
##  S = stalactite       s = stalagmite         b = crystal_blue
##  p = crystal_purple   g = crystal_green      m = mushroom_glow
##  f = fungus           B = bone_pile          W = webbing
##  C = chains           R = rune               A = altar
##  O = boss_floor       X = boss_wall          ~ = entrance

## Cavern layout - 50 cols x 40 rows
## Entrance at top (row 0-2), boss chamber at bottom (row 35-39)
const LAYOUT: Array[String] = [
	# 01234567890123456789012345678901234567890123456789
	"##################################################",  # 0  entrance ceiling
	"##################################################",  # 1
	"##################################################",  # 2
	"###............................................###",  # 3  entrance opening
	"###............................................###",  # 4
	"###............................................###",  # 5
	"###........####..........####.................###",  # 6  pillars
	"###........####..........####.................###",  # 7
	"###........####..........####.................###",  # 8
	"###........####..........####.................###",  # 9
	"###............................................###",  # 10
	"###..........##########..........##########....###",  # 11  chamber walls
	"###..........##########..........##########....###",  # 12
	"###..........#........#..........#........#....###",  # 13
	"###..........#........#..........#........#....###",  # 14
	"###..........#........#..........#........#....###",  # 15
	"###..........#........#..........#........#....###",  # 16
	"###..........#........#..........#........#....###",  # 17
	"###..........#........#..........#........#....###",  # 18
	"###..........#........#..........#........#....###",  # 19
	"###..........#........#..........#........#....###",  # 20
	"###..........#........#..........#........#....###",  # 21
	"###..........#........#..........#........#....###",  # 22
	"###..........#........#..........#........#....###",  # 23
	"###..........#........#..........#........#....###",  # 24
	"###..........##########..........##########....###",  # 25
	"###............................................###",  # 26  corridor
	"###............................................###",  # 27
	"###............................................###",  # 28
	"###..........##########..........##########....###",  # 29  crystal chamber
	"###..........#bbbbbbbb#..........#pppppppp#....###",  # 30  crystals
	"###..........#bbbbbbbb#..........#pppppppp#....###",  # 31
	"###..........#bbbbbbbb#..........#pppppppp#....###",  # 32
	"###..........#bbbbbbbb#..........#pppppppp#....###",  # 33
	"###..........##########..........##########....###",  # 34
	"###..........#gggggggg#..........#gggggggg#....###",  # 35  glowing fungus
	"###..........#gggggggg#..........#gggggggg#....###",  # 36
	"###..........##########..........##########....###",  # 37
	"###............................................###",  # 38  boss approach
	"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",  # 39  boss chamber walls
]

## Character legend to atlas coords mapping
const CHAR_MAP: Dictionary = {
	".": T_CAVE_FLOOR,
	"d": T_CAVE_FLOOR_DARK,
	"#": T_CAVE_WALL,
	"D": T_CAVE_WALL_DARK,
	"w": T_WATER_SHALLOW,
	"W": T_WATER_DEEP,
	"S": T_STALACTITE,
	"s": T_STALAGMITE,
	"b": T_CRYSTAL_BLUE,
	"p": T_CRYSTAL_PURPLE,
	"g": T_CRYSTAL_GREEN,
	"m": T_MUSHROOM_GLOW,
	"f": T_FUNGUS,
	"B": T_BONE_PILE,
	"Y": T_WEBBING,
	"C": T_CHAINS,
	"R": T_RUNE,
	"A": T_ALTAR,
	"O": T_BOSS_FLOOR,
	"X": T_BOSS_WALL,
	"~": T_CAVE_FLOOR,
}


func build(tilemap: TileMap) -> void:
	if tilemap == null:
		push_error("[CavernTilemapBuilder] TileMap is null")
		return

	for row in range(ROWS):
		if row >= LAYOUT.size():
			break
		var line: String = LAYOUT[row]
		for col in range(min(line.length(), COLS)):
			var ch: String = line[col]
			if ch == " ":
				continue
			var atlas_coords: Vector2i = CHAR_MAP.get(ch, T_CAVE_FLOOR)
			tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, atlas_coords, 0)

	print("[CavernTilemapBuilder] Painted %d rows x %d cols tilemap" % [ROWS, COLS])


## Add cave details after base build
func add_cavern_details(tilemap: TileMap) -> void:
	if tilemap == null:
		return
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Add stalactites on ceiling (row 3)
	for col in range(5, COLS - 5):
		if rng.randi() % 5 == 0:
			tilemap.set_cell(0, Vector2i(col, 3), SOURCE_ID, T_STALACTITE, 0)
	
	# Add stalagmites on floor areas
	for row in range(4, ROWS - 5):
		for col in range(5, COLS - 5):
			var cell = tilemap.get_cell_atlas_coords(0, Vector2i(col, row), 0)
			if cell == T_CAVE_FLOOR or cell == T_CAVE_FLOOR_DARK:
				var roll = rng.randi() % 100
				
				# Stalagmites
				if roll < 2:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_STALAGMITE, 0)
				
				# Crystals
				elif roll < 5:
					var crystal = rng.randi() % 3
					if crystal == 0:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_CRYSTAL_BLUE, 0)
					elif crystal == 1:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_CRYSTAL_PURPLE, 0)
					else:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_CRYSTAL_GREEN, 0)
				
				# Glowing mushrooms/fungus
				elif roll < 8:
					var bio = rng.randi() % 2
					if bio == 0:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_MUSHROOM_GLOW, 0)
					else:
						tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_FUNGUS, 0)
				
				# Bone piles
				elif roll < 10:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_BONE_PILE, 0)
				
				# Webbing
				elif roll < 12:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_WEBBING, 0)
				
				# Runes (rare)
				elif roll < 13:
					tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_RUNE, 0)
	
	# Add water pools
	for row in [10, 15, 20, 25, 30]:
		for col in range(10, 40):
			if rng.randi() % 20 == 0:
				tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_WATER_SHALLOW, 0)
	
	# Add webbing in corners
	for row in [5, 6, 7, 8, 9]:
		for col in [5, 6, 7, 43, 44, 45]:
			if rng.randi() % 3 == 0:
				tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_WEBBING, 0)
	
	print("[CavernTilemapBuilder] Added stalactites, stalagmites, crystals, mushrooms, bones, webbing, water pools")