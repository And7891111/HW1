extends Control
## 圣诞小镇布局图：自动探测小镇模型（Town 节点）的包围盒，绘制建筑点阵、
## 返回传送门、出生点、玩家实时位置与飘雪。风格与雪原布局图一致。
## 用法：town_level.gd 创建实例，设 .player = player，挂到 CanvasLayer。

signal close_requested
var player
var accepts_input := false

var _minx := INF
var _maxx := -INF
var _minz := INF
var _maxz := -INF
var _center := Vector2(0.0, 5.0)
var _extent := 60.0
var _bounds_done := false
var _obj_pts: Array = []
var _t := 0.0

const C_PANEL := Color(0.93, 0.95, 0.98, 0.45)
const C_BORDER := Color(0.66, 0.80, 0.90, 0.6)
const C_BUILD := Color(0.55, 0.62, 0.72, 0.85)
const C_ROOF := Color(0.82, 0.42, 0.38, 0.92)
const C_TREE := Color(0.2, 0.45, 0.28, 0.92)
const C_SNOWMAN := Color(1.0, 1.0, 1.0, 0.95)
const C_DECO := Color(1.0, 0.85, 0.4, 0.92)
const C_PORTAL := Color(0.2, 0.9, 0.7, 0.95)
const C_SPAWN := Color(1.0, 1.0, 1.0, 0.9)
const C_PLAYER := Color(0.12, 0.6, 0.82)
const C_GRID := Color(0.5, 0.7, 0.85, 0.1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	_detect()


func _detect() -> void:
	var root := get_tree().current_scene
	var town := root.get_node_or_null("Town") if root != null else null
	if town == null:
		return
	_minx = INF
	_maxx = -INF
	_minz = INF
	_maxz = -INF
	_collect(town)
	if is_inf(_minx):
		return
	_center = Vector2((_minx + _maxx) * 0.5, (_minz + _maxz) * 0.5)
	_extent = maxf(_maxx - _minx, _maxz - _minz) * 0.5 + 10.0
	_bounds_done = true


func _collect(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		var aabb := mi.global_transform * mi.mesh.get_aabb()
		_minx = minf(_minx, aabb.position.x)
		_maxx = maxf(_maxx, aabb.end.x)
		_minz = minf(_minz, aabb.position.z)
		_maxz = maxf(_maxz, aabb.end.z)
		var c := Vector2(aabb.get_center().x, aabb.get_center().z)
		if not _too_close(c):
			_obj_pts.append({"pos": c, "kind": _kind(mi.name)})
	for ch in n.get_children():
		_collect(ch)


func _too_close(p: Vector2) -> bool:
	for e in _obj_pts:
		if (e["pos"] as Vector2).distance_to(p) < 2.5:
			return true
	return false


func _kind(nm: String) -> String:
	nm = nm.to_lower()
	if "tree" in nm:
		return "tree"
	if "snowman" in nm or "snow_man" in nm:
		return "snowman"
	if "door" in nm or "house" in nm or "cabin" in nm:
		return "house"
	if "bell" in nm or "lantern" in nm or "light" in nm or "lamp" in nm:
		return "deco"
	return "build"


func project(p: Vector2) -> Vector2:
	var s := _scale()
	return Vector2(size.x * 0.5, size.y * 0.5) + (p - _center) * s


func _scale() -> float:
	return minf((size.x - 30.0) / (_extent * 2.0), (size.y - 40.0) / (_extent * 2.0))


func _process(delta: float) -> void:
	_t += delta
	if not _bounds_done and get_tree().current_scene != null:
		_detect()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not accepts_input or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		if k == KEY_M or k == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close_requested.emit()


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL
	sb.set_border_width_all(2)
	sb.border_color = C_BORDER
	sb.set_corner_radius_all(10)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	if not _bounds_done:
		return
	var s := _scale()
	# 网格
	for gx in range(-int(_extent), int(_extent) + 1, 10):
		var gxf := float(gx)
		draw_line(project(Vector2(gxf, _center.y - _extent)), project(Vector2(gxf, _center.y + _extent)), C_GRID, 1)
	for gz in range(-int(_extent), int(_extent) + 1, 10):
		var gzf := float(gz)
		draw_line(project(Vector2(_center.x - _extent, gzf)), project(Vector2(_center.x + _extent, gzf)), C_GRID, 1)
	# 建筑点阵
	for e in _obj_pts:
		var p := project(e["pos"] as Vector2)
		match e["kind"]:
			"tree":
				draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 3), p + Vector2(3, 3), p + Vector2(0, -4)]), C_TREE)
			"snowman":
				draw_circle(p, 2.5, C_SNOWMAN)
			"house":
				draw_rect(Rect2(p - Vector2(3, 2.5), Vector2(6, 5)), C_ROOF)
			"deco":
				draw_circle(p, 2.0, C_DECO)
			_:
				draw_circle(p, 2.5, C_BUILD)
	# 返回传送门（town_level.tscn 中 ReturnPortal 位于 (0, 0, 16)）
	var portal := project(Vector2(0, 16))
	draw_arc(portal, 6.0, 0, TAU, 20, C_PORTAL, 2)
	draw_circle(portal, 3.0, C_PORTAL)
	# 出生点白环（DEFAULT_SPAWN 在 (0, 0.02, 5)）
	var sp := project(Vector2(0, 5))
	draw_arc(sp, 5.0, 0, TAU, 18, C_SPAWN, 2)
	# 玩家实时位置
	if player != null and is_instance_valid(player):
		var pp := project(Vector2(player.global_position.x, player.global_position.z))
		draw_circle(pp, 5.0, C_PLAYER)
		draw_arc(pp, 9.0, 0, TAU, 18, C_PLAYER, 1)
	# 飘雪
	var sn := 50
	for i in sn:
		var j := sin(float(i) * 12.9898) * 43758.5453
		j = j - floor(j)
		var sx := fmod(j * size.x + _t * 6.0 + float(i) * 9.1, size.x)
		var sy := fmod(float(i) * 17.7 + _t * 14.0, size.y)
		draw_circle(Vector2(sx, sy), 1.0 + j * 0.7, Color(1.0, 1.0, 1.0, 0.4))
