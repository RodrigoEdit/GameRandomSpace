extends CharacterBody2D

@export var speed: float = 140.0
@export var max_health: int = 100

var current_health: int

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label

func _ready() -> void:
	current_health = max_health
	health_bar.max_value = max_health
	actualizar_interfaz_vida()

func _physics_process(_delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * speed
	move_and_slide()
	actualizar_animacion(input_dir)

#Pruebas de daño y de dar vida
#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed and not event.echo:
		#if event.keycode == KEY_J:
			#take_damage(20)
		#elif event.keycode == KEY_H:
			#heal(20)

func actualizar_animacion(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		anim.play("idle")
		return

	if abs(dir.x) > abs(dir.y):
		anim.play("walk_side")
		anim.flip_h = (dir.x < 0)
	else:
		anim.flip_h = false
		if dir.y > 0:
			anim.play("walk_down")
		else:
			anim.play("walk_up")

func actualizar_interfaz_vida() -> void:
	health_bar.value = current_health
	health_label.text = str(current_health) + " / " + str(max_health)

func take_damage(amount: int) -> void:
	current_health = clamp(current_health - amount, 0, max_health)
	actualizar_interfaz_vida()
	
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	current_health = clamp(current_health + amount, 0, max_health)
	actualizar_interfaz_vida()

func die() -> void:
	queue_free()
