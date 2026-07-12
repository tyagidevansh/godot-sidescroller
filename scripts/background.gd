extends CanvasLayer

enum Zone { BLUE, BLACK }

const BLUE_PLAIN  = [Vector2i(0,0),  Vector2i(32,0),  Vector2i(0,32),  Vector2i(32,32)]
const BLUE_ROCK   = [Vector2i(64,0), Vector2i(96,0),  Vector2i(64,32), Vector2i(96,32)]
const BLACK_ROCK  = [Vector2i(0,64), Vector2i(32,64), Vector2i(64,64), Vector2i(96,64),
					 Vector2i(0,96), Vector2i(32,96), Vector2i(64,96), Vector2i(96,96)]
# Only x=192 and x=224 are actual glow tiles (confirmed by color analysis)
const GLOW_TILES  = [Vector2i(192,0), Vector2i(224,0), Vector2i(192,32), Vector2i(224,32)]

const BLOCK = 96
const COLS  = 14   # 14 × 96 = 1344 px — image width
const ROWS  = 8    # 8  × 96 = 768  px — exact screen height

var _blue_tex:  ImageTexture
var _black_tex: ImageTexture
var _scroll:    float = 0.0

@onready var _tex_rect: TextureRect = $TextureRect

func _ready():
	var img = (load("res://assets/bgplatform.png") as Texture2D).get_image()
	_blue_tex  = _build_blue(img)
	_black_tex = _build_black(img)
	switch_zone(Zone.BLUE)

func _process(delta: float) -> void:
	# Slow horizontal drift — gives a subtle cave-atmosphere scroll
	_scroll += delta * 45.0
	_tex_rect.position.x = -fmod(_scroll, float(COLS * BLOCK))

func switch_zone(zone: Zone) -> void:
	_tex_rect.texture = _blue_tex if zone == Zone.BLUE else _black_tex

# ── Blue zone ────────────────────────────────────────────────────────────────
# Row 0 and Row 7 = glow tiles  (locked to screen top and bottom, no vertical drift)
# Rows 1-6       = blue plain + blue rock only, NO black tiles whatsoever
func _build_blue(img: Image) -> ImageTexture:
	var comp = Image.create(COLS * BLOCK, ROWS * BLOCK, false, img.get_format())
	for row in range(ROWS):
		for col in range(COLS):
			var src: Vector2i
			if row == 0 or row == ROWS - 1:
				src = GLOW_TILES[randi() % GLOW_TILES.size()]
			elif randf() < 0.5:
				src = BLUE_PLAIN[randi() % BLUE_PLAIN.size()]
			else:
				src = BLUE_ROCK[randi() % BLUE_ROCK.size()]
			_blit(img, comp, src, col, row)
	return ImageTexture.create_from_image(comp)

# ── Black zone ───────────────────────────────────────────────────────────────
# Row 4 (middle) = glow stripe  (one clean horizontal line, nothing else glows)
# All other rows = black rock only, NO blue tiles whatsoever
func _build_black(img: Image) -> ImageTexture:
	var comp = Image.create(COLS * BLOCK, ROWS * BLOCK, false, img.get_format())
	for row in range(ROWS):
		for col in range(COLS):
			var src: Vector2i
			if row == ROWS / 2:
				src = GLOW_TILES[randi() % GLOW_TILES.size()]
			else:
				src = BLACK_ROCK[randi() % BLACK_ROCK.size()]
			_blit(img, comp, src, col, row)
	return ImageTexture.create_from_image(comp)

func _blit(src_img: Image, dst: Image, origin: Vector2i, col: int, row: int) -> void:
	var tile = src_img.get_region(Rect2i(origin.x, origin.y, 32, 32))
	tile.resize(BLOCK, BLOCK, Image.INTERPOLATE_NEAREST)
	dst.blit_rect(tile, Rect2i(0, 0, BLOCK, BLOCK), Vector2i(col * BLOCK, row * BLOCK))
