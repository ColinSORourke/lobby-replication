This is a Proof-Of-Concept, built in a custom Branch of Godot 4.8

The intent is to demonstrate the advantages of:
	
* https://github.com/godotengine/godot-proposals/issues/15683
* and the accompanying Pull Request
	
This features a very basic Host/Join setup, taking Users to a Lobby Scene

The Lobby Scene uses the new MultiplayerData API to replicate
* A current Level Name
* A Name for each peer
* A Color for each peer

Without any user-written RPCs, Spawners, or Synchronizers.
