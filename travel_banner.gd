extends Control

const SKY := Color("#163552")
const SNOW := Color("#eaf5fb")
const SNOW_SHADOW := Color("#c4dbe8")
const TREE := Color("#1e765f")
const TREE_DARK := Color("#145044")
const RED := Color("#d95757")
const YELLOW := Color("#f7d36b")
const BROWN := Color("#8b5a3c")
const ROAD := Color("#26394c")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), SKY)
	draw_circle(Vector2(size.x - 75, 38), 22, Color("#ffe8a6"))
	for i in range(18):
		var x := fmod(float(i * 83 + 31), size.x)
		var y := fmod(float(i * 47 + 12), max(1.0, size.y - 35.0))
		draw_circle(Vector2(x, y), 2.0, Color(1, 1, 1, 0.72))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 100), Vector2(115, 48), Vector2(220, 102), Vector2(340, 42),
		Vector2(470, 103), Vector2(610, 44), Vector2(760, 104), Vector2(size.x, 57),
		Vector2(size.x, size.y), Vector2(0, size.y)
	]), SNOW_SHADOW)
	draw_rect(Rect2(0, 122, size.x, size.y - 122), SNOW)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 142), Vector2(size.x * 0.25, 129), Vector2(size.x * 0.52, 150),
		Vector2(size.x * 0.77, 132), Vector2(size.x, 145), Vector2(size.x, size.y),
		Vector2(0, size.y)
	]), Color("#d7eaf2"))
	draw_line(Vector2(0, 151), Vector2(size.x, 151), ROAD, 34)
	for x in range(22, int(size.x), 70):
		draw_line(Vector2(x, 151), Vector2(x + 32, 151), YELLOW, 3)
	_draw_tree(Vector2(47, 105), 0.75)
	_draw_tree(Vector2(size.x - 47, 106), 0.8)
	_draw_tree(Vector2(size.x * 0.67, 116), 0.48)
	_draw_car(Vector2(size.x * 0.47, 143))
	_draw_person(Vector2(size.x * 0.38, 117), RED, "M")
	_draw_person(Vector2(size.x * 0.53, 117), YELLOW, "L")
	_draw_person(Vector2(size.x * 0.60, 120), Color("#9b7de8"), "J")
	draw_string(ThemeDB.fallback_font, Vector2(18, 27), "THE CHRISTMAS ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffffff"))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 173, 27), "GRANDMA'S HOUSE  →", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d8eaf4"))

func _draw_tree(pos: Vector2, scale: float) -> void:
	draw_rect(Rect2(pos + Vector2(-4, 27) * scale, Vector2(8, 24) * scale), BROWN)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -35) * scale, pos + Vector2(-29, 13) * scale,
		pos + Vector2(29, 13) * scale
	]), TREE_DARK)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -22) * scale, pos + Vector2(-36, 31) * scale,
		pos + Vector2(36, 31) * scale
	]), TREE)
	draw_circle(pos + Vector2(-8, 4) * scale, 3 * scale, RED)
	draw_circle(pos + Vector2(10, 14) * scale, 3 * scale, YELLOW)

func _draw_car(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-43, -13), Vector2(86, 27)), RED, true)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-27, -13), pos + Vector2(-12, -30),
		pos + Vector2(20, -30), pos + Vector2(36, -13)
	]), RED)
	draw_rect(Rect2(pos + Vector2(-8, -25), Vector2(20, 12)), Color("#a9d8e8"), true)
	draw_circle(pos + Vector2(-26, 15), 9, Color("#182432"))
	draw_circle(pos + Vector2(26, 15), 9, Color("#182432"))
	draw_circle(pos + Vector2(-26, 15), 4, SNOW_SHADOW)
	draw_circle(pos + Vector2(26, 15), 4, SNOW_SHADOW)
	draw_circle(pos + Vector2(38, -2), 3, YELLOW)

func _draw_person(pos: Vector2, shirt: Color, initial: String) -> void:
	draw_circle(pos + Vector2(0, -15), 10, Color("#f0bd91"))
	draw_circle(pos + Vector2(0, -17), 11, Color("#43352d"))
	draw_rect(Rect2(pos + Vector2(-11, -5), Vector2(22, 27)), shirt, true)
	draw_line(pos + Vector2(-5, 22), pos + Vector2(-7, 31), Color("#24344a"), 4)
	draw_line(pos + Vector2(5, 22), pos + Vector2(7, 31), Color("#24344a"), 4)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-4, 2), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#ffffff"))
