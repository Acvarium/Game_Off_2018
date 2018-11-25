extends TextureButton
export var tab_num = 0
var menu = null

func _ready():
	menu = get_node("/root/menu")

func _on_tab_pressed():
	menu.select_tab(tab_num)
