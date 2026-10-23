extends VBoxContainer


var peerLabels: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var levelMetaData = multiplayer.get_lobby_property("CurrentLevel")
	if (levelMetaData):
		$LevelLabel.text = levelMetaData
	
	multiplayer.connect("peer_connected", _add_peer_label)
	multiplayer.connect("peer_disconnected", _remove_peer_label)
	multiplayer.connect("lobby_property_changed", _on_lobby_prop_change)
	multiplayer.connect("peer_property_changed", _on_peer_prop_change)
	
	_add_peer_label(multiplayer.get_unique_id())
	for peer in multiplayer.get_peers():
		_add_peer_label(peer)

func _add_peer_label(peer: int):
	var peerLabel = Label.new()
	peerLabels[peer] = peerLabel
	peerLabel.text = "%s" % peer
	peerLabel.set("theme_override_colors/font_color", Color.WHITE)
	add_child(peerLabel)

func _remove_peer_label(peer: int):
	peerLabels[peer].queue_free()
	peerLabels.erase(peer)

func _on_lobby_prop_change(prop: String) -> void:
	if (prop == "CurrentLevel"):
		var levelMetaData = multiplayer.get_lobby_property("CurrentLevel")
		$LevelLabel.text = levelMetaData

func _on_peer_prop_change(prop: String, peer: int) -> void:
	print("Received Peer Prop Change")
	if (prop == "Name"):
		var nameMetaData = multiplayer.get_peer_property("Name", peer)
		peerLabels[peer].text = nameMetaData
	if (prop == "Color"):
		var colorMetaData = multiplayer.get_peer_property("Color", peer)
		peerLabels[peer].set("theme_override_colors/font_color", colorMetaData)
