extends Node2D

const PLAYER := 1
const ENEMY := 2
const MAP_BG := Color("#202b2b")
const ROAD := Color("#67716a")
const PLAYER_COLOR := Color("#4f9bd8")
const ENEMY_COLOR := Color("#cf6257")
const NEUTRAL_COLOR := Color("#8d9685")
const SELECT_COLOR := Color("#f5d76e")

var regions: Array[Dictionary] = []
var selected_region: int = -1
var turn_number: int = 1
var message: String = "Select one of your blue regions, then tap a connected region."
var game_over: bool = false

var region_names := [
	"West Base", "Old Road", "North Field", "Pine Woods", "River Bend",
	"Village", "Crossroads", "Hill", "Bridge", "Supply Depot",
	"East Field", "Forest Edge", "Rail Junction", "Enemy Camp", "HQ"
]

var links: Array[Vector2i] = []

func _ready() -> void:
	_build_map()
	queue_redraw()

func _build_map() -> void:
	regions.clear()
	links.clear()
	for i in range(15):
		var col := i % 5
		var row := int(i / 5)
		var pos := Vector2(150.0 + col * 245.0, 210.0 + row * 150.0)
		regions.append({
			"name": region_names[i],
			"pos": pos,
			"owner": 0,
			"troops": 1,
			"terrain": "plain"
		})
	for row in range(3):
		for col in range(5):
			var i := row * 5 + col
			if col < 4:
				links.append(Vector2i(i, i + 1))
			if row < 2:
				links.append(Vector2i(i, i + 5))
	links.append(Vector2i(1, 6))
	links.append(Vector2i(3, 7))
	links.append(Vector2i(6, 12))
	links.append(Vector2i(8, 14))
	_set_region(0, PLAYER, 4)
	_set_region(1, PLAYER, 2)
	_set_region(5, PLAYER, 2)
	_set_region(9, ENEMY, 2)
	_set_region(13, ENEMY, 3)
	_set_region(14, ENEMY, 4)
	_set_region(4, 0, 2)
	_set_region(8, 0, 2)
	_set_region(12, 0, 2)

func _set_region(index: int, owner: int, troops: int) -> void:
	regions[index]["owner"] = owner
	regions[index]["troops"] = troops

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), MAP_BG)
	_draw_background_details()
	for link in links:
		var a: Vector2 = regions[link.x]["pos"]
		var b: Vector2 = regions[link.y]["pos"]
		draw_line(a, b, ROAD, 8.0, true)
		draw_line(a, b, Color("#313b36"), 2.0, true)
	for i in range(regions.size()):
		_draw_region(i)
	_draw_hud()

func _draw_background_details() -> void:
	for i in range(16):
		var x := 35.0 + float(i) * 83.0
		draw_line(Vector2(x, 105), Vector2(x - 15, 620), Color(0.7, 0.75, 0.65, 0.045), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(36, 54), "FRONT LINE  /  OPERATION DAWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#e5e2d4"))
	draw_string(ThemeDB.fallback_font, Vector2(36, 82), "OFFLINE CAMPAIGN  •  PROTOTYPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9ca99d"))

func _draw_region(index: int) -> void:
	var region: Dictionary = regions[index]
	var pos: Vector2 = region["pos"]
	var owner: int = region["owner"]
	var troops: int = region["troops"]
	var color: Color = NEUTRAL_COLOR
	if owner == PLAYER:
		color = PLAYER_COLOR
	elif owner == ENEMY:
		color = ENEMY_COLOR
	draw_circle(pos, 35.0, Color("#141c1b"))
	draw_circle(pos, 29.0, color)
	draw_circle(pos, 23.0, color.lightened(0.12))
	if index == selected_region:
		draw_arc(pos, 40.0, 0.0, TAU, 48, SELECT_COLOR, 4.0, true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-6, 6), str(troops), HORIZONTAL_ALIGNMENT_CENTER, 18, 19, Color("#ffffff"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-85, 57), str(region["name"]), HORIZONTAL_ALIGNMENT_CENTER, 170, 16, Color("#e5e2d4"))
	if index == 14:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-12, -42), "★", HORIZONTAL_ALIGNMENT_CENTER, 24, 20, Color("#f5d76e"))

func _draw_hud() -> void:
	draw_rect(Rect2(Vector2(25, 605), Vector2(1230, 90)), Color(0.06, 0.09, 0.09, 0.94), true)
	draw_string(ThemeDB.fallback_font, Vector2(45, 634), "TURN %d" % turn_number, HORIZONTAL_ALIGNMENT_LEFT, 150, 18, Color("#f5d76e"))
	draw_string(ThemeDB.fallback_font, Vector2(45, 660), message, HORIZONTAL_ALIGNMENT_LEFT, 900, 17, Color("#f1f1e8"))
	draw_string(ThemeDB.fallback_font, Vector2(45, 682), "Blue: you   Red: enemy   Grey: neutral   •   Tap a blue region, then an adjacent region", HORIZONTAL_ALIGNMENT_LEFT, 1000, 13, Color("#aeb9ad"))
	var button_color := Color("#b94f43") if not game_over else Color("#56645a")
	draw_rect(Rect2(Vector2(1030, 620), Vector2(200, 52)), button_color, true)
	draw_string(ThemeDB.fallback_font, Vector2(1050, 652), "END TURN  ›", HORIZONTAL_ALIGNMENT_LEFT, 170, 20, Color.WHITE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)

func _handle_tap(pos: Vector2) -> void:
	if game_over:
		return
	if Rect2(Vector2(1030, 620), Vector2(200, 52)).has_point(pos):
		_end_turn()
		return
	var hit := _find_region(pos)
	if hit == -1:
		return
	if selected_region == -1:
		if int(regions[hit]["owner"]) == PLAYER:
			selected_region = hit
			message = "Selected %s. Choose a connected destination." % regions[hit]["name"]
		else:
			message = "Select a blue region first."
	elif hit == selected_region:
		selected_region = -1
		message = "Selection cleared."
	elif _are_connected(selected_region, hit):
		_move_or_attack(selected_region, hit)
		selected_region = -1
	else:
		if int(regions[hit]["owner"]) == PLAYER:
			selected_region = hit
			message = "Selected %s. Choose a connected destination." % regions[hit]["name"]
		else:
			message = "That region is not connected. Choose a neighboring region."
	queue_redraw()

func _find_region(pos: Vector2) -> int:
	for i in range(regions.size()):
		if pos.distance_to(regions[i]["pos"]) <= 38.0:
			return i
	return -1

func _are_connected(a: int, b: int) -> bool:
	for link in links:
		if (link.x == a and link.y == b) or (link.x == b and link.y == a):
			return true
	return false

func _move_or_attack(from: int, to: int) -> void:
	if int(regions[from]["owner"]) != PLAYER:
		message = "Only your regions can move."
		return
	var attacker: int = int(regions[from]["troops"])
	var defender_owner: int = int(regions[to]["owner"])
	var defender: int = int(regions[to]["troops"])
	if attacker <= 1:
		message = "This region needs at least 2 troop groups to attack."
		return
	if defender_owner == PLAYER:
		message = "Reinforcement movement is planned for the next prototype."
		return
	var attack_power := attacker * 20 + randi_range(-5, 10)
	var defense_power := defender * 18 + (12 if defender_owner == ENEMY else 0) + randi_range(0, 8)
	if attack_power > defense_power:
		var survivors: int = max(1, attacker - max(1, int(defense_power / 25)))
		regions[to]["owner"] = PLAYER
		regions[to]["troops"] = survivors
		regions[from]["troops"] = 1
		message = "Victory! %s captured with %d troop group(s)." % [regions[to]["name"], survivors]
		if to == 14:
			game_over = true
			message = "MISSION COMPLETE! Enemy headquarters captured. Restart to replay."
	else:
		regions[from]["troops"] = max(1, attacker - 1)
		regions[to]["troops"] = max(1, defender - 1)
		message = "Attack repelled at %s. Try another route or build strength." % regions[to]["name"]
	_check_end_state()

func _end_turn() -> void:
	turn_number += 1
	_enemy_action()
	if not game_over:
		for i in range(regions.size()):
			if int(regions[i]["owner"]) == PLAYER and int(regions[i]["troops"]) < 4:
				regions[i]["troops"] = int(regions[i]["troops"]) + 1
		message = "Turn %d: supply delivered. Plan your next move." % turn_number
	_check_end_state()
	queue_redraw()

func _enemy_action() -> void:
	for i in range(regions.size()):
		if int(regions[i]["owner"]) != ENEMY:
			continue
		var neighbors: Array[int] = []
		for link in links:
			if link.x == i:
				neighbors.append(link.y)
			elif link.y == i:
				neighbors.append(link.x)
		for n in neighbors:
			if int(regions[n]["owner"]) == PLAYER and int(regions[i]["troops"]) >= int(regions[n]["troops"]) + 2:
				var enemy_troops: int = int(regions[i]["troops"])
				regions[n]["troops"] = max(1, int(regions[n]["troops"]) - 1)
				regions[i]["troops"] = max(1, enemy_troops - 1)
				if enemy_troops > int(regions[n]["troops"]) + 1:
					regions[n]["owner"] = ENEMY
					regions[n]["troops"] = max(1, enemy_troops - 2)
				message = "Enemy counterattack near %s." % regions[n]["name"]
				return
	for i in range(regions.size()):
		if int(regions[i]["owner"]) != ENEMY:
			continue
		for link in links:
			var n: int = -1
			if link.x == i:
				n = link.y
			elif link.y == i:
				n = link.x
			if n >= 0 and int(regions[n]["owner"]) == 0:
				regions[n]["owner"] = ENEMY
				regions[n]["troops"] = 2
				message = "Enemy advances into %s." % regions[n]["name"]
				return

func _check_end_state() -> void:
	var player_regions := 0
	var enemy_regions := 0
	for region in regions:
		if int(region["owner"]) == PLAYER:
			player_regions += 1
		elif int(region["owner"]) == ENEMY:
			enemy_regions += 1
	if player_regions == 0:
		game_over = true
		message = "MISSION FAILED. All friendly regions lost."
	elif enemy_regions == 0:
		game_over = true
		message = "MISSION COMPLETE. Enemy territories liberated."
	queue_redraw()
