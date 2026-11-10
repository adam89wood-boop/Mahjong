extends RefCounted
class_name ChristmasTileArt

const COUNT := 63

# Curated distinct faces for solitaire deals. Similar-looking variants are
# deliberately omitted so a player never sees more than one matching pair of
# any illustration on the board.
const PAIR_ART_IDS := [
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
	23, 25, 26, 27, 28, 29, 30, 31, 33, 37, 39, 40, 41, 43, 46, 47, 58,
]

const TEXTURES := [
	preload("res://assets/tiles/tile_00.png"),
	preload("res://assets/tiles/tile_01.png"),
	preload("res://assets/tiles/tile_02.png"),
	preload("res://assets/tiles/tile_03.png"),
	preload("res://assets/tiles/tile_04.png"),
	preload("res://assets/tiles/tile_05.png"),
	preload("res://assets/tiles/tile_06.png"),
	preload("res://assets/tiles/tile_07.png"),
	preload("res://assets/tiles/tile_08.png"),
	preload("res://assets/tiles/tile_09.png"),
	preload("res://assets/tiles/tile_10.png"),
	preload("res://assets/tiles/tile_11.png"),
	preload("res://assets/tiles/tile_12.png"),
	preload("res://assets/tiles/tile_13.png"),
	preload("res://assets/tiles/tile_14.png"),
	preload("res://assets/tiles/tile_15.png"),
	preload("res://assets/tiles/tile_16.png"),
	preload("res://assets/tiles/tile_17.png"),
	preload("res://assets/tiles/tile_18.png"),
	preload("res://assets/tiles/tile_19.png"),
	preload("res://assets/tiles/tile_20.png"),
	preload("res://assets/tiles/tile_21.png"),
	preload("res://assets/tiles/tile_22.png"),
	preload("res://assets/tiles/tile_23.png"),
	preload("res://assets/tiles/tile_24.png"),
	preload("res://assets/tiles/tile_25.png"),
	preload("res://assets/tiles/tile_26.png"),
	preload("res://assets/tiles/tile_27.png"),
	preload("res://assets/tiles/tile_28.png"),
	preload("res://assets/tiles/tile_29.png"),
	preload("res://assets/tiles/tile_30.png"),
	preload("res://assets/tiles/tile_31.png"),
	preload("res://assets/tiles/tile_32.png"),
	preload("res://assets/tiles/tile_33.png"),
	preload("res://assets/tiles/tile_34.png"),
	preload("res://assets/tiles/tile_35.png"),
	preload("res://assets/tiles/tile_36.png"),
	preload("res://assets/tiles/tile_37.png"),
	preload("res://assets/tiles/tile_38.png"),
	preload("res://assets/tiles/tile_39.png"),
	preload("res://assets/tiles/tile_40.png"),
	preload("res://assets/tiles/tile_41.png"),
	preload("res://assets/tiles/tile_42.png"),
	preload("res://assets/tiles/tile_43.png"),
	preload("res://assets/tiles/tile_44.png"),
	preload("res://assets/tiles/tile_45.png"),
	preload("res://assets/tiles/tile_46.png"),
	preload("res://assets/tiles/tile_47.png"),
	preload("res://assets/tiles/tile_48.png"),
	preload("res://assets/tiles/tile_49.png"),
	preload("res://assets/tiles/tile_50.png"),
	preload("res://assets/tiles/tile_51.png"),
	preload("res://assets/tiles/tile_52.png"),
	preload("res://assets/tiles/tile_53.png"),
	preload("res://assets/tiles/tile_54.png"),
	preload("res://assets/tiles/tile_55.png"),
	preload("res://assets/tiles/tile_56.png"),
	preload("res://assets/tiles/tile_57.png"),
	preload("res://assets/tiles/tile_58.png"),
	preload("res://assets/tiles/tile_59.png"),
	preload("res://assets/tiles/tile_60.png"),
	preload("res://assets/tiles/tile_61.png"),
	preload("res://assets/tiles/tile_62.png"),
]

static func get_texture(id: int) -> Texture2D:
	return TEXTURES[id % COUNT]

