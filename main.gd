extends Node3D # Inheritance of Node3D class

class OrderCard extends Control:
	var order_data: Dictionary

	func _init(data: Dictionary) -> void:
		order_data = data
		custom_minimum_size = Vector2(253, 132)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

# HUD Graphics
	func _draw() -> void:
		var patience: int = order_data.get("patience", 0)
		var recipe_name: String = order_data.get("recipe", "DISH")
		var recipe_color: Color = Color(order_data.get("color", "#ed514b"))
		
		var card_color := Color("#fff3d0")
		var border_color := Color("#d5b978")
		draw_style_box(_panel_style(card_color, border_color, 8, 1), Rect2(Vector2.ZERO, size))

		draw_rect(Rect2(10, 9, size.x - 20, 8), Color("#c7c5b8"))
		draw_rect(Rect2(10, 9, (size.x - 20) * patience / 100.0, 8), Color("#61b879"))

		draw_circle(Vector2(35, 54), 19, Color("#f1e4c4"))
		draw_arc(Vector2(35, 54), 19, 0, TAU, 24, Color("#b7c8ce"), 2)
		draw_circle(Vector2(35, 53), 13, recipe_color)
		draw_arc(Vector2(35, 53), 13, 0, PI, 16, Color("#f2c56b"), 2)
		draw_string(ThemeDB.fallback_font, Vector2(21, 82), "XMAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#26384a"))

		draw_string(ThemeDB.fallback_font, Vector2(64, 43), recipe_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#26384a"))
		draw_string(ThemeDB.fallback_font, Vector2(64, 78), "ORDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#66737b"))
		
		draw_rect(Rect2(166, 98, 24, 10), Color("#5d6872"))
		draw_circle(Vector2(178, 97), 9, Color("#303d4a"))
		draw_arc(Vector2(178, 97), 9, 0, TAU, 16, Color("#d5a74c"), 2)
		draw_string(ThemeDB.fallback_font, Vector2(195, 105), "XMAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#26384a"))

	func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(border_width)
		style.set_corner_radius_all(radius)
		return style

# Room dimensions
const FLOOR_SIZE := Vector3(22, 0.3, 13)

# List of stations
const STATION_NAMES := {
	"fish_crate": "FISH CRATE",
	"carrot_crate": "CARROT CRATE",
	"potato_crate": "POTATO CRATE",
	"dough_crate": "DOUGH CRATE",
	"mayo_crate": "MAYO CRATE",
	"cut": "CUTTING BOARD",
	"cook": "STOCK POT",
	"oven": "OVEN",
	"plates": "PLATE COUNTER",
	"serve": "SERVING WINDOW"
}

# Christmas recipes
const RECIPES := {
	"Rybí polévka": {
		"ingredients": ["Fish", "Chopped carrot"],
		"station": "cook",
		"prep_time": 7.0,
		"result_item": "Fish soup",
		"color": "#3b6ba5"
	},
	"Bramborový salát": {
		"ingredients": ["Chopped potato", "Mayonnaise"],
		"station": "cut",
		"prep_time": 4.0,
		"result_item": "Potato salad",
		"color": "#f2c56b"
	},
	"Vánoční cukroví": {
		"ingredients": ["Dough"],
		"station": "oven",
		"prep_time": 5.0,
		"result_item": "Cookies",
		"color": "#d5a74c"
	}
}

# Variables
var chef: CharacterBody3D
var chef_mesh: Node3D
var beaver_animation: AnimationPlayer
var beaver_animation_name := ""
var beaver_target_yaw := deg_to_rad(-90.0)
var held_item_offset := Vector3(0.8, 0.25, 0.4)
var nearest_station := ""
var held_item := "Empty hands"

var board_has_item := false
var board_has_chopped_item := false
var current_board_ingredient := ""

var cutting_remaining := 0.0
var cooking_remaining := 0.0
var baking_remaining := 0.0

var dish_ready := false
var oven_ready := false
var current_cooking_recipe := ""

var score := 0
var combo := 0
var time_left := 120
var is_paused := false
var game_over := false
var orders: Array[Dictionary] = []
var next_order_id := 1
var station_nodes: Dictionary = {}

var restart_label: Label
var time_label: Label
var score_label: Label
var pause_overlay: ColorRect
var pause_title: Label
var pause_hint: Label
var final_overlay: ColorRect
var final_title: Label
var final_score_label: Label
var final_restart_label: Label
var orders_container: VBoxContainer
var timer: Timer

var held_visual: Node3D
var item_visual: MeshInstance3D
var chopped_visual: MeshInstance3D
var plate_visual: MeshInstance3D
var pot_animation: Node3D
var pot_progress_label: Label3D
var oven_animation: Node3D
var oven_progress_label: Label3D
var cutting_animation: Node3D
var cutting_progress_label: Label3D
var board_chopped_visual: MeshInstance3D
var board_whole_visual: MeshInstance3D
var knife_visual: MeshInstance3D

var walk_phase := 0.0
var putting_remaining := 0.0
var putting_total := 0.45

# Functions call
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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

# Keybinds
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

# Environment
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
	_add_box("BackWall", Vector3(22, 3.2, 0.3), Vector3(0, 1.45, -6.35), Color("#294052"))
	_add_box("LeftWall", Vector3(0.3, 3.2, 13), Vector3(-11, 1.45, 0), Color("#294052"))
	_add_box("RightWall", Vector3(0.3, 3.2, 13), Vector3(11, 1.45, 0), Color("#294052"))
	_add_kitchen_tools()

	# Stanice rozmístěné podle počtu
	var positions := {
		"fish_crate": -9.0,
		"carrot_crate": -7.0,
		"potato_crate": -5.0,
		"dough_crate": -3.0,
		"mayo_crate": -1.0,
		"cut": 1.0,
		"cook": 3.0,
		"oven": 5.0,
		"plates": 7.0,
		"serve": 9.0
	}
	for station_id in positions:
		var station_z := -4.4 if station_id != "plates" else -2.4
		var station := _create_station(station_id, Vector3(positions[station_id], 0.8, station_z))
		station_nodes[station_id] = station
		if station_id == "cook":
			_create_pot_animation(station)
		if station_id == "oven":
			_create_oven_animation(station)
		if station_id == "cut":
			_create_cutting_animation(station)

# Character
	chef = CharacterBody3D.new()
	chef.name = "Beaver"
	chef.position = Vector3(0, 0.65, 2.5)
	add_child(chef)
	var beaver_scene := load("res://assets/beaver/scene.gltf") as PackedScene
	if not beaver_scene:
		push_error("Could not load the beaver model.")
		return
	chef_mesh = beaver_scene.instantiate()
	chef_mesh.scale = Vector3(0.09, 0.09, 0.09)
	chef_mesh.position.y = -0.65
	chef_mesh.rotation_degrees.y = 90.0
	chef.add_child(chef_mesh)
	
	var chef_shape := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.height = 1.45
	capsule_shape.radius = 0.38
	chef_shape.shape = capsule_shape
	chef.add_child(chef_shape)

	var animation_players := chef_mesh.find_children("*", "AnimationPlayer", true, false)
	if not animation_players.is_empty():
		beaver_animation = animation_players[0] as AnimationPlayer

	held_visual = Node3D.new()
	var skeletons := chef_mesh.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		var skeleton := skeletons[0] as Skeleton3D
		var right_wrist := BoneAttachment3D.new()
		right_wrist.name = "RightHandAttachment"
		var wrist_bone := skeleton.find_bone("Wrist_R_013")
		if wrist_bone >= 0:
			right_wrist.set_bone_idx(wrist_bone)
		skeleton.add_child(right_wrist)
		right_wrist.add_child(held_visual)
		held_visual.scale = Vector3(
			1.0 / chef_mesh.scale.x,
			1.0 / chef_mesh.scale.y,
			1.0 / chef_mesh.scale.z
		)
		held_visual.position = held_item_offset
	else:
		held_visual.position = held_item_offset
		chef.add_child(held_visual)

	item_visual = MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.16
	sphere_mesh.height = 0.32
	item_visual.mesh = sphere_mesh
	item_visual.material_override = _material(Color("#ed514b"))
	item_visual.visible = false
	held_visual.add_child(item_visual)

	chopped_visual = MeshInstance3D.new()
	var chopped_mesh := BoxMesh.new()
	chopped_mesh.size = Vector3(0.28, 0.08, 0.28)
	chopped_visual.mesh = chopped_mesh
	chopped_visual.material_override = _material(Color("#ed514b"))
	chopped_visual.position.y = -0.1
	chopped_visual.visible = false
	held_visual.add_child(chopped_visual)

	plate_visual = MeshInstance3D.new()
	var plate_mesh := CylinderMesh.new()
	plate_mesh.top_radius = 0.27
	plate_mesh.bottom_radius = 0.27
	plate_mesh.height = 0.05
	plate_visual.mesh = plate_mesh
	plate_visual.material_override = _material(Color("#fff4d6"))
	plate_visual.visible = false
	plate_visual.position.y = -0.12
	held_visual.add_child(plate_visual)
	
	_update_held_visual()

	var camera := Camera3D.new()
	camera.position = Vector3(0, 13, 14)
	camera.rotation_degrees = Vector3(-40, 0, 0)
	camera.current = true
	add_child(camera)

func _add_box(node_name: String, size: Vector3, position: Vector3, color: Color, show_mesh: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	mesh.visible = show_mesh
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _add_kitchen_tools() -> void:
	var kitchen_scene := load("res://assets/kitchen_tools/scene.gltf") as PackedScene
	if not kitchen_scene:
		push_error("Could not load the kitchen tools model.")
		return
	var kitchen := kitchen_scene.instantiate() as Node3D
	if not kitchen:
		push_error("The kitchen tools scene has no Node3D root.")
		return
	kitchen.name = "KitchenTools"
	kitchen.position = Vector3(0, 0, -4.4)
	_hide_kitchen_floor(kitchen)
	add_child(kitchen)

func _hide_kitchen_floor(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var is_floor := mesh_instance.name.begins_with("Object_2")
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.get_active_material(surface)
			if material and material.resource_name.to_lower().contains("floor"):
				is_floor = true
		if is_floor:
			mesh_instance.visible = false
	for child in node.get_children():
		_hide_kitchen_floor(child)

func _create_station(station_id: String, position: Vector3) -> StaticBody3D:
	var station := _add_box(STATION_NAMES[station_id], Vector3(1.8, 1.5, 1.2), position, _station_color(station_id), false)
	var sign := Label3D.new()
	sign.text = STATION_NAMES[station_id]
	sign.position = Vector3(0, 1.35, 0)
	sign.font_size = 24
	sign.modulate = Color("#fff3d0")
	sign.outline_size = 8
	sign.outline_modulate = Color("#142235")
	station.add_child(sign)
	
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
		board_whole_visual = MeshInstance3D.new()
		var whole_mesh := SphereMesh.new()
		whole_mesh.radius = 0.16
		whole_mesh.height = 0.32
		board_whole_visual.mesh = whole_mesh
		board_whole_visual.position = Vector3(0, 0.98, 0)
		board_whole_visual.visible = false
		station.add_child(board_whole_visual)

		board_chopped_visual = MeshInstance3D.new()
		var chopped_mesh := BoxMesh.new()
		chopped_mesh.size = Vector3(0.28, 0.08, 0.28)
		board_chopped_visual.mesh = chopped_mesh
		board_chopped_visual.position = Vector3(0, 0.82, 0)
		board_chopped_visual.visible = false
		station.add_child(board_chopped_visual)
		
	return station

func _create_pot_animation(station: StaticBody3D) -> void:
	pot_animation = Node3D.new()
	pot_animation.position = Vector3(0, 1.65, 0)
	pot_animation.visible = false
	station.add_child(pot_animation)
	pot_progress_label = Label3D.new()
	pot_progress_label.text = "COOKING..."
	pot_progress_label.position = Vector3(0, 0.65, 0)
	pot_progress_label.font_size = 24
	pot_progress_label.modulate = Color("#f4ca67")
	pot_progress_label.outline_size = 8
	pot_progress_label.outline_modulate = Color("#142235")
	pot_animation.add_child(pot_progress_label)

func _create_oven_animation(station: StaticBody3D) -> void:
	oven_animation = Node3D.new()
	oven_animation.position = Vector3(0, 1.65, 0)
	oven_animation.visible = false
	station.add_child(oven_animation)
	oven_progress_label = Label3D.new()
	oven_progress_label.text = "BAKING..."
	oven_progress_label.position = Vector3(0, 0.65, 0)
	oven_progress_label.font_size = 24
	oven_progress_label.modulate = Color("#f4ca67")
	oven_progress_label.outline_size = 8
	oven_progress_label.outline_modulate = Color("#142235")
	oven_animation.add_child(oven_progress_label)

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
	cutting_progress_label.font_size = 24
	cutting_progress_label.modulate = Color("#f4ca67")
	cutting_progress_label.outline_size = 8
	cutting_progress_label.outline_modulate = Color("#142235")
	cutting_animation.add_child(cutting_progress_label)

func _update_pot_animation() -> void:
	if not pot_animation:
		return
	pot_animation.visible = cooking_remaining > 0.0 or dish_ready
	if cooking_remaining > 0.0:
		pot_progress_label.text = "COOKING %.1fs" % cooking_remaining

func _update_oven_animation() -> void:
	if not oven_animation:
		return
	oven_animation.visible = baking_remaining > 0.0 or oven_ready
	if baking_remaining > 0.0:
		oven_progress_label.text = "BAKING %.1fs" % baking_remaining

func _update_cutting_animation() -> void:
	if not cutting_animation:
		return
	cutting_animation.visible = cutting_remaining > 0.0
	if cutting_remaining > 0.0:
		cutting_progress_label.text = "CHOPPING %.1fs" % cutting_remaining

func _station_color(station_id: String) -> Color:
	return {
		"fish_crate": Color("#3b6ba5"),
		"carrot_crate": Color("#e67e22"),
		"potato_crate": Color("#c49142"),
		"dough_crate": Color("#dfc086"),
		"mayo_crate": Color("#e0e0e0"),
		"cut": Color("#bf5b50"),
		"cook": Color("#d47b46"),
		"oven": Color("#8c5643"),
		"plates": Color("#8b73b9"),
		"serve": Color("#d3a64b")
	}[station_id]

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material

func _physics_process(delta: float) -> void:
	if not chef:
		return
	if is_paused or game_over:
		chef.velocity = Vector3.ZERO
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	chef.velocity = Vector3(input.x, 0, input.y) * 4.8
	chef.move_and_slide()
	_update_walk_animation(input, delta)
	_update_action_animation(delta)
	chef.position.x = clamp(chef.position.x, -10.0, 10.0)
	chef.position.z = clamp(chef.position.z, -2.4, 5.4)
	_update_nearest_station()
	if Input.is_action_just_pressed("interact") and nearest_station != "":
		_interact(nearest_station)

func _play_beaver_animation(names: Array[String]) -> void:
	if not beaver_animation:
		return
	for clip_name in names:
		if beaver_animation.has_animation(clip_name):
			if beaver_animation_name != clip_name:
				beaver_animation_name = clip_name
				var clip := beaver_animation.get_animation(clip_name)
				if clip:
					clip.loop_mode = Animation.LOOP_LINEAR
				beaver_animation.play(clip_name)
			return

func _update_walk_animation(input: Vector2, delta: float) -> void:
	if input.length() > 0.05:
		walk_phase += delta * 11.0
		beaver_target_yaw = deg_to_rad(-90.0) + atan2(input.x, input.y)
		chef_mesh.rotation.y = lerp_angle(chef_mesh.rotation.y, beaver_target_yaw, delta * 10.0)
		chef_mesh.position.y = abs(sin(walk_phase)) * 0.06
		chef_mesh.rotation.z = sin(walk_phase) * 0.045
		held_visual.position.y = held_item_offset.y + abs(sin(walk_phase)) * 0.035
		if held_item == "Empty hands":
			_play_beaver_animation(["Idle_Walk"])
		else:
			_play_beaver_animation(["IdleCarry_Walk"])
	else:
		walk_phase = 0.0
		chef_mesh.position.y = lerpf(chef_mesh.position.y, 0.0, delta * 12.0)
		chef_mesh.rotation.z = lerpf(chef_mesh.rotation.z, 0.0, delta * 12.0)
		held_visual.position.y = lerpf(held_visual.position.y, held_item_offset.y, delta * 12.0)
		if held_item == "Empty hands":
			_play_beaver_animation(["Idle_Swim", "Idle_Walk"])
		else:
			_play_beaver_animation(["IdleCarry_Swim", "IdleCarry_Walk"])

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
		held_visual.position.z = held_item_offset.z - put_wave * 0.28
	else:
		chef_mesh.rotation.x = lerpf(chef_mesh.rotation.x, 0.0, delta * 14.0)
		held_visual.position.z = lerpf(held_visual.position.z, held_item_offset.z, delta * 14.0)

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

# Interaction logic for all items and recipes
func _interact(station_id: String) -> void:
	match station_id:
		"fish_crate":
			if held_item == "Empty hands":
				_set_held_item("Fish")
				_start_put_animation()
			elif held_item == "Fish":
				_set_held_item("Empty hands")
				_start_put_animation()

		"carrot_crate":
			if held_item == "Empty hands":
				_set_held_item("Carrot")
				_start_put_animation()
			elif held_item == "Carrot":
				_set_held_item("Empty hands")
				_start_put_animation()

		"potato_crate":
			if held_item == "Empty hands":
				_set_held_item("Potato")
				_start_put_animation()
			elif held_item == "Potato":
				_set_held_item("Empty hands")
				_start_put_animation()

		"dough_crate":
			if held_item == "Empty hands":
				_set_held_item("Dough")
				_start_put_animation()
			elif held_item == "Dough":
				_set_held_item("Empty hands")
				_start_put_animation()

		"mayo_crate":
			if held_item == "Empty hands":
				_set_held_item("Mayonnaise")
				_start_put_animation()
			elif held_item == "Mayonnaise":
				_set_held_item("Empty hands")
				_start_put_animation()

		"cut":
			if held_item in ["Chopped carrot", "Chopped potato"]:
				if not board_has_item and not board_has_chopped_item:
					board_has_chopped_item = true
					current_board_ingredient = held_item.replace("Chopped ", "").capitalize()
					_set_held_item("Empty hands")
					_update_board_visual()
					_start_put_animation()
			elif held_item in ["Carrot", "Potato"]:
				if not board_has_item and not board_has_chopped_item:
					board_has_item = true
					current_board_ingredient = held_item
					_set_held_item("Empty hands")
					_update_board_visual()
					_start_put_animation()
			elif held_item == "Empty hands" and board_has_chopped_item:
				board_has_chopped_item = false
				_set_held_item("Chopped " + current_board_ingredient.to_lower())
				_update_board_visual()
				_start_put_animation()
			elif held_item == "Empty hands" and board_has_item and cutting_remaining <= 0.0:
				board_has_item = false
				cutting_remaining = 2.0
				_update_cutting_animation()

		"cook":
			if held_item == "Plate" and dish_ready:
				dish_ready = false
				_set_held_item(current_cooking_recipe)
				current_cooking_recipe = ""
				_start_put_animation()
				_update_pot_animation()
			elif held_item == "Fish" or held_item == "Chopped carrot":
				if cooking_remaining > 0.0 or dish_ready:
					return
				# Vaříme Rybí polévku
				current_cooking_recipe = RECIPES["Rybí polévka"]["result_item"]
				cooking_remaining = RECIPES["Rybí polévka"]["prep_time"]
				_set_held_item("Empty hands")
				_start_put_animation()
				_update_pot_animation()

		"oven":
			if held_item == "Plate" and oven_ready:
				oven_ready = false
				_set_held_item("Cookies")
				_start_put_animation()
				_update_oven_animation()
			elif held_item == "Dough":
				if baking_remaining > 0.0 or oven_ready:
					return
				baking_remaining = RECIPES["Vánoční cukroví"]["prep_time"]
				_set_held_item("Empty hands")
				_start_put_animation()
				_update_oven_animation()

		"plates":
			if held_item == "Plate":
				_set_held_item("Empty hands")
				_start_put_animation()
			elif held_item == "Empty hands":
				_set_held_item("Plate")
				_start_put_animation()

		"serve":
			if held_item in ["Fish soup", "Potato salad", "Cookies"]:
				if orders.is_empty():
					return
				var top_order = orders[0]
				var required_result = RECIPES[top_order["recipe"]]["result_item"]
				
				if held_item == required_result:
					var patience: int = top_order.patience
					orders.pop_front()
					var patience_points := 150 if patience >= 66 else 100 if patience >= 33 else 50
					var points := patience_points + combo * 25
					score += points
					combo += 1
					_set_held_item("Empty hands")
					_start_put_animation()
					_spawn_order()
	_update_hud()

func _spawn_order() -> void:
	var recipe_keys := RECIPES.keys()
	var random_recipe_name: String = recipe_keys[randi() % recipe_keys.size()]
	var recipe_info: Dictionary = RECIPES[random_recipe_name]
	
	orders.append({
		"id": next_order_id,
		"patience": 100,
		"recipe": random_recipe_name,
		"ingredients": recipe_info["ingredients"],
		"color": recipe_info["color"]
	})
	next_order_id += 1

func _tick() -> void:
	if time_left <= 0:
		_finish_game()
		return
	time_left -= 1
	
	if cutting_remaining > 0.0:
		cutting_remaining = maxf(0.0, cutting_remaining - 1.0)
		_update_cutting_animation()
		if cutting_remaining == 0.0:
			board_has_chopped_item = true
			_update_board_visual()

	if cooking_remaining > 0.0:
		cooking_remaining = maxf(0.0, cooking_remaining - 1.0)
		_update_pot_animation()
		if cooking_remaining == 0.0:
			dish_ready = true
			if pot_animation:
				pot_animation.visible = true
				pot_progress_label.text = "READY!"

	if baking_remaining > 0.0:
		baking_remaining = maxf(0.0, baking_remaining - 1.0)
		_update_oven_animation()
		if baking_remaining == 0.0:
			oven_ready = true
			if oven_animation:
				oven_animation.visible = true
				oven_progress_label.text = "READY!"

	for order in orders:
		order.patience = maxi(0, order.patience - 1)

	if time_left == 0:
		_finish_game()
	
	if time_left % 25 == 0 and orders.size() < 3:
		_spawn_order()
		
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_restart()
		elif event.keycode == KEY_ESCAPE:
			if game_over:
				return
			if is_paused:
				_unpause()
			else:
				_pause()

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	
	restart_label = _label("PRESS R TO RESTART", Color("#ffffff"), 18)
	restart_label.position = Vector2(419, 638)
	canvas.add_child(restart_label)

	score_label = _label("SCORE  0", Color("#f4ca67"), 20)
	score_label.position = Vector2(42, 638)
	canvas.add_child(score_label)

	time_label = _label("TIME  2:00", Color("#ef6b62"), 20)
	time_label.position = Vector2(910, 638)
	canvas.add_child(time_label)

	orders_container = VBoxContainer.new()
	orders_container.position = Vector2(33, 30)
	orders_container.size = Vector2(253, 395)
	orders_container.add_theme_constant_override("separation", 8)
	canvas.add_child(orders_container)

	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.03, 0.05, 0.09, 0.78)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	canvas.add_child(pause_overlay)

	pause_title = _label("Paused", Color("#fff3d0"), 48)
	pause_title.position = Vector2(0, 270)
	pause_title.size = Vector2(1100, 60)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.visible = false
	canvas.add_child(pause_title)

	pause_hint = _label("Press Esc to resume", Color("#b4c6cf"), 22)
	pause_hint.position = Vector2(0, 338)
	pause_hint.size = Vector2(1100, 40)
	pause_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_hint.visible = false
	canvas.add_child(pause_hint)

	final_overlay = ColorRect.new()
	final_overlay.color = Color(0.03, 0.05, 0.09, 0.86)
	final_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	final_overlay.visible = false
	canvas.add_child(final_overlay)

	final_title = _label("Time's Up!", Color("#fff3d0"), 48)
	final_title.position = Vector2(0, 245)
	final_title.size = Vector2(1100, 60)
	final_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_title.visible = false
	canvas.add_child(final_title)

	final_score_label = _label("Final Score: 0", Color("#f4ca67"), 30)
	final_score_label.position = Vector2(0, 320)
	final_score_label.size = Vector2(1100, 45)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_score_label.visible = false
	canvas.add_child(final_score_label)

	final_restart_label = _label("Press R to restart", Color("#b4c6cf"), 20)
	final_restart_label.position = Vector2(0, 380)
	final_restart_label.size = Vector2(1100, 35)
	final_restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_restart_label.visible = false
	canvas.add_child(final_restart_label)

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
	
	for child in orders_container.get_children():
		child.queue_free()
		
	if orders.is_empty():
		var empty_label := _label("No customers waiting.", Color("#b4c6cf"), 13)
		orders_container.add_child(empty_label)
	else:
		for order in orders:
			orders_container.add_child(OrderCard.new(order))

func _restart() -> void:
	is_paused = false
	game_over = false
	get_tree().paused = false
	score = 0
	combo = 0
	time_left = 120
	chef.position = Vector3(0, 0.65, 2.5)
	chef.velocity = Vector3.ZERO
	cooking_remaining = 0.0
	baking_remaining = 0.0
	cutting_remaining = 0.0
	board_has_item = false
	board_has_chopped_item = false
	dish_ready = false
	oven_ready = false
	orders.clear()
	next_order_id = 1
	_spawn_order()
	timer.start()
	_set_held_item("Empty hands")
	_start_put_animation()
	_update_pot_animation()
	_update_oven_animation()
	_update_cutting_animation()
	_update_board_visual()
	pause_overlay.visible = false
	pause_title.visible = false
	pause_hint.visible = false
	final_overlay.visible = false
	final_title.visible = false
	final_score_label.visible = false
	final_restart_label.visible = false

func _pause() -> void:
	is_paused = true
	get_tree().paused = true
	timer.stop()
	pause_overlay.visible = true
	pause_title.visible = true
	pause_hint.visible = true

func _unpause() -> void:
	is_paused = false
	get_tree().paused = false
	timer.start()
	pause_overlay.visible = false
	pause_title.visible = false
	pause_hint.visible = false

func _finish_game() -> void:
	game_over = true
	is_paused = false
	chef.velocity = Vector3.ZERO
	get_tree().paused = false
	timer.stop()
	final_score_label.text = "Final Score: %d" % score
	final_overlay.visible = true
	final_title.visible = true
	final_score_label.visible = true
	final_restart_label.visible = true

func _set_held_item(item: String) -> void:
	held_item = item
	_update_held_visual()
	_update_hud()

func _start_put_animation() -> void:
	putting_remaining = putting_total

func _update_held_visual() -> void:
	if not item_visual or not plate_visual:
		return
		
	item_visual.visible = held_item in ["Fish", "Carrot", "Potato", "Dough", "Mayonnaise"]
	chopped_visual.visible = held_item in ["Chopped carrot", "Chopped potato"]
	plate_visual.visible = held_item in ["Plate", "Fish soup", "Potato salad", "Cookies"]
	
	if held_item == "Fish":
		item_visual.material_override = _material(Color("#3b6ba5"))
	elif held_item == "Carrot":
		item_visual.material_override = _material(Color("#e67e22"))
	elif held_item == "Potato":
		item_visual.material_override = _material(Color("#c49142"))
	elif held_item == "Dough":
		item_visual.material_override = _material(Color("#dfc086"))
	elif held_item == "Mayonnaise":
		item_visual.material_override = _material(Color("#ffffff"))
	elif held_item == "Fish soup":
		item_visual.visible = true
		item_visual.material_override = _material(Color("#3b6ba5"))
	elif held_item == "Potato salad":
		item_visual.visible = true
		item_visual.material_override = _material(Color("#f2c56b"))
	elif held_item == "Cookies":
		item_visual.visible = true
		item_visual.material_override = _material(Color("#d5a74c"))

func _update_board_visual() -> void:
	if board_whole_visual:
		board_whole_visual.visible = board_has_item
		if board_has_item:
			if current_board_ingredient == "Carrot":
				board_whole_visual.material_override = _material(Color("#e67e22"))
			elif current_board_ingredient == "Potato":
				board_whole_visual.material_override = _material(Color("#c49142"))
				
	if board_chopped_visual:
		board_chopped_visual.visible = board_has_chopped_item
		if board_has_chopped_item:
			if current_board_ingredient == "Carrot":
				board_chopped_visual.material_override = _material(Color("#e67e22"))
			elif current_board_ingredient == "Potato":
				board_chopped_visual.material_override = _material(Color("#c49142"))
