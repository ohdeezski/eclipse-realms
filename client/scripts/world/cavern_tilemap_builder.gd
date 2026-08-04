extends Node
## CavernTilemapBuilder.gd - Populates the Whispering Caverns TileMap at runtime.
##
## Attach this to a Node child of the TileMap (or call build(tilemap) directly).
## Reads a compact string-based layout and paints tiles + collision.
## Dungeon layout: 50 columns x 35 rows with multiple rooms and corridors.

## Tile atlas coordinates (dungeon-specific tiles from oakrest_village tileset)
## Using available tiles with dungeon-appropriate mapping
const T_STONE_FLOOR  := Vector2i(4, 0)  # Stone floor for dungeon ground
const T_STONE_WALL   := Vector2i(6, 0)  # Stone wall (reuses tree slot as wall)
const T_DARK_FLOOR   := Vector2i(3, 0)  # Dark floor (reuses dirt)
const T_CRYSTAL      := Vector2i(5, 0)  # Crystal formation (reuses water)
const T_DOOR_CLOSED  := Vector2i(7, 0)  # Closed door (reuses building wall)
const T_DOOR_OPEN    := Vector2i(0, 1)  # Open door
const T_TORCH        := Vector2i(9, 0)  # Wall torch (reuses flowers)
const T_CHEST        := Vector2i(4, 1)  # Treasure chest (reuses well)
const T_PILLAR       := Vector2i(8, 0)  # Stone pillar (reuses fence)
const T_SPIKES       := Vector2i(5, 1)  # Spike trap (reuses sign post)
const T_BOSS_FLOOR   := Vector2i(2, 1)  # Boss arena floor (reuses stone path)
const T_ALTAR        := Vector2i(3, 1)  # Altar (reuses roof)
const T_LAVA         := Vector2i(5, 0)  # Lava hazard (reuses water)
const T_WATER_DARK   := Vector2i(5, 0)  # Dark water (reuses water)
const T_VINE         := Vector2i(1, 1)  # Hanging vines (reuses dark grass)
const T_BONES        := Vector2i(9, 1)  # Bone pile (unused)
const T_RUBBLE       := Vector2i(2, 0)  # Rubble (reuses path)

const COLS := 50
const ROWS := 35
const SOURCE_ID := 0

## Legend:
##  # = stone_wall       . = stone_floor     d = dark_floor
##  C = crystal          D = door_closed      o = door_open
##  T = torch            X = chest            P = pillar
##  S = spikes           B = boss_floor       A = altar
##  L = lava             ~ = water_dark       V = vine
##  R = rubble           B = boss_floor       + = entry_point

## Whispering Caverns layout - 50 columns x 35 rows
## Sections: Entrance -> Corridor -> Puzzle Room -> Skeleton Hall -> Boss Arena
const LAYOUT: Array[String] = [
	#01234567890123456789012345678901234567890123456789
	"##################################################",  # 0  top wall
	"#dddddddddddddddddddddddddd##,,,,,,,,,,,,,,,,,,#",  # 1  entrance hall
	"#d.+.ddddddddddddddddddddddd##,,,,,,,,,,,,,,,,,,#",  # 2  entrance
	"#d...dddddddddddddddddddddd##,,,,,,,,,,,,,,,,,,#",  # 3
	"#d...dddddddddddddddddddddd##,,T,,,,,,,,,,,,,T,,#",  # 4  skeleton hall top
	"#dddddddddddddddddddddddddd##,,,,,,,,,,,,,,,,,,#",  # 5
	"#dddddddddddddddddddddddddd##,,,,,,,,,,,,,,,,,,#",  # 6
	"#ddddddddddddddddddddddDDddd##,,T,,,,,,,,,,,,,T,,#",  # 7  corridor
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 8
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 9
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 10
	"#ddSSSddddddddddddddSSS##d##,,T,,,,,,,,,,,,,T,,#",  # 11 spike traps
	"#ddSSSddddddddddddddSSS##d##,,,,,,,,,,,,,,,,,,#",  # 12
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 13
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 14
	"#dddddddddddddddddddddd##D##,,T,,,,,,,,,,,,,T,,#",  # 15 puzzle door
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 16
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 17
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 18
	"#dddddddddddddddddddddd##d##,,T,,,,,,,,,,,,,T,,#",  # 19
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 20
	"#ddPPPPPPddddddddPPPPP##d##,,,,,,,,,,,,,,,,,,#",  # 21 pillars
	"#ddPPPPPPddddddddPPPPP##d##,,,,,,,,,,,,,,,,,,#",  # 22
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 23
	"#dddddddddddddddddddddd##d##,,T,,,,,,,,,,,,,T,,#",  # 24
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 25
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 26
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 27
	"#dddddddddddddddddddddd##d##,,T,,,,,,,,,,,,,T,,#",  # 28
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 29
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 30
	"#dddddddddddddddddddddd##d##,,,AAAAA,,,,,,,,,,,#",  # 31 boss altar
	"#dddddddddddddddddddddd##d##,,,AAAAA,,,,,,,,,,,#",  # 32
	"#dddddddddddddddddddddd##d##,,,,,,,,,,,,,,,,,,#",  # 33
	"##################################################",  # 34 bottom wall
]

## Character legend to atlas coords mapping
const CHAR_MAP: Dictionary = {
	"#": T_STONE_WALL,
	".": T_STONE_FLOOR,
	"d": T_DARK_FLOOR,
	"C": T_CRYSTAL,
	"D": T_DOOR_CLOSED,
	"o": T_DOOR_OPEN,
	"T": T_TORCH,
	"X": T_CHEST,
	"P": T_PILLAR,
	"S": T_SPIKES,
	"B": T_BOSS_FLOOR,
	"A": T_ALTAR,
	"L": T_LAVA,
	"~": T_WATER_DARK,
	"V": T_VINE,
	"R": T_RUBBLE,
	"+": T_STONE_FLOOR,  # Entry point uses floor tile
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
			var atlas_coords: Vector2i = CHAR_MAP.get(ch, T_STONE_FLOOR)
			tilemap.set_cell(0, Vector2i(col, row), SOURCE_ID, atlas_coords, 0)

	print("[CavernTilemapBuilder] Painted %d rows x %d cols tilemap" % [ROWS, COLS])
