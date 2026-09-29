extends CharacterBody2D

@export var speed: float = 60.0
@export var detection_range: float = 250.0
@export var attack_range: float = 35.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

var player: CharacterBody2D = null
var is_attacking: bool = false
var is_dead: bool = false

func _ready() -> void:
	# Busca al jugador por su grupo
	player = get_tree().get_first_node_in_group("player")
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(_delta: float) -> void:
	if is_dead or is_attacking or player == null:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	# Si el jugador está dentro de su rango de visión
	if distance_to_player <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		
		# Rango de ataque cuerpo a cuerpo
		if distance_to_player <= attack_range:
			start_attack()
		else:
			# Movimiento y animaciones
			velocity = direction * speed
			move_and_slide()
			update_animation(direction)
	else:
		velocity = Vector2.ZERO
		anim.play("walk_down")
		anim.stop()

func update_animation(dir: Vector2) -> void:
	# Girar sprite según dirección horizontal
	if dir.x != 0:
		anim.flip_h = dir.x < 0
	
	if abs(dir.x) > abs(dir.y):
		anim.play("walk_side")
	else:
		anim.play("walk_down")

func start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("attack")
	
	# Espera a que termine la animación del golpe
	await anim.animation_finished
	is_attacking = false

# Si el jugador entra en contacto con el arma o cuerpo
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dead:
		get_tree().call_deferred("reload_current_scene")
