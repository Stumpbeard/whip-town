extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const PORT = 4242
#const WEB_URL = 'wss://www.whip-town.com/wss'
var WEB_URL = OS.get_environment("WEB_URL")

var player_scene = preload("res://Player.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	var peer
	if WEB_URL == '':
		WEB_URL = 'ws://127.0.0.1:' + str(PORT)
	if '--server' in OS.get_cmdline_args():
		peer = WebSocketServer.new()
		peer.connect("peer_connected", self, "_connected")
		peer.listen(PORT, [], true)
		get_tree().multiplayer.network_peer = peer
	else:
		peer = WebSocketClient.new()
		peer.connect_to_url(WEB_URL, [], true)
		get_tree().multiplayer.network_peer = peer


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _connected(id):
	create_player(id, 0.0, 0.0)
	print("Client connected: " + str(id))

func _on_Players_child_entered_tree(node):
	if get_tree().multiplayer.is_network_server():
		for player in $Players.get_children():
			rpc("create_player", player.name, player.position.x, player.position.y)
			
remote func create_player(id, x, y):
	if $Players.get_node_or_null(str(id)):
		return
	var player = player_scene.instance()
	player.name = str(id)
	player.position = Vector2(x, y)
	$Players.add_child(player)
