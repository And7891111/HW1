extends Node
## 虚拟接口：跨地图传送的中转站（autoload，切场景不销毁）。
## 负责黑幕转场、切场景、把"从哪个门进来"传给目标地图。
## 目标地图在 _ready 里调用 consume() 决定玩家落点。

var destination: StringName = &""

func travel(scene_path: String, dest: StringName) -> void:
	if scene_path.is_empty():
		return
	destination = dest
	await CinematicFlow.cover(0.55)
	get_tree().change_scene_to_file(scene_path)
	# autoload 本身不会被释放；等新场景装配完再拉开黑幕
	await get_tree().process_frame
	await get_tree().process_frame
	CinematicFlow.reveal(0.9)

func consume() -> StringName:
	var d := destination
	destination = &""
	return d

## 按门 ID 找到目标场景里的落点；找不到时返回 Vector3.INF 由调用方兜底
func find_arrival(id: StringName) -> Vector3:
	if id == &"":
		return Vector3.INF
	for p in get_tree().get_nodes_in_group("portal"):
		if p.has_method("arrival_position") and p.get("portal_id") == id:
			return p.arrival_position()
	return Vector3.INF
