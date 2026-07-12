extends StaticBody2D

@onready var collision = $CollisionShape2D

const PLAT_H    = 18.0
const RIVET_SZ  = 4.0
const RIVET_GAP = 44.0

# Three platform styles — each picked once per platform.
# Format: [glow_color, surface_color, top_edge_color, rivet_color]
const STYLES = [
	[Color(1.0, 0.45, 0.05, 0.9),  Color(0.15, 0.17, 0.22), Color(0.28, 0.31, 0.38), Color(0.09, 0.10, 0.14)],
	[Color(0.25, 0.55, 1.0, 0.85), Color(0.08, 0.14, 0.24), Color(0.16, 0.24, 0.40), Color(0.06, 0.10, 0.18)],
	[Color(0.9, 0.25, 0.05, 0.85), Color(0.20, 0.10, 0.07), Color(0.33, 0.18, 0.12), Color(0.13, 0.07, 0.05)],
]

func setup_platform(requested_width: float, style: int = 0):
	var s = STYLES[clamp(style, 0, STYLES.size() - 1)]
	var glow_col    = s[0] as Color
	var surf_col    = s[1] as Color
	var edge_col    = s[2] as Color
	var rivet_col   = s[3] as Color

	var glow = ColorRect.new()
	glow.color = glow_col
	glow.size = Vector2(requested_width, 3)
	glow.position = Vector2(0, -3)
	add_child(glow)

	var base = ColorRect.new()
	base.color = surf_col
	base.size = Vector2(requested_width, PLAT_H)
	base.position = Vector2(0, 0)
	add_child(base)

	var top_edge = ColorRect.new()
	top_edge.color = edge_col
	top_edge.size = Vector2(requested_width, 3)
	top_edge.position = Vector2(0, 0)
	add_child(top_edge)

	var bot_edge = ColorRect.new()
	bot_edge.color = surf_col.darkened(0.4)
	bot_edge.size = Vector2(requested_width, 4)
	bot_edge.position = Vector2(0, PLAT_H - 4)
	add_child(bot_edge)

	var num_rivets = int(requested_width / RIVET_GAP)
	for i in range(num_rivets):
		var rivet = ColorRect.new()
		rivet.color = rivet_col
		rivet.size = Vector2(RIVET_SZ, RIVET_SZ)
		rivet.position = Vector2(i * RIVET_GAP + 20.0, (PLAT_H - RIVET_SZ) / 2.0)
		add_child(rivet)

		var hi = ColorRect.new()
		hi.color = edge_col
		hi.size = Vector2(2, 1)
		hi.position = Vector2(i * RIVET_GAP + 20.0, (PLAT_H - RIVET_SZ) / 2.0)
		add_child(hi)

	collision.shape = collision.shape.duplicate()
	collision.shape.size = Vector2(requested_width, PLAT_H)
	collision.position = Vector2(requested_width / 2.0, PLAT_H / 2.0)
