extends Node2D

const PLATFORM_WIDTH = 500.0
const SPAWN_AHEAD_DISTANCE = 2000.0
const DESPAWN_BEHIND_DISTANCE = 1500.0

var platform_scene = preload("res://scenes/platform.tscn")
var obstacle_scene = preload("res://scenes/obstacle.tscn")

var player
var last_spawn_x = 0.0
var active_platforms = []
var time_elapsed = 0.0

func _ready():
	player = $Player
	
	spawn_platform(0.0, 400.0, 1000.0, false) 
	last_spawn_x = 1000.0
	
	for i in range(5):
		generate_next_platform()

func _process(delta):
	if player == null:
		return
		
	if not player.is_dead:
		var score = int(player.position.x / 100.0)
		$HUD/ScoreLabel.text = "Score: " + str(max(0, score))

		time_elapsed += delta
		player.current_speed = min(1000.0, 400.0 + (time_elapsed * 15.0))
		
		$Camera2D.position.x = player.position.x + 350
		$Camera2D.position.y = 300
		
	elif not $HUD/GameOver.visible:
		$HUD/GameOver.visible = true
		
	while last_spawn_x < player.position.x + SPAWN_AHEAD_DISTANCE:
		generate_next_platform()

	for i in range(active_platforms.size() - 1, -1, -1):
		var p = active_platforms[i]
		if p.position.x < player.position.x - DESPAWN_BEHIND_DISTANCE:
			p.queue_free() 
			active_platforms.remove_at(i)
			
	if player.position.y > 1000 and not player.is_dead:
		player.die()

func generate_next_platform():
	var max_safe_gap = player.current_speed * 0.75 
	var gap_x = randf_range(100, max_safe_gap)
	
	var x_pos = last_spawn_x + gap_x
	
	var last_y = 400.0
	if active_platforms.size() > 0:
		last_y = active_platforms[-1].position.y
	
	var y_pos = last_y + randf_range(-100, 100)
	y_pos = clamp(y_pos, 200, 600)
	
	var p_width = randf_range(300, 800)
	
	spawn_platform(x_pos, y_pos, p_width, true)
	last_spawn_x = x_pos + p_width

func spawn_platform(x_pos, y_pos, p_width, can_spawn_obstacles):
	var p = platform_scene.instantiate()
	p.position = Vector2(x_pos, y_pos)
	
	p.get_node("ColorRect").size.x = p_width
	var col = p.get_node("CollisionShape2D")
	col.shape = col.shape.duplicate()
	col.shape.size.x = p_width
	col.position.x = p_width / 2.0
	
	add_child(p)
	active_platforms.append(p)

	if can_spawn_obstacles and p_width > 500 and randf() > 0.7:
		var obs = obstacle_scene.instantiate()
		var safe_margin = 150.0
		obs.position = Vector2(randf_range(safe_margin, p_width - safe_margin), -40)
		p.add_child(obs)

func restart_game():
	get_tree().reload_current_scene()
