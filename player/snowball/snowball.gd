extends RigidBody3D
@export var speed:int = 100
@onready var snow_break:GPUParticles3D = $snow_break

var has_hit = false

func _on_body_entered(body: Node) -> void:
	if not has_hit:
		has_hit = true
		$CollisionShape3D.disabled = true
		$MeshInstance3D.visible = false
		snow_break.restart()
		$AudioStreamPlayer3D.play()

func _on_snow_break_finished() -> void:
	queue_free()
