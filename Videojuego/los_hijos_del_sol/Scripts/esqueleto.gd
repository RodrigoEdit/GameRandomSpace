extends CharacterBody2D

@export var speed: float = 60.0
@export var detection_range: float = 20000.0
@export var attack_range: float = 35.0

# Sistema de vida y daño
@export var max_health: int = 50
@export var attack_damage: int = 15
var current_health: int

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

var player: CharacterBody2D = null
var is_attacking: bool = false
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Asegurarnos de que el arma no haga daño mientras solo camina
	if hitbox_collision:
		hitbox_collision.disabled = true

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
	if dir.x != 0:
		anim.flip_h = dir.x < 0
	
	if abs(dir.x) > abs(dir.y):
		anim.play("walk_side")
	else:
		anim.play("walk_down")

func _orient_side(is_left: bool) -> void:
	anim.flip_h = is_left
	hitbox.position.x = -abs(hitbox.position.x) if is_left else abs(hitbox.position.x)
	
func start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	
	if player:
		var is_left = player.global_position.x < global_position.x
		_orient_side(is_left)
		
	anim.play("attack")
	
	# Activamos la colisión del golpe durante el ataque
	if hitbox_collision and not is_dead:
		hitbox_collision.set_deferred("disabled", false)
	
	await anim.animation_finished
	
	# Apagamos la colisión al terminar el ataque
	if hitbox_collision:
		hitbox_collision.set_deferred("disabled", true)
		
	is_attacking = false

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	print("Esqueleto recibió daño. Vida restante: ", current_health)

	if current_health <= 0:
		die()
	else:
		# Si lo golpean mientras atacaba, cancelamos su ataque para que no se quede trabado
		is_attacking = false
		if hitbox_collision:
			hitbox_collision.set_deferred("disabled", true)
			
		if anim.sprite_frames.has_animation("hurt"):
			anim.play("hurt")

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO

	if hitbox_collision:
		hitbox_collision.set_deferred("disabled", true)

	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished

	queue_free()
	
# Cuando el ataque conecta con el jugador
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dead:
		# Si el jugador tiene el método take_damage, le resta vida en vez de reiniciar
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
		else:
			print("Golpeó al jugador por ", attack_damage, " de daño (Falta función take_damage en el script del jugador)")
