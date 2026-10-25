extends Control

func _ready() -> void:
	if (multiplayer.get_unique_id() == 1):
		$VBoxContainer/HBoxContainer/LevelLineEdit.visible = true

func _on_disconnect_button_up() -> void:
	GameGlobal.multiplayer_disconnect()


func _on_line_edit_text_submitted(new_text: String) -> void:
	multiplayer.set_lobby_property("CurrentLevel", new_text)

func _on_name_line_edit_text_submitted(new_text: String) -> void:
	multiplayer.set_peer_property("Name", new_text)

func _on_color_picker_button_color_changed(color: Color) -> void:
	multiplayer.set_peer_property("Color", color)
