extends Node2D

const ARENA := Rect2(32, 48, 896, 444)
const PLAYER_SPEED := 240.0
const BOSS_SPEED := 78.0

var player_pos := Vector2(250, 270)
var boss_pos := Vector2(700, 270)
var player_hp := 100
var boss_hp := 300
var attack_cooldown := 0.0
var skill_cooldown := 0.0
var hurt_cooldown := 0.0
var message := "DARK LORD AKTEYNT AWAKENS"
var message_time := 2.5
var touch_direction := Vector2.ZERO
var move_touch_id := -1
var attack_requested := false
var skill_requested := false

func _process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	skill_cooldown = maxf(0.0, skill_cooldown - delta)
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	message_time = maxf(0.0, message_time - delta)

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

	player_pos += direction * PLAYER_SPEED * delta
	player_pos.x = clampf(player_pos.x, ARENA.position.x + 22.0, ARENA.end.x - 22.0)
	player_pos.y = clampf(player_pos.y, ARENA.position.y + 22.0, ARENA.end.y - 22.0)

	if Input.is_key_pressed(KEY_SPACE) or attack_requested:
		_do_attack()
	if Input.is_key_pressed(KEY_E) or skill_requested:
		_do_skill()
	attack_requested = false
	skill_requested = false

	if boss_hp > 0:
		var to_player := player_pos - boss_pos
		if to_player.length() > 86.0:
			boss_pos += to_player.normalized() * BOSS_SPEED * delta
		elif hurt_cooldown <= 0.0:
			player_hp = maxi(0, player_hp - 8)
			hurt_cooldown = 0.8
			message = "AKTEYNT STRIKES!"
			message_time = 0.7

	queue_redraw()

func _do_attack() -> void:
	if attack_cooldown > 0.0 or boss_hp <= 0:
		return
	attack_cooldown = 0.42
	if player_pos.distance_to(boss_pos) <= 118.0:
		boss_hp = maxi(0, boss_hp - 18)
		message = "DARK SLASH  -18"
		message_time = 0.6
		if boss_hp == 0:
			message = "THE DARK LORD HAS FALLEN"
			message_time = 5.0

func _do_skill() -> void:
	if skill_cooldown > 0.0 or boss_hp <= 0:
		return
	skill_cooldown = 4.0
	if player_pos.distance_to(boss_pos) <= 230.0:
		boss_hp = maxi(0, boss_hp - 42)
		message = "ABYSS NOVA  -42"
		message_time = 0.9
		if boss_hp == 0:
			message = "THE DARK LORD HAS FALLEN"
			message_time = 5.0
	else:
		message = "MOVE CLOSER TO USE ABYSS NOVA"
		message_time = 0.9

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var screen_size := get_viewport_rect().size
		if event.pressed:
			if event.position.x < screen_size.x * 0.40 and event.position.y > screen_size.y * 0.48:
				move_touch_id = event.index
				var center := Vector2(100.0, screen_size.y - 90.0)
				touch_direction = ((event.position - center) / 52.0).limit_length(1.0)
			elif event.position.x > screen_size.x * 0.72 and event.position.y > screen_size.y * 0.60:
				if event.position.x > screen_size.x * 0.86:
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

	draw_circle(player_pos, 34.0, Color(0.22, 0.65, 1.0, 0.12))
	draw_circle(player_pos, 21.0, Color("#4bc7ff"))
	draw_circle(player_pos + Vector2(0, -5), 9.0, Color("#d8f5ff"))
	draw_line(player_pos + Vector2(12, 5), player_pos + Vector2(29, -10), Color("#e8f7ff"), 5.0)

	if boss_hp > 0:
		draw_circle(boss_pos, 58.0, Color(0.72, 0.08, 0.95, 0.12))
		draw_circle(boss_pos, 42.0, Color("#321044"))
		draw_circle(boss_pos, 34.0, Color("#8b21b8"))
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
	draw_string(ThemeDB.fallback_font, Vector2(28, 47), "TOP-DOWN COMBAT PROTOTYPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#a89abf"))
	_draw_bar(Vector2(28, 62), 230.0, 16.0, float(player_hp) / 100.0, Color("#45d5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 98), "HERO  %d / 100" % player_hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	_draw_bar(Vector2(screen_size.x - 278, 62), 250.0, 18.0, float(boss_hp) / 300.0, Color("#d14aff"))
	draw_string(ThemeDB.fallback_font, Vector2(screen_size.x - 278, 98), "DARK LORD AKTEYNT  %d / 300" % boss_hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(0, 132), message, HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 18, Color("#f0d7ff"))

	draw_circle(Vector2(100, screen_size.y - 90), 54.0, Color(0.45, 0.35, 0.65, 0.20))
	draw_circle(Vector2(100, screen_size.y - 90), 54.0, Color(0.72, 0.55, 1.0, 0.7), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(48, screen_size.y - 84), "MOVE", HORIZONTAL_ALIGNMENT_CENTER, 104, 13, Color.WHITE)
	_draw_button(Vector2(screen_size.x - 164, screen_size.y - 104), "ATTACK", Color("#8e37c7"))
	_draw_button(Vector2(screen_size.x - 78, screen_size.y - 104), "SKILL", Color("#bd267f"))
	draw_string(ThemeDB.fallback_font, Vector2(20, screen_size.y - 14), "PC: WASD/ARROWS move | SPACE attack | E skill", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#b6a8c9"))

func _draw_bar(pos: Vector2, width: float, height: float, ratio: float, fill: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, height)), Color("#342840"), true)
	draw_rect(Rect2(pos, Vector2(width * clampf(ratio, 0.0, 1.0), height)), fill, true)
	draw_rect(Rect2(pos, Vector2(width, height)), Color("#d9c6f5"), false, 1.0)

func _draw_button(center: Vector2, label: String, color: Color) -> void:
	draw_circle(center, 35.0, Color(color.r, color.g, color.b, 0.22))
	draw_circle(center, 29.0, color, false, 3.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-34, 5), label, HORIZONTAL_ALIGNMENT_CENTER, 68, 10, Color.WHITE)
