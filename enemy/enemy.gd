extends CharacterBody3D

@onready var face_dir:Node3D = $face_dir
@onready var nav_agent:NavigationAgent3D = $NavigationAgent3D
@onready var player_view_state:String = "HIDDEN" # HIDDEN, NOTICED
@onready var previous_player_view_state:String = "HIDDEN" # HIDDEN, NOTICED
#@onready var billy_status:String = "WANDERING" # WANDERING, PURSUING, SEARCHING, WAITING, NOTICED, GOINGTOLASTPOS
@onready var navRegion:NavigationRegion3D = $"../NavigationRegion3D"
@onready var animation_player:AnimationPlayer = $AnimationPlayer

@export var SPEED:float
@export var RUN_SPEED:float
@export var TURN_SPEED:float
@export var ENEMY_FOV = 70

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

#timers
@onready var footstep_timer = $"Timers/footstep_timer"
@onready var wait_in_pos_timer:Timer = $"Timers/wait_in_pos_timer"
@onready var attack_cooldown:Timer = $"Timers/attack_cooldown_timer"

@onready var nav_bake_finished = false

@export_group("Jared's Extra Settings")
@export var snowball:PackedScene
@onready var snowball_spawn:Node3D = $snowball_spawn

@onready var PLAYER = get_tree().get_nodes_in_group("player")[0]

func _ready():
	ENEMY_FOV = cos(deg_to_rad(ENEMY_FOV))

	if not PLAYER:
		assert(false, "PLAYER NOT FOUND BY ENEMY!!")



func _physics_process(delta):
	PLAYER.get_node("UserInterface/DebugPanel").add_property("Wandering POS", wander_pos)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("Enemy POS", global_transform.origin)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("Enemy State", player_view_state)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("player_noticed", player_noticed)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("player_in_attack_zone", player_in_attack_zone)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("SPEED", SPEED)
	PLAYER.get_node("UserInterface/DebugPanel").add_property("last_player_pos", last_player_pos)

	if not nav_bake_finished:
		print_debug("NAV MESH NOT BAKED, ENEMIES CANNOT MOVE") 

	# if(player_view_state == "THROWING"):
	# 	return
	# elif(player_view_state == "WAITING"):
	# 	pass
	# 	# animation_player.play("IDLELONG")
	# elif(cur_speed == RUN_SPEED):
	# 	pass # run animation
	# 	# animation_player.play("RUN")
	# 	# play_sound(load("res://Enemies/Billy/sounds/monsterbreathingrun.mp3"), [-3, -5], [1, 2.5])
	# elif(cur_speed == SPEED):
	# 	pass #walk
	# 	# animation_player.play("WALK1")
	# 	sound_maker.stop()
		
	# if footstep_timer.is_stopped() and player_view_state == "PURSUING" or player_view_state == "WANDERING" or player_view_state == "NOTICED" or player_view_state == "GOINGTOLASTPOS":
	# 	# play_footstep_sound(load("res://Enemies/Billy/sounds/thud.wav"), [-4, -5], [-1, -2.5])
	# 	if cur_speed == RUN_SPEED:
	# 		footstep_timer.start(.3)
	# 	else:
	# 		footstep_timer.start(.5)
		
	# if(player_view_state == "NOTICED"):
	# 	if(!player_noticed): return
	# 	if(previous_player_view_state == "PURSUING"):
	# 		cur_speed = RUN_SPEED
	# 	else:
	# 		cur_speed = SPEED
	# 	move_to_player(delta)
	# el
	if(player_view_state == "GOINGTOLASTPOS"):
		if(previous_player_view_state == "PURSUING"):
			cur_speed = RUN_SPEED
		else:
			cur_speed = SPEED
		cur_speed = RUN_SPEED
		
		# if(abs(wander_pos.x - global_transform.origin.x) < 0.1 and abs(wander_pos.z - global_transform.origin.z) < 0.1): #if timer stopped or at pos, get new pos
		# 	SHOUT()
		# else:
		wander(delta)
	elif(player_view_state == "PURSUING"): #
		# if(!player_in_view): return
		cur_speed = RUN_SPEED
		move_to_player(delta)
	elif(player_view_state == "WAITING"):
		#animation_player.play("IDLESHORT")
		return
	elif(player_view_state == "HIDDEN"):
		cur_speed = SPEED
		if(!wander_pos):
			set_rand_wander_pos()
		
		if(abs(wander_pos.x - global_transform.origin.x) < 0.1 and abs(wander_pos.z - global_transform.origin.z) < 0.1): #if timer stopped or at pos, get new pos
			switch_state("WAITING")
			wait_in_pos_timer.start(rng.randf_range(1.0, 11.0))
		else:
			wander(delta)

func _process(_delta):
	if(player_in_attack_zone && attack_cooldown.is_stopped()):
		throw_snowball()
		switch_state("ATTACKING")
	if(player_noticed):
		check_if_player_in_sight()

func throw_snowball():
	pass

### MOVEMENT METHODS ########################################################################################
func update_target_loc(target_loc):
	player_pos = target_loc
func bake_finished():
	nav_bake_finished = true

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

func check_if_player_in_sight():
		var direction = global_position.direction_to( player_pos )
		var facing = (global_transform.basis.tdotz(direction)) * -1
		var canseeya
		
		vision_cast.look_at(player_pos)
		vision_cast2.look_at(player_pos)
		vision_cast3.look_at(player_pos)
		var can_see = (vision_cast.get_collider() && vision_cast.get_collider().is_in_group("player")) || (vision_cast2.get_collider() && vision_cast2.get_collider().is_in_group("player")) || (vision_cast3.get_collider() && vision_cast3.get_collider().is_in_group("player"))
		
		if(!can_see): # if i cant see ya, i cant see ya.
			canseeya = "I cant see ya, ya behind a wall or somethin ya little shit"
			if(player_view_state == "PURSUING" && player_view_state != "GOINGTOLASTPOS" && player_view_state != "SHOUT"): # if i cant see ya, but i used to see ya
				lost_View_of_player()
		elif(facing > ENEMY_FOV && can_see): #if ya in my fov and i can see ya
			canseeya = "Im lookin at ya"
			if(player_noticed):
				switch_state("PURSUING")
		else:
			canseeya = "I cant see ya"
			
		# PLAYER.get_node("UserInterface/DebugPanel").add_property("Can enemy see you", canseeya)
		# PLAYER.get_node("UserInterface/DebugPanel").add_property("behind wall? ", !can_see)
		
func lost_View_of_player():
	switch_state("GOINGTOLASTPOS")
	last_player_pos = player_pos
	wander_pos = last_player_pos
	nav_agent.target_position = wander_pos
################################################################################################################################################################################

func play_sound(sound, max_db_rng:Array = [0,0], pitch_rng:Array = [0,0], skip_wait_for_done:bool = false):
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
