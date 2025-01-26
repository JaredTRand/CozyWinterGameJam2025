extends MeshInstance3D

@export var is_active:bool = true
@export var interaction_type:String
@export var interaction_name:String
@export var interaction_cooldown_time:float = 3.0
@export var thought:String

@export var hvr_txt_size:int = 50
@export var txt_name:String = ""

@export_group("Pickup")
@export var pickup_able:bool = false
@export var pickup_sound:AudioStreamWAV = load("res://world/sounds/pickupitem.wav")
@export var inv_img:CompressedTexture2D
@export var parent_interactable:Node3D

@export_group("Openable")
@export var openable:bool = false
@export var open_sound:AudioStreamWAV
@export var close_sound:AudioStreamWAV

@export var animator:AnimationPlayer
@export var sound:AudioStreamPlayer3D
@onready var hotbar_sound:AudioStreamPlayer = get_tree().get_first_node_in_group("hotbar_sound")

var hover_text_canbevisible = true

enum open_states {closed, open_locked, open, done}
var  open_state = open_states.closed

@onready var interaction_cooldown:Timer = Timer.new()
var in_player_interact_area = false

# Called when the node enters the scene tree for the first time.
func _ready():	
	if not is_this_active():
		is_active = false
	
	if not interaction_type:
		if pickup_able:
			interaction_type = "Pick Up"
		elif openable:
			interaction_type = "Open"
		else:
			interaction_type = "Interact"
	
	if not animator:
		animator = find_child("AnimationPlayer")
	
	if not sound:
		sound = find_child("AudioStreamPlayer3D")
		
	
func interact():
	if not is_active: return
		
	if pickup_able:
		pass #pick up
	
	if openable:
		if open_state == open_states.open:
			close()
		else:
			open()
					
func open():
	open_state = open_states.open
	interaction_type = "Close"
	
	if animator: animator.play("open")
	if sound:
		if open_sound: sound.stream = open_sound
		if sound.stream: sound.play()

	
func close():
	open_state = open_states.closed
	interaction_type = "Open"

	if animator: animator.play_backwards("open")	
	if sound:
		if close_sound: sound.stream = close_sound
		if sound.stream: sound.play()
		
func is_this_active():
	if is_active: 
		return true

	if is_instance_valid(parent_interactable):
		if parent_interactable.has_method("interact") and not parent_interactable.locked:
			is_active = true
		else: 
			is_active = false
	
	return is_active
	
