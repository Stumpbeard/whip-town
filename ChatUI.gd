extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var player


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !player:
		if get_tree().multiplayer.network_peer:
			if get_tree().multiplayer.is_network_server():
				return
			var id = str(get_tree().multiplayer.network_peer.get_unique_id())
			player = get_tree().root.get_child(0).get_node("Players").get_node_or_null(id)
			if !player:
				return
			print("found player")
	if Input.is_action_just_pressed("ui_accept"):
		if !$TextEdit.visible:
			$TextEdit.visible = true
			$TextEdit.grab_focus()
		else:
			$TextEdit.visible = false
			player.set_chat($TextEdit.text)
			$TextEdit.text = ''
			

