extends Node3D # Inheritance of Node3D class

class OrderCard extends Control:
	var order_data: Dictionary

	func _init(data: Dictionary) -> void:
		order_data = data
		custom_minimum_size = Vector2(253, 132)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	const INGREDIENT_DISPLAY_NAMES := {
		"Chopped fish": "Nakrájená ryba",
		"Boiled potato": "Vařené brambory",
		"Mayonnaise": "Majonéza",
		"Dough": "Těsto",
		"Sugar": "Cukr"
	}
	const STATION_ICONS := {
		"cook": preload("res://assets/kitchen_images/pot.png"),
		"oven": preload("res://assets/kitchen_images/oven.png"),
		"mixer": preload("res://assets/kitchen_images/mixer.png")
	}

# HUD Graphics
	func _draw() -> void:
		var patience: int = order_data.get("patience", 0)
		var recipe_name: String = order_data.get("recipe", "DISH")
		var ingredients: Array = order_data.get("ingredients", [])
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
		var stations: Array[String] = [order_data.get("station", "")]
		if order_data.get("recipe", "") == "Bramborový salát":
			stations = ["cook", "mixer"]

		var icon_x := 64.0
		for station in stations:
			if STATION_ICONS.has(station):
				var icon_y := 80.0
				if station == "mixer":
					icon_y = 78.0
				draw_texture_rect(STATION_ICONS[station],Rect2(icon_x, icon_y, 20, 20),false)
				icon_x += 24.0

		draw_string(ThemeDB.fallback_font, Vector2(64, 43), recipe_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#26384a"))
		draw_string(ThemeDB.fallback_font, Vector2(64, 61), "INGREDIENCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#66737b"))
		draw_string(ThemeDB.fallback_font, Vector2(64, 75), ", ".join(PackedStringArray(ingredients.map(func(ingredient): return INGREDIENT_DISPLAY_NAMES.get(ingredient, ingredient)))), HORIZONTAL_ALIGNMENT_LEFT, -1, 9,Color("#26384a"))

	func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(border_width)
		style.set_corner_radius_all(radius)
		return style

# List of stations
const STATION_NAMES := {
	"fish_crate": "RYBA",
	"potato_crate": "BRAMBORY",
	"dough_crate": "TĚSTO",
	"mayo_crate": "MAJONÉZA",
	"sugar_crate": "CUKR",
	"cut": "KRÁJECÍ PRKÉNKO",
	"cook": "HRNEC",
	"oven": "TROUBA",
	"mixer": "MIXÉR",
	"plates": "TALÍŘE",
	"serve": "VÝDEJNÍ OKNO",
	"trash": "KOŠ"
}

const INGREDIENT_STATIONS := {
	"fish_crate": "Fish",
	"potato_crate": "Potato",
	"dough_crate": "Dough",
	"mayo_crate": "Mayonnaise",
	"sugar_crate": "Sugar"
}

const PREPARATIONS := {
	"Boil potatoes": {
		"ingredients": ["Potato"],
		"station": "cook",
		"prep_time": 10.0,
		"result_item": "Boiled potato"
	}
}

# Christmas recipes
const RECIPES := {
	"Rybí polévka": {
		"ingredients": ["Chopped fish"],
		"station": "cook",
		"prep_time": 7.0,
		"result_item": "Fish soup",
		"color": "#3b6ba5"
	},
	"Bramborový salát": {
		"ingredients": ["Boiled potato", "Mayonnaise"],
		"station": "mixer",
		"prep_time": 0.0,
		"result_item": "Potato salad",
		"color": "#f2c56b"
	},
	"Vánoční cukroví": {
		"ingredients": ["Dough", "Sugar"],
		"station": "oven",
		"prep_time": 12.0,
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
var held_item_on_plate := false

var board_has_item := false
var board_has_chopped_item := false
var current_board_ingredient := ""

var cutting_remaining := 0.0
var station_ingredients: Dictionary = {}
var station_remaining: Dictionary = {}
var ready_dishes: Dictionary = {}
var active_recipes: Dictionary = {}

var score := 0
var combo := 0
var time_left := 300
var is_paused := false
var game_over := false
var orders: Array[Dictionary] = []
var next_order_id := 1
var station_nodes: Dictionary = {}
var board_food_visual: Node3D

var restart_label: Label
var music_skip_label: Label
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
var mixer_animation: Node3D
var mixer_progress_label: Label3D
var prep_animations: Dictionary = {}
var prep_progress_labels: Dictionary = {}
var cutting_animation: Node3D
var cutting_progress_label: Label3D
var knife_visual: MeshInstance3D

var walk_phase := 0.0
var putting_remaining := 0.0
var putting_total := 0.45

var music_tracks: Array[AudioStream] = [
	preload("res://assets/music/Bobby Helms - Jingle Bell Rock.mp3"),
	preload("res://assets/music/Dean Martin - Let It Snow! Let It Snow! Let It Snow!.mp3"),
	preload("res://assets/music/Wham! - Last Christmas.mp3")
]
var music_player: AudioStreamPlayer
var current_music_track := -1

# Functions call
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_build_world()
	_build_hud()
	_start_music()
	_spawn_order()
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()
	_update_hud()

# Keybinds
func _setup_input() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "interact", "skip_music"]:
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
	_bind("skip_music", KEY_N)

func _bind(action: String, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

# Environment
func _build_world() -> void:
	var tool_positions := {
		"cut": Vector3(-9.5, 0.8, -5.0),
		"cook": Vector3(-9.5, 0.8, -2.5),
		"oven": Vector3(-9.5, 0.8, 0.0),
		"mixer": Vector3(-9.5, 0.8, 2.5),
		"plates": Vector3(-3.0, 0.8, -5.0),
		"serve": Vector3(0.0, 0.8, -5.0),
		"trash": Vector3(-9.5, 0.8, 5.5)
	}
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
	
	var tree_scene := load("res://assets/christmas_tree/scene.gltf") as PackedScene
	if tree_scene:
		var tree := tree_scene.instantiate()
		tree.position = Vector3(20.0, 0.0, -10)
		tree.scale = Vector3(0.04, 0.04, 0.04)
		add_child(tree)

	_add_box("Floor", Vector3(18, 0.3, 13), Vector3(-2.1, -0.15, 0), Color("#b99571"))
	_add_box("BackWall", Vector3(18, 3.2, 0.3), Vector3(-2.1, 1.45, -6.35), Color("#294052"))
	_add_box("LeftWall", Vector3(0.3, 3.2, 13), Vector3(-11, 1.45, 0), Color("#294052"))
	
	var background_texture := load("res://assets/chrismas_background.jpg") as Texture2D
	if background_texture:
		var background := Sprite3D.new()
		background.texture = background_texture
		background.position = Vector3(0.0, -17.0, -100.0)
		background.pixel_size = 0.14
		add_child(background)

	var ingredient_ids: Array = INGREDIENT_STATIONS.keys()
	for index in range(ingredient_ids.size()):
		var station_id: String = ingredient_ids[index]
		var station_position := Vector3(5.5, 0.8, -4.5 + index * 1.8)
		var station := _create_station(station_id, station_position)
		station.rotation_degrees.y = -90
		station_nodes[station_id] = station

	for station_id in tool_positions:
		var station := _create_station(station_id, tool_positions[station_id])
		if station_id in ["cut", "cook", "oven", "mixer"]:
			station.rotation_degrees.y = 90
		station_nodes[station_id] = station
		match station_id:
			"cook":
				_create_pot_animation(station)
			"oven":
				_create_oven_animation(station)
			"mixer":
				_create_mixer_animation(station)
			"cut":
				_create_cutting_animation(station)

# Character
	chef = CharacterBody3D.new()
	chef.name = "Beaver"
	chef.position = Vector3.ZERO
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

func _create_station(station_id: String, position: Vector3) -> StaticBody3D:
	var station := _add_box(STATION_NAMES[station_id], Vector3(1.8, 1.5, 1.2), position, _station_color(station_id), false)
	var sign := Label3D.new()
	sign.text = STATION_NAMES[station_id]
	sign.position = Vector3(0, 1.45, 0)
	sign.font_size =  64
	sign.modulate = Color("#fff3d0")
	sign.outline_size = 8
	sign.outline_modulate = Color("#142235")
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station.add_child(sign)
	if INGREDIENT_STATIONS.has(station_id):
		_create_crate_model(station, station_id)
	else:
		_create_station_model(station, station_id)
	return station

func _create_crate_model(station: StaticBody3D, station_id: String) -> void:
	var crate_body := BoxMesh.new()
	var crate_position := Vector3(0, -0.35, 0)
	if station_id == "serve":
		crate_body.size = Vector3(1.8, 0.9, 1.05)
		crate_position.y = -0.25
	else:
		crate_body.size = Vector3(1.05, 0.7, 1.05)
	_add_station_mesh(station, crate_body, crate_position, Color("#8a5939"))

	for index in range(2):
		var slat := BoxMesh.new()
		slat.size = Vector3(crate_body.size.x + 0.02, 0.1, 0.05)
		var slat_y := -0.52 + index * 0.22 if station_id != "serve" else -0.52 + index * 0.3
		_add_station_mesh(station, slat, Vector3(0, slat_y, crate_body.size.z / 2.0 + 0.025), Color("#b17a50"))

func _create_station_model(station: StaticBody3D, station_id: String) -> void:
	match station_id:
		"cut":
			_create_cutting_board_model(station)
		"cook":
			_create_stock_pot_station_model(station)
		"oven":
			_create_oven_station_model(station)
		"mixer":
			_create_mixer_station_model(station)
		"plates":
			_create_plate_station_model(station)
		"serve":
			_create_serving_window_model(station)
		"trash":
			_create_trash_can_model(station)

func _create_cutting_board_model(station: StaticBody3D) -> void:
	_create_counter_model(station, Color("#80533b"))
	var board := BoxMesh.new()
	board.size = Vector3(1.35, 0.12, 0.86)
	_add_station_mesh(station, board, Vector3(0, 0.3, 0), Color("#d2a36b"))
	var groove := BoxMesh.new()
	groove.size = Vector3(1.08, 0.02, 0.035)
	_add_station_mesh(station, groove, Vector3(0, 0.367, 0.32), Color("#9b704d"))
	var fish := SphereMesh.new()
	var fish_visual := _add_station_mesh(station, fish, Vector3(0, 0.4, 0), Color("#3b6ba5"))
	fish_visual.scale = Vector3(0.34, 0.12, 0.13)
	fish_visual.visible = false
	board_food_visual = fish_visual

func _create_stock_pot_station_model(station: StaticBody3D) -> void:
	_create_counter_model(station, Color("#303d4a"))
	var cooktop := BoxMesh.new()
	cooktop.size = Vector3(1.65, 0.12, 1.05)
	_add_station_mesh(station, cooktop, Vector3(0, 0.31, 0), Color("#647487"))
	for x in [-0.42, 0.42]:
		for z in [-0.25, 0.25]:
			var burner := CylinderMesh.new()
			burner.top_radius = 0.22
			burner.bottom_radius = 0.22
			burner.height = 0.055
			_add_station_mesh(station, burner, Vector3(x, 0.4, z), Color("#222c38"))
	var pot := CylinderMesh.new()
	pot.top_radius = 0.34
	pot.bottom_radius = 0.29
	pot.height = 0.42
	_add_station_mesh(station, pot, Vector3(0, 0.67, 0), Color("#8c9ba5"))
	var lid := CylinderMesh.new()
	lid.top_radius = 0.36
	lid.bottom_radius = 0.36
	lid.height = 0.06
	_add_station_mesh(station, lid, Vector3(0, 0.91, 0), Color("#dbe7ee"))
	for x in [-0.4, 0.4]:
		var handle := BoxMesh.new()
		handle.size = Vector3(0.18, 0.07, 0.1)
		_add_station_mesh(station, handle, Vector3(x, 0.68, 0), Color("#303d4a"))

func _create_oven_station_model(station: StaticBody3D) -> void:
	_create_counter_model(station, Color("#80533b"))
	var body := BoxMesh.new()
	body.size = Vector3(1.45, 1.15, 1.0)
	_add_station_mesh(station, body, Vector3(0, -0.02, 0), Color("#667687"))
	var door := BoxMesh.new()
	door.size = Vector3(1.14, 0.57, 0.08)
	_add_station_mesh(station, door, Vector3(0, -0.16, 0.54), Color("#26384a"))
	var glass := BoxMesh.new()
	glass.size = Vector3(0.88, 0.32, 0.025)
	_add_station_mesh(station, glass, Vector3(0, -0.16, 0.595), Color("#7eb2c2"))
	for x in [-0.4, 0.0, 0.4]:
		var knob := SphereMesh.new()
		var knob_visual := _add_station_mesh(station, knob, Vector3(x, 0.54, 0.55), Color("#f0c66b"))
		knob_visual.scale = Vector3.ONE * 0.09

func _create_mixer_station_model(station: StaticBody3D) -> void:
	_create_counter_model(station, Color("#80533b"))
	var base := BoxMesh.new()
	base.size = Vector3(0.68, 0.2, 0.52)
	_add_station_mesh(station, base, Vector3(0, 0.32, 0), Color("#71a7a5"))
	var arm := BoxMesh.new()
	arm.size = Vector3(0.18, 0.58, 0.2)
	_add_station_mesh(station, arm, Vector3(0.22, 0.65, -0.1), Color("#71a7a5"))
	var head := BoxMesh.new()
	head.size = Vector3(0.62, 0.2, 0.32)
	_add_station_mesh(station, head, Vector3(-0.02, 0.9, -0.08), Color("#82b8b3"))
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.34
	bowl.bottom_radius = 0.25
	bowl.height = 0.38
	_add_station_mesh(station, bowl, Vector3(-0.02, 0.59, 0.18), Color("#dbe7ee"))
	var whisk := BoxMesh.new()
	whisk.size = Vector3(0.035, 0.32, 0.035)
	_add_station_mesh(station, whisk, Vector3(-0.02, 0.65, 0.18), Color("#596c80"))

func _create_plate_station_model(station: StaticBody3D) -> void:
	_create_counter_model(station, Color("#80533b"))
	for index in range(4):
		var plate := CylinderMesh.new()
		plate.top_radius = 0.48 - index * 0.04
		plate.bottom_radius = 0.45 - index * 0.04
		plate.height = 0.07
		_add_station_mesh(station, plate, Vector3(0, 0.34 + index * 0.065, 0), Color("#fff3d0"))

func _create_serving_window_model(station: StaticBody3D) -> void:
	var counter := BoxMesh.new()
	counter.size = Vector3(1.9, 0.82, 1.05)
	_add_station_mesh(station, counter, Vector3(0, -0.26, 0.08), Color("#8a5939"))
	var top := BoxMesh.new()
	top.size = Vector3(2.0, 0.16, 1.18)
	_add_station_mesh(station, top, Vector3(0, 0.23, 0.08), Color("#d5a74c"))
	for x in [-0.92, 0.92]:
		var post := BoxMesh.new()
		post.size = Vector3(0.14, 1.45, 0.14)
		_add_station_mesh(station, post, Vector3(x, 0.72, -0.42), Color("#80533b"))
	var canopy := BoxMesh.new()
	canopy.size = Vector3(2.0, 0.16, 0.2)
	_add_station_mesh(station, canopy, Vector3(0, 1.45, -0.42), Color("#d5a74c"))
	var opening := BoxMesh.new()
	opening.size = Vector3(1.45, 0.68, 0.04)
	_add_station_mesh(station, opening, Vector3(0, 0.98, -0.3), Color("#26384a"))

func _create_trash_can_model(station: StaticBody3D) -> void:
	var bin := CylinderMesh.new()
	bin.top_radius = 0.42
	bin.bottom_radius = 0.34
	bin.height = 0.82
	_add_station_mesh(station, bin, Vector3(0, -0.3, 0), Color("#596c80"))
	var rim := CylinderMesh.new()
	rim.top_radius = 0.44
	rim.bottom_radius = 0.44
	rim.height = 0.08
	_add_station_mesh(station, rim, Vector3(0, 0.15, 0), Color("#303d4a"))
	var lid := CylinderMesh.new()
	lid.top_radius = 0.46
	lid.bottom_radius = 0.46
	lid.height = 0.07
	_add_station_mesh(station, lid, Vector3(0, 0.22, 0), Color("#303d4a"))

func _create_counter_model(station: StaticBody3D, color: Color) -> void:
	var cabinet := BoxMesh.new()
	cabinet.size = Vector3(1.58, 0.78, 0.98)
	_add_station_mesh(station, cabinet, Vector3(0, -0.3, 0), color)
	var countertop := BoxMesh.new()
	countertop.size = Vector3(1.78, 0.16, 1.15)
	_add_station_mesh(station, countertop, Vector3(0, 0.17, 0), color.lightened(0.2))
	for x in [-0.5, 0.0, 0.5]:
		var pull := BoxMesh.new()
		pull.size = Vector3(0.2, 0.035, 0.03)
		_add_station_mesh(station, pull, Vector3(x, -0.18, 0.51), Color("#d5b978"))

func _add_station_mesh(station: StaticBody3D, mesh: Mesh, position: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = position
	visual.material_override = _material(color)
	station.add_child(visual)
	return visual

func _create_pot_animation(station: StaticBody3D) -> void:
	pot_animation = Node3D.new()
	pot_animation.position = Vector3(0, 1.65, 0)
	pot_animation.visible = false
	station.add_child(pot_animation)
	pot_progress_label = Label3D.new()
	pot_progress_label.text = "COOKING..."
	pot_progress_label.position = Vector3(0, 0.65, 0)
	pot_progress_label.font_size = 48
	pot_progress_label.modulate = Color("#f4ca67")
	pot_progress_label.outline_size = 8
	pot_progress_label.outline_modulate = Color("#142235")
	pot_animation.add_child(pot_progress_label)
	prep_animations["cook"] = pot_animation
	prep_progress_labels["cook"] = pot_progress_label
	pot_progress_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func _create_oven_animation(station: StaticBody3D) -> void:
	oven_animation = Node3D.new()
	oven_animation.position = Vector3(0, 1.65, 0)
	oven_animation.visible = false
	station.add_child(oven_animation)
	oven_progress_label = Label3D.new()
	oven_progress_label.text = "BAKING..."
	oven_progress_label.position = Vector3(0, 0.65, 0)
	oven_progress_label.font_size = 48
	oven_progress_label.modulate = Color("#f4ca67")
	oven_progress_label.outline_size = 8
	oven_progress_label.outline_modulate = Color("#142235")
	oven_animation.add_child(oven_progress_label)
	prep_animations["oven"] = oven_animation
	prep_progress_labels["oven"] = oven_progress_label
	oven_progress_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func _create_mixer_animation(station: StaticBody3D) -> void:
	mixer_animation = _create_extra_prep_animation(station, "MIXING...")
	mixer_progress_label = mixer_animation.get_child(0) as Label3D
	prep_animations["mixer"] = mixer_animation
	prep_progress_labels["mixer"] = mixer_progress_label

func _create_extra_prep_animation(station: StaticBody3D, status_text: String) -> Node3D:
	var animation := Node3D.new()
	animation.position = Vector3(0, 1.65, 0)
	animation.visible = false
	station.add_child(animation)
	var progress_label := Label3D.new()
	progress_label.text = status_text
	progress_label.position = Vector3(0, 0.65, 0)
	progress_label.font_size = 48
	progress_label.modulate = Color("#f4ca67")
	progress_label.outline_size = 8
	progress_label.outline_modulate = Color("#142235")
	progress_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	animation.add_child(progress_label)
	return animation

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
	cutting_progress_label.font_size = 48
	cutting_progress_label.modulate = Color("#f4ca67")
	cutting_progress_label.outline_size = 8
	cutting_progress_label.outline_modulate = Color("#142235")
	cutting_animation.add_child(cutting_progress_label)
	cutting_progress_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func _update_pot_animation() -> void:
	_update_prep_animation("cook")

func _update_oven_animation() -> void:
	_update_prep_animation("oven")

func _update_prep_animation(station_id: String) -> void:
	if not prep_animations.has(station_id):
		return

	var animation: Node3D = prep_animations[station_id]
	var progress_label: Label3D = prep_progress_labels[station_id]
	var remaining: float = station_remaining.get(station_id, 0.0)

	animation.visible = remaining > 0.0 or ready_dishes.has(station_id)

	if ready_dishes.has(station_id):
		progress_label.text = "HOTOVO!"
	elif remaining > 0.0:
		var status: String = {
			"cook": "VAŘÍ SE",
			"oven": "PEČE SE",
			"mixer": "MÍCHÁ SE",
		}[station_id]

		var process_name: String = active_recipes.get(station_id, "")
		var total_time: float = _get_process_info(process_name).get("prep_time", 1.0)
		var progress: float = 1.0 - remaining / total_time
		var filled: int = int(progress * 10.0)
		var bar := "■".repeat(filled) + "□".repeat(10 - filled)

		progress_label.text = "%s\n[%s]" % [status, bar]

func _update_cutting_animation() -> void:
	if not cutting_animation:
		return
	cutting_animation.visible = cutting_remaining > 0.0
	if cutting_remaining > 0.0:
		var progress: float = 1.0 - cutting_remaining / 2.0
		var filled: int = int(progress * 10.0)
		var bar := "■".repeat(filled) + "□".repeat(10 - filled)
		cutting_progress_label.text = "CHOPPING\n[%s]" % bar

func _station_color(station_id: String) -> Color:
	return {
		"fish_crate": Color("#3b6ba5"),
		"potato_crate": Color("#c49142"),
		"dough_crate": Color("#dfc086"),
		"mayo_crate": Color("#e0e0e0"),
		"sugar_crate": Color("#f4f0e5"),
		"cut": Color("#bf5b50"),
		"cook": Color("#d47b46"),
		"oven": Color("#8c5643"),
		"mixer": Color("#71a7a5"),
		"plates": Color("#8b73b9"),
		"serve": Color("#d3a64b"),
		"trash": Color("#596c80")
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
	chef.position.z = clamp(chef.position.z, -4.5, 6.2)
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
			_play_beaver_animation(["Walk"])
		else:
			_play_beaver_animation(["WalkCarry"])
	else:
		walk_phase = 0.0
		chef_mesh.position.y = lerpf(chef_mesh.position.y, 0.0, delta * 12.0)
		chef_mesh.rotation.z = lerpf(chef_mesh.rotation.z, 0.0, delta * 12.0)
		held_visual.position.y = lerpf(held_visual.position.y, held_item_offset.y, delta * 12.0)
		if held_item == "Empty hands":
			_play_beaver_animation(["Idle_Walk"])
		else:
			_play_beaver_animation(["IdleCarry_Walk"])

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
	if station_id == "trash":
		if held_item != "Empty hands":
			_set_held_item("Empty hands")
			_start_put_animation()
		_update_hud()
		return

	if INGREDIENT_STATIONS.has(station_id):
		var ingredient: String = INGREDIENT_STATIONS[station_id]
		if held_item == "Empty hands":
			_set_held_item(ingredient)
			_start_put_animation()
		elif held_item == ingredient:
			_set_held_item("Empty hands")
			_start_put_animation()
		_update_hud()
		return

	match station_id:
		"cut":
			if held_item == "Chopped fish":
				if not board_has_item and not board_has_chopped_item:
					board_has_chopped_item = true
					current_board_ingredient = held_item.replace("Chopped ", "").capitalize()
					_set_held_item("Empty hands")
					_update_board_visual()
					_start_put_animation()
			elif held_item == "Fish":
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

		"cook", "oven", "mixer":
			_interact_with_prep_station(station_id)

		"plates":
			if held_item == "Plate":
				_set_held_item("Empty hands")
				_start_put_animation()
			elif held_item == "Empty hands":
				_set_held_item("Plate")
				_start_put_animation()
			elif _is_recipe_result(held_item) and not held_item_on_plate:
				held_item_on_plate = true
				_update_held_visual()
				_start_put_animation()

		"serve":
			if _is_recipe_result(held_item) and held_item_on_plate:
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

func _interact_with_prep_station(station_id: String) -> void:
	if ready_dishes.has(station_id):
		if station_id == "cook" and ready_dishes[station_id] == "Boiled potato":
			if held_item != "Empty hands":
				return

			ready_dishes.erase(station_id)
			active_recipes.erase(station_id)
			station_ingredients.erase(station_id)
			_set_held_item("Boiled potato")
			_start_put_animation()
			_update_prep_animation(station_id)
			return
		if held_item == "Plate":
			var result: String = ready_dishes[station_id]
			ready_dishes.erase(station_id)
			active_recipes.erase(station_id)
			station_ingredients.erase(station_id)
			_set_held_item(result)
			held_item_on_plate = true
			_update_held_visual()
			_start_put_animation()
			_update_prep_animation(station_id)
			return
	if held_item == "Plate" or held_item == "Empty hands":
		return
	if station_remaining.get(station_id, 0.0) > 0.0 or ready_dishes.has(station_id):
		return

	var current_ingredients: Array = station_ingredients.get(station_id, []).duplicate()
	var matching_process := ""
	var process_names: Array = PREPARATIONS.keys()
	process_names.append_array(RECIPES.keys())
	for process_name in process_names:
		var process: Dictionary = _get_process_info(process_name)
		var process_ingredients: Array = process["ingredients"]
		if process["station"] != station_id or held_item not in process_ingredients:
			continue
		if held_item in current_ingredients:
			continue
		var compatible := true
		for current_ingredient in current_ingredients:
			if current_ingredient not in process_ingredients:
				compatible = false
				break
		if compatible:
			matching_process = process_name
			break
	if matching_process.is_empty():
		return

	current_ingredients.append(held_item)
	_set_held_item("Empty hands")
	_start_put_animation()
	var selected_process: Dictionary = _get_process_info(matching_process)
	if current_ingredients.size() == selected_process["ingredients"].size():
		station_ingredients.erase(station_id)
		active_recipes[station_id] = matching_process
		var prep_time: float = selected_process["prep_time"]
		if prep_time == 0.0:
			ready_dishes[station_id] = selected_process["result_item"]
		else:
			station_remaining[station_id] = prep_time
	else:
		station_ingredients[station_id] = current_ingredients
	_update_prep_animation(station_id)

func _get_process_info(process_name: String) -> Dictionary:
	if PREPARATIONS.has(process_name):
		return PREPARATIONS[process_name]
	return RECIPES[process_name]

func _is_recipe_result(item: String) -> bool:
	for recipe in RECIPES.values():
		if recipe["result_item"] == item:
			return true
	return false

func _is_preparation_result(item: String) -> bool:
	for preparation in PREPARATIONS.values():
		if preparation["result_item"] == item:
			return true
	return false

func _spawn_order() -> void:
	var recipe_keys := RECIPES.keys()
	var random_recipe_name: String = recipe_keys[randi() % recipe_keys.size()]
	var recipe_info: Dictionary = RECIPES[random_recipe_name]
	
	orders.append({
		"id": next_order_id,
		"patience": 100,
		"recipe": random_recipe_name,
		"ingredients": recipe_info["ingredients"],
		"color": recipe_info["color"],
		"station": recipe_info["station"]
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

	for station_id in station_remaining.keys():
		var remaining: float = maxf(0.0, station_remaining[station_id] - 1.0)
		if remaining == 0.0:
			var process_name: String = active_recipes[station_id]
			var process: Dictionary = _get_process_info(process_name)
			ready_dishes[station_id] = process["result_item"]
			station_remaining.erase(station_id)
		else:
			station_remaining[station_id] = remaining
		_update_prep_animation(station_id)

	for order in orders:
		order.patience = maxi(0, order.patience - 1)

	if time_left == 0:
		_finish_game()
	
	if time_left % 40 == 0 and orders.size() < 3:
		_spawn_order()
		
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skip_music") and not (event is InputEventKey and event.echo):
		_skip_music()
		return

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
	
	restart_label = _label("[R] ZNOVUSPUŠTĚNÍ", Color("#ffffff"), 18)
	restart_label.position = Vector2(419, 638)
	canvas.add_child(restart_label)

	music_skip_label = _label("[N] DALŠÍ PÍSNIČKA", Color("#ffffff"), 16)
	music_skip_label.position = Vector2(650, 640)
	canvas.add_child(music_skip_label)

	score_label = _label("SKÓRE  0", Color("#f4ca67"), 20)
	score_label.position = Vector2(42, 638)
	canvas.add_child(score_label)

	time_label = _label("ČAS  5:00", Color("#ef6b62"), 20)
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
	time_label.text = "ČAS  %d:%02d" % [time_left / 60, time_left % 60]
	score_label.text = "SKÓRE  %d" % score
	
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
	time_left = 300
	chef.position = Vector3.ZERO
	chef.velocity = Vector3.ZERO
	station_ingredients.clear()
	station_remaining.clear()
	ready_dishes.clear()
	active_recipes.clear()
	cutting_remaining = 0.0
	board_has_item = false
	board_has_chopped_item = false
	current_board_ingredient = ""
	orders.clear()
	next_order_id = 1
	_spawn_order()
	timer.start()
	_set_held_item("Empty hands")
	_start_put_animation()
	for station_id in prep_animations:
		_update_prep_animation(station_id)
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
	held_item_on_plate = false
	_update_held_visual()
	_update_hud()

func _start_put_animation() -> void:
	putting_remaining = putting_total

func _update_held_visual() -> void:
	if not item_visual or not plate_visual:
		return

	var is_chopped := held_item == "Chopped fish"
	var is_ingredient: bool = held_item in INGREDIENT_STATIONS.values()
	var is_result := _is_recipe_result(held_item)
	var is_prepared_ingredient := _is_preparation_result(held_item)
	item_visual.visible = is_ingredient or is_result or is_prepared_ingredient
	chopped_visual.visible = is_chopped
	plate_visual.visible = held_item == "Plate" or (is_result and held_item_on_plate)
	if is_chopped:
		var chopped_colors := {
			"Chopped fish": "#3b6ba5"
		}
		chopped_visual.material_override = _material(Color(chopped_colors[held_item]))
	if not item_visual.visible:
		return

	var item_colors := {
		"Fish": "#3b6ba5",
		"Potato": "#c49142",
		"Boiled potato": "#c49142",
		"Dough": "#dfc086",
		"Mayonnaise": "#ffffff",
		"Sugar": "#f4f0e5"
	}
	var item_color := Color(item_colors.get(held_item, "#ed514b"))
	for recipe in RECIPES.values():
		if recipe["result_item"] == held_item:
			item_color = Color(recipe["color"])
			break
	item_visual.material_override = _material(item_color)

func _update_board_visual() -> void:
	if not board_food_visual:
		return
	board_food_visual.visible = board_has_item or board_has_chopped_item
	if board_has_chopped_item:
		board_food_visual.scale = Vector3(0.22, 0.07, 0.2)
	else:
		board_food_visual.scale = Vector3(0.34, 0.12, 0.13)

func _start_music() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -10.0
	music_player.finished.connect(_play_next_track)
	add_child(music_player)
	_play_next_track()

func _play_next_track() -> void:
	if music_tracks.is_empty():
		return

	var track_index := randi_range(0, music_tracks.size() - 1)
	if music_tracks.size() > 1 and track_index == current_music_track:
		track_index = (track_index + 1) % music_tracks.size()
	current_music_track = track_index
	music_player.stream = music_tracks[track_index]
	music_player.play()

func _skip_music() -> void:
	if music_player and not music_tracks.is_empty():
		_play_next_track()
