class_name Player
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal usage_progress_changed(ratio: float)
signal equipment_changed(weapon: ItemData)
signal attack_performed(weapon: ItemData)
signal died

enum State { UNARMED, EQUIPPED, USING_ITEM }

@export var max_speed: float = 120.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

@export var max_health: int = 100
var current_health: int

# Nodos de la escena
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var effects: StatusEffectManager = $StatusEffectManager

# Nodos de Hitbox según la jerarquía de tu escena (HitboxPivot -> Area2D -> CollisionShape2D)
@onready var hitbox_pivot: Node2D = $HitboxPivot
@onready var attack_hitbox: Area2D = $HitboxPivot/Area2D
@onready var attack_shape: CollisionShape2D = $HitboxPivot/Area2D/CollisionShape2D

var facing_sign: float = 1.0
var current_dir_suffix: String = "down"

var state: State = State.UNARMED
var equipped_weapon: ItemData = null
var _hotbar: HotbarManager = null
var _usage_elapsed: float = 0.0
var _must_release_use: bool = false
var _attack_cooldown_left: float = 0.0

var is_attacking: bool = false
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health
	state = State.UNARMED
	equipped_weapon = null
	
	if attack_shape:
		attack_shape.disabled = true
		
	if attack_hitbox:
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	
	if anim and anim.sprite_frames:
		anim.sprite_frames.set_animation_loop("attack", false)
	
	# Inicia obligatoriamente en idle_down
	_play_anim("idle_down")
		
	_bind_hud.call_deferred()


func _bind_hud() -> void:
	var hud: PlayerHUD = get_tree().get_first_node_in_group("hud") as PlayerHUD
	if hud == null:
		push_warning("Player: no se encontró la HUD (grupo 'hud').")
		return
	_hotbar = hud.hotbar
	_hotbar.selected_item_changed.connect(_on_selected_item_changed)
	hud.bind_player(self)
	_on_selected_item_changed(_hotbar.get_selected_item())


func _physics_process(delta: float) -> void:
	if is_dead or is_attacking:
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target_speed: float = max_speed * effects.get_speed_multiplier()

	if input_vector != Vector2.ZERO:
		_update_direction_suffix(input_vector)
		velocity = velocity.move_toward(input_vector * target_speed, acceleration * delta)
		update_animation(true)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		update_animation(false)

	move_and_slide()


func _process(delta: float) -> void:
	if is_dead:
		return
	if _attack_cooldown_left > 0.0:
		_attack_cooldown_left -= delta
	_process_usage(delta)


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	if event.is_action_pressed("attack") and state == State.EQUIPPED and _attack_cooldown_left <= 0.0 and not is_attacking:
		_perform_attack()
		return

	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			take_damage(20)
		elif event.keycode == KEY_L:
			heal(20)


func _perform_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	_attack_cooldown_left = equipped_weapon.attack_cooldown if equipped_weapon else 0.5
	attack_performed.emit(equipped_weapon)
	
	_update_flip()
	_play_anim("attack")

	if attack_shape:
		attack_shape.disabled = false

	if anim:
		await anim.animation_finished

	if attack_shape:
		attack_shape.disabled = true
	is_attacking = false
	
	update_animation(velocity != Vector2.ZERO)


# Determina la dirección actual y gestiona la orientación lateral
func _update_direction_suffix(input_vector: Vector2) -> void:
	if abs(input_vector.x) > abs(input_vector.y):
		if input_vector.x > 0:
			current_dir_suffix = "rigth" # Respeta el nombre de tu animación en el editor
			facing_sign = 1.0
		else:
			current_dir_suffix = "left"
			facing_sign = -1.0
	else:
		if input_vector.y > 0:
			current_dir_suffix = "down"
		else:
			current_dir_suffix = "up"

	# Orientación de la Hitbox según hacia dónde mira
	if hitbox_pivot:
		hitbox_pivot.scale.x = facing_sign


# Actualiza las animaciones según estado (Desarmado vs Con Mazo)
func update_animation(is_moving: bool) -> void:
	if is_attacking or is_dead:
		return
		
	_update_flip()

	if state == State.EQUIPPED:
		# Estado con Arma/Mazo equipado
		if is_moving:
			_play_anim("walk_weapon")
		else:
			_play_anim("idle_weapon")
	else:
		# Estado Desarmado
		if is_moving:
			var anim_name := "walk_" + current_dir_suffix
			if not _play_anim(anim_name):
				_play_anim("walk_down")
		else:
			_play_anim("idle_down")


func _play_anim(anim_name: String) -> bool:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
		return true
	push_warning("Animación no encontrada: " + anim_name)
	return false


func _process_usage(delta: float) -> void:
	var holding: bool = Input.is_action_pressed("use_item")

	if not holding:
		_must_release_use = false
		_cancel_usage()
		return

	if _must_release_use or _hotbar == null:
		return

	var item: ItemData = _hotbar.get_selected_item()
	if item == null or item.item_type != ItemData.ItemType.CONSUMABLE:
		return

	if state != State.USING_ITEM:
		state = State.USING_ITEM
		_usage_elapsed = 0.0

	_usage_elapsed += delta
	usage_progress_changed.emit(clampf(_usage_elapsed / item.use_time, 0.0, 1.0))

	if _usage_elapsed >= item.use_time:
		_complete_usage(item)


func _cancel_usage() -> void:
	if state != State.USING_ITEM:
		return
	state = State.UNARMED
	_usage_elapsed = 0.0
	usage_progress_changed.emit(0.0)


func _complete_usage(item: ItemData) -> void:
	state = State.UNARMED
	_usage_elapsed = 0.0
	_must_release_use = true
	usage_progress_changed.emit(0.0)
	if _hotbar.consume_selected():
		_apply_item_effect(item)


func _apply_item_effect(item: ItemData) -> void:
	var buff_icon: Texture2D = item.effect_icon if item.effect_icon != null else item.item_icon
	match item.effect_type:
		ItemData.EffectType.HEAL:
			heal(item.heal_amount)
		ItemData.EffectType.SPEED_BOOST:
			effects.apply_speed(item.speed_multiplier, item.stamina_multiplier, item.effect_duration, buff_icon)
		ItemData.EffectType.SHIELD:
			effects.apply_shield(item.shield_hits, buff_icon)


func _on_selected_item_changed(item: ItemData) -> void:
	print("SELECCIONADO: ", item)
	if item:
		print("  tipo: ", item.item_type, " | WEAPON es: ", ItemData.ItemType.WEAPON)
	_cancel_usage()
	if item != null and item.item_type == ItemData.ItemType.WEAPON:
		equipped_weapon = item
		state = State.EQUIPPED
		equipment_changed.emit(item)
	else:
		if state == State.EQUIPPED:
			state = State.UNARMED
		equipped_weapon = null
		equipment_changed.emit(null)

	update_animation(velocity != Vector2.ZERO)


func actualizar_interfaz_vida() -> void:
	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	if effects and effects.absorb_hit():
		return
		
	_cancel_usage()
	current_health = clampi(current_health - amount, 0, max_health)
	actualizar_interfaz_vida()

	if current_health <= 0:
		die()


func heal(amount: int) -> void:
	if is_dead:
		return
	current_health = clampi(current_health + amount, 0, max_health)
	actualizar_interfaz_vida()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	_cancel_usage()
	
	if attack_shape:
		attack_shape.set_deferred("disabled", true)
	if $CollisionShape2D:
		$CollisionShape2D.set_deferred("disabled", true)
	
	if _play_anim("death"):
		await anim.animation_finished
	
	died.emit()

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.has_method("take_damage"):
		var damage: int = equipped_weapon.weapon_damage if equipped_weapon else 10
		body.take_damage(damage)
		
func _update_flip() -> void:
	if not anim:
		return
	if state == State.EQUIPPED or is_attacking:
		anim.flip_h = facing_sign < 0.0
	else:
		anim.flip_h = false
