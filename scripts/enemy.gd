extends Area2D

@onready var sprite = $AnimatedSprite2D

var active: bool = false
@export var speed: float = 100.0

func _ready():
	sprite.play("default")
	sprite.scale = Vector2(3.5, 3.5)

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not active and player:
		if global_position.x - player.global_position.x < 500.0:
			active = true
			
	if active and player:
		var dir_x = sign(player.global_position.x - global_position.x)
		position.x += dir_x * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("hit_by_enemy"):
		body.hit_by_enemy()
		queue_free()
