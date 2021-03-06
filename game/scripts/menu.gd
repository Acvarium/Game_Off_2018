extends Control
var global
var page = 0
var tabs = ["l_cont", "options"]
var selected_tab = 0

func _ready():
	global = get_node("/root/global")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	set_page(0)
	select_tab(0)
	set_options()
	
func set_options():
	$options/glow.pressed = bool(global.options["glow"])
	
func set_page(_page):
	page = _page
	if page < 0:
		page = 0
	$l_cont/page_minus.visible = page > 0
	for i in range(8):
		get_node("l_cont/level_button" + str(i+1)).set_level(i + page * 8)
	$page_num.text = str(page)
	$l_cont/page_plus.visible = (page + 1) * 8 < (global.levels.size())
	print(page * 8 )

func select_tab(value):
	for t in tabs:
		get_node("tabs/" + t).disabled = false
		get_node(t).visible = false
	get_node("tabs/" + tabs[value]).disabled = true
	get_node(tabs[value]).visible = true
	selected_tab = value

func _on_page_minus_pressed():
	set_page(page - 1)

func _on_page_plus_pressed():
	set_page(page + 1)

func _on_game_name_pressed():
	OS.shell_open("https://acvarium.itch.io/super-gold-oranda")

func _on_exit_pressed():
	global.save_game()
	get_tree().quit()

func _on_glow_toggled(button_pressed):
	global.options["glow"] = int(button_pressed)
	global.save_options()
