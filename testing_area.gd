extends Node3D
@onready var player = $Character
@onready var navServer:NavigationRegion3D = $Environment_shit/NavigationRegion3D
@export var enemy_count:int = 20
@export var enemies_at_a_time:int = 10
@export var enemy:PackedScene
var bake_finished = false
@onready var all_spawn_positions = get_tree().get_nodes_in_group("enemyspawnloc")

var enemies_spawned:int = 0
var enemies_killed:int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#navServer.bake_navigation_mesh()
	spawn_enemies(enemies_at_a_time)


func spawn_enemies(num):
	if enemies_spawned >= enemy_count: return
	print("spawned " + str(num))
	for i in num:
		# var spawn_pos = NavigationServer3D.region_get_random_point(navServer.get_rid(), 1, false)
		if enemy.can_instantiate():
			var new_enemy = enemy.instantiate()
			new_enemy.global_position = all_spawn_positions.pick_random().global_position
			get_tree().root.add_child.call_deferred(new_enemy)

			new_enemy.enemy_death.connect(enemy_died)

			enemies_spawned += 1
			if enemies_spawned >= enemy_count:
				break
			
func enemy_died():
	enemies_killed += 1

	if enemies_killed >= enemy_count:
		you_won()
	else:
		spawn_enemies(1)

func you_won():
	for i in get_tree().get_nodes_in_group("enemy"):
		i.queue_free()
	player.queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://endlevel.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	get_tree().call_group("enemy", "update_target_loc", player.global_transform.origin)
#func _on_navigation_region_3d_bake_finished() -> void:
	#get_tree().call_group("enemy", "bake_finished")
