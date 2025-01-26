extends CharacterBody3D

@onready var face_dir:Node3D = $face_dir
@onready var nav_agent:NavigationAgent3D = $NavigationAgent3D
@onready var player_view_state:String = "HIDDEN" # HIDDEN, NOTICED
@onready var previous_player_view_state:String = "HIDDEN" # HIDDEN, NOTICED
#@onready var billy_status:String = "WANDERING" # WANDERING, PURSUING, SEARCHING, WAITING, NOTICED, GOINGTOLASTPOS
@onready var navRegion:NavigationRegion3D = get_tree().get_nodes_in_group("nav")[0]
@onready var animation_player:AnimationPlayer = $enemymesh/AnimationPlayer

@export var SPEED:float
@export var RUN_SPEED:float
@export var TURN_SPEED:float
@export var ENEMY_FOV = 70
@export var HEALTH = 100

@onready var wander_pos = set_rand_wander_pos()
var player_pos
var last_player_pos
@onready var rng = RandomNumberGenerator.new()
@onready var cur_speed = RUN_SPEED
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process


@onready var vision_cast:RayCast3D  = $"RayCasts/vision_cast"
@onready var vision_cast2:RayCast3D = $"RayCasts/vision_cast2"
@onready var vision_cast3:RayCast3D = $"RayCasts/vision_cast3"

var player_noticed:bool
var player_in_attack_zone:bool

@onready var sound_maker = $sound_maker
@onready var footstep_sound = $footstep_sound

@onready var animator : AnimationTree = $"enemymesh/AnimationTree"
const ANIMATION_BLEND : float = 7.0

#timers
@onready var footstep_timer = $"Timers/footstep_timer"
@onready var wait_in_pos_timer:Timer = $"Timers/wait_in_pos_timer"
@onready var attack_cooldown:Timer = $"Timers/attack_cooldown_timer"
@onready var noticed_timer:Timer = $Timers/player_noticed

@onready var nav_bake_finished = false

@export_group("Jared's Extra Settings")
@export var snowball:PackedScene
@onready var snowball_spawn:Node3D = $snowball_spawn

@onready var PLAYER = get_tree().get_nodes_in_group("player")[0]


@onready var enemy_hurt_sounds = [load("res://enemy/sounds/oof1.wav"), load("res://enemy/sounds/oof2.wav"), load("res://enemy/sounds/oof3.wav"), load("res://enemy/sounds/oof4.wav"), load("res://enemy/sounds/oof5.wav"), load("res://enemy/sounds/oof6.wav"), load("res://enemy/sounds/oof7.wav")]

signal enemy_death

func _ready():
	ENEMY_FOV = cos(deg_to_rad(ENEMY_FOV))
	
	var skin = load(["res://enemy/enemyskin1.tres", "res://enemy/enemyskin2.tres", "res://enemy/enemyskin3.tres"].pick_random())
	$enemymesh/Root_001/Skeleton3D/characterSmall.set_surface_override_material(0, skin)

	if not PLAYER:
		assert(false, "PLAYER NOT FOUND BY ENEMY!!")



func _physics_process(delta):
	if player_view_state == "DEAD": return
	PLAYER.get_node("UserInterface/DebugPanel").add_property("Wandering POS", wander_pos)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("Enemy POS", global_transform.origin)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("Enemy State", player_view_state)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("player_noticed", player_noticed)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("player_in_attack_zone", player_in_attack_zone)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("SPEED", cur_speed)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("last_player_pos", last_player_pos)
	

	animate(delta)
	
	if(player_view_state == "GOINGTOLASTPOS"):
		if(previous_player_view_state == "PURSUING"):
			cur_speed = RUN_SPEED
		else:
			cur_speed = SPEED
		cur_speed = RUN_SPEED
		
		wander(delta)
		
	elif(player_view_state == "PURSUING"): #
		cur_speed = RUN_SPEED
		move_to_player(delta)
	elif(player_view_state == "WAITING"):
		return
	elif(player_view_state == "HIDDEN"):
		cur_speed = SPEED
		if(!wander_pos):
			set_rand_wander_pos()
		
		if(abs(wander_pos.x - global_transform.origin.x) < 0.1 and abs(wander_pos.z - global_transform.origin.z) < 0.1): #if timer stopped or at pos, get new pos
			switch_state("WAITING")
			velocity = Vector3.ZERO
			wait_in_pos_timer.start(rng.randf_range(1.0, 11.0))
		else:
			wander(delta)
	

func _process(_delta):
	if player_view_state == "DEAD": return
	if(player_noticed):
		var can_see = player_in_sight()
		
		if not can_see:
			if(player_view_state == "PURSUING" && player_view_state != "GOINGTOLASTPOS"): # if i cant see ya, but i used to see ya
				lost_View_of_player()
		elif noticed_timer.is_stopped():
			noticed_timer.start()
	if(player_in_attack_zone and attack_cooldown.is_stopped() and player_in_sight()):
		switch_state("PURSUING")
		start_throw()
		# switch_state("ATTACKING")
func _on_player_noticed_timeout() -> void:
	if player_noticed and player_in_sight():
		switch_state("PURSUING")

func start_throw():
	if animator.get("parameters/OneShot/active"): return
	animator.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	pass
func throw_snowball():
	if attack_cooldown.is_stopped():
		attack_cooldown.start()
		if snowball.can_instantiate():
			var newball:RigidBody3D = snowball.instantiate()
			get_tree().root.add_child(newball)
			newball.global_position = snowball_spawn.global_position
			newball.global_rotation = snowball_spawn.global_rotation
			newball.apply_impulse((-face_dir.get_global_transform().basis.z  * newball.speed) + velocity)

func take_hit(damage):
	HEALTH -= damage
	if HEALTH <= 0:
		die()
	else:
		switch_state("PURSUING")
		play_sound(enemy_hurt_sounds.pick_random(), [0.1,0.1], [0,0], true)

func die():
	play_sound(enemy_hurt_sounds.pick_random(), [0,0], [0,0], true) #REPLACE WITH DEATH SOUND TODO
	if player_view_state != "DEAD":
		enemy_death.emit()
		switch_state("DEAD")
		animator.queue_free()
		$Areas.queue_free()
		$Timers.queue_free()
		animation_player.play(["Root_001|DIE1", "Root_001|DIE2", "Root_001|DIE3"].pick_random())
	
	
func _on_death_timer_timeout() -> void:
	queue_free()



func animate(delta):
	if player_view_state == "DEAD": return

	PLAYER.get_node("UserInterface/DebugPanel").add_property("velocity", velocity)

	if velocity.length() > 0:
		if cur_speed == RUN_SPEED:
			animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
		else:
			animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
	else:
		animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), -1.0, delta * ANIMATION_BLEND))


### MOVEMENT METHODS ########################################################################################
func update_target_loc(target_loc):
	player_pos = target_loc

func set_rand_wander_pos():
	wander_pos = NavigationServer3D.region_get_random_point(navRegion.get_rid(), 1, false)
	nav_agent.target_position = wander_pos
	
func move_to_player(delta):
	nav_agent.target_position = player_pos
	
	face_dir.look_at(nav_agent.target_position, Vector3.UP)
	rotate_y(deg_to_rad(face_dir.rotation.y * TURN_SPEED))
	var current_loc = global_transform.origin
	var next_loc = nav_agent.get_next_path_position()
	var new_velocity = (next_loc - current_loc).normalized() * cur_speed

	if not is_on_floor() and gravity:
		new_velocity.y -= gravity * delta
	velocity = new_velocity

	if not player_in_attack_zone:
		move_and_slide()

func wander(delta):
	if(!wander_pos):
		set_rand_wander_pos()
		
	face_dir.look_at(nav_agent.get_next_path_position(), Vector3.UP)
	rotate_y(deg_to_rad(face_dir.rotation.y * TURN_SPEED))
	var current_loc = global_transform.origin
	var next_loc = nav_agent.get_next_path_position()
	var new_velocity = (next_loc - current_loc).normalized() * cur_speed

	if not is_on_floor() and gravity:
		new_velocity.y -= gravity * delta
	velocity = new_velocity
	move_and_slide()

########################################################################################



### ENEMY SIGHT ################################################################################################################################################################################
func _on_wait_in_pos_timer_timeout():
	set_rand_wander_pos()
	switch_state("HIDDEN")


func player_in_sight():
	var direction = global_position.direction_to( player_pos )
	var facing = (global_transform.basis.tdotz(direction)) * -1
	
	vision_cast.look_at(player_pos)
	vision_cast2.look_at(player_pos)
	vision_cast3.look_at(player_pos)
	var can_see = (vision_cast.get_collider() && vision_cast.get_collider().is_in_group("player")) || (vision_cast2.get_collider() && vision_cast2.get_collider().is_in_group("player")) || (vision_cast3.get_collider() && vision_cast3.get_collider().is_in_group("player"))
	
	if(!can_see): # if i cant see ya, i cant see ya.
		return false
	elif(player_noticed && facing > ENEMY_FOV && can_see): #if ya in my fov and i can see ya
		return true
	return false
		
func lost_View_of_player():
	$Timers/lost_view_of_player.start()
func _on_lost_view_of_player_timeout() -> void:
	if not player_in_sight() && previous_player_view_state == "PURSUING":
		switch_state("GOINGTOLASTPOS")
		last_player_pos = player_pos
		wander_pos = last_player_pos
		nav_agent.target_position = wander_pos

	
################################################################################################################################################################################

func play_sound(sound, max_db_rng:Array = [0,0], pitch_rng:Array = [0.1,0.1], skip_wait_for_done:bool = false):
	if skip_wait_for_done or !sound_maker.is_playing(): 
		 #just to give the sound a litte variety
		sound_maker.stream = sound
		
		if pitch_rng[0] == pitch_rng[1]:
			sound_maker.set_pitch_scale(pitch_rng[0])
		else:
			sound_maker.set_pitch_scale(RandomNumberGenerator.new().randf_range(pitch_rng[0], pitch_rng[1]))
			
		if max_db_rng[0] == max_db_rng[1]:
			sound_maker.volume_db = max_db_rng[0]
		else:
			sound_maker.volume_db = RandomNumberGenerator.new().randf_range(max_db_rng[0], max_db_rng[1])
		sound_maker.play()
func play_footstep_sound(sound, max_db_rng:Array = [0,0], pitch_rng:Array = [0,0], skip_wait_for_done:bool = false):
	if skip_wait_for_done or !footstep_sound.is_playing(): 
		 #just to give the sound a litte variety
		footstep_sound.stream = sound
		
		if pitch_rng[0] == pitch_rng[1]:
			footstep_sound.set_pitch_scale(pitch_rng[0])
		else:
			footstep_sound.set_pitch_scale(RandomNumberGenerator.new().randf_range(pitch_rng[0], pitch_rng[1]))
			
		if max_db_rng[0] == max_db_rng[1]:
			footstep_sound.volume_db = max_db_rng[0]
		else:
			footstep_sound.volume_db = RandomNumberGenerator.new().randf_range(max_db_rng[0], max_db_rng[1])
		footstep_sound.play()
		
func switch_state(newstate):
	previous_player_view_state = player_view_state
	player_view_state = newstate




### AREA CODE #########################################################################################

func _on_notice_player_body_entered(body):
	if(body.is_in_group("player")):
		player_noticed = true

func _on_notice_player_body_exited(body):
	if(body.is_in_group("player")):
		player_noticed = false
		if(player_view_state == "PURSUING" && player_view_state != "GOINGTOLASTPOS" && player_view_state != "SHOUT"):
			lost_View_of_player()


func _on_attack_player_body_entered(body: Node3D) -> void:
	if(body.is_in_group("player")):
		player_in_attack_zone = true


func _on_attack_player_body_exited(body: Node3D) -> void:
	if(body.is_in_group("player")):
		player_in_attack_zone = false

######################################################################################################
