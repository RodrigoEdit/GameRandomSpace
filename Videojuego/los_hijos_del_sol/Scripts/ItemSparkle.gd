class_name ItemSparkle
extends Area2D
## Destello interactuable. RANDOM_LOOT = vasijas; FIXED_ITEM = objetos fijos (armas).

enum Mode { RANDOM_LOOT, FIXED_ITEM }

@export var mode: Mode = Mode.RANDOM_LOOT

@export_group("Random Loot (vasijas)")
@export var loot_table: Array[ItemData] = []
@export_range(0.0, 1.0, 0.05) var empty_chance: float = 0.2
@export var empty_message: String = "La vasija está vacía..."

@export_group("Fixed Item (objetos fijos)")
@export var fixed_item_name: String = ""
@export_multiline var fixed_item_desc: String = ""
@export var fixed_item_icon: Texture2D

@export_group("Destello")
@export_range(0.1, 3.0, 0.05) var blink_half_period: float = 0.6
@export_range(0.0, 1.0, 0.05) var min_alpha: float = 0.3
@export_range(0.0, 1.0, 0.05) var max_alpha: float = 1.0

@export_group("Indicador")
@export var show_prompt: bool = true
@export_range(8, 96, 1) var prompt_font_size: int = 24

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt_label: Label = $PromptLabel

var _item: ItemData = null # null = vacío
var _player_inside: bool = false
var _is_busy: bool = false
var _is_depleted: bool = false
var _blink_tween: Tween


func _ready() -> void:
	z_as_relative = false
	z_index = 50

	_prompt_label.add_theme_font_size_override("font_size", prompt_font_size)
	_prompt_label.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# El contenido se decide UNA sola vez, al aparecer en escena.
	# Si se sorteara en cada interacción, el jugador podría pulsar "No"
	# y volver a intentar hasta que salga un ítem mejor.
	_item = _resolve_item()

	if mode == Mode.FIXED_ITEM and _item == null:
		push_warning("%s: modo FIXED_ITEM sin 'fixed_item_name'. Destello desactivado." % name)
		_deplete()
		return

	_start_blink()


# --- Resolución del ítem -------------------------------------------------

func _resolve_item() -> ItemData:
	match mode:
		Mode.RANDOM_LOOT:
			return _roll_loot()
		Mode.FIXED_ITEM:
			return _build_fixed_item()
	return null


func _roll_loot() -> ItemData:
	if loot_table.is_empty() or randf() < empty_chance:
		return null
	return loot_table.pick_random() as ItemData


func _build_fixed_item() -> ItemData:
	if fixed_item_name.is_empty():
		return null
	var item: ItemData = ItemData.new()
	item.item_id = StringName(fixed_item_name.to_snake_case())
	item.item_name = fixed_item_name
	item.item_description = fixed_item_desc
	item.item_icon = fixed_item_icon
	return item


# --- Destello visual -----------------------------------------------------

func _start_blink() -> void:
	_sprite.modulate.a = max_alpha
	_blink_tween = create_tween().set_loops()
	_blink_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blink_tween.tween_property(_sprite, "modulate:a", min_alpha, blink_half_period)
	_blink_tween.tween_property(_sprite, "modulate:a", max_alpha, blink_half_period)


func _refresh_prompt() -> void:
	_prompt_label.visible = show_prompt and _player_inside and not _is_busy and not _is_depleted


# --- Detección del jugador -----------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	_refresh_prompt()


# --- Interacción ---------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or _is_busy or _is_depleted:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_interact()


func _interact() -> void:
	_is_busy = true
	_refresh_prompt()

	# Vasija vacía: mensaje con solo "Aceptar" y el destello queda inactivo.
	if _item == null:
		await ItemPopupManager.show_message(empty_message)
		_deplete()
		return

	var accepted: bool = await ItemPopupManager.ask_pickup(_item)
	if accepted:
		queue_free()
	else:
		# "No": el destello permanece para recogerlo después.
		_is_busy = false
		_refresh_prompt()


func _deplete() -> void:
	_is_depleted = true
	_is_busy = false
	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()
	_sprite.visible = false
	_prompt_label.visible = false
	set_deferred("monitoring", false)
	set_process_unhandled_input(false)
