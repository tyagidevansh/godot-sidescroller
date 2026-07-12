extends Node2D

@onready var sprite = $AnimatedSprite2D

var drift_time: float = 0.0

func _ready():
	var sheet = load("res://assets/spritesheet.png")
	var frames = SpriteFrames.new()
	frames.add_animation("drill")
	frames.set_animation_loop("drill", true)
	frames.set_animation_speed("drill", 8.0)
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * 128, 0, 128, 128)
		frames.add_frame("drill", atlas)
	sprite.sprite_frames = frames
	sprite.scale = Vector2(3.5, 3.5)
	sprite.play("drill")

func _process(delta):
	drift_time += delta
	var camera = get_parent().get_node_or_null("Camera2D")
	if camera == null:
		return
	# Slow sine drift — purely visual, never kills the player
	var x_drift = sin(drift_time * 0.2) * 50.0
	# -580 keeps the driller mostly behind the left screen edge with just
	# the drill tips and right body visible. Never intersects the player.
	position.x = camera.position.x - 580.0 + x_drift
	position.y = camera.position.y - 60.0
