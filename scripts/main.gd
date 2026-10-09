extends Node2D

const ARENA := Rect2(32, 48, 896, 444)
const PLAYER_SPEED := 240.0
const DASH_SPEED := 690.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 1.6
const BOSS_SPEED_PHASE_ONE := 78.0
const BOSS_SPEED_PHASE_TWO := 112.0
const PLAYER_MAX_HP := 100
const BOSS_MAX_HP := 300
const HERO_TEXTURE = preload("res://assets/hero.svg")
const AKTEYNT_TEXTURE = preload("res://assets/akteynt.svg")

var player_pos := Vector2(250, 270)
var boss_pos := Vector2(700, 270)
var player_hp := PLAYER_MAX_HP
var boss_hp := BOSS_MAX_HP
var attack_cooldown := 0.0
var skill_cooldown := 0.0
var hurt_cooldown := 0.0
var message := "AKTEYNT • ABYSS EMPRESS AWAKENS"
var message_time := 2.5
var touch_direction := Vector2.ZERO
var move_touch_id := -1
var attack_requested := false
var skill_requested := false
var facing := Vector2.RIGHT
var game_over := false
var victory := false
var boss_windup := 0.0
var boss_attack_cooldown := 0.0
var hit_flash := 0.0
var phase_two_announced := false
var dash_timer := 0.0
var dash_cooldown := 0.0
var dash_direction := Vector2.RIGHT
var dash_requested := false
var slash_timer := 0.0
var nova_timer := 0.0
var orb_windup := 0.0
var orb_cooldown := 0.0
var boss_orbs: Array[Dictionary] = []
var hit_particles: Array[Dictionary] = []
var boss_strike_timer := 0.0
var boss_hit_flash := 0.0
var arena_time := 0.0
var hero_trail_timer := 0.0
var footstep_timer := 0.0
var hero_afterimages: Array[Dictionary] = []
var combo_step := 0
var combo_chain_timer := 0.0
var combo_flash_timer := 0.0
var boss_wave_timer := 0.0
var boss_wave_radius := 0.0
var boss_wave_hit := false
var boss_wave_cooldown := 0.0

func _process(delta: float) -> void:
	if game_over:
		queue_redraw()
		return

	arena_time += delta
	hero_trail_timer = maxf(0.0, hero_trail_timer - delta)
	footstep_timer = maxf(0.0, footstep_timer - delta)
	_update_hero_afterimages(delta)
	combo_chain_timer = maxf(0.0, combo_chain_timer - delta)
	combo_flash_timer = maxf(0.0, combo_flash_timer - delta)
	boss_wave_cooldown = maxf(0.0, boss_wave_cooldown - delta)
	if combo_chain_timer <= 0.0:
		combo_step = 0
	if boss_wave_timer > 0.0:
		boss_wave_timer = maxf(0.0, boss_wave_timer - delta)
		boss_wave_radius = (1.0 - boss_wave_timer / 0.72) * 250.0
		if not boss_wave_hit and absf(player_pos.distance_to(boss_pos) - boss_wave_radius) < 22.0 and dash_timer <= 0.0:
			boss_wave_hit = true
			_damage_player(22)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	skill_cooldown = maxf(0.0, skill_cooldown - delta)
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	message_time = maxf(0.0, message_time - delta)
	boss_attack_cooldown = maxf(0.0, boss_attack_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	boss_hit_flash = maxf(0.0, boss_hit_flash - delta)
	boss_strike_timer = maxf(0.0, boss_strike_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	slash_timer = maxf(0.0, slash_timer - delta)
	nova_timer = maxf(0.0, nova_timer - delta)
	orb_cooldown = maxf(0.0, orb_cooldown - delta)
	_update_hit_particles(delta)
	if dash_timer > 0.0 and randf() < 0.8:
		_spawn_particles(player_pos - dash_direction * 18.0, Color("#54dcff"), 2, 65.0)
	if orb_windup > 0.0:
		orb_windup = maxf(0.0, orb_windup - delta)
		if orb_windup == 0.0:
			_spawn_boss_orb()
			orb_cooldown = 2.4

	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if touch_direction.length() > 0.1:
		direction = touch_direction
	if direction.length() > 1.0:
		direction = direction.normalized()
	if direction.length() > 0.05:
		facing = direction.normalized()

	if Input.is_key_pressed(KEY_SHIFT) or dash_requested:
		_do_dash(direction)
	dash_requested = false
	if dash_timer > 0.0:
		if hero_trail_timer <= 0.0:
			hero_afterimages.append({"pos": player_pos, "facing": dash_direction.angle(), "life": 0.24, "max_life": 0.24})
			hero_trail_timer = 0.035
		player_pos += dash_direction * DASH_SPEED * delta
	else:
		if direction.length() > 0.1:
			if hero_trail_timer <= 0.0:
				hero_afterimages.append({"pos": player_pos, "facing": facing.angle(), "life": 0.14, "max_life": 0.14})
				hero_trail_timer = 0.085
			if footstep_timer <= 0.0:
				_spawn_particles(player_pos + Vector2(0, 18), Color("#6c70ff"), 2, 28.0)
				footstep_timer = 0.14
		player_pos += direction * PLAYER_SPEED * delta
	player_pos.x = clampf(player_pos.x, ARENA.position.x + 22.0, ARENA.end.x - 22.0)
	player_pos.y = clampf(player_pos.y, ARENA.position.y + 22.0, ARENA.end.y - 22.0)

	if Input.is_key_pressed(KEY_SPACE) or attack_requested:
		_do_attack()
	if Input.is_key_pressed(KEY_E) or skill_requested:
		_do_skill()
	attack_requested = false
	skill_requested = false

	_update_boss(delta)
	_update_boss_orbs(delta)
	queue_redraw()

func _update_boss(delta: float) -> void:
	if boss_hp <= 0:
		return

	var to_player := player_pos - boss_pos
	var distance := to_player.length()
	var phase_two := boss_hp <= 150
	var boss_speed := BOSS_SPEED_PHASE_TWO if phase_two else BOSS_SPEED_PHASE_ONE

	if phase_two and not phase_two_announced:
		phase_two_announced = true
		message = "AKTEYNT ENTERS ABYSS PHASE"
		message_time = 1.8

	if phase_two and distance <= 210.0 and boss_wave_cooldown <= 0.0 and boss_wave_timer <= 0.0 and boss_windup <= 0.0:
		boss_wave_timer = 0.72
		boss_wave_radius = 0.0
		boss_wave_hit = false
		boss_wave_cooldown = 5.5
		message = "ABYSS SHOCKWAVE! DASH THROUGH THE RING!"
		message_time = 0.72
		_spawn_particles(boss_pos, Color("#ff367e"), 14, 110.0)
	if phase_two and distance > 165.0 and orb_cooldown <= 0.0 and orb_windup <= 0.0:
		orb_windup = 0.65
		message = "AKTEYNT SUMMONS AN ABYSS ORB!"
		message_time = 0.65
	if boss_windup > 0.0:
		boss_windup = maxf(0.0, boss_windup - delta)
		if boss_windup == 0.0:
			var strike_direction := to_player.normalized() if distance > 0.01 else Vector2.LEFT
			boss_strike_timer = 0.30
			boss_pos += strike_direction * 18.0
			_spawn_particles(boss_pos, Color("#ff367e") if phase_two else Color("#b95cff"), 10, 95.0)
			if player_pos.distance_to(boss_pos) <= (155.0 if phase_two else 128.0):
				_damage_player(18 if phase_two else 12)
			boss_attack_cooldown = 1.35 if phase_two else 1.8
	elif distance > 92.0:
		boss_pos += to_player.normalized() * boss_speed * delta
	elif boss_attack_cooldown <= 0.0:
		boss_windup = 0.55
		message = "AKTEYNT IS CHARGING A STRIKE!"
		message_time = 0.55

func _spawn_boss_orb() -> void:
	if boss_hp <= 0 or game_over:
		return
	var direction := (player_pos - boss_pos).normalized()
	boss_orbs.append({"pos": boss_pos, "velocity": direction * 230.0, "life": 3.0})
	_spawn_particles(boss_pos, Color("#ce52ff"), 12, 120.0)
	message = "DODGE THE ABYSS ORB!"
	message_time = 0.8

func _update_boss_orbs(delta: float) -> void:
	for i in range(boss_orbs.size() - 1, -1, -1):
		var orb: Dictionary = boss_orbs[i]
		var pos: Vector2 = orb["pos"]
		var velocity: Vector2 = orb["velocity"]
		var life: float = float(orb["life"]) - delta
		pos += velocity * delta
		if pos.distance_to(player_pos) < 25.0:
			_spawn_particles(pos, Color("#ed8bff"), 16, 170.0)
			_damage_player(16)
			boss_orbs.remove_at(i)
		elif life <= 0.0 or not ARENA.has_point(pos):
			boss_orbs.remove_at(i)
		else:
			orb["pos"] = pos
			orb["life"] = life
			boss_orbs[i] = orb

func _damage_player(amount: int) -> void:
	if hurt_cooldown > 0.0 or dash_timer > 0.0 or game_over:
		return
	player_hp = maxi(0, player_hp - amount)
	hurt_cooldown = 0.7
	hit_flash = 0.25
	_spawn_particles(player_pos, Color("#ff477e"), 14, 145.0)
	message = "YOU TOOK %d DAMAGE" % amount
	message_time = 0.8
	if player_hp == 0:
		game_over = true
		victory = false
		message = "YOU HAVE FALLEN"
		message_time = 999.0

func _do_dash(direction: Vector2) -> void:
	if dash_cooldown > 0.0 or game_over:
		return
	dash_direction = direction.normalized() if direction.length() > 0.05 else facing
	dash_timer = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	hit_flash = 0.12
	_spawn_particles(player_pos, Color("#51ddff"), 10, 100.0)
	message = "ABYSS STEP"
	message_time = 0.35

func _do_attack() -> void:
	if attack_cooldown > 0.0 or boss_hp <= 0 or game_over:
		return
	combo_step = (combo_step % 3) + 1 if combo_chain_timer > 0.0 else 1
	combo_chain_timer = 0.72
	combo_flash_timer = 0.24
	attack_cooldown = 0.32 if combo_step == 1 else (0.28 if combo_step == 2 else 0.48)
	slash_timer = 0.16 if combo_step < 3 else 0.30
	var to_boss := boss_pos - player_pos
	var combo_damage := 12 if combo_step == 1 else (16 if combo_step == 2 else 26)
	var combo_reach := 118.0 if combo_step < 3 else 142.0
	if to_boss.length() <= combo_reach and (to_boss.length() < 0.01 or facing.dot(to_boss.normalized()) > -0.25):
		boss_hp = maxi(0, boss_hp - combo_damage)
		boss_hit_flash = 0.22 if combo_step < 3 else 0.34
		_spawn_particles(boss_pos, Color("#9bf3ff") if combo_step < 3 else Color("#ffffff"), 18 if combo_step < 3 else 30, 190.0 if combo_step < 3 else 280.0)
		hit_flash = 0.18
		message = "COMBO %d  -%d" % [combo_step, combo_damage]
		message_time = 0.6
		_check_victory()
	else:
		message = "COMBO %d" % combo_step
		message_time = 0.35

func _do_skill() -> void:
	if skill_cooldown > 0.0 or boss_hp <= 0 or game_over:
		return
	skill_cooldown = 4.0
	nova_timer = 0.42
	if player_pos.distance_to(boss_pos) <= 230.0:
		boss_hp = maxi(0, boss_hp - 42)
		boss_hit_flash = 0.28
		_spawn_particles(boss_pos, Color("#d55cff"), 28, 230.0)
		hit_flash = 0.24
		message = "ABYSS NOVA  -42"
		message_time = 0.9
		_check_victory()
	else:
		message = "MOVE CLOSER TO USE ABYSS NOVA"
		message_time = 0.9

func _check_victory() -> void:
	if boss_hp <= 0:
		game_over = true
		victory = true
		message = "THE ABYSS EMPRESS HAS FALLEN"
		message_time = 999.0

func _restart() -> void:
	player_pos = Vector2(250, 270)
	boss_pos = Vector2(700, 270)
	player_hp = PLAYER_MAX_HP
	boss_hp = BOSS_MAX_HP
	attack_cooldown = 0.0
	skill_cooldown = 0.0
	hurt_cooldown = 0.0
	boss_windup = 0.0
	boss_attack_cooldown = 0.0
	hit_flash = 0.0
	dash_timer = 0.0
	dash_cooldown = 0.0
	dash_direction = Vector2.RIGHT
	slash_timer = 0.0
	nova_timer = 0.0
	dash_requested = false
	phase_two_announced = false
	orb_windup = 0.0
	orb_cooldown = 0.0
	boss_orbs.clear()
	hit_particles.clear()
	boss_strike_timer = 0.0
	boss_hit_flash = 0.0
	combo_step = 0
	combo_chain_timer = 0.0
	combo_flash_timer = 0.0
	boss_wave_timer = 0.0
	boss_wave_radius = 0.0
	boss_wave_hit = false
	boss_wave_cooldown = 0.0
	arena_time = 0.0
	hero_trail_timer = 0.0
	footstep_timer = 0.0
	hero_afterimages.clear()
	facing = Vector2.RIGHT
	game_over = false
	victory = false
	message = "AKTEYNT • ABYSS EMPRESS AWAKENS"
	message_time = 2.0

func _input(event: InputEvent) -> void:
	if game_over:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
			_restart()
		elif event is InputEventScreenTouch and event.pressed:
			_restart()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_restart()
		return

	if event is InputEventScreenTouch:
		var screen_size := get_viewport_rect().size
		if event.pressed:
			if event.position.x < screen_size.x * 0.40 and event.position.y > screen_size.y * 0.48:
				move_touch_id = event.index
				var center := Vector2(100.0, screen_size.y - 90.0)
				touch_direction = ((event.position - center) / 52.0).limit_length(1.0)
			elif event.position.x > screen_size.x * 0.70 and event.position.y > screen_size.y * 0.60:
				if event.position.x > screen_size.x * 0.92:
					dash_requested = true
				elif event.position.x > screen_size.x * 0.83:
					skill_requested = true
				else:
					attack_requested = true
		elif event.index == move_touch_id:
			move_touch_id = -1
			touch_direction = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == move_touch_id:
		var screen_size := get_viewport_rect().size
		var center := Vector2(100.0, screen_size.y - 90.0)
		touch_direction = ((event.position - center) / 52.0).limit_length(1.0)

func _draw() -> void:
	var screen_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#090713"), true)
	var abyss_phase := boss_hp <= 150
	var floor_tint := Color("#1b0b20") if abyss_phase else Color("#151025")
	draw_rect(ARENA, floor_tint, true)
	# Distant cathedral silhouettes frame the duel without covering the fighters.
	for tower_index in range(7):
		var tower_x := ARENA.position.x + 58.0 + float(tower_index) * 130.0
		var tower_height := 42.0 + float((tower_index * 37) % 56)
		var tower_base := ARENA.position.y + 20.0
		draw_colored_polygon(PackedVector2Array([Vector2(tower_x - 18, tower_base), Vector2(tower_x - 11, tower_base - tower_height), Vector2(tower_x, tower_base - tower_height - 17), Vector2(tower_x + 11, tower_base - tower_height), Vector2(tower_x + 18, tower_base)]), Color(0.035, 0.018, 0.065, 0.92))
		draw_line(Vector2(tower_x, tower_base - tower_height - 12), Vector2(tower_x, tower_base - tower_height + 7), Color(0.63, 0.22, 0.78, 0.30), 2.0)
	# Layered obsidian floor: fine grid, central ritual seal, and animated runes.
	for x in range(int(ARENA.position.x), int(ARENA.end.x), 48):
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color(0.38, 0.22, 0.58, 0.16), 1.0)
	for y in range(int(ARENA.position.y), int(ARENA.end.y), 48):
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), Color(0.38, 0.22, 0.58, 0.16), 1.0)
	draw_rect(ARENA, Color("#9b5cff"), false, 3.0)
	var seal_center := ARENA.position + ARENA.size * 0.5
	var seal_pulse := 0.5 + 0.5 * sin(arena_time * 1.6)
	draw_circle(seal_center, 154.0, Color(0.28, 0.08, 0.48, 0.05 + seal_pulse * 0.035), true)
	draw_arc(seal_center, 150.0, 0.0, TAU, 120, Color(0.55, 0.25, 0.85, 0.22 + seal_pulse * 0.12), 2.0)
	draw_arc(seal_center, 128.0, arena_time * 0.12, arena_time * 0.12 + TAU, 96, Color(0.25, 0.65, 1.0, 0.16), 1.5)
	draw_arc(seal_center, 104.0, -arena_time * 0.18, -arena_time * 0.18 + TAU, 72, Color(0.72, 0.32, 1.0, 0.25), 2.0)
	for rune_index in range(12):
		var rune_angle := TAU * float(rune_index) / 12.0 + arena_time * 0.035
		var rune_inner := seal_center + Vector2.RIGHT.rotated(rune_angle) * 112.0
		var rune_outer := seal_center + Vector2.RIGHT.rotated(rune_angle + 0.035) * 137.0
		draw_line(rune_inner, rune_outer, Color(0.68, 0.46, 1.0, 0.30 + seal_pulse * 0.20), 2.0)
	# Broken stone seams and distant floating embers add depth without heavy textures.
	for crack_index in range(7):
		var crack_x := 145.0 + float(crack_index) * 112.0
		var crack_y := 145.0 + float((crack_index * 67) % 230)
		draw_line(Vector2(crack_x, crack_y), Vector2(crack_x + 12.0, crack_y + 9.0), Color(0.62, 0.38, 0.85, 0.16), 2.0)
		draw_line(Vector2(crack_x + 12.0, crack_y + 9.0), Vector2(crack_x + 22.0, crack_y + 5.0), Color(0.62, 0.38, 0.85, 0.12), 1.0)
	for ember_index in range(18):
		var ember_x := 48.0 + float((ember_index * 137) % 860)
		var ember_y := 58.0 + float((ember_index * 79) % 420)
		var ember_blink := 0.20 + 0.30 * (0.5 + 0.5 * sin(arena_time * (1.2 + float(ember_index % 4) * 0.3) + float(ember_index)))
		draw_circle(Vector2(ember_x, ember_y), 1.5 + ember_blink, Color(0.68, 0.45, 1.0, ember_blink))

	for pillar in [Vector2(95, 100), Vector2(865, 100), Vector2(95, 440), Vector2(865, 440)]:
		draw_circle(pillar, 24.0, Color("#302047"))
		draw_circle(pillar, 18.0, Color("#a66bff"), false, 2.0)
		draw_line(pillar + Vector2(-12, -10), pillar + Vector2(0, -29), Color("#d35cff"), 3.0)
		draw_line(pillar + Vector2(0, -29), pillar + Vector2(12, -10), Color("#d35cff"), 3.0)
	# Floating rune shards orbit the arena seal, brightening when the Empress enrages.
	for shard_index in range(16):
		var shard_angle := TAU * float(shard_index) / 16.0 - arena_time * (0.12 if abyss_phase else 0.055)
		var shard_radius := 176.0 + sin(arena_time * 1.7 + float(shard_index)) * 5.0
		var shard_pos := seal_center + Vector2.RIGHT.rotated(shard_angle) * shard_radius
		var shard_color := Color("#ff347e") if abyss_phase else Color("#a75bff")
		draw_colored_polygon(PackedVector2Array([shard_pos + Vector2(0, -5), shard_pos + Vector2(3, 0), shard_pos + Vector2(0, 5), shard_pos + Vector2(-3, 0)]), shard_color)
	# The boss's eclipse halo expands during the second phase.
	var eclipse_center := boss_pos + Vector2(0, -49)
	var eclipse_radius := 43.0 if not abyss_phase else 55.0 + sin(arena_time * 3.0) * 3.0
	draw_arc(eclipse_center, eclipse_radius, 0.0, TAU, 64, Color(0.95, 0.22, 0.70, 0.28 if not abyss_phase else 0.52), 2.0)
	for ray_index in range(12):
		var ray_angle := TAU * float(ray_index) / 12.0 + arena_time * 0.12
		var ray_start := eclipse_center + Vector2.RIGHT.rotated(ray_angle) * (eclipse_radius + 3.0)
		var ray_end := eclipse_center + Vector2.RIGHT.rotated(ray_angle) * (eclipse_radius + (13.0 if abyss_phase else 8.0))
		draw_line(ray_start, ray_end, Color("#ff5acb") if abyss_phase else Color("#b95cff"), 1.5)

	if hit_flash > 0.0 and hurt_cooldown > 0.0:
		draw_circle(player_pos, 39.0, Color(1.0, 0.15, 0.25, 0.25))
	if dash_timer > 0.0:
		draw_line(player_pos - dash_direction * 46.0, player_pos - dash_direction * 12.0, Color(0.35, 0.82, 1.0, 0.75), 8.0)
	if nova_timer > 0.0:
		var nova_progress := 1.0 - nova_timer / 0.42
		draw_circle(player_pos, 230.0 * nova_progress, Color(0.78, 0.20, 1.0, 0.18), true)
		draw_circle(player_pos, 230.0 * nova_progress, Color(0.88, 0.48, 1.0, 0.8), false, 4.0)
	if boss_wave_timer > 0.0:
		var wave_alpha := clampf(boss_wave_timer / 0.72, 0.0, 1.0)
		draw_circle(boss_pos, 68.0, Color(0.88, 0.12, 0.48, 0.10 + wave_alpha * 0.08), true)
		draw_arc(boss_pos, boss_wave_radius, 0.0, TAU, 96, Color(1.0, 0.18, 0.58, wave_alpha), 8.0)
		draw_arc(boss_pos, boss_wave_radius + 8.0, 0.0, TAU, 96, Color(0.70, 0.25, 1.0, wave_alpha * 0.65), 3.0)
	if slash_timer > 0.0:
		var slash_progress := slash_timer / 0.30
		var slash_color := Color(0.85, 0.96, 1.0, slash_progress) if combo_step < 3 else Color(1.0, 0.45, 0.88, slash_progress)
		draw_arc(player_pos + facing * 22.0, 48.0 + (1.0 - slash_progress) * 25.0, facing.angle() - (1.15 if combo_step < 3 else 1.45), facing.angle() + (1.15 if combo_step < 3 else 1.45), 24, slash_color, 7.0 if combo_step < 3 else 11.0)
	# Motion afterimages are drawn behind the hero, strongest during dash.
	for ghost in hero_afterimages:
		var ghost_pos: Vector2 = ghost["pos"]
		var ghost_angle: float = float(ghost["facing"])
		var ghost_alpha := clampf(float(ghost["life"]) / float(ghost["max_life"]), 0.0, 1.0) * 0.30
		draw_set_transform(ghost_pos, ghost_angle, Vector2.ONE)
		draw_texture_rect(HERO_TEXTURE, Rect2(-38, -38, 76, 76), false, Color(0.35, 0.78, 1.0, ghost_alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Hero sprite: subtle idle bob and a shadow keep the character grounded.
	var hero_bob := sin(Time.get_ticks_msec() * 0.006) * 2.2
	draw_ellipse_shadow(player_pos + Vector2(0, 25), Vector2(24, 8), Color(0.02, 0.01, 0.06, 0.78))
	if hit_flash > 0.0 and hurt_cooldown > 0.0:
		draw_circle(player_pos, 42.0, Color(1.0, 0.15, 0.25, 0.22))
	draw_set_transform(player_pos + Vector2(0, hero_bob), facing.angle(), Vector2.ONE)
	draw_texture_rect(HERO_TEXTURE, Rect2(-49, -49, 98, 98), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Tiny particles make dashes and hits feel responsive without heavy assets.
	for particle in hit_particles:
		var p: Vector2 = particle["pos"]
		var color: Color = particle["color"]
		var life_ratio := clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		draw_circle(p, float(particle["size"]) * life_ratio, Color(color.r, color.g, color.b, life_ratio))

	for orb in boss_orbs:
		var orb_pos: Vector2 = orb["pos"]
		draw_circle(orb_pos, 22.0, Color(0.72, 0.12, 1.0, 0.20))
		draw_circle(orb_pos, 13.0, Color("#d85bff"))
		draw_circle(orb_pos, 5.0, Color("#fff0ff"))
	if orb_windup > 0.0:
		draw_circle(boss_pos, 82.0, Color("#c74aff"), false, 4.0)
	if boss_hp > 0:
		var boss_color := Color("#d14aff") if boss_hp > 150 else Color("#ff367e")
		var boss_bob := sin(Time.get_ticks_msec() * 0.0035 + 1.2) * 2.0
		draw_ellipse_shadow(boss_pos + Vector2(0, 35), Vector2(38, 12), Color(0.02, 0.0, 0.05, 0.88))
		draw_circle(boss_pos, 75.0, Color(boss_color.r, boss_color.g, boss_color.b, 0.10))
		if boss_hit_flash > 0.0:
			draw_circle(boss_pos, 62.0, Color(0.95, 0.85, 1.0, boss_hit_flash * 1.7))
		if boss_windup > 0.0:
			var charge_pulse := 3.0 + sin(Time.get_ticks_msec() * 0.025) * 2.0
			draw_circle(boss_pos, 76.0 + charge_pulse, Color("#ff3c75"), false, 4.0)
		if boss_strike_timer > 0.0:
			var strike_fade := boss_strike_timer / 0.30
			var strike_angle := (player_pos - boss_pos).angle()
			draw_arc(boss_pos, 94.0 + (1.0 - strike_fade) * 24.0, strike_angle - 1.0, strike_angle + 1.0, 24, Color(1.0, 0.16, 0.52, strike_fade), 10.0)
		var boss_scale := 1.0 if boss_hp > 150 else 1.10 + sin(arena_time * 2.8) * 0.025
		var boss_rect := Rect2(boss_pos + Vector2(-82 * boss_scale, -96 * boss_scale + boss_bob), Vector2(164 * boss_scale, 164 * boss_scale))
		draw_texture_rect(AKTEYNT_TEXTURE, boss_rect, false)
	else:
		draw_circle(boss_pos, 35.0, Color(0.55, 0.25, 0.75, 0.25))

	draw_string(ThemeDB.fallback_font, Vector2(28, 28), "THE FINAL BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e8d8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 47), "ABYSS EMPRESS  |  PHASE %d" % (2 if boss_hp <= 150 else 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#a89abf"))
	_draw_bar(Vector2(28, 62), 230.0, 16.0, float(player_hp) / PLAYER_MAX_HP, Color("#45d5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 98), "HERO  %d / %d" % [player_hp, PLAYER_MAX_HP], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	_draw_bar(Vector2(28, 105), 230.0, 4.0, 1.0 - skill_cooldown / 4.0, Color("#b85cff"))
	_draw_bar(Vector2(screen_size.x - 278, 62), 250.0, 18.0, float(boss_hp) / BOSS_MAX_HP, Color("#d14aff") if boss_hp > 150 else Color("#ff367e"))
	draw_string(ThemeDB.fallback_font, Vector2(screen_size.x - 278, 98), "AKTEYNT • ABYSS EMPRESS  %d / %d" % [boss_hp, BOSS_MAX_HP], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(0, 132), message, HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 18, Color("#f0d7ff"))

	draw_circle(Vector2(100, screen_size.y - 90), 54.0, Color(0.45, 0.35, 0.65, 0.20))
	draw_circle(Vector2(100, screen_size.y - 90), 54.0, Color(0.72, 0.55, 1.0, 0.7), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(48, screen_size.y - 84), "MOVE", HORIZONTAL_ALIGNMENT_CENTER, 104, 13, Color.WHITE)
	_draw_button(Vector2(screen_size.x - 220, screen_size.y - 104), "ATTACK", Color("#8e37c7"))
	_draw_button(Vector2(screen_size.x - 135, screen_size.y - 104), "SKILL", Color("#bd267f"))
	_draw_button(Vector2(screen_size.x - 55, screen_size.y - 104), "DASH", Color("#2a9bd6"))
	draw_string(ThemeDB.fallback_font, Vector2(screen_size.x - 258, screen_size.y - 52), "Combo: %d/3   Skill: %.1fs   Dash: %.1fs" % [combo_step, skill_cooldown, dash_cooldown], HORIZONTAL_ALIGNMENT_LEFT, 300, 10, Color("#d7c4ef"))
	draw_string(ThemeDB.fallback_font, Vector2(20, screen_size.y - 14), "PC: WASD/ARROWS move | SPACE attack | E skill | SHIFT dash | R restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#b6a8c9"))

	if game_over:
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.02, 0.01, 0.05, 0.78), true)
		var headline := "VICTORY" if victory else "DEFEATED"
		draw_string(ThemeDB.fallback_font, Vector2(0, screen_size.y * 0.43), headline, HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 34, Color("#f0d7ff"))
		draw_string(ThemeDB.fallback_font, Vector2(0, screen_size.y * 0.52), "TAP TO PLAY AGAIN  |  PRESS R", HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 16, Color("#bca5d8"))

func _spawn_particles(origin: Vector2, color: Color, count: int, power: float) -> void:
	for i in range(count):
		var angle := randf_range(0.0, TAU)
		var speed := randf_range(power * 0.25, power)
		var lifetime := randf_range(0.18, 0.48)
		hit_particles.append({
			"pos": origin + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)),
			"velocity": Vector2.RIGHT.rotated(angle) * speed,
			"life": lifetime,
			"max_life": lifetime,
			"color": color,
			"size": randf_range(2.0, 5.0)
		})

func _update_hero_afterimages(delta: float) -> void:
	for i in range(hero_afterimages.size() - 1, -1, -1):
		var ghost: Dictionary = hero_afterimages[i]
		ghost["life"] = float(ghost["life"]) - delta
		if float(ghost["life"]) <= 0.0:
			hero_afterimages.remove_at(i)
		else:
			hero_afterimages[i] = ghost

func _update_hit_particles(delta: float) -> void:
	for i in range(hit_particles.size() - 1, -1, -1):
		var particle: Dictionary = hit_particles[i]
		var particle_pos: Vector2 = particle["pos"]
		var particle_velocity: Vector2 = particle["velocity"]
		particle["pos"] = particle_pos + particle_velocity * delta
		particle["velocity"] = particle_velocity * 0.90
		particle["life"] = float(particle["life"]) - delta
		if float(particle["life"]) <= 0.0:
			hit_particles.remove_at(i)
		else:
			hit_particles[i] = particle

func draw_ellipse_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
	# Draw a flattened shadow under the sprite, then restore the normal canvas transform.
	draw_set_transform(center, 0.0, Vector2(1.0, radii.y / maxf(radii.x, 1.0)))
	draw_circle(Vector2.ZERO, radii.x, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_bar(pos: Vector2, width: float, height: float, ratio: float, fill: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, height)), Color("#342840"), true)
	draw_rect(Rect2(pos, Vector2(width * clampf(ratio, 0.0, 1.0), height)), fill, true)
	draw_rect(Rect2(pos, Vector2(width, height)), Color("#d9c6f5"), false, 1.0)

func _draw_button(center: Vector2, label: String, color: Color) -> void:
	draw_circle(center, 35.0, Color(color.r, color.g, color.b, 0.22))
	draw_circle(center, 29.0, color, false, 3.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-34, 5), label, HORIZONTAL_ALIGNMENT_CENTER, 68, 10, Color.WHITE)
