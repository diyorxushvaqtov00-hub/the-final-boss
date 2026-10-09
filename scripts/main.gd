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

var player_pos := Vector2(250, 270)
var boss_pos := Vector2(700, 270)
var player_hp := PLAYER_MAX_HP
var boss_hp := BOSS_MAX_HP
var attack_cooldown := 0.0
var skill_cooldown := 0.0
var hurt_cooldown := 0.0
var message := "DARK LORD AKTEYNT AWAKENS"
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

func _process(delta: float) -> void:
	if game_over:
		queue_redraw()
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	skill_cooldown = maxf(0.0, skill_cooldown - delta)
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	message_time = maxf(0.0, message_time - delta)
	boss_attack_cooldown = maxf(0.0, boss_attack_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	slash_timer = maxf(0.0, slash_timer - delta)
	nova_timer = maxf(0.0, nova_timer - delta)
	orb_cooldown = maxf(0.0, orb_cooldown - delta)
	orb_windup = maxf(0.0, orb_windup - delta)

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
		player_pos += dash_direction * DASH_SPEED * delta
	else:
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

	if phase_two and distance > 165.0 and orb_cooldown <= 0.0 and orb_windup <= 0.0:
		orb_windup = 0.65
		message = "AKTEYNT SUMMONS AN ABYSS ORB!"
		message_time = 0.65
	elif orb_windup > 0.0 and orb_windup <= 0.05:
		_spawn_boss_orb()
		orb_cooldown = 2.4
	if boss_windup > 0.0:
		boss_windup = maxf(0.0, boss_windup - delta)
		if boss_windup == 0.0:
			if player_pos.distance_to(boss_pos) <= (145.0 if phase_two else 120.0):
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
	message = "ABYSS STEP"
	message_time = 0.35

func _do_attack() -> void:
	if attack_cooldown > 0.0 or boss_hp <= 0 or game_over:
		return
	attack_cooldown = 0.42
	slash_timer = 0.20
	var to_boss := boss_pos - player_pos
	if to_boss.length() <= 118.0 and (to_boss.length() < 0.01 or facing.dot(to_boss.normalized()) > -0.25):
		boss_hp = maxi(0, boss_hp - 18)
		hit_flash = 0.18
		message = "DARK SLASH  -18"
		message_time = 0.6
		_check_victory()

func _do_skill() -> void:
	if skill_cooldown > 0.0 or boss_hp <= 0 or game_over:
		return
	skill_cooldown = 4.0
	nova_timer = 0.42
	if player_pos.distance_to(boss_pos) <= 230.0:
		boss_hp = maxi(0, boss_hp - 42)
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
		message = "THE DARK LORD HAS FALLEN"
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
	facing = Vector2.RIGHT
	game_over = false
	victory = false
	message = "DARK LORD AKTEYNT AWAKENS"
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
	draw_rect(ARENA, Color("#151025"), true)

	for x in range(int(ARENA.position.x), int(ARENA.end.x), 48):
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color(0.38, 0.22, 0.58, 0.16), 1.0)
	for y in range(int(ARENA.position.y), int(ARENA.end.y), 48):
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), Color(0.38, 0.22, 0.58, 0.16), 1.0)
	draw_rect(ARENA, Color("#9b5cff"), false, 3.0)

	for pillar in [Vector2(95, 100), Vector2(865, 100), Vector2(95, 440), Vector2(865, 440)]:
		draw_circle(pillar, 18.0, Color("#302047"))
		draw_circle(pillar, 18.0, Color("#a66bff"), false, 2.0)

	if hit_flash > 0.0 and hurt_cooldown > 0.0:
		draw_circle(player_pos, 39.0, Color(1.0, 0.15, 0.25, 0.25))
	if dash_timer > 0.0:
		draw_line(player_pos - dash_direction * 46.0, player_pos - dash_direction * 12.0, Color(0.35, 0.82, 1.0, 0.75), 8.0)
	if nova_timer > 0.0:
		var nova_progress := 1.0 - nova_timer / 0.42
		draw_circle(player_pos, 230.0 * nova_progress, Color(0.78, 0.20, 1.0, 0.18), true)
		draw_circle(player_pos, 230.0 * nova_progress, Color(0.88, 0.48, 1.0, 0.8), false, 4.0)
	if slash_timer > 0.0:
		draw_arc(player_pos + facing * 22.0, 48.0, facing.angle() - 1.0, facing.angle() + 1.0, 18, Color(0.75, 0.93, 1.0, 0.95), 7.0)
	draw_circle(player_pos, 34.0, Color(0.22, 0.65, 1.0, 0.12))
	draw_circle(player_pos, 21.0, Color("#4bc7ff"))
	draw_circle(player_pos + Vector2(0, -5), 9.0, Color("#d8f5ff"))
	draw_line(player_pos, player_pos + facing * 31.0, Color("#e8f7ff"), 5.0)

	for orb in boss_orbs:
		var orb_pos: Vector2 = orb["pos"]
		draw_circle(orb_pos, 22.0, Color(0.72, 0.12, 1.0, 0.20))
		draw_circle(orb_pos, 13.0, Color("#d85bff"))
		draw_circle(orb_pos, 5.0, Color("#fff0ff"))
	if orb_windup > 0.0:
		draw_circle(boss_pos, 82.0, Color("#c74aff"), false, 4.0)
	if boss_hp > 0:
		var boss_color := Color("#d14aff") if boss_hp > 150 else Color("#ff367e")
		draw_circle(boss_pos, 62.0, Color(boss_color.r, boss_color.g, boss_color.b, 0.12))
		if boss_windup > 0.0:
			draw_circle(boss_pos, 70.0, Color("#ff3c75"), false, 4.0)
		draw_circle(boss_pos, 42.0, Color("#321044"))
		draw_circle(boss_pos, 34.0, boss_color)
		draw_colored_polygon(PackedVector2Array([
			boss_pos + Vector2(-28, -26), boss_pos + Vector2(-23, -53),
			boss_pos + Vector2(-8, -34), boss_pos + Vector2(0, -45),
			boss_pos + Vector2(11, -34), boss_pos + Vector2(28, -52),
			boss_pos + Vector2(25, -20)
		]), Color("#d9a8ff"))
		draw_circle(boss_pos + Vector2(-12, -4), 4.0, Color("#ff2f9b"))
		draw_circle(boss_pos + Vector2(12, -4), 4.0, Color("#ff2f9b"))
	else:
		draw_circle(boss_pos, 22.0, Color(0.55, 0.25, 0.75, 0.35))

	draw_string(ThemeDB.fallback_font, Vector2(28, 28), "THE FINAL BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e8d8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 47), "ABYSS ARENA  |  PHASE %d" % (2 if boss_hp <= 150 else 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#a89abf"))
	_draw_bar(Vector2(28, 62), 230.0, 16.0, float(player_hp) / PLAYER_MAX_HP, Color("#45d5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 98), "HERO  %d / %d" % [player_hp, PLAYER_MAX_HP], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	_draw_bar(Vector2(screen_size.x - 278, 62), 250.0, 18.0, float(boss_hp) / BOSS_MAX_HP, Color("#d14aff") if boss_hp > 150 else Color("#ff367e"))
	draw_string(ThemeDB.fallback_font, Vector2(screen_size.x - 278, 98), "DARK LORD AKTEYNT  %d / %d" % [boss_hp, BOSS_MAX_HP], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(0, 132), message, HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 18, Color("#f0d7ff"))

	draw_circle(Vector2(100, screen_size.y - 90), 54.0, Color(0.45, 0.35, 0.65, 0.20))
	draw_circle(Vector2(100, screen_size.y - 90), 54.0, Color(0.72, 0.55, 1.0, 0.7), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(48, screen_size.y - 84), "MOVE", HORIZONTAL_ALIGNMENT_CENTER, 104, 13, Color.WHITE)
	_draw_button(Vector2(screen_size.x - 220, screen_size.y - 104), "ATTACK", Color("#8e37c7"))
	_draw_button(Vector2(screen_size.x - 135, screen_size.y - 104), "SKILL", Color("#bd267f"))
	_draw_button(Vector2(screen_size.x - 55, screen_size.y - 104), "DASH", Color("#2a9bd6"))
	draw_string(ThemeDB.fallback_font, Vector2(screen_size.x - 258, screen_size.y - 52), "Skill: %.1fs   Dash: %.1fs" % [skill_cooldown, dash_cooldown], HORIZONTAL_ALIGNMENT_LEFT, 250, 10, Color("#d7c4ef"))
	draw_string(ThemeDB.fallback_font, Vector2(20, screen_size.y - 14), "PC: WASD/ARROWS move | SPACE attack | E skill | SHIFT dash | R restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#b6a8c9"))

	if game_over:
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.02, 0.01, 0.05, 0.78), true)
		var headline := "VICTORY" if victory else "DEFEATED"
		draw_string(ThemeDB.fallback_font, Vector2(0, screen_size.y * 0.43), headline, HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 34, Color("#f0d7ff"))
		draw_string(ThemeDB.fallback_font, Vector2(0, screen_size.y * 0.52), "TAP TO PLAY AGAIN  |  PRESS R", HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 16, Color("#bca5d8"))

func _draw_bar(pos: Vector2, width: float, height: float, ratio: float, fill: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, height)), Color("#342840"), true)
	draw_rect(Rect2(pos, Vector2(width * clampf(ratio, 0.0, 1.0), height)), fill, true)
	draw_rect(Rect2(pos, Vector2(width, height)), Color("#d9c6f5"), false, 1.0)

func _draw_button(center: Vector2, label: String, color: Color) -> void:
	draw_circle(center, 35.0, Color(color.r, color.g, color.b, 0.22))
	draw_circle(center, 29.0, color, false, 3.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-34, 5), label, HORIZONTAL_ALIGNMENT_CENTER, 68, 10, Color.WHITE)
