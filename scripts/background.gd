extends CanvasLayer

enum Zone { BLUE, BLACK }

const BORDER_TL = Vector2i(0, 0)
const BORDER_T  = Vector2i(32, 0)
const BORDER_TR = Vector2i(64, 0)
const BORDER_L  = Vector2i(0, 32)
const BORDER_R  = Vector2i(64, 32)
const BORDER_BL = Vector2i(0, 64)
const BORDER_B  = Vector2i(32, 64)
const BORDER_BR = Vector2i(64, 64)

const FILL_TILES = [
	Vector2i(32, 32),
	Vector2i(0, 128), Vector2i(32, 128), Vector2i(64, 128),
	Vector2i(32, 160), Vector2i(64, 160)
]

const BLACK_FILL_TILES = [
	Vector2i(96, 128), Vector2i(128, 128), Vector2i(160, 128),
	Vector2i(96, 160), Vector2i(128, 160), Vector2i(160, 160)
]

const LAMP = [
	# Row 0
	Vector2i(196, 0),  Vector2i(228, 0),  Vector2i(256, 0),
	# Row 1
	Vector2i(196, 32), Vector2i(228, 32), Vector2i(256, 32),
	# Row 2
	Vector2i(196, 64), Vector2i(228, 64), Vector2i(256, 64),
]

const BLOCK = 96
const COLS  = 14  
const ROWS  = 8    

var _blue_tex:  ImageTexture
var _black_tex: ImageTexture
var _current_zone: int = Zone.BLACK

var _active_blocks: Array[TextureRect] = []
var _last_bg_x: float = 0.0
var _chunks_spawned: int = 0
const CHUNKS_PER_ZONE: int = 3

signal zone_changed(new_zone: int)

@onready var _tex_rect1: TextureRect = $TextureRect

func _ready():
	var img = (load("res://assets/bgplatform.png") as Texture2D).get_image()
	_blue_tex  = _build_blue(img)
	_black_tex = _build_black(img)
	
	_tex_rect1.hide()
	
	_spawn_block(0.0)
	_spawn_block(COLS * BLOCK)

func _spawn_block(x_pos: float):
	if _chunks_spawned > 0 and _chunks_spawned % CHUNKS_PER_ZONE == 0:
		if _current_zone == Zone.BLUE:
			_current_zone = Zone.BLACK
		else:
			_current_zone = Zone.BLUE
		zone_changed.emit(_current_zone)

	var tex = _blue_tex if _current_zone == Zone.BLUE else _black_tex
	var tr = TextureRect.new()
	tr.texture = tex
	tr.position.x = x_pos
	add_child(tr)
	_active_blocks.append(tr)
	_last_bg_x = x_pos + (COLS * BLOCK)
	_chunks_spawned += 1

func _process(delta: float) -> void:
	var move = delta * 45.0
	for b in _active_blocks:
		b.position.x -= move
	_last_bg_x -= move
	
	while _last_bg_x < 1152.0 + (COLS * BLOCK):
		_spawn_block(_last_bg_x)
		
	while _active_blocks.size() > 0 and _active_blocks[0].position.x <= -(COLS * BLOCK):
		_active_blocks[0].queue_free()
		_active_blocks.pop_front()

# ── Blue zone ────────────────────────────────────────────────────────────────
func _build_blue(img: Image) -> ImageTexture:
	var comp = Image.create(COLS * BLOCK, ROWS * BLOCK, false, img.get_format())
	for row in range(ROWS):
		for col in range(COLS):
			var src: Vector2i
			if row == 0 and col == 0:
				src = BORDER_TL
			elif row == 0 and col == COLS - 1:
				src = BORDER_TR
			elif row == 0:
				src = BORDER_T
			elif row == ROWS - 1 and col == 0:
				src = BORDER_BL
			elif row == ROWS - 1 and col == COLS - 1:
				src = BORDER_BR
			elif row == ROWS - 1:
				src = BORDER_B
			elif col == 0:
				src = BORDER_L
			elif col == COLS - 1:
				src = BORDER_R
			else:
				src = FILL_TILES[randi() % FILL_TILES.size()]
			_blit(img, comp, src, col, row)
	return ImageTexture.create_from_image(comp)

# ── Black zone ───────────────────────────────────────────────────────────────
func _build_black(img: Image) -> ImageTexture:
	var comp = Image.create(COLS * BLOCK, ROWS * BLOCK, false, img.get_format())
	
	# Fill entire background with rocks
	for row in range(ROWS):
		for col in range(COLS):
			var src = BLACK_FILL_TILES[randi() % BLACK_FILL_TILES.size()]
			_blit(img, comp, src, col, row)
			
	# Place two 4x4 lamps horizontally
	for c in [2, 8]:
		# Row 0 (maps to row 2)
		_blit(img, comp, LAMP[0], c, 2)
		_blit(img, comp, LAMP[1], c+1, 2)
		_blit(img, comp, LAMP[2], c+2, 2)
		# Row 1 (maps to row 3)
		_blit(img, comp, LAMP[3], c, 3)
		_blit(img, comp, LAMP[4], c+1, 3)
		_blit(img, comp, LAMP[5], c+2, 3)
			
	return ImageTexture.create_from_image(comp)

func _blit(src_img: Image, dst: Image, origin: Vector2i, col: int, row: int) -> void:
	var tile = src_img.get_region(Rect2i(origin.x, origin.y, 32, 32))
	tile.resize(BLOCK, BLOCK, Image.INTERPOLATE_NEAREST)
	# blend_rect ensures transparency in tiles (like cages) doesn't erase the rock background behind them
	dst.blend_rect(tile, Rect2i(0, 0, BLOCK, BLOCK), Vector2i(col * BLOCK, row * BLOCK))
