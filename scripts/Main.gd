extends Node2D

const PLAYER := 1
const ENEMY := 2
const SAVE_PATH := "user://front_line_save.cfg"
const MAP_BG := Color("#202b2b")
const ROAD := Color("#67716a")
const PLAYER_COLOR := Color("#4f9bd8")
const ENEMY_COLOR := Color("#cf6257")
const NEUTRAL_COLOR := Color("#8d9685")
const SELECT_COLOR := Color("#f5d76e")

var regions: Array[Dictionary] = []
var selected_region: int = -1
var turn_number: int = 1
var coins: int = 10
var message: String = "Select a blue region, then tap a connected region."
var game_over: bool = false
var mission_won: bool = false
var show_menu: bool = true

var region_names := [
	"West Base", "Old Road", "North Field", "Pine Woods", "River Bend",
	"Village", "Crossroads", "Hill", "Bridge", "Supply Depot",
	"East Field", "Forest Edge", "Rail Junction", "Enemy Camp", "HQ"
]
var links: Array[Vector2i] = []

func _ready() -> void:
	# Seed combat randomness once; keep all gameplay fully offline.
	randomize()
	_build_map()
	_load_game()
	_check_end_state()
	queue_redraw()

func _build_map() -> void:
	regions.clear()
	links.clear()
	for i in range(15):
		var col := i % 5
		var row := int(i / 5)
		var pos := Vector2(150.0 + col * 245.0, 210.0 + row * 150.0)
		var terrain_name := "plain"
		if i == 3 or i == 11:
			terrain_name = "forest"
		elif i == 4 or i == 8:
			terrain_name = "river"
		elif i == 7:
			terrain_name = "hill"
		elif i == 9:
			terrain_name = "depot"
		regions.append({
			"name": region_names[i],
			"pos": pos,
			"owner": 0,
			"troops": 1,
			"terrain": terrain_name
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
	# Polished low-cost tactical map: layered background, grid and map framing.
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("#111b20"))
	for row in range(9):
		for col in range(16):
			var cell := Rect2(Vector2(col * 82 - 12, row * 82 - 8), Vector2(78, 78))
			draw_rect(cell, Color(0.20, 0.30, 0.30, 0.13), false, 1.0)
	draw_circle(Vector2(640, 350), 410.0, Color(0.20, 0.31, 0.28, 0.10))
	if show_menu:
		_draw_menu()
		return
	_draw_background_details()
	# Road shadows and luminous route lines improve map readability.
	for link in links:
		var a: Vector2 = regions[link.x]["pos"]
		var b: Vector2 = regions[link.y]["pos"]
		draw_line(a + Vector2(0, 4), b + Vector2(0, 4), Color("#0a1114"), 13.0, true)
		draw_line(a, b, Color("#344b4a"), 8.0, true)
		draw_line(a, b, Color("#7d9483"), 2.0, true)
	for i in range(regions.size()):
		_draw_region(i)
	_draw_hud()
	if game_over:
		_draw_end_overlay()

func _draw_end_overlay() -> void:
	var panel := Rect2(Vector2(330, 235), Vector2(620, 250))
	draw_rect(panel, Color(0.04, 0.07, 0.07, 0.96), true)
	draw_rect(panel, Color("#e3c978") if mission_won else Color("#cf6257"), false, 3.0)
	var heading := "MISSION COMPLETE" if mission_won else "MISSION FAILED"
	var detail := "Enemy headquarters secured." if mission_won else "Your forces have lost the sector."
	draw_string(ThemeDB.fallback_font, Vector2(390, 300), heading, HORIZONTAL_ALIGNMENT_CENTER, 500, 34, Color("#f0ead7"))
	draw_string(ThemeDB.fallback_font, Vector2(390, 340), detail, HORIZONTAL_ALIGNMENT_CENTER, 500, 18, Color("#b7c8bc"))
	draw_string(ThemeDB.fallback_font, Vector2(390, 375), "Turns completed: %d" % turn_number, HORIZONTAL_ALIGNMENT_CENTER, 500, 16, Color("#a9b7a9"))
	_draw_button(Rect2(Vector2(490, 405), Vector2(300, 58)), "START NEW CAMPAIGN", Color("#477d68"))

func _draw_menu() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("#182321"))
	for i in range(14):
		var x := 30.0 + float(i) * 95.0
		draw_line(Vector2(x, 0), Vector2(x - 70, 720), Color(0.7, 0.8, 0.7, 0.035), 1.0)
	draw_rect(Rect2(Vector2(65, 70), Vector2(1150, 560)), Color("#222f2b"), true)
	draw_rect(Rect2(Vector2(65, 70), Vector2(1150, 560)), Color("#65786b"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(130, 165), "FRONT LINE", HORIZONTAL_ALIGNMENT_LEFT, 800, 58, Color("#f0ead7"))
	draw_string(ThemeDB.fallback_font, Vector2(135, 210), "OFFLINE TACTICAL CAMPAIGN", HORIZONTAL_ALIGNMENT_LEFT, 800, 20, Color("#a9b7a9"))
	draw_string(ThemeDB.fallback_font, Vector2(135, 280), "COMMANDER, YOUR SECTOR NEEDS YOU.", HORIZONTAL_ALIGNMENT_LEFT, 850, 24, Color("#e3c978"))
	draw_string(ThemeDB.fallback_font, Vector2(135, 320), "Capture territories, manage supplies, reinforce units,", HORIZONTAL_ALIGNMENT_LEFT, 900, 19, Color("#d4ddd2"))
	draw_string(ThemeDB.fallback_font, Vector2(135, 350), "and push toward the enemy headquarters.", HORIZONTAL_ALIGNMENT_LEFT, 900, 19, Color("#d4ddd2"))
	_draw_button(Rect2(Vector2(135, 410), Vector2(280, 68)), "PLAY CAMPAIGN", Color("#477d68"))
	_draw_button(Rect2(Vector2(435, 410), Vector2(280, 68)), "NEW CAMPAIGN", Color("#b94f43"))
	draw_string(ThemeDB.fallback_font, Vector2(135, 535), "15 TERRITORIES  •  LOCAL SAVE  •  NO SERVER REQUIRED", HORIZONTAL_ALIGNMENT_LEFT, 950, 16, Color("#a9b7a9"))
	draw_string(ThemeDB.fallback_font, Vector2(135, 570), "Prototype build 0.3  |  Designed for offline play", HORIZONTAL_ALIGNMENT_LEFT, 950, 14, Color("#7f9284"))

func _draw_background_details() -> void:
	# Top command strip.
	draw_rect(Rect2(Vector2(18, 18), Vector2(1244, 76)), Color(0.04, 0.08, 0.09, 0.94), true)
	draw_rect(Rect2(Vector2(18, 18), Vector2(1244, 76)), Color("#50665e"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(38, 49), "FRONT LINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#f0ead7"))
	draw_string(ThemeDB.fallback_font, Vector2(38, 75), "OPERATION DAWN  /  MISSION 01", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#9ca99d"))
	draw_string(ThemeDB.fallback_font, Vector2(820, 49), "SUPPLIES  %d" % coins, HORIZONTAL_ALIGNMENT_LEFT, 220, 19, Color("#f5d76e"))
	draw_string(ThemeDB.fallback_font, Vector2(820, 75), "CONTROLLED SECTORS  %d / 15" % _count_owned(PLAYER), HORIZONTAL_ALIGNMENT_LEFT, 300, 13, Color("#b7c8bc"))

func _draw_region(index: int) -> void:
	var region: Dictionary = regions[index]
	var pos: Vector2 = region["pos"]
	var owner: int = int(region["owner"])
	var troops: int = int(region["troops"])
	var color: Color = NEUTRAL_COLOR
	if owner == PLAYER:
		color = PLAYER_COLOR
	elif owner == ENEMY:
		color = ENEMY_COLOR

	# Territory node with soft shadow, outer faction ring and layered core.
	draw_circle(pos + Vector2(0, 5), 43.0, Color(0.0, 0.0, 0.0, 0.34))
	draw_circle(pos, 40.0, Color("#0c1417"))
	draw_arc(pos, 38.0, 0.0, TAU, 48, color.darkened(0.20), 5.0, true)
	draw_circle(pos, 31.0, color.darkened(0.25))
	draw_circle(pos, 26.0, color)
	draw_arc(pos, 23.0, PI, TAU, 32, color.lightened(0.38), 2.0, true)

	# Terrain badge.
	var terrain_mark := ""
	match str(region["terrain"]):
		"forest":
			terrain_mark = "♣"
		"river":
			terrain_mark = "≈"
		"hill":
			terrain_mark = "▲"
		"depot":
			terrain_mark = "+"
	if not terrain_mark.is_empty():
		draw_circle(pos + Vector2(25, -23), 13.0, Color("#172321"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(19, -18), terrain_mark, HORIZONTAL_ALIGNMENT_CENTER, 16, 14, Color("#f5d76e"))

	# Troop count chip.
	draw_circle(pos + Vector2(0, 1), 13.0, Color("#172027"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 7), str(troops), HORIZONTAL_ALIGNMENT_CENTER, 16, 18, Color("#ffffff"))
	if index == selected_region:
		draw_arc(pos, 46.0, 0.0, TAU, 56, SELECT_COLOR, 4.0, true)
		draw_circle(pos, 50.0, Color(0.96, 0.84, 0.43, 0.08))
	if index == 14:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-9, -48), "★", HORIZONTAL_ALIGNMENT_CENTER, 20, 20, Color("#f5d76e"))

	# Nameplate under each territory.
	var plate := Rect2(pos + Vector2(-83, 43), Vector2(166, 23))
	draw_rect(plate, Color(0.04, 0.08, 0.09, 0.88), true)
	draw_rect(plate, Color(color.r, color.g, color.b, 0.65), false, 1.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-79, 59), str(region["name"]), HORIZONTAL_ALIGNMENT_CENTER, 158, 13, Color("#edf2e9"))

func _draw_hud() -> void:
	draw_rect(Rect2(Vector2(25, 605), Vector2(1230, 90)), Color(0.06, 0.09, 0.09, 0.96), true)
	draw_string(ThemeDB.fallback_font, Vector2(42, 630), "TURN %d" % turn_number, HORIZONTAL_ALIGNMENT_LEFT, 120, 17, Color("#f5d76e"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 655), message, HORIZONTAL_ALIGNMENT_LEFT, 800, 16, Color("#f1f1e8"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 680), "Tap blue then adjacent region • Reinforce costs 3 supplies", HORIZONTAL_ALIGNMENT_LEFT, 700, 13, Color("#aeb9ad"))
	_draw_button(Rect2(Vector2(810, 618), Vector2(125, 54)), "REINFORCE", Color("#477d68"))
	_draw_button(Rect2(Vector2(945, 618), Vector2(125, 54)), "END TURN", Color("#b94f43") if not game_over else Color("#56645a"))
	_draw_button(Rect2(Vector2(1080, 618), Vector2(150, 54)), "MENU", Color("#586c83"))

func _draw_button(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, color, true)
	draw_rect(rect, color.lightened(0.18), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 32), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20, 14, Color.WHITE)

func _input(event: InputEvent) -> void:
	# Convert screen/viewport input into the same canvas coordinate space used by _draw().
	# This accounts for stretch scaling and letterboxing on Android devices.
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_tap(_screen_to_canvas(event.position))
	elif event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_handle_tap(_screen_to_canvas(event.position))

func _screen_to_canvas(screen_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_pos

func _handle_tap(pos: Vector2) -> void:
	if show_menu:
		if Rect2(Vector2(135, 410), Vector2(280, 68)).has_point(pos):
			show_menu = false
			message = "Campaign started! Tap a blue region, then an adjacent region."
		elif Rect2(Vector2(435, 410), Vector2(280, 68)).has_point(pos):
			_restart_game()
		queue_redraw()
		return
	if Rect2(Vector2(1080, 618), Vector2(150, 54)).has_point(pos):
		show_menu = true
		selected_region = -1
		queue_redraw()
		return
	if game_over:
		if Rect2(Vector2(490, 405), Vector2(300, 58)).has_point(pos):
			_restart_game()
		else:
			message = "Mission ended. Choose START NEW CAMPAIGN."
			queue_redraw()
		return
	if Rect2(Vector2(810, 618), Vector2(125, 54)).has_point(pos):
		_reinforce_selected()
		return
	if Rect2(Vector2(945, 618), Vector2(125, 54)).has_point(pos):
		_end_turn()
		return
	var hit := _find_region(pos)
	if hit == -1:
		return
	if selected_region == -1:
		if int(regions[hit]["owner"]) == PLAYER:
			selected_region = hit
			message = "Selected %s: %s terrain (+%d combat). Choose a connected region." % [regions[hit]["name"], str(regions[hit]["terrain"]), _terrain_bonus(str(regions[hit]["terrain"]))]
		else:
			message = "Select one of your blue regions first."
	elif hit == selected_region:
		selected_region = -1
		message = "Selection cleared."
	elif _are_connected(selected_region, hit):
		_move_or_attack(selected_region, hit)
		selected_region = -1
	else:
		if int(regions[hit]["owner"]) == PLAYER:
			selected_region = hit
			message = "Selected %s. Choose a connected region." % regions[hit]["name"]
		else:
			message = "That region is not connected."
	queue_redraw()

func _find_region(pos: Vector2) -> int:
	# Slightly larger hit area makes territory selection reliable on phone screens.
	for i in range(regions.size()):
		if pos.distance_to(regions[i]["pos"]) <= 46.0:
			return i
	return -1

func _are_connected(a: int, b: int) -> bool:
	for link in links:
		if (link.x == a and link.y == b) or (link.x == b and link.y == a):
			return true
	return false

func _move_or_attack(from: int, to: int) -> void:
	var attacker: int = int(regions[from]["troops"])
	var defender_owner: int = int(regions[to]["owner"])
	var defender: int = int(regions[to]["troops"])
	if attacker <= 1:
		message = "Not enough troops. Reinforce this region or wait for supplies."
		return
	if defender_owner == PLAYER:
		var moved: int = max(1, int((attacker - 1) / 2))
		regions[from]["troops"] = attacker - moved
		regions[to]["troops"] = defender + moved
		message = "Moved %d troop group(s) to %s." % [moved, regions[to]["name"]]
		_save_game()
		return
	var attack_bonus: int = _terrain_bonus(str(regions[from]["terrain"]))
	var defense_bonus: int = _terrain_bonus(str(regions[to]["terrain"]))
	var attack_power: int = attacker * 20 + attack_bonus + randi_range(-5, 10)
	var defense_power: int = defender * 18 + defense_bonus + (12 if defender_owner == ENEMY else 0) + randi_range(0, 8)
	if attack_power > defense_power:
		var survivors: int = max(1, attacker - max(1, int(defense_power / 25)))
		regions[to]["owner"] = PLAYER
		regions[to]["troops"] = survivors
		regions[from]["troops"] = 1
		message = "Captured %s! Remaining troop groups: %d." % [regions[to]["name"], survivors]
		if to == 14:
			game_over = true
			mission_won = true
			message = "MISSION COMPLETE! Enemy headquarters captured."
	else:
		regions[from]["troops"] = max(1, attacker - 1)
		regions[to]["troops"] = max(1, defender - 1)
		message = "Attack repelled at %s. Regroup and try again." % regions[to]["name"]
	_check_end_state()
	_save_game()

func _reinforce_selected() -> void:
	if selected_region < 0 or int(regions[selected_region]["owner"]) != PLAYER:
		message = "Select one of your blue regions before reinforcing."
	elif coins < 3:
		message = "Not enough supplies. End your turn to earn more."
	else:
		coins -= 3
		regions[selected_region]["troops"] = int(regions[selected_region]["troops"]) + 2
		message = "%s reinforced with 2 troop groups." % regions[selected_region]["name"]
		_save_game()
	queue_redraw()

func _end_turn() -> void:
	if game_over:
		message = "Mission ended. Start a new campaign to continue."
		queue_redraw()
		return
	turn_number += 1
	var income := _count_owned(PLAYER)
	if int(regions[9]["owner"]) == PLAYER:
		income += 2
	coins += income
	_enemy_action()
	if not game_over:
		for i in range(regions.size()):
			if int(regions[i]["owner"]) == PLAYER and int(regions[i]["troops"]) < 5:
				regions[i]["troops"] = int(regions[i]["troops"]) + 1
		message = "Turn %d: +%d supplies delivered. Depot gives +2." % [turn_number, income]
	_check_end_state()
	_save_game()
	queue_redraw()

func _enemy_action() -> void:
	# Enemy chooses a vulnerable adjacent player territory instead of the first link.
	for i in range(regions.size()):
		if int(regions[i]["owner"]) != ENEMY:
			continue
		var target := -1
		var weakest := 999
		for link in links:
			var n := -1
			if link.x == i:
				n = link.y
			elif link.y == i:
				n = link.x
			if n >= 0 and int(regions[n]["owner"]) == PLAYER:
				var defenders := int(regions[n]["troops"])
				if defenders < weakest:
					weakest = defenders
					target = n
		if target >= 0 and int(regions[i]["troops"]) >= weakest + 2:
			var attackers := int(regions[i]["troops"])
			var attack_power := attackers * 18 + randi_range(0, 8)
			var defense_power := weakest * 20 + _terrain_bonus(str(regions[target]["terrain"])) + randi_range(0, 8)
			if attack_power > defense_power:
				regions[target]["owner"] = ENEMY
				regions[target]["troops"] = max(1, attackers - 2)
				regions[i]["troops"] = max(1, int(attackers / 2))
				message = "Enemy captured %s! Defend your frontier." % regions[target]["name"]
			else:
				regions[target]["troops"] = max(1, weakest - 1)
				regions[i]["troops"] = max(1, attackers - 1)
				message = "Enemy assault repelled near %s." % regions[target]["name"]
			return
	# If no attack is possible, expand into a neutral neighboring region.
	for i in range(regions.size()):
		if int(regions[i]["owner"]) != ENEMY:
			continue
		for link in links:
			var n := -1
			if link.x == i:
				n = link.y
			elif link.y == i:
				n = link.x
			if n >= 0 and int(regions[n]["owner"]) == 0:
				regions[n]["owner"] = ENEMY
				regions[n]["troops"] = 2
				message = "Enemy advanced into %s." % regions[n]["name"]
				return

func _terrain_bonus(terrain: String) -> int:
	match terrain:
		"forest":
			return 10
		"river":
			return 8
		"hill":
			return 14
		"depot":
			return 4
		_:
			return 0

func _check_end_state() -> void:
	if _count_owned(PLAYER) == 0:
		game_over = true
		mission_won = false
		message = "MISSION FAILED. Your territories were lost."
	elif _count_owned(ENEMY) == 0:
		game_over = true
		mission_won = true
		message = "MISSION COMPLETE. Enemy forces defeated."
	queue_redraw()

func _count_owned(owner: int) -> int:
	var count := 0
	for region in regions:
		if int(region["owner"]) == owner:
			count += 1
	return count

func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("save", "turn", turn_number)
	config.set_value("save", "coins", coins)
	config.set_value("save", "game_over", game_over)
	config.set_value("save", "mission_won", mission_won)
	var saved_regions: Array[Dictionary] = []
	for region in regions:
		saved_regions.append({"owner": int(region["owner"]), "troops": int(region["troops"])})
	config.set_value("save", "regions", saved_regions)
	config.save(SAVE_PATH)

func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	# Reject invalid/corrupt saves instead of loading impossible campaign values.
	var saved_regions: Array = config.get_value("save", "regions", [])
	if saved_regions.size() != regions.size():
		return
	turn_number = max(1, int(config.get_value("save", "turn", 1)))
	coins = max(0, int(config.get_value("save", "coins", 10)))
	game_over = bool(config.get_value("save", "game_over", false))
	mission_won = bool(config.get_value("save", "mission_won", false))
	# Validate every entry first so a bad save cannot partially alter the map.
	for saved_value in saved_regions:
		if not (saved_value is Dictionary):
			return
		var owner := int(saved_value.get("owner", -1))
		var troops := int(saved_value.get("troops", 0))
		if owner < 0 or owner > ENEMY or troops < 1:
			return
	for i in range(regions.size()):
		var saved: Dictionary = saved_regions[i]
		regions[i]["owner"] = int(saved["owner"])
		regions[i]["troops"] = int(saved["troops"])
	if game_over:
		message = "Saved mission ended. Start a new campaign to play again."
	else:
		message = "Saved campaign loaded. Your progress is preserved."

func _restart_game() -> void:
	var config := ConfigFile.new()
	config.save(SAVE_PATH)
	turn_number = 1
	coins = 10
	selected_region = -1
	game_over = false
	mission_won = false
	message = "New campaign started. Capture the enemy HQ!"
	_build_map()
	show_menu = false
	_save_game()
	queue_redraw()
