class_name Player                                            # CAMBIO 1
extends CharacterBody2D

# NUEVO 2: señales que escucha la HUD
signal health_changed(current: int, maximum: int)
signal usage_progress_changed(ratio: float)
signal equipment_changed(weapon: ItemData)
signal attack_performed(weapon: ItemData)
signal died

enum State { UNARMED, EQUIPPED, USING_ITEM }                 # NUEVO

@export var max_speed: float = 120.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

@export var max_health: int = 100
var current_health: int

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $HealthBar2
@onready var health_label: Label = $HealthBar2/Label
@onready var effects: StatusEffectManager = $StatusEffectManager   # CAMBIO 3

var facing_direction: Vector2 = Vector2.DOWN

# NUEVO: estado de consumo y equipamiento
var state: State = State.UNARMED
var equipped_weapon: ItemData = null
var _hotbar: HotbarManager = null
var _usage_elapsed: float = 0.0
var _must_release_use: bool = false  # evita consumir en bucle con la tecla mantenida
var _attack_cooldown_left: float = 0.0


func _ready() -> void:
	current_health = max_health
	health_bar.max_value = max_health
	actualizar_interfaz_vida()
	_bind_hud.call_deferred()                                # NUEVO


# NUEVO: conecta con la HUD y la Hotbar (diferido: no importa el orden en el árbol)
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
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target_speed: float = max_speed * effects.get_speed_multiplier()   # CAMBIO 4

	if input_vector != Vector2.ZERO:
		facing_direction = input_vector.normalized()
		velocity = velocity.move_toward(input_vector * target_speed, acceleration * delta)
		update_animation(true)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		update_animation(false)

	move_and_slide()


# CAMBIO 5: consumo con barra de carga
func _process(delta: float) -> void:
	if _attack_cooldown_left > 0.0:
		_attack_cooldown_left -= delta
	_process_usage(delta)


func _process_usage(delta: float) -> void:
	var holding: bool = Input.is_action_pressed("use_item")

	if not holding:
		_must_release_use = false
		_cancel_usage()  # soltar antes del 100 % cancela
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


# NUEVO: equipar armas
func _on_selected_item_changed(item: ItemData) -> void:
	_cancel_usage()  # cambiar de slot interrumpe el consumo
	if item != null and item.item_type == ItemData.ItemType.WEAPON:
		equipped_weapon = item
		state = State.EQUIPPED
		equipment_changed.emit(item)
	else:
		if state == State.EQUIPPED:
			state = State.UNARMED
		equipped_weapon = null
		equipment_changed.emit(null)


# CAMBIO: tus pruebas K/L ahora conviven con el ataque
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and state == State.EQUIPPED and _attack_cooldown_left <= 0.0:
		_perform_attack()
		return

	# Pruebas de daño y de dar vida (solo en builds de depuración)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			take_damage(20)
		elif event.keycode == KEY_L:
			heal(20)


func _perform_attack() -> void:
	_attack_cooldown_left = equipped_weapon.attack_cooldown
	attack_performed.emit(equipped_weapon)
	print("Ataque con %s (daño %d)" % [equipped_weapon.item_name, equipped_weapon.weapon_damage])
	# Aquí conectarás tu hitbox y tu animación de ataque.


func update_animation(is_moving: bool) -> void:
	var dir_suffix := get_direction_suffix(facing_direction)
	var prefix := "walk_" if is_moving else "idle_"
	var anim_name := prefix + dir_suffix

	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)


func get_direction_suffix(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"


func actualizar_interfaz_vida() -> void:
	health_bar.value = current_health
	health_label.text = str(current_health) + " / " + str(max_health)
	health_changed.emit(current_health, max_health)          # CAMBIO 6: avisa a la HUD


func take_damage(amount: int) -> void:
	if effects.absorb_hit():                                 # CAMBIO 6: el escudo absorbe 1 impacto
		return
	_cancel_usage()                                          # recibir daño interrumpe el consumo
	current_health = clampi(current_health - amount, 0, max_health)
	actualizar_interfaz_vida()

	if current_health <= 0:
		die()


func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	actualizar_interfaz_vida()


func die() -> void:
	died.emit()
	queue_free()
