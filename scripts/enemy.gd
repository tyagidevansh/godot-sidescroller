extends Area2D

@onready var sprite = $Sprite2D

# Tweak these in the Inspector to find the right green alien frame!
@export var sprite_region: Rect2 = Rect2(0, 192, 32, 32)

var base_y: float
var bob_timer: float = 0.0

func _ready():
	var sheet = load("res://assets/spritesheet.png")
	sprite.texture = sheet
	sprite.region_enabled = true
	sprite.region_rect = sprite_region
	sprite.scale = Vector2(3.5, 3.5)
	sprite.centered = true
	sprite.flip_h = true
	base_y = position.y

func _process(delta):
	bob_timer += delta
	position.y = base_y + sin(bob_timer * 3.0) * 3.0

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
