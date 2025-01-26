extends Area3D
var playerbody:CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if playerbody and playerbody.HEALTH < playerbody.init_HEALTH:
		playerbody.HEALTH = lerp(float(playerbody.HEALTH), float(playerbody.init_HEALTH), delta/2)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		playerbody = body

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		playerbody = null
