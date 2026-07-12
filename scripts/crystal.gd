extends Area2D

@onready var sprite = $Sprite2D

var collected = false
var float_timer: float = 0.0
var base_y: float

signal crystal_collected

func _ready():
	var sheet = load("res://assets/spritesheet.png")
	var atlas = AtlasTexture.new()
	atlas.atlas = sheet
	# Pink/purple crystal gem — visible at the right-center area of the sprite rows
	# at approximately x=258, y=128 in the 512px spritesheet
	atlas.region = Rect2(320, 128, 32, 32)
	sprite.texture = atlas
	sprite.scale = Vector2(1.5, 1.5)
	base_y = position.y

func _process(delta):
	if collected:
		return
	float_timer += delta
	position.y = base_y + sin(float_timer * 4.0) * 4.0
	sprite.modulate = Color(
		1.0,
		0.5 + sin(float_timer * 3.0) * 0.5,
		1.0,
		1.0
	)

func _on_body_entered(body):
	if collected:
		return
	if body.is_in_group("player"):
		collected = true
		emit_signal("crystal_collected")
		queue_free()
