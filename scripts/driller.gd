extends Node2D

var drift_time: float = 0.0

func _ready():
	z_index = 50
	# Clear the old single sprite
	for child in get_children():
		child.queue_free()

	var sheet = load("res://assets/spritesheet.png")
	var frames = SpriteFrames.new()
	frames.add_animation("drill")
	frames.set_animation_loop("drill", true)
	frames.set_animation_speed("drill", 12.0)
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * 128, 0, 128, 128)
		frames.add_frame("drill", atlas)
		
	# 1. Center Driller
	var center = AnimatedSprite2D.new()
	center.sprite_frames = frames
	center.scale = Vector2(3.5, 3.5)
	center.play("drill")
	add_child(center)
	
	# 2. Top Driller
	var top = AnimatedSprite2D.new()
	top.sprite_frames = frames
	top.scale = Vector2(3.5, 3.5)
	top.position = Vector2(0, -448)
	top.play("drill")
	add_child(top)
	
	# 3. Bottom Driller
	var bottom = AnimatedSprite2D.new()
	bottom.sprite_frames = frames
	bottom.scale = Vector2(3.5, 3.5)
	bottom.position = Vector2(0, 448)
	bottom.play("drill")
	add_child(bottom)
	
	# Area2D for killing the player
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(250, 1500) # Large wall covering all 3 drills
	shape.shape = rect
	shape.position = Vector2(50, 0)
	area.add_child(shape)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player or player.is_dead:
		return
		
	drift_time += delta
		
	# Follow camera exactly on X to stay fixed on the left edge of the screen
	var camera = get_viewport().get_camera_2d()
	if camera:
		position.x = camera.global_position.x - 580.0
		# Y position remains static in the world, allowing the camera to pan across it

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
