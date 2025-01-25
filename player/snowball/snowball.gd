extends RigidBody3D
@export var speed:int = 100
@onready var snow_break:GPUParticles3D = $snow_break

var has_hit = false

func _on_body_entered(body: Node) -> void:
	if not has_hit:
		if body.has_method("take_hit"):
			if body.is_in_group("head"): # not working yet TODO
				body.take_hit(100)
			else:
				body.take_hit(34)

		has_hit = true
		call_deferred("do_the_stuff")
		$MeshInstance3D.visible = false
		snow_break.restart()
		$AudioStreamPlayer3D.play()


func _on_snow_break_finished() -> void:
	queue_free()

func do_the_stuff():
		$CollisionShape3D.disabled = true
