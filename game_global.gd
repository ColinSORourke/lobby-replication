extends Node

const default_address: String = "127.0.0.1"
const default_port: int = 7000

@export
var MainMenu: PackedScene
@export
var LobbyScene: PackedScene


func _ready() -> void:
	get_tree().set_multiplayer(MetaDataMultiplayer.new())
	multiplayer.connected_to_server.connect(func(): change_to_lobby())
	multiplayer.server_disconnected.connect(func(): multiplayer_disconnect())
	multiplayer.connection_failed.connect(func(): print("Connection failed"))

func host() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(default_port)
	if err == OK:
		multiplayer.multiplayer_peer = peer
		multiplayer.add_lobby_property("CurrentLevel")
		multiplayer.add_peer_property("Name")
		multiplayer.add_peer_property("Color")
		multiplayer.set_lobby_property("CurrentLevel", "Level1")
		change_to_lobby()
	else:
		warn("Failed to create server")

func join() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(default_address, default_port)
	if err == OK:
		multiplayer.multiplayer_peer = peer
		print("Trying to connect to server")
	else:
		warn("Failed to connect to server")

func change_to_main() -> void:
	get_tree().change_scene_to_packed(MainMenu)
	
func change_to_lobby() -> void:
	get_tree().change_scene_to_packed(LobbyScene)

func multiplayer_disconnect() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	change_to_main()
	warn("Multiplayer Disconnected")

func warn(txt: String) -> void:
	$WarnDialog.dialog_text = txt
	$WarnDialog.visible = true
	$WarnDialog.move_to_center()
