extends RigidBody3D
@export var speed:int = 100
@onready var snow_break:GPUParticles3D = $snow_break

func _on_body_entered(body: Node) -> void:
	print("aaaaa")
	$CollisionShape3D.disabled = true
	$MeshInstance3D.visible = false
	snow_break.restart()


func _on_snow_break_finished() -> void:
	queue_free()
