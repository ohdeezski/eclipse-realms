extends Node
## WatchtowerTilemapBuilder.gd - Populates the Old Watchtower TileMap at runtime.
## Ancient stone tower with spiral staircase, viewing platform, lore room

## Tile atlas coordinates (matches watchtower_tileset.png layout - 32x32 tiles)
const T_STONE_FLOOR    := Vector2i(0, 0)
const T_STONE_FLOOR_DARK:= Vector2i(1, 0)
const T_STONE_WALL     := Vector2i(2, 0)
const T_STONE_WALL_DARK:= Vector2i(3, 0)
const T_STAIRS_UP      := Vector2i(4, 0)
const T_STAIRS_DOWN    := Vector2i(5, 0)
const T_WINDOW         := Vector2i(6, 0)
const T_ARROW_SLIT     := Vector2i(7, 0)
const T_TORCH_WALL     := Vector2i(8, 0)
const T_BANNER         := Vector2i(9, 0)
const T_BOOKSHELF      := Vector2i(0, 1)
const T_TABLE          := Vector2i(1, 1)
const T_CHAIR          := Vector2i(2, 1)
const T_CHEST          := Vector2i(3, 1)
const T_RUNE_STONE     := Vector2i(4, 1)
const T_STATUE         := Vector2i(5, 1)
const T_PILLAR         := Vector2i(6, 1)
const T_CRACKED_FLOOR  := Vector2i(7, 1)
const T_MOSS           := Vector2i(8, 1)
const T_VINES          := Vector2i(9, 1)

const COLS := 20
const ROWS := 30
const SOURCE_ID := 0

## Legend:
##  . = stone_floor      d = stone_floor_dark   # = stone_wall
##  D = stone_wall_dark  U = stairs_up          D = stairs_down
##  W = window           A = arrow_slit         T = torch_wall
##  B = banner           b = bookshelf          t = table
##  c = chair            C = chest              R = rune_stone
##  S = statue           P = pillar             x = cracked_floor
##  m = moss             v = vines              ~ = entrance

## Watchtower layout - 20 cols x 30 rows (vertical tower)
## Ground floor (rows 25-29): entrance, storage
## Mid floors (rows 15-24): spiral staircase, guard rooms
## Upper floors (rows 5-14): archer positions, arrow slits
## Top floor (rows 0-4): viewing platform, lore room, beacon

const LAYOUT: Array[String] = [
	# 01234567890123456789
	"####################",  # 0  roof/viewing platform
	"#..........RR......#",  # 1  viewing platform + runes
	"#..........SS......#",  # 2  statues
	"#..........bb......#",  # 3  bookshelves (lore room)
	"#..........tt......#",  # 4  table + chairs
	"####################",  # 5  floor 4 ceiling
	"#UUUUUUUUUUUUUUUUUU#",  # 6  stairs up
	"#..................#",  # 7
	"#..................#",  # 8
	"#..................#",  # 9
	"#......WWWWWW......#",  # 10 arrow slits (archer positions)
	"#..................#",  # 11
	"#..................#",  # 12
	"#..................#",  # 13
	"#..................#",  # 14
	"####################",  # 15 floor 3 ceiling
	"#DDDDDDDDDDDDDDDDD#",  # 16 stairs down
	"#..................#",  # 17
	"#..................#",  # 18
	"#..................#",  # 19
	"#......WWWWWW......#",  # 20 arrow slits
	"#..................#",  # 21
	"#..................#",  # 22
	"#..................#",  # 23
	"#..................#",  # 24
	"####################",  # 25 floor 2 ceiling
	"#UUUUUUUUUUUUUUUUUU#",  # 26 stairs up
	"#..................#",  # 27
	"#........CC........#",  # 28 chest room (ground floor storage)
	"#~~~~~~~~~~~~~~~~~~#",  # 29 entrance
]

## Character legend to atlas coords mapping
const CHAR_MAP: Dictionary = {
	".": T_STONE_FLOOR,
	"d": T_STONE_FLOOR_DARK,
	"#": T_STONE_WALL,
	"D": T_STONE_WALL_DARK,
	"U": T_STAIRS_UP,
	"X": T_STAIRS_DOWN,
	"W": T_WINDOW,
	"A": T_ARROW_SLIT,
	"T": T_TORCH_WALL,
	"B": T_BANNER,
	"b": T_BOOKSHELF,
	"t": T_TABLE,
	"c": T_CHAIR,
	"C": T_CHEST,
	"R": T_RUNE_STONE,
	"S": T_STATUE,
	"P": T_PILLAR,
	"x": T_CRACKED_FLOOR,
	"m": T_MOSS,
	"v": T_VINES,
	"~": T_STONE_FLOOR,
}


func build(tilemap: TileMap) -> void:
	if tilemap == null:
		push_error("[WatchtowerTilemapBuilder] TileMap is null")
		return

	for row in range(ROWS):
		if row >= LAYOUT.size():
			break
		var line: String = LAYOUT[row]
		for col in range(min(line.length(), COLS)):
			var ch: String = line[col]
			if ch == " ":
				continue
			var atlas_coords: Vector2i = CHAR_MAP.get(ch, T_STONE_FLOOR)
			tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, atlas_coords, 0)

	print("[WatchtowerTilemapBuilder] Painted %d rows x %d cols tilemap" % [ROWS, COLS])


## Add watchtower details after base build
func add_watchtower_details(tilemap: TileMap) -> void:
	if tilemap == null:
		return
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Torches on walls
	for row in range(5, ROWS - 2):
		# Left wall torches
		if tilemap.get_cell_atlas_coords(0, Vector2i(1, row), 0) == T_STONE_WALL:
			if rng.randi() % 3 == 0:
				tilemap.set_cell(0, Vector2i(1, row), SOURCE_ID, T_TORCH_WALL, 0)
		# Right wall torches
		if tilemap.get_cell_atlas_coords(0, Vector2i(COLS - 2, row), 0) == T_STONE_WALL:
			if rng.randi() % 3 == 0:
				tilemap.set_cell(0, Vector2i(COLS - 2, row), SOURCE_ID, T_TORCH_WALL, 0)
	
	# Banners on upper floors
	for row in [1, 2, 3]:
		tilemap.set_cell(0, Vector2i(5, row), SOURCE_ID, T_BANNER, 0)
		tilemap.set_cell(0, Vector2i(COLS - 6, row), SOURCE_ID, T_BANNER, 0)
	
	# Moss and vines on lower floors (age)
	for row in range(25, ROWS):
		for col in range(2, COLS - 2):
			if rng.randi() % 10 == 0:
				tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_MOSS, 0)
			if rng.randi() % 15 == 0:
				tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_VINES, 0)
	
	# Cracked floor in spots
	for row in range(25, ROWS):
		for col in range(2, COLS - 2):
			if rng.randi() % 20 == 0:
				tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, T_CRACKED_FLOOR, 0)
	
	# Pillars supporting upper floors
	for row in [10, 15, 20]:
		tilemap.set_cell(0, Vector2i(5, row), SOURCE_ID, T_PILLAR, 0)
		tilemap.set_cell(0, Vector2i(COLS - 6, row), SOURCE_ID, T_PILLAR, 0)
	
	# Runes on viewing platform
	tilemap.set_cell(0, Vector2i(8, 1), SOURCE_ID, T_RUNE_STONE, 0)
	tilemap.set_cell(0, Vector2i(11, 1), SOURCE_ID, T_RUNE_STONE, 0)
	
	# Statues on viewing platform
	tilemap.set_cell(0, Vector2i(6, 2), SOURCE_ID, T_STATUE, 0)
	tilemap.set_cell(0, Vector2i(13, 2), SOURCE_ID, T_STATUE, 0)
	
	# Bookshelves in lore room
	for col in [8, 9, 10, 11]:
		tilemap.set_cell(0, Vector2i(col, 3), SOURCE_ID, T_BOOKSHELF, 0)
	
	# Table and chairs in lore room
	tilemap.set_cell(0, Vector2i(9, 4), SOURCE_ID, T_TABLE, 0)
	tilemap.set_cell(0, Vector2i(8, 4), SOURCE_ID, T_CHAIR, 0)
	tilemap.set_cell(0, Vector2i(12, 4), SOURCE_ID, T_CHAIR, 0)
	
	# Chest in ground floor storage
	tilemap.set_cell(0, Vector2i(8, 28), SOURCE_ID, T_CHEST, 0)
	tilemap.set_cell(0, Vector2i(11, 28), SOURCE_ID, T_CHEST, 0)
	
	print("[WatchtowerTilemapBuilder] Added torches, banners, moss, vines, cracked floor, pillars, runes, statues, books, table, chairs, chests")