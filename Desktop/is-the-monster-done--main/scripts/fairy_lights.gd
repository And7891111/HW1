extends Node3D

## 缠在树上的“星星灯带”：沿树冠锥面螺旋缠绕的小星星 + 电线，另有几颗垂坠星星。
## 白天隐藏；入夜由昼夜控制器(day_night_cycle)调用 set_night() 与路灯同节奏渐亮。
## 尺寸自适应：挂载时测量所在树的 AABB，自动决定缠绕高度、半径与星星大小。

var _bulb_mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("fairy_lights")
	_build()
	set_night(0.0)

func set_night(k: float) -> void:
	visible = k > 0.001
	if _bulb_mat != null:
		_bulb_mat.emission_energy_multiplier = lerpf(0.25, 3.0, k)

func _build() -> void:
	var aabb := _tree_aabb()
	var height := aabb.size.y
	if height < 1.5:
		return
	var half_w := maxf(aabb.size.x, aabb.size.z) * 0.5
	var r_base := clampf(half_w * 0.82, 0.35, 2.8)
	var r_top := r_base * 0.22
	var y0 := height * 0.16
	var y1 := height * 0.74
	var turns := 3.2
	var steps := int(clampf(height * 4.0, 20.0, 44.0))
	var bulb_size := clampf(height * 0.016, 0.05, 0.14)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(global_position)

	# 星星：五棱柱薄片，远看即五角星
	var bulb_mesh := CylinderMesh.new()
	bulb_mesh.top_radius = bulb_size
	bulb_mesh.bottom_radius = bulb_size
	bulb_mesh.height = bulb_size * 0.5
	bulb_mesh.radial_segments = 5
	bulb_mesh.rings = 1

	_bulb_mat = StandardMaterial3D.new()
	_bulb_mat.albedo_color = Color(1.0, 0.9, 0.62, 1.0)
	_bulb_mat.emission_enabled = true
	_bulb_mat.emission = Color(1.0, 0.8, 0.42, 1.0)
	_bulb_mat.emission_energy_multiplier = 0.0

	# 电线：单位高细杆，逐段缩放
	var wire_mesh := CylinderMesh.new()
	wire_mesh.top_radius = 0.014
	wire_mesh.bottom_radius = 0.014
	wire_mesh.height = 1.0
	wire_mesh.radial_segments = 4
	wire_mesh.rings = 1
	var wire_mat := StandardMaterial3D.new()
	wire_mat.albedo_color = Color(0.16, 0.14, 0.12, 1.0)
	wire_mat.roughness = 0.9

	# 螺旋采样点
	var points: Array[Vector3] = []
	for i in steps + 1:
		var t := float(i) / float(steps)
		var r := lerpf(r_base, r_top, t)
		var ang := t * turns * TAU
		points.append(Vector3(cos(ang) * r, lerpf(y0, y1, t), sin(ang) * r))

	var bulb_xforms: Array[Transform3D] = []
	var wire_xforms: Array[Transform3D] = []

	for p in points:
		var rot := Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))
		bulb_xforms.append(Transform3D(Basis.from_euler(rot), p))

	for i in range(1, points.size()):
		wire_xforms.append(_seg_transform(points[i - 1], points[i]))

	# 几颗垂坠星星：从螺旋下段垂下一小截电线
	for _j in 4:
		var idx := rng.randi_range(1, maxi(1, steps / 2))
		var drop := rng.randf_range(0.35, 0.6)
		var top := points[idx]
		var low := top + Vector3(0.0, -drop, 0.0)
		wire_xforms.append(_seg_transform(top, low))
		bulb_xforms.append(Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0.0)), low))

	var bulb_mm := MultiMesh.new()
	bulb_mm.transform_format = MultiMesh.TRANSFORM_3D
	bulb_mm.mesh = bulb_mesh
	bulb_mm.instance_count = bulb_xforms.size()
	for i in bulb_xforms.size():
		bulb_mm.set_instance_transform(i, bulb_xforms[i])
	var bulbs := MultiMeshInstance3D.new()
	bulbs.multimesh = bulb_mm
	bulbs.material_override = _bulb_mat
	add_child(bulbs)

	var wire_mm := MultiMesh.new()
	wire_mm.transform_format = MultiMesh.TRANSFORM_3D
	wire_mm.mesh = wire_mesh
	wire_mm.instance_count = wire_xforms.size()
	for i in wire_xforms.size():
		wire_mm.set_instance_transform(i, wire_xforms[i])
	var wires := MultiMeshInstance3D.new()
	wires.multimesh = wire_mm
	wires.material_override = wire_mat
	add_child(wires)

func _seg_transform(a: Vector3, b: Vector3) -> Transform3D:
	var dir := b - a
	var seg_len := dir.length()
	if seg_len < 0.001:
		return Transform3D(Basis.IDENTITY, a)
	var y := dir / seg_len
	var x := Vector3.UP.cross(y)
	if x.length_squared() < 0.0001:
		x = Vector3.RIGHT.cross(y)
	x = x.normalized()
	var z := x.cross(y).normalized()
	return Transform3D(Basis(x, y * seg_len, z), (a + b) * 0.5)

func _tree_aabb() -> AABB:
	var result := AABB()
	var first := true
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var box: AABB = mi.transform * mi.get_aabb()
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	return result
