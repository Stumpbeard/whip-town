extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var game_scene = preload("res://Game.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	if '--nosound' in OS.get_cmdline_args():
		AudioServer.set_bus_mute(0, true)
	if '--server' in OS.get_cmdline_args():
		start_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		start_game()

func start_game():
	var root = get_tree().root
	var game = game_scene.instance()
	root.get_child(0).queue_free()
	root.call_deferred("add_child", game)
