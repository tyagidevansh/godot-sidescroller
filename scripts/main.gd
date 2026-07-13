extends Node2D

const SPAWN_AHEAD_DISTANCE = 2000.0
const DESPAWN_BEHIND_DISTANCE = 1500.0

var platform_scene = preload("res://scenes/platform.tscn")
var enemy_scene    = preload("res://scenes/enemy.tscn")
var crystal_scene  = preload("res://scenes/crystal.tscn")

var player: CharacterBody2D
var camera: Camera2D

var last_spawn_x = 0.0
var active_platforms = []
var time_elapsed = 0.0
var crystals_collected = 0

# ── Zone system ─────────────────────────────────────────────────────────────
enum Zone { BLUE, BLACK }
var current_zone: Zone = Zone.BLUE
var zone_end_x:   float = 10000.0         # first zone: ~20s at 500px/s
# Blue zone -> platform style 1 (blue stone)
# Black zone -> platform styles 0 (orange industrial) or 2 (lava)
var zone_styles := [1]

func _ready():
	player = $Player
	camera = $Camera2D

	if current_zone == Zone.BLUE:
		zone_styles = [1]
	else:
		zone_styles = [0, 2]
	$Background.zone_changed.connect(_on_zone_changed)

	spawn_platform(0.0, 380.0, 1100.0, false, zone_styles[0])
	last_spawn_x = 1100.0
	for i in range(6):
		generate_next_platform()

var current_camera_offset: float = 150.0

func _process(delta):
	if player == null:
		return

	if not player.is_dead:
		time_elapsed += delta
		player.current_speed = min(900.0, 380.0 + time_elapsed * 12.0)

		var dist_score = int(player.position.x / 80.0)
		$HUD/ScoreLabel.text = str(dist_score + crystals_collected * 10)
		$HUD/CrystalLabel.text = "x" + str(crystals_collected)

		# Camera tracking with mistakes logic
		var target_camera_offset = 150.0 + (player.mistakes * 150.0)
		current_camera_offset = lerp(current_camera_offset, target_camera_offset, delta * 2.0)
		
		camera.position.x = player.position.x + current_camera_offset
		var target_y = lerp(camera.position.y, player.position.y - 30.0, delta * 4.0)
		camera.position.y = clamp(target_y, 150.0, 550.0)

	elif not $HUD/GameOver.visible:
		$HUD/GameOver.visible = true

	while last_spawn_x < player.position.x + SPAWN_AHEAD_DISTANCE:
		generate_next_platform()

	for i in range(active_platforms.size() - 1, -1, -1):
		var p = active_platforms[i]
		if p.position.x < player.position.x - DESPAWN_BEHIND_DISTANCE:
			p.queue_free()
			active_platforms.remove_at(i)

	# Pit death: player fell too far below the camera view
	if player.position.y > camera.position.y + 500.0 and not player.is_dead:
		player.die()

func generate_next_platform():
	var max_gap = player.current_speed * 0.68
	var gap_x   = randf_range(90.0, max_gap)
	var x_pos   = last_spawn_x + gap_x

	var last_y = 380.0
	if active_platforms.size() > 0:
		last_y = active_platforms[-1].position.y
	var y_pos = clamp(last_y + randf_range(-110.0, 110.0), 180.0, 560.0)

	var p_width = randf_range(280.0, 750.0)
	# Pick a platform style valid for the current zone
	var platform_style = zone_styles[randi() % zone_styles.size()]

	# 30% chance: spawn a second fork platform at the same X but different Y.
	# One fork gets crystals, the other gets an enemy — creates a meaningful choice.
	if randf() < 0.30:
		var fork_dir = 1.0
		if y_pos > 400.0:
			fork_dir = -1.0 # Force fork upwards if we're near the bottom
		elif y_pos < 300.0:
			fork_dir = 1.0  # Force fork downwards if we're near the top
		else:
			fork_dir = sign(randf() - 0.5)
			
		var fork_y = y_pos + randf_range(140.0, 200.0) * fork_dir
		fork_y = clamp(fork_y, 180.0, 560.0)
		
		var fork_width = randf_range(200.0, 500.0)
		# Top fork: crystals only
		spawn_platform(x_pos, min(y_pos, fork_y), p_width, true, platform_style, true, false)
		# Bottom fork: enemy only
		spawn_platform(x_pos, max(y_pos, fork_y), fork_width, true, platform_style, false, true)
		last_spawn_x = x_pos + max(p_width, fork_width)
	else:
		spawn_platform(x_pos, y_pos, p_width, true, platform_style, true, true)
		last_spawn_x = x_pos + p_width

func spawn_platform(x_pos: float, y_pos: float, p_width: float, can_decorate: bool, style: int = 0, spawn_crystals: bool = true, spawn_enemy: bool = true):
	var p = platform_scene.instantiate()
	p.position = Vector2(x_pos, y_pos)
	add_child(p)
	p.setup_platform(p_width, style)
	active_platforms.append(p)

	if not can_decorate:
		return

	if spawn_enemy and p_width > 400.0 and randf() > 0.50:
		var e = enemy_scene.instantiate()
		e.position = Vector2(randf_range(80.0, p_width - 80.0), -30.0)
		p.add_child(e)

	if spawn_crystals and randf() > 0.35:
		var num_crystals = randi_range(1, 3)
		var start_x = (p_width - (num_crystals * 40.0)) / 2.0
		for i in range(num_crystals):
			var c = crystal_scene.instantiate()
			# Line them up neatly in the middle of the platform, spaced 40px apart
			c.position = Vector2(start_x + (i * 40.0) + 20.0, -45.0 - (i % 2) * 15.0)
			c.crystal_collected.connect(_on_crystal_collected)
			p.add_child(c)

func _on_crystal_collected():
	crystals_collected += 1

func _on_zone_changed(new_zone: int) -> void:
	current_zone = new_zone
	if current_zone == Zone.BLUE:
		zone_styles = [1]
	else:
		zone_styles = [0, 2]
	
	# Update any platforms that were already spawned ahead of the player!
	for p in active_platforms:
		if p.position.x > player.position.x:
			var new_style = zone_styles[randi() % zone_styles.size()]
			# collision.shape.size.x contains the width of the platform
			p.setup_platform(p.get_node("CollisionShape2D").shape.size.x, new_style)

func restart_game():
	get_tree().reload_current_scene()
