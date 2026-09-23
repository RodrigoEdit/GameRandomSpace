extends CharacterBody2D

@export var speed: float = 180.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

	if direction != Vector2.ZERO:
		anim.play("walk")
		if direction.x < 0:
			sprite.flip_h = true   # Gira a la izquierda
		elif direction.x > 0:
			sprite.flip_h = false  # Gira a la derecha
	else:
		anim.play("idle")
