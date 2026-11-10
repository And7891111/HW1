extends CanvasLayer
signal restart_requested
signal menu_requested
const Book = preload("res://scripts/book_ui.gd")
var data: Dictionary = {}
var ui_root: Control


func configure(d: Dictionary) -> void:
	data = d
	_build()


func _build() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)

	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	var theme_ := Theme.new()
	theme_.default_font = font
	theme_.default_font_size = 20
	ui_root.theme = theme_

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05, 0.74)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(760, 0)
	card.add_theme_stylebox_override("panel", Book.style(Color("202b31"), Book.GOLD, 26))
	center.add_child(card)

	var margin := MarginContainer.new()
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(key, 30)
	card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	col.add_child(Book.label("雪原征程 · 胜利", 34, Book.GOLD))

	var pname: String = data.get("player_name", "无名旅人")
	col.add_child(Book.paragraph("勇者 %s，你穿过了暴雪与炉火。\n冰封山洞的蓝光，是为归人而亮。" % pname, 20, Book.CREAM))
	col.add_child(Book.rule())

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 6)
	col.add_child(stats)
	stats.add_child(Book.label("本局时长：%s" % _fmt_time(data.get("elapsed", 0.0)), 20))
	stats.add_child(Book.label("击败敌人：%d" % int(data.get("kills", 0)), 20))
	stats.add_child(Book.label("最终 Boss：已击败", 20))

	col.add_child(Book.rule())

	col.add_child(Book.label("本局解锁的料理", 24, Book.GOLD))

	var recipes: Array = data.get("recipes", [])
	var rs: Node = data.get("recipe_system", null)
	if recipes.is_empty() or rs == null:
		col.add_child(Book.paragraph("本局未凑齐任何料理——食材散落雪原，下次再试。", 18, Book.MUTED))
	else:
		for rid in recipes:
			var rname: String = rs.RECIPE_NAMES.get(rid, rid)
			var formula: String = rs.RECIPE_DETAILS.get(rid, {}).get("formula", "")
			var color_str: String = rs.RECIPE_DETAILS.get(rid, {}).get("color", "ffffff")
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			var dot := ColorRect.new()
			dot.custom_minimum_size = Vector2(20, 20)
			dot.color = Color(color_str)
			row.add_child(dot)
			row.add_child(Book.label("%s    %s" % [rname, formula], 20, Book.CREAM))
			col.add_child(row)

	col.add_child(Book.rule())

	var run_pct: float = data.get("run_pct", 0.0)
	var career_pct: float = data.get("career_pct", 0.0)
	var career_total: int = data.get("career_total", 0)
	col.add_child(Book.label("本局成就完成度：%d%%" % int(run_pct), 22, Book.CREAM))
	col.add_child(Book.label("生涯图鉴完成度：%d%%  （已解锁 %d / 5）" % [int(career_pct), career_total], 20, Book.MUTED))

	col.add_child(Book.rule())

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(btn_row)
	var restart_btn := Book.button("再做一锅")
	restart_btn.pressed.connect(func() -> void: restart_requested.emit())
	btn_row.add_child(restart_btn)
	var menu_btn := Book.button("返回主菜单", false)
	menu_btn.pressed.connect(func() -> void: menu_requested.emit())
	btn_row.add_child(menu_btn)


func _fmt_time(sec: float) -> String:
	var total := int(sec)
	var m := total / 60
	var s := total % 60
	return "%02d:%02d" % [m, s]
