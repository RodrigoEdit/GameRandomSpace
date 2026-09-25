extends CharacterBody2D

@export var speed: float = 180.0
@export var jump_force: float = -400.0

# Multiplicadores para el estilo Mario
@export var fall_gravity_multiplier: float = 1.8  # Gravedad más pesada al caer
@export var short_jump_multiplier: float = 2.5   # Gravedad extra si sueltas el botón rápido

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	var base_gravity := get_gravity().y

	# 1. Sistema de salto tipo Mario
	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = jump_force
	else:
		# Si está cayendo, aplica una gravedad más pesada
		if velocity.y > 0:
			velocity.y += base_gravity * fall_gravity_multiplier * delta
		# Si está subiendo pero el jugador SOLTÓ la tecla de salto, frena el salto
		elif velocity.y < 0 and not Input.is_action_pressed("ui_accept"):
			velocity.y += base_gravity * short_jump_multiplier * delta
		# Si sigue manteniendo presionado mientras sube, usa gravedad normal
		else:
			velocity.y += base_gravity * delta

	# 2. Movimiento Horizontal (Izquierda / Derecha)
	var axis := Input.get_axis("ui_left", "ui_right")
	velocity.x = axis * speed

	move_and_slide()

	# 3. Animaciones y Orientación
	if axis != 0:
		anim.play("walk")
		sprite.flip_h = (axis < 0)
	else:
		anim.play("idle")
