extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const WALK_SPEED = 60 * 2.0
const GRAVITY = 60 * 4 * 2.0
const JUMP_HEIGHT = 36 * 2.0
const JUMP_FRAMES = 48.0
var velocity = Vector2()
var last_jump_diff = 0.0
var jump_diff = 0.0

var jump_tween

var left_input = false
var right_input = false
var jump_input = false
var attack_input = false

var jump_released = true
var attack_released = true


# Called when the node enters the scene tree for the first time.
func _ready():
	if int(name) == get_tree().multiplayer.network_peer.get_unique_id():
		$Camera2D.current = true


func _physics_process(delta):
	if int(name) == get_tree().multiplayer.network_peer.get_unique_id():
		if Input.is_action_pressed("ui_left"):
			left_input = true
		if Input.is_action_pressed("ui_right"):
			right_input = true
			
		if Input.is_action_pressed("jump") && jump_released:
			jump_input = true
			jump_released = false
		elif !Input.is_action_pressed("jump"):
			jump_released = true
			
		if Input.is_action_pressed("attack") && attack_released:
			attack_input = true
			attack_released = false
		elif !Input.is_action_pressed("attack"):
			attack_released = true
		rpc_id(1, "sync_input", left_input, right_input, jump_input, attack_input)
		left_input = false
		right_input = false
		jump_input = false
		attack_input = false
	
	if get_tree().multiplayer.is_network_server():
		if left_input:
			velocity.x -= 1
		if right_input:
			velocity.x += 1
			
		if jump_input && !jump_tween:
			$AnimatedSprite.play("jump")
			rpc("set_jump_collision_shape")
			jump_diff = 0.0
			last_jump_diff = 0.0
			jump_tween = get_tree().create_tween()
			jump_tween.tween_property(self, "jump_diff", -JUMP_HEIGHT, JUMP_FRAMES/2/60).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			jump_tween.tween_property(self, "jump_diff", 0.0, JUMP_FRAMES/2/60).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			jump_tween.tween_callback(self, "kill_tween")
			
		if attack_input:
			$AnimatedSprite.play("attack")
			$WhipSprite.play("level1")
			
		velocity.x *= WALK_SPEED
		if jump_tween:
			velocity.y = (jump_diff-last_jump_diff) * 60
			last_jump_diff = jump_diff
		else:
			velocity.y = GRAVITY

		if !is_jumping() && !is_attacking():
			if velocity.x > 0:
				$AnimatedSprite.flip_h = true
				$WhipSprite.flip_h = true
				$AnimatedSprite.play("walk")
			elif velocity.x < 0:
				$AnimatedSprite.flip_h = false
				$WhipSprite.flip_h = false
				$AnimatedSprite.play("walk")
			else:
				$AnimatedSprite.play("stand")

		move_and_slide(velocity, Vector2.UP)
		prepare_player_sync()
		
	velocity = Vector2()
	
func is_jumping():
	return !(jump_tween == null) || $AnimatedSprite.animation == 'jump'
	
func is_attacking():
	return $AnimatedSprite.animation == 'attack'

func kill_tween():
	jump_tween.kill()
	jump_tween = null
	$AnimatedSprite.play("stand")
	rpc("set_stand_collision_shape")
	
func set_chat(text):
	rpc("update_chat_label", text)
	
remotesync func update_chat_label(text):
	$Chat.text = text
	$Chat/ChatTimer.start()

func _on_ChatTimer_timeout():
	$Chat.text = ''

remotesync func set_jump_collision_shape():
	$CollisionShape2D.shape.extents = Vector2(16, 25)
	$CollisionShape2D.position = Vector2(0, -7)
	
remotesync func set_stand_collision_shape():
	$CollisionShape2D.shape.extents = Vector2(16, 32)
	$CollisionShape2D.position = Vector2(0, 0)
	
	
master func sync_input(left, right, jump, attack):
	left_input = left
	right_input = right
	jump_input = jump
	attack_input = attack
	
func prepare_player_sync():
	var data = {
		"x": position.x,
		"y": position.y,
		"animation": $AnimatedSprite.animation,
		"frame": $AnimatedSprite.frame,
		"flip_h": $AnimatedSprite.flip_h,
		"whip": $WhipSprite.animation,
		"whip_frame": $WhipSprite.frame,
		"whip_flip_h": $WhipSprite.flip_h
	}
	rpc("sync_player", data)
	
puppet func sync_player(data):
	position.x = data["x"]
	position.y = data["y"]
	$AnimatedSprite.animation = data["animation"]
	$AnimatedSprite.frame = data["frame"]
	$AnimatedSprite.flip_h = data["flip_h"]
	$WhipSprite.animation = data["whip"]
	$WhipSprite.frame = data["whip_frame"]
	$WhipSprite.flip_h = data["whip_flip_h"]


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == 'attack':
		$AnimatedSprite.play("stand")


func _on_WhipSprite_animation_finished():
	if $WhipSprite.animation != 'hidden':
		$WhipSprite.play("hidden")
