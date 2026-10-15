extends CharacterBody2D

@export var speed: float = 140.0
@export var max_health: int = 100
@export var escena_fuego: PackedScene = preload("res://Scenes/FuegoAzul.tscn")

var current_health: int
var atacando: bool = false
var ultima_direccion_x: float = 1.0 # 1.0 = derecha, -1.0 = izquierda

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label

func _ready() -> void:
	current_health = max_health
	health_bar.max_value = max_health
	actualizar_interfaz_vida()

func _physics_process(_delta: float) -> void:
	# Si presiona Espacio/Enter (ui_accept) y no está atacando, lanza el ataque
	if Input.is_action_just_pressed("ui_accept") and not atacando:
		realizar_ataque()
		return

	# Mientras da el puñetazo se detiene un instante
	if atacando:
		return

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Guardar hacia qué lado horizontal miró por última vez para el disparo
	if input_dir.x != 0:
		ultima_direccion_x = -1.0 if input_dir.x < 0 else 1.0

	velocity = input_dir * speed
	move_and_slide()
	actualizar_animacion(input_dir)

# Pruebas de daño, vida y tecla extra de ataque (K)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K and not atacando:
			realizar_ataque()
		#elif event.keycode == KEY_J:
			#take_damage(20)
		#elif event.keycode == KEY_H:
			#heal(20)

func realizar_ataque() -> void:
	atacando = true
	velocity = Vector2.ZERO
	
	# Voltear el sprite hacia el lado donde va a disparar
	anim.flip_h = (ultima_direccion_x < 0)
	
	# Si creaste una animación llamada "attack" en tu AnimatedSprite2D, la reproduce
	if anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
	
	# --- MATEMÁTICA: Distribución angular simétrica (2*PI / N) ---
	var cantidad_fuegos: int = 3
	for i in range(cantidad_fuegos):
		var fuego = escena_fuego.instantiate()
		get_parent().add_child(fuego)
		
		# Nace a 25 píxeles adelante de las manos de la jugadora
		var punto_salida = global_position + Vector2(25.0 * ultima_direccion_x, 0)
		fuego.global_position = punto_salida
		fuego.posicion_inicial = punto_salida
		fuego.direccion_x = ultima_direccion_x
		
		# Desfase en radianes: TAU (2π) dividido entre 3 = 120° entre cada bola de fuego
		fuego.angulo_inicial = i * (TAU / cantidad_fuegos)
	
	# Tiempo que dura la pose del golpe antes de poder volver a caminar
	await get_tree().create_timer(0.35).timeout
	atacando = false

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
