extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const WALK_SPEED = 60 * 2.0
const GRAVITY = 60 * 4 * 2.0
const JUMP_HEIGHT = 38 * 2.0
const JUMP_FRAMES = 40.0
const HURT_HEIGHT = 16 * 2.0
const HURT_FRAMES = 20.0
var velocity = Vector2()
var jump_velocity = 0.0
var last_jump_diff = 0.0
var jump_diff = 0.0

var jump_tween
var stair_tween

var left_input = false
var right_input = false
var jump_input = false
var attack_input = false
var up_input = false
var down_input = false

var jump_released = true
var attack_released = true

var stair_flipped = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
		
func _process(delta):
	visible = true
	if is_hurt():
		if Time.get_ticks_msec() % 2 == 0:
			visible = false

func _physics_process(delta):
	if Input.is_action_pressed("ui_left"):
		left_input = true
	if Input.is_action_pressed("ui_right"):
		right_input = true
	if Input.is_action_pressed("ui_up"):
		up_input = true
	if Input.is_action_pressed("ui_down"):
		down_input = true
		
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
	

	if !is_jumping() && !is_attacking() && !is_crouching() && !is_hurt():
		if left_input:
			if !is_on_stair():
				velocity.x -= 1
			else:
				if stair_flipped:
					up_input = true
				else:
					down_input = true
		if right_input:
			if !is_on_stair():
				velocity.x += 1
			else:
				if stair_flipped:
					down_input = true
				else:
					up_input = true
		jump_velocity = velocity.x
	elif !is_on_floor():
		velocity.x = jump_velocity
		
	if is_attacking():
		if $AnimatedSprite.frame >= 2:
			$HurtBox/CollisionShape2D.set_deferred("disabled", false)
		
	if down_input && is_on_floor() && !is_hurt() && !is_on_stair() && !is_attacking():
		$AnimatedSprite.play("crouch")
		set_jump_collision_shape()
		set_crouch_hurtbox_pos()
		
	if up_input && !is_hurt() && !stair_tween && !is_jumping() && (is_on_floor() || is_on_stair()):
		var areas = $FeetArea.get_overlapping_areas()
		for area in areas:
			if "Stair" in area.name:
				velocity.x = 0.0
				velocity.y = 0.0
				var x_diff = 16.0
				if area.flipped:
					flip(false)
					x_diff *= -1
					stair_flipped = true
				else:
					flip(true)
					stair_flipped = false
				$AnimatedSprite.play("walk")
				$AnimatedSprite.frame = 0
				stair_tween = get_tree().create_tween()
				stair_tween.tween_property(self, "position:x", area.position.x, 1.0/60*abs(area.position.x-position.x)/2.0)
				stair_tween.tween_callback($AnimatedSprite, "play", ['upstair'])
				stair_tween.tween_property(self, "position", Vector2(area.position.x+x_diff, position.y-16.0), 1.0/60*16)
				stair_tween.tween_callback(self, "kill_stair_tween")
				break
				
	if down_input && !is_hurt() && !stair_tween && !is_jumping() && (is_on_floor() || is_on_stair()):
		var areas = $FeetArea.get_overlapping_areas()
		for area in areas:
			if "DownStep" in area.name:
				velocity.x = 0.0
				velocity.y = 0.0
				var x_diff = 16.0
				if area.get_parent().flipped:
					flip(true)
					x_diff *= -1
					stair_flipped = true
				else:
					flip(false)
					stair_flipped = false
				$AnimatedSprite.play("walk")
				$AnimatedSprite.frame = 0
				stair_tween = get_tree().create_tween()
				stair_tween.tween_property(self, "global_position:x", area.global_position.x, 1.0/60*abs(area.global_position.x-global_position.x)/2.0)
				stair_tween.tween_callback($AnimatedSprite, "play", ['downstair'])
				stair_tween.tween_property(self, "global_position", Vector2(area.global_position.x-x_diff, global_position.y+16.0), 1.0/60*16)
				stair_tween.tween_callback(self, "kill_stair_tween")
				break
		
	if jump_input && !jump_tween && !is_on_stair() &&!is_crouching() && !is_hurt():
		$AnimatedSprite.play("jump")
		jump_velocity = velocity.x
		set_jump_collision_shape()
		jump_diff = 0.0
		last_jump_diff = 0.0
		jump_tween = get_tree().create_tween()
		jump_tween.tween_property(self, "jump_diff", -JUMP_HEIGHT, JUMP_FRAMES/2/60).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		jump_tween.tween_property(self, "jump_diff", 0.0, JUMP_FRAMES/2/60).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		jump_tween.tween_callback(self, "kill_jump_tween")
		
	if attack_input && !is_attacking() && !is_hurt():
		play_whip_sound()
		if is_crouching():
			$AnimatedSprite.play("crouch_attack")
			$WhipSprite.play("level1_crouch")
		elif is_on_stair():
			if $AnimatedSprite.frame == 1 && !stair_tween:
				if $AnimatedSprite.animation == 'upstair':
					$AnimatedSprite.play("upstair_attack")
				elif $AnimatedSprite.animation == 'downstair':
					$AnimatedSprite.play("downstair_attack")
				$WhipSprite.play("level1")
		elif is_on_floor() || is_jumping():
			$AnimatedSprite.play("attack")
			$WhipSprite.play("level1")
		
	velocity.x *= WALK_SPEED
	if jump_tween:
		velocity.y = (jump_diff-last_jump_diff) * 60
		last_jump_diff = jump_diff
	elif !is_jumping() && !is_on_stair():
		velocity.y = GRAVITY

	if !is_jumping() && !is_attacking() && !is_on_stair() && is_on_floor():
		if velocity.x > 0:
			flip(true)
			$AnimatedSprite.play("walk")
		elif velocity.x < 0:
			flip(false)
			$AnimatedSprite.play("walk")
		else:
			if !down_input:
				$AnimatedSprite.play("stand")
				set_stand_collision_shape()
				set_stand_hurtbox_pos()

	if !is_on_stair():
		move_and_slide(velocity, Vector2.UP)
		
	velocity = Vector2()
	left_input = false
	right_input = false
	up_input = false
	down_input = false
	jump_input = false
	attack_input = false
	
func flip(f):
	$AnimatedSprite.flip_h = f
	$WhipSprite.flip_h = f
	if f:
		$HurtBox.position.x = 56
	else:
		$HurtBox.position.x = -56
	
func is_jumping():
	return !(jump_tween == null) || $AnimatedSprite.animation == 'jump'
	
func is_attacking():
	return $AnimatedSprite.animation in ['attack', 'crouch_attack', 'upstair_attack', 'downstair_attack']
	
func is_on_stair():
	return !(stair_tween == null) || $AnimatedSprite.animation in ['upstair', 'downstair', 'upstair_attack', 'downstair_attack']
	
func is_crouching():
	return $AnimatedSprite.animation == "crouch"
	
func is_hurt():
	return $AnimatedSprite.animation in ["hurt", "crouch_hurt"]

func kill_jump_tween():
	jump_tween.kill()
	jump_tween = null
	if !is_attacking():
		$AnimatedSprite.play("crouch")
#	jump_velocity = 0.0
	
func kill_stair_tween():
	stair_tween.kill()
	stair_tween = null
	var no_stairs = true
	if $AnimatedSprite.animation == 'upstair':
		var areas = $FeetArea.get_overlapping_areas()
		for area in areas:
			if "Stair" in area.name:
				no_stairs = false
	elif $AnimatedSprite.animation == 'downstair':
		var areas = $FeetArea.get_overlapping_areas()
		for area in areas:
			if "DownStep" in area.name:
				no_stairs = false
				
	if no_stairs:
		$AnimatedSprite.play("stand")
	
func set_chat(text):
	rpc("update_chat_label", text)
	
remotesync func update_chat_label(text):
	$Chat.text = text
	$Chat/ChatTimer.start()

func _on_ChatTimer_timeout():
	$Chat.text = ''

remotesync func set_jump_collision_shape():
	$CollisionShape2D.shape.extents = Vector2(16, 26)
	$CollisionShape2D.position = Vector2(0, 6)
	
remotesync func set_stand_collision_shape():
	$CollisionShape2D.shape.extents = Vector2(16, 32)
	$CollisionShape2D.position = Vector2(0, 0)
	
remotesync func set_crouch_hurtbox_pos():
	$HurtBox.position.y = 9
	
remotesync func set_stand_hurtbox_pos():
	$HurtBox.position.y = -4
	
master func sync_input(left, right, up, down, jump, attack):
	left_input = left
	right_input = right
	up_input = up
	down_input = down
	jump_input = jump
	attack_input = attack
	
func prepare_player_sync():
	var data = {
		"x": position.x,
		"y": position.y,
		"collision_extents": $CollisionShape2D.shape.extents,
		"collision_pos": $CollisionShape2D.position,
		"animation": $AnimatedSprite.animation,
		"frame": $AnimatedSprite.frame,
		"flip_h": $AnimatedSprite.flip_h,
		"whip": $WhipSprite.animation,
		"whip_frame": $WhipSprite.frame,
		"whip_flip_h": $WhipSprite.flip_h,
		"hurtbox": $HurtBox/CollisionShape2D.disabled,
		"hurtbox_x": $HurtBox.position.x,
		"hurtbox_y": $HurtBox.position.y
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
	$HurtBox/CollisionShape2D.disabled = data["hurtbox"]
	$HurtBox.position.x = data["hurtbox_x"]
	$HurtBox.position.y = data["hurtbox_y"]
	$CollisionShape2D.shape.extents = data["collision_extents"]
	$CollisionShape2D.position = data["collision_pos"]


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation in ['attack', 'crouch_attack']:
		if down_input:
			$AnimatedSprite.play("crouch")
		else:
			$AnimatedSprite.play("stand")
		$HurtBox/CollisionShape2D.set_deferred("disabled", true)
	elif $AnimatedSprite.animation == 'upstair_attack':
		$AnimatedSprite.play("upstair")
		$AnimatedSprite.frame = 1
		$HurtBox/CollisionShape2D.set_deferred("disabled", true)
	elif $AnimatedSprite.animation == 'downstair_attack':
		$AnimatedSprite.play("downstair")
		$AnimatedSprite.frame = 1
		$HurtBox/CollisionShape2D.set_deferred("disabled", true)

func _on_WhipSprite_animation_finished():
	if $WhipSprite.animation != 'hidden':
		$WhipSprite.play("hidden")

func get_hurtbox_results():
	return $HurtBox.get_overlapping_bodies()
	
func hurt():
	if !is_hurt():
		$AnimatedSprite.play("hurt")
		jump_velocity = 1
		if $AnimatedSprite.flip_h:
			jump_velocity = -1
		jump_diff = 0.0
		last_jump_diff = 0.0
		jump_tween = get_tree().create_tween()
		jump_tween.tween_property(self, "jump_diff", -HURT_HEIGHT, HURT_HEIGHT/2/60).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		jump_tween.tween_property(self, "jump_diff", 0.0, HURT_HEIGHT/2/60).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		jump_tween.tween_callback(self, "kill_jump_tween")
		
remote func play_whip_sound():
	$WhipSound.play()
