extends Node3D

class OrderCard extends Control:
	var order_data: Dictionary

	func _init(data: Dictionary) -> void:
		order_data = data
		custom_minimum_size = Vector2(253, 132)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var patience: int = order_data.get("patience", 0)
		var card_color := Color("#fff3d0")
		var border_color := Color("#d5b978")
		draw_style_box(_panel_style(card_color, border_color, 8, 1), Rect2(Vector2.ZERO, size))

		draw_rect(Rect2(10, 9, size.x - 20, 8), Color("#c7c5b8"))
		draw_rect(Rect2(10, 9, (size.x - 20) * patience / 100.0, 8), Color("#61b879"))
		draw_circle(Vector2(size.x - 15, 13), 3, Color("#ef6b62"))

		draw_circle(Vector2(35, 54), 19, Color("#f1e4c4"))
		draw_arc(Vector2(35, 54), 19, 0, TAU, 24, Color("#b7c8ce"), 2)
		draw_circle(Vector2(35, 53), 13, Color("#d95846"))
		draw_arc(Vector2(35, 53), 13, 0, PI, 16, Color("#f2c56b"), 2)
		draw_string(ThemeDB.fallback_font, Vector2(21, 82), "SOUP", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#26384a"))

		draw_string(ThemeDB.fallback_font, Vector2(64, 43), "TOMATO SOUP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#26384a"))
		draw_string(ThemeDB.fallback_font, Vector2(64, 78), "INGREDIENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#66737b"))
		draw_circle(Vector2(78, 101), 10, Color("#ed514b"))
		draw_string(ThemeDB.fallback_font, Vector2(74, 105), "T", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#fff3d0"))
		draw_string(ThemeDB.fallback_font, Vector2(94, 105), "TOMATO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#26384a"))

		draw_string(ThemeDB.fallback_font, Vector2(166, 101), "COOK AT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#66737b"))
		draw_rect(Rect2(166, 108, 24, 10), Color("#5d6872"))
		draw_circle(Vector2(178, 107), 9, Color("#303d4a"))
		draw_arc(Vector2(178, 107), 9, 0, TAU, 16, Color("#d5a74c"), 2)
		draw_string(ThemeDB.fallback_font, Vector2(195, 115), "POT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#26384a"))

	func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(border_width)
		style.set_corner_radius_all(radius)
		return style

const FLOOR_SIZE := Vector3(20, 0.3, 13)
const STATION_NAMES := {
	"crate": "TOMATO CRATE",
	"cut": "CUTTING BOARD",
	"cook": "STOCK POT",
	"plates": "PLATE COUNTER",
	"serve": "SERVING WINDOW"
}

var chef: CharacterBody3D
var chef_mesh: MeshInstance3D
var nearest_station := ""
var held_item := "Empty hands"
var board_has_tomato := false
var board_has_chopped_tomato := false
var cutting_remaining := 0.0
var cooking_remaining := 0.0
var soup_ready := false
var score := 0
var combo := 0
var time_left := 120
var orders: Array[Dictionary] = []
var next_order_id := 1
var feedback := "WASD / arrows to move. Walk near a station and press E."
var feedback_color := Color("#70c8ed")
var station_nodes: Dictionary = {}
var time_label: Label
var score_label: Label
var order_label: RichTextLabel
var orders_container: VBoxContainer
var status_label: Label
var feedback_label: Label
var timer: Timer
var held_visual: Node3D
var tomato_visual: MeshInstance3D
var plate_visual: MeshInstance3D
var pot_animation: Node3D
var pot_progress_label: Label3D
var cutting_animation: Node3D
var cutting_progress_label: Label3D
var chopped_visual: MeshInstance3D
var board_tomato_visual: MeshInstance3D
var board_whole_tomato_visual: MeshInstance3D
var knife_visual: MeshInstance3D
var walk_phase := 0.0
var putting_remaining := 0.0
var putting_total := 0.45

func _ready() -> void:
	_setup_input()
	_build_world()
	_build_hud()
	_spawn_order()
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()
	_update_hud()

func _setup_input() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "interact"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	_bind("move_up", KEY_W)
	_bind("move_up", KEY_UP)
	_bind("move_down", KEY_S)
	_bind("move_down", KEY_DOWN)
	_bind("move_left", KEY_A)
	_bind("move_left", KEY_LEFT)
	_bind("move_right", KEY_D)
	_bind("move_right", KEY_RIGHT)
	_bind("interact", KEY_E)

func _bind(action: String, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#16253b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b5cbed")
	env.ambient_light_energy = 0.55
	environment.environment = env
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_color = Color("#ffe4b2")
	light.light_energy = 1.25
	light.shadow_enabled = true
	add_child(light)

	_add_box("Floor", FLOOR_SIZE, Vector3(0, -0.15, 0), Color("#b99571"))
	_add_box("BackWall", Vector3(20, 3.2, 0.3), Vector3(0, 1.45, -6.35), Color("#294052"))
	_add_box("LeftWall", Vector3(0.3, 3.2, 13), Vector3(-10, 1.45, 0), Color("#294052"))
	_add_box("RightWall", Vector3(0.3, 3.2, 13), Vector3(10, 1.45, 0), Color("#294052"))

	var positions := {"crate": -7.0, "cut": -4.5, "cook": -1.5, "plates": 2.0, "serve": 6.0}
	for station_id in positions:
		var station_z := -4.4 if station_id != "plates" else -2.4
		var station := _create_station(station_id, Vector3(positions[station_id], 0.8, station_z))
		station_nodes[station_id] = station
		if station_id == "cook":
			_create_pot_animation(station)
		if station_id == "cut":
			_create_cutting_animation(station)

	chef = CharacterBody3D.new()
	chef.name = "Chef"
	chef.position = Vector3(0, 0.65, 2.5)
	add_child(chef)
	chef_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.45
	capsule.radius = 0.38
	chef_mesh.mesh = capsule
	chef_mesh.material_override = _material(Color("#d95757"))
	chef.add_child(chef_mesh)
	var chef_shape := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.height = 1.45
	capsule_shape.radius = 0.38
	chef_shape.shape = capsule_shape
	chef.add_child(chef_shape)
	var hat := MeshInstance3D.new()
	var hat_mesh := CylinderMesh.new()
	hat_mesh.top_radius = 0.34
	hat_mesh.bottom_radius = 0.44
	hat_mesh.height = 0.28
	hat.mesh = hat_mesh
	hat.position.y = 0.82
	hat.material_override = _material(Color("#fff4d6"))
	chef.add_child(hat)
	held_visual = Node3D.new()
	held_visual.position = Vector3(0.52, 0.15, -0.22)
	chef.add_child(held_visual)
	tomato_visual = MeshInstance3D.new()
	var tomato_mesh := SphereMesh.new()
	tomato_mesh.radius = 0.16
	tomato_mesh.height = 0.32
	tomato_visual.mesh = tomato_mesh
	tomato_visual.material_override = _material(Color("#ed514b"))
	held_visual.add_child(tomato_visual)
	chopped_visual = MeshInstance3D.new()
	var chopped_mesh := BoxMesh.new()
	chopped_mesh.size = Vector3(0.28, 0.08, 0.28)
	chopped_visual.mesh = chopped_mesh
	chopped_visual.material_override = _material(Color("#ed514b"))
	chopped_visual.position.y = -0.1
	held_visual.add_child(chopped_visual)
	plate_visual = MeshInstance3D.new()
	var plate_mesh := CylinderMesh.new()
	plate_mesh.top_radius = 0.27
	plate_mesh.bottom_radius = 0.27
	plate_mesh.height = 0.05
	plate_visual.mesh = plate_mesh
	plate_visual.material_override = _material(Color("#fff4d6"))
	plate_visual.position.y = -0.12
	held_visual.add_child(plate_visual)
	_update_held_visual()

	var camera := Camera3D.new()
	camera.position = Vector3(0, 12, 13)
	camera.rotation_degrees = Vector3(-39, 0, 0)
	camera.current = true
	add_child(camera)

func _add_box(node_name: String, size: Vector3, position: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _create_station(station_id: String, position: Vector3) -> StaticBody3D:
	var station := _add_box(STATION_NAMES[station_id], Vector3(2.6, 1.5, 1.2), position, _station_color(station_id))
	var sign := Label3D.new()
	sign.text = STATION_NAMES[station_id]
	sign.position = Vector3(0, 1.35, 0)
	sign.font_size = 32
	sign.modulate = Color("#fff3d0")
	sign.outline_size = 8
	sign.outline_modulate = Color("#142235")
	station.add_child(sign)
	if station_id == "crate":
		for offset in [Vector3(-0.35, 0.9, 0), Vector3(0, 0.95, 0.12), Vector3(0.35, 0.9, -0.05)]:
			var tomato := MeshInstance3D.new()
			var tomato_mesh := SphereMesh.new()
			tomato_mesh.radius = 0.18
			tomato_mesh.height = 0.36
			tomato.mesh = tomato_mesh
			tomato.position = offset
			tomato.material_override = _material(Color("#ed514b"))
			station.add_child(tomato)
	if station_id == "plates":
		for index in range(3):
			var plate := MeshInstance3D.new()
			var plate_mesh := CylinderMesh.new()
			plate_mesh.top_radius = 0.38
			plate_mesh.bottom_radius = 0.38
			plate_mesh.height = 0.06
			plate.mesh = plate_mesh
			plate.position = Vector3(0, 0.82 + index * 0.08, 0)
			plate.material_override = _material(Color("#fff4d6"))
			station.add_child(plate)
	if station_id == "cut":
		board_whole_tomato_visual = MeshInstance3D.new()
		var whole_tomato_mesh := SphereMesh.new()
		whole_tomato_mesh.radius = 0.18
		whole_tomato_mesh.height = 0.36
		board_whole_tomato_visual.mesh = whole_tomato_mesh
		board_whole_tomato_visual.position = Vector3(0, 0.98, 0)
		board_whole_tomato_visual.material_override = _material(Color("#ed514b"))
		board_whole_tomato_visual.visible = false
		station.add_child(board_whole_tomato_visual)
		board_tomato_visual = MeshInstance3D.new()
		var board_tomato_mesh := BoxMesh.new()
		board_tomato_mesh.size = Vector3(0.3, 0.08, 0.3)
		board_tomato_visual.mesh = board_tomato_mesh
		board_tomato_visual.position = Vector3(0, 0.82, 0)
		board_tomato_visual.material_override = _material(Color("#ed514b"))
		board_tomato_visual.visible = false
		station.add_child(board_tomato_visual)
	return station

func _create_pot_animation(station: StaticBody3D) -> void:
	pot_animation = Node3D.new()
	pot_animation.position = Vector3(0, 1.65, 0)
	pot_animation.visible = false
	station.add_child(pot_animation)
	for offset in [Vector3(-0.3, 0, 0), Vector3(0, 0.15, 0), Vector3(0.3, 0, 0)]:
		var steam := MeshInstance3D.new()
		var steam_mesh := SphereMesh.new()
		steam_mesh.radius = 0.1
		steam_mesh.height = 0.2
		steam.mesh = steam_mesh
		steam.position = offset
		steam.material_override = _material(Color("#f4f1df"))
		pot_animation.add_child(steam)
	pot_progress_label = Label3D.new()
	pot_progress_label.text = "COOKING..."
	pot_progress_label.position = Vector3(0, 0.65, 0)
	pot_progress_label.font_size = 30
	pot_progress_label.modulate = Color("#f4ca67")
	pot_progress_label.outline_size = 8
	pot_progress_label.outline_modulate = Color("#142235")
	pot_animation.add_child(pot_progress_label)

func _create_cutting_animation(station: StaticBody3D) -> void:
	cutting_animation = Node3D.new()
	cutting_animation.position = Vector3(0, 1.5, 0)
	cutting_animation.visible = false
	station.add_child(cutting_animation)
	knife_visual = MeshInstance3D.new()
	var knife_mesh := BoxMesh.new()
	knife_mesh.size = Vector3(0.12, 0.5, 0.08)
	knife_visual.mesh = knife_mesh
	knife_visual.position = Vector3(0, 0.2, 0)
	knife_visual.material_override = _material(Color("#dbe7ee"))
	cutting_animation.add_child(knife_visual)
	cutting_progress_label = Label3D.new()
	cutting_progress_label.text = "CHOPPING..."
	cutting_progress_label.position = Vector3(0, 0.75, 0)
	cutting_progress_label.font_size = 30
	cutting_progress_label.modulate = Color("#f4ca67")
	cutting_progress_label.outline_size = 8
	cutting_progress_label.outline_modulate = Color("#142235")
	cutting_animation.add_child(cutting_progress_label)

func _update_pot_animation() -> void:
	if not pot_animation:
		return
	pot_animation.visible = cooking_remaining > 0.0
	if cooking_remaining > 0.0:
		pot_progress_label.text = "COOKING  %.1fs" % cooking_remaining

func _update_cutting_animation() -> void:
	if not cutting_animation:
		return
	cutting_animation.visible = cutting_remaining > 0.0
	if cutting_remaining > 0.0:
		cutting_progress_label.text = "CHOPPING  %.1fs" % cutting_remaining

func _station_color(station_id: String) -> Color:
	return {"crate": Color("#bd7448"), "cut": Color("#bf5b50"), "cook": Color("#d47b46"), "plates": Color("#8b73b9"), "serve": Color("#d3a64b")}[station_id]

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material

func _physics_process(delta: float) -> void:
	if not chef:
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	chef.velocity = Vector3(input.x, 0, input.y) * 4.8
	chef.move_and_slide()
	_update_walk_animation(input, delta)
	_update_action_animation(delta)
	chef.position.x = clamp(chef.position.x, -8.8, 8.8)
	chef.position.z = clamp(chef.position.z, -2.4, 5.4)
	_update_nearest_station()
	if Input.is_action_just_pressed("interact") and nearest_station != "":
		_interact(nearest_station)

func _update_walk_animation(input: Vector2, delta: float) -> void:
	if input.length() > 0.05:
		walk_phase += delta * 11.0
		chef_mesh.position.y = abs(sin(walk_phase)) * 0.06
		chef_mesh.rotation.z = sin(walk_phase) * 0.045
		held_visual.position.y = 0.15 + abs(sin(walk_phase)) * 0.035
	else:
		walk_phase = 0.0
		chef_mesh.position.y = lerpf(chef_mesh.position.y, 0.0, delta * 12.0)
		chef_mesh.rotation.z = lerpf(chef_mesh.rotation.z, 0.0, delta * 12.0)
		held_visual.position.y = lerpf(held_visual.position.y, 0.15, delta * 12.0)

func _update_action_animation(delta: float) -> void:
	if cutting_remaining > 0.0 and knife_visual:
		var chop_wave := sin(Time.get_ticks_msec() * 0.018)
		knife_visual.rotation.z = chop_wave * 0.55
		knife_visual.position.y = 0.2 + abs(chop_wave) * 0.12
	elif knife_visual:
		knife_visual.rotation.z = 0.0
		knife_visual.position.y = 0.2
	if putting_remaining > 0.0:
		putting_remaining = maxf(0.0, putting_remaining - delta)
		var progress := 1.0 - putting_remaining / putting_total
		var put_wave := sin(progress * PI)
		chef_mesh.rotation.x = -put_wave * 0.28
		held_visual.position.z = -0.22 - put_wave * 0.28
	else:
		chef_mesh.rotation.x = lerpf(chef_mesh.rotation.x, 0.0, delta * 14.0)
		held_visual.position.z = lerpf(held_visual.position.z, -0.22, delta * 14.0)

func _update_nearest_station() -> void:
	var best := ""
	var best_distance := 2.4
	for station_id in station_nodes:
		var distance: float = chef.global_position.distance_to(station_nodes[station_id].global_position)
		if distance < best_distance:
			best = station_id
			best_distance = distance
	if best != nearest_station:
		nearest_station = best
		for station_id in station_nodes:
			var sign: Label3D = station_nodes[station_id].get_child(2)
			sign.modulate = Color("#f4ca67") if station_id == nearest_station else Color("#fff3d0")
		_update_hud()

func _interact(station_id: String) -> void:
	match station_id:
		"crate":
			if held_item == "Tomato":
				_set_held_item("Empty hands")
				_start_put_animation()
				_feedback("Tomato returned to the crate.", Color("#61d39a"))
				return
			if held_item != "Empty hands":
				_feedback("Your hands are full. Use the item first.", Color("#ef6b62"))
				return
			_set_held_item("Tomato")
			_start_put_animation()
			_feedback("You took a tomato from the crate. Take it to the stock pot.", Color("#61d39a"))
		"cut":
			if held_item == "Chopped tomato":
				if board_has_chopped_tomato:
					_feedback("The cutting board already has chopped tomato.", Color("#ef6b62"))
					return
				board_has_chopped_tomato = true
				_set_held_item("Empty hands")
				_start_put_animation()
				_update_board_visual()
				_feedback("Chopped tomato placed back on the cutting board.", Color("#61d39a"))
				return
			if held_item == "Tomato" and (board_has_tomato or board_has_chopped_tomato):
				_feedback("The cutting board is occupied. Pick up the chopped tomato first.", Color("#ef6b62"))
				return
			if held_item == "Tomato":
				board_has_tomato = true
				_set_held_item("Empty hands")
				_update_board_visual()
				_start_put_animation()
				_feedback("Tomato placed on the cutting board. Press E to chop it.", Color("#61d39a"))
				return
			if held_item == "Empty hands" and board_has_chopped_tomato:
				board_has_chopped_tomato = false
				_set_held_item("Chopped tomato")
				_start_put_animation()
				_update_board_visual()
				_feedback("You picked up the chopped tomato from the board.", Color("#61d39a"))
				return
			if held_item == "Empty hands" and board_has_tomato:
				board_has_tomato = false
				cutting_remaining = 2.0
				_update_board_visual()
				_update_cutting_animation()
				_feedback("Chopping started! Stay beside the cutting board for two seconds.", Color("#f4ca67"))
				return
			if held_item != "Tomato":
				_feedback("Bring a whole tomato here to chop it.", Color("#ef6b62"))
				return
			if cutting_remaining > 0.0:
				_feedback("The tomato is being chopped. %.1f seconds left." % cutting_remaining, Color("#f4ca67"))
				return
			_set_held_item("Empty hands")
			_start_put_animation()
			cutting_remaining = 2.0
			_update_cutting_animation()
			_feedback("Chopping started! Wait two seconds.", Color("#f4ca67"))
		"cook":
			if held_item == "Plate" and soup_ready:
				soup_ready = false
				_set_held_item("Tomato soup")
				_start_put_animation()
				_update_pot_animation()
				_feedback("You collected the soup. Take it to the serving window.", Color("#61d39a"))
			elif held_item == "Plate" and cooking_remaining > 0.0:
				_feedback("The soup is still cooking. %.1f seconds left." % cooking_remaining, Color("#f4ca67"))
			elif held_item == "Chopped tomato":
				if cooking_remaining > 0.0 or soup_ready:
					_feedback("The pot is occupied. Wait until the soup is collected.", Color("#ef6b62"))
					return
				_set_held_item("Empty hands")
				_start_put_animation()
				cooking_remaining = 6.0
				_update_pot_animation()
				_feedback("Cooking started! Wait six seconds, then bring a plate.", Color("#f4ca67"))
			else:
				_feedback("Bring a chopped tomato to start cooking, or a plate when it is ready.", Color("#ef6b62"))
		"plates":
			if held_item == "Plate":
				_set_held_item("Empty hands")
				_start_put_animation()
				_feedback("Plate returned to the plate counter.", Color("#61d39a"))
				return
			if held_item != "Empty hands":
				_feedback("Your hands are full. Serve what you are carrying first.", Color("#ef6b62"))
				return
			_set_held_item("Plate")
			_start_put_animation()
			_feedback("You took a clean plate. Bring it to the pot when soup is ready.", Color("#61d39a"))
		"serve":
			if held_item == "Plate" and soup_ready:
				_feedback("The soup is ready, but this plate is empty. Take it to the pot.", Color("#f4ca67"))
				return
			if held_item != "Tomato soup":
				_feedback("Bring a plated tomato soup here first.", Color("#ef6b62"))
				return
			if orders.is_empty():
				_feedback("No customers are waiting.", Color("#70c8ed"))
				return
			_set_held_item("Empty hands")
			_start_put_animation()
			var patience: int = orders[0].patience
			orders.pop_front()
			var patience_points := 150 if patience >= 66 else 100 if patience >= 33 else 50
			var points := patience_points + combo * 25
			score += points
			combo += 1
			_feedback("Perfect serve! +%d points  •  combo x%d" % [points, combo], Color("#61d39a"))
			_spawn_order()
	_update_hud()

func _spawn_order() -> void:
	orders.append({
		"id": next_order_id,
		"patience": 100,
		"recipe": "Tomato Soup",
		"ingredients": ["Tomato", "Salt", "Plate"],
		"station": "Stock Pot"
	})
	next_order_id += 1

func _tick() -> void:
	if time_left <= 0:
		timer.stop()
		_feedback("SERVICE CLOSED  •  Final score: %d  •  Press R to restart" % score, Color("#f4ca67"))
		return
	time_left -= 1
	if cutting_remaining > 0.0:
		var board_position: Vector3 = station_nodes["cut"].global_position
		if chef.global_position.distance_to(board_position) > 2.4:
			cutting_remaining = 0.0
			board_has_tomato = true
			_update_cutting_animation()
			_update_board_visual()
			_set_held_item("Empty hands")
			_feedback("Chopping cancelled: stay beside the cutting board.", Color("#ef6b62"))
	if cooking_remaining > 0.0:
		cooking_remaining = maxf(0.0, cooking_remaining - 1.0)
		_update_pot_animation()
		if cooking_remaining == 0.0:
			soup_ready = true
			pot_animation.visible = true
			pot_progress_label.text = "SOUP READY!"
			_feedback("Ding! The tomato soup is ready. Bring a plate to the pot.", Color("#61d39a"))
	if cutting_remaining > 0.0:
		cutting_remaining = maxf(0.0, cutting_remaining - 1.0)
		_update_cutting_animation()
		if cutting_remaining == 0.0:
			board_has_chopped_tomato = true
			_update_board_visual()
			_feedback("Chopping finished! Pick up the chopped tomato from the board.", Color("#61d39a"))
	for order in orders:
		order.patience = maxi(0, order.patience - 1)
	if time_left % 30 == 0 and orders.size() < 2:
		_spawn_order()
		_feedback("A new family has entered the restaurant!", Color("#70c8ed"))
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_restart()

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	score_label = _label("SCORE  0", Color("#f4ca67"), 20)
	score_label.position = Vector2(42, 638)
	canvas.add_child(score_label)
	time_label = _label("TIME  2:00", Color("#ef6b62"), 20)
	time_label.position = Vector2(910, 638)
	canvas.add_child(time_label)
	var side := ColorRect.new()
	side.color = Color("#142235e6")
	side.position = Vector2(22, 18)
	side.size = Vector2(275, 460)
	canvas.add_child(side)
	orders_container = VBoxContainer.new()
	orders_container.position = Vector2(33, 30)
	orders_container.size = Vector2(253, 395)
	orders_container.add_theme_constant_override("separation", 8)
	canvas.add_child(orders_container)

func _label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label

func _update_hud() -> void:
	if not orders_container:
		return
	time_label.text = "TIME  %d:%02d" % [time_left / 60, time_left % 60]
	score_label.text = "SCORE  %d" % score
	var pot_status := "Pot: ready" if soup_ready else "Pot: cooking %.1fs" % cooking_remaining if cooking_remaining > 0.0 else "Pot: empty"
	if cutting_remaining > 0.0:
		pot_status = "Board: chopping %.1fs" % cutting_remaining
	var board_status := "Board: chopped tomato" if board_has_chopped_tomato else "Board: empty"
	for child in orders_container.get_children():
		child.queue_free()
	if orders.is_empty():
		var empty_label := _label("No customers waiting.", Color("#b4c6cf"), 13)
		orders_container.add_child(empty_label)
	else:
		for order in orders:
			orders_container.add_child(OrderCard.new(order))

func _feedback(message: String, color: Color) -> void:
	feedback = message
	feedback_color = color
	_update_hud()

func _restart() -> void:
	score = 0
	combo = 0
	time_left = 120
	cooking_remaining = 0.0
	cutting_remaining = 0.0
	board_has_tomato = false
	board_has_chopped_tomato = false
	soup_ready = false
	orders.clear()
	next_order_id = 1
	_spawn_order()
	_feedback("New 3D service started. Get cooking!", Color("#70c8ed"))
	timer.start()
	_set_held_item("Empty hands")
	_start_put_animation()
	_update_pot_animation()
	_update_cutting_animation()
	_update_board_visual()

func _set_held_item(item: String) -> void:
	held_item = item
	_update_held_visual()
	_update_hud()

func _start_put_animation() -> void:
	putting_remaining = putting_total

func _update_held_visual() -> void:
	if not tomato_visual or not plate_visual:
		return
	tomato_visual.visible = held_item == "Tomato"
	chopped_visual.visible = held_item == "Chopped tomato"
	plate_visual.visible = held_item == "Plate" or held_item == "Tomato soup"
	if held_item == "Tomato soup":
		tomato_visual.visible = true
		tomato_visual.material_override = _material(Color("#e95c45"))
	elif held_item == "Tomato":
		tomato_visual.material_override = _material(Color("#ed514b"))

func _update_board_visual() -> void:
	if board_whole_tomato_visual:
		board_whole_tomato_visual.visible = board_has_tomato
	if board_tomato_visual:
		board_tomato_visual.visible = board_has_chopped_tomato
