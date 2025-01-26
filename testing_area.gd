extends Node3D
@onready var player = $Character
@onready var navServer:NavigationRegion3D = $Environment_shit/NavigationRegion3D
@export var enemy_count:int = 10
@export var enemies_at_a_time:int = 5
var bake_finished = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	navServer.bake_navigation_mesh()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	get_tree().call_group("enemy", "update_target_loc", player.global_transform.origin)
func _on_navigation_region_3d_bake_finished() -> void:
	get_tree().call_group("enemy", "bake_finished")
