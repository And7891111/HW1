extends Area3D
class_name Portal

## 虚拟接口：一个可复用的传送门。
## 两块地图在几何上不相连，靠 portal_id / target_portal_id 配对，
## 通过 PortalLink autoload 中转；目标场景和落点都可在检查器里改。

@export_file("*.tscn") var target_scene: String = ""
@export var portal_id: StringName = &""
@export var target_portal_id: StringName = &""
@export var spawn_offset: Vector3 = Vector3(0, 0, 3.0)
@export var trigger_size: Vector3 = Vector3(4.0, 4.0, 2.0)
@export var enabled := true

var _busy := false

func _ready() -> void:
	monitoring = true
	add_to_group("portal")
	var cs := CollisionShape3D.new()
	cs.name = "TriggerShape"
	var box := BoxShape3D.new()
	box.size = trigger_size
	cs.shape = box
	add_child(cs)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _busy or not enabled or target_scene.is_empty():
		return
	if not (body.is_in_group("Player") or body is CharacterBody3D):
		return
	_busy = true
	PortalLink.travel(target_scene, target_portal_id)

## 从别的地图传送进来时，玩家应该出现的位置
func arrival_position() -> Vector3:
	return global_position + spawn_offset
