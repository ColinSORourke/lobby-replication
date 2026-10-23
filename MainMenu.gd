extends Control



func _on_quit_button_button_up() -> void:
	get_tree().quit()

func _on_host_button_button_up() -> void:
	GameGlobal.host()

func _on_join_button_button_up() -> void:
	GameGlobal.join()
