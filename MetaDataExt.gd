extends SceneMultiplayer
class_name MetaDataMultiplayer

signal lobby_property_changed(prop, value)
signal peer_property_changed(prop, peer_id, value)

const METADATA_STAMP: int = 0x4D455441 # META
const PEER_STAMP: int = 0x50454552 # PEER
const LOBBY_STAMP: int = 0x4C4F4259 # LOBY

var transfer_channel = 0

var LobbyProperties: Dictionary[String, Variant] = {}
var PeerProperties: Dictionary[int, Dictionary] = {1: {}}
var LocalPeerProperties: Dictionary[String, Variant] = {}
var PeerPropNames: PackedStringArray = []
var LobbyPropNames: PackedStringArray = []

func _init() -> void:
	peer_packet.connect(_process_replicate)
	
	connected_to_server.connect(_server_connected)
	peer_connected.connect(_peer_connected)
	
	connection_failed.connect(_clear)
	server_disconnected.connect(_clear)

func _replicate_lobby_property(name: String, id: int = 0) -> void:
	var name_buff: PackedByteArray = name.to_utf8_buffer()
	var variant_buff = PackedByteArray()
	if (get_lobby_property(name)):
		variant_buff = var_to_bytes(get_lobby_property(name))
	
	var packet = PackedByteArray()
	packet.resize(4 + 4 + 2 + 2)
	packet.encode_u32(0, METADATA_STAMP)
	packet.encode_u32(4, LOBBY_STAMP)
	packet.encode_u16(8, name_buff.size())
	packet.encode_u16(10, variant_buff.size())
	packet.append_array(name_buff)
	packet.append_array(variant_buff)
	send_bytes(packet, id, MultiplayerPeer.TRANSFER_MODE_RELIABLE, transfer_channel)

func _replicate_peer_property(name: String, id: int = 0) -> void:
	var name_buff: PackedByteArray = name.to_utf8_buffer()
	var variant_buff = PackedByteArray()
	if (get_peer_property(name, get_unique_id())):
		variant_buff = var_to_bytes(get_peer_property(name, get_unique_id()))
	
	var packet = PackedByteArray()
	packet.resize(4 + 4 + 2 + 2)
	packet.encode_u32(0, METADATA_STAMP)
	packet.encode_u32(4, PEER_STAMP)
	packet.encode_u16(8, name_buff.size())
	packet.encode_u16(10, variant_buff.size())
	packet.append_array(name_buff)
	packet.append_array(variant_buff)
	send_bytes(packet, id, MultiplayerPeer.TRANSFER_MODE_RELIABLE, transfer_channel)

func _process_replicate(id: int, packet: PackedByteArray) -> void:
	if (packet.size() < 12):
		return
	if (packet.decode_u32(0) == METADATA_STAMP):
		var stamp = packet.decode_u32(4)
		var name_size = packet.decode_u16(8)
		var var_size = packet.decode_u16(10)
		var name_buff = packet.slice(12, 12 + name_size)
		var var_buff = packet.slice(12 + name_size, 12 + name_size + var_size)
		var name = name_buff.get_string_from_utf8()
		var value = null
		if (var_buff.size() > 4):
			value = bytes_to_var(var_buff)
		if (stamp == LOBBY_STAMP):
			_handle_replicate_lobby(name, value)
		elif (stamp == PEER_STAMP):
			_handle_replicate_peer(name, id, value)
		
				
func _handle_replicate_lobby(name: String, value: Variant) -> void:
	if (not LobbyPropNames.has(name)):
		LobbyPropNames.append(name)
		LobbyProperties[name] = null
	if (value && LobbyProperties[name] != value):
		LobbyProperties[name] = value
		lobby_property_changed.emit(name, value)

func _handle_replicate_peer(name: String, peer_from: int, value: Variant) -> void:
	if (not PeerPropNames.has(name)):
		PeerPropNames.append(name)
		for peer in PeerProperties.keys():
			PeerProperties[peer][name] = null
		_peer_local_match(name)
	if (value && PeerProperties.has(peer_from)):
		if (PeerProperties[peer_from][name] != value):
			PeerProperties[peer_from][name] = value
			peer_property_changed.emit(name, peer_from, value)

func add_lobby_property(name: String) -> void:
	if (get_unique_id() != 1):
		push_warning("Only the server can set Lobby Properties")
		return
	if (LobbyPropNames.has(name)):
		return
	LobbyPropNames.append(name)
	LobbyProperties[name] = null
	_replicate_lobby_property(name)

func set_lobby_property(name: String, value: Variant) -> void:
	if (get_unique_id() != 1):
		push_warning("Only the server can set Lobby Properties")
		return
	if (not LobbyPropNames.has(name)):
		return
	if (LobbyProperties[name] != value):
		LobbyProperties[name] = value
		_replicate_lobby_property(name)
		lobby_property_changed.emit(name, value)

func get_lobby_property(name: String) -> Variant:
	return LobbyProperties.get(name)
	
func add_peer_property(name: String) -> void:
	if (get_unique_id() != 1):
		push_warning("Only the server can add Peer Properties")
		return
	if (PeerPropNames.has(name)):
		return
	PeerPropNames.append(name)
	for peer in PeerProperties.keys():
		PeerProperties[peer][name] = null
	_peer_local_match(name)
	_replicate_peer_property(name)

func _peer_local_match(name: String) -> bool:
	if (LocalPeerProperties.has(name)):
		PeerProperties[get_unique_id()][name] = LocalPeerProperties[name]
		peer_property_changed.emit(name, get_unique_id(), LocalPeerProperties[name])
		LocalPeerProperties.erase(name)
		return true
	return false

func set_peer_property(name: String, value: Variant) -> void:
	if (not PeerPropNames.has(name)):
		LocalPeerProperties[name] = value
		return
	if (PeerProperties[get_unique_id()][name] != value):
		PeerProperties[get_unique_id()][name] = value
		_replicate_peer_property(name)
		peer_property_changed.emit(name, get_unique_id(), value)

func get_peer_property(name: String, peer_id: int) -> Variant:
	if (LocalPeerProperties.has(name) && peer_id == get_unique_id()):
		return LocalPeerProperties[name]
	if (PeerProperties.has(peer_id)):
		return PeerProperties[peer_id][name]
	return null

func _clear() -> void:
	LobbyProperties.clear()
	PeerProperties.clear()
	LocalPeerProperties.clear()
	PeerPropNames.clear()
	LobbyPropNames.clear()
	PeerProperties = {1: {}}

func _server_connected() -> void:
	_clear()
	PeerProperties[get_unique_id()] = {}

func _peer_connected(id: int) -> void:
	PeerProperties[id] = {}
	if (get_unique_id() == 1):
		for property in LobbyProperties:
			_replicate_lobby_property(property, id)
		for property in PeerPropNames:
			PeerProperties[id][property] = null
			_replicate_peer_property(property, id)
