tool
extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var flipped = false


func _init(flip = false):
	flipped = flip

# Called when the node enters the scene tree for the first time.
func _ready():
	if flipped:
		$DownStep.position.x = -16.0
	else:
		$DownStep.position.x = 16.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
