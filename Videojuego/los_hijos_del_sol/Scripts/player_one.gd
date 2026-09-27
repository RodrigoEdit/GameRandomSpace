extends CharacterBody2D

@export var speed: float = 140.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = input_dir * speed
	move_and_slide()
	
	actualizar_animacion(input_dir)

func actualizar_animacion(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		anim.play("idle")
		return

	# Si se mueve horizontalmente (o diagonal dominada por X)
	if abs(dir.x) > abs(dir.y):
		anim.play("walk_side")
		# Voltea horizontalmente el sprite si va a la izquierda
		anim.flip_h = (dir.x < 0)
	else:
		anim.flip_h = false
		if dir.y > 0:
			anim.play("walk_down")
		else:
			anim.play("walk_up")
