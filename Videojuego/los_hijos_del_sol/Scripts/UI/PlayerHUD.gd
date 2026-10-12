class_name PlayerHUD
extends CanvasLayer
## Barras de vida y uso, e iconos de buffs. El Player se conecta con bind_player().

@export var buff_icon_size: Vector2 = Vector2(28, 28)

@onready var hotbar: HotbarManager = $Root/BottomPanel/Hotbar
@onready var _health_bar: ProgressBar = $Root/BottomPanel/StatusRow/HealthBar
@onready var _buffs_container: HBoxContainer = $Root/BottomPanel/StatusRow/StatusBuffsContainer
@onready var _usage_bar: ProgressBar = $Root/BottomPanel/UsageBar

# StatusEffect -> { "holder": Control, "label": Label }
var _buff_widgets: Dictionary = {}


func _ready() -> void:
	add_to_group("hud")
	_usage_bar.min_value = 0.0
	_usage_bar.max_value = 1.0
	_usage_bar.step = 0.001
	_usage_bar.value = 0.0


func bind_player(player: Player) -> void:
	player.health_changed.connect(_on_health_changed)
	player.usage_progress_changed.connect(_on_usage_progress_changed)
	player.effects.effect_added.connect(_on_effect_added)
	player.effects.effect_removed.connect(_on_effect_removed)
	_on_health_changed(player.current_health, player.max_health)
	_on_usage_progress_changed(0.0)


func _process(_delta: float) -> void:
	# Actualiza la cuenta atrás de cada buff con duración.
	for key in _buff_widgets:
		var effect: StatusEffect = key as StatusEffect
		var entry: Dictionary = _buff_widgets[key]
		var label: Label = entry["label"] as Label
		label.text = ("%d" % ceili(effect.time_left)) if effect.has_timer() else ""


func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func _on_usage_progress_changed(ratio: float) -> void:
	_usage_bar.value = ratio


func _on_effect_added(effect: StatusEffect) -> void:
	var holder: Control = Control.new()
	holder.custom_minimum_size = buff_icon_size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buffs_container.add_child(holder)

	if effect.icon != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = effect.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		# Marcador de color mientras no tengas icono.
		var placeholder: ColorRect = ColorRect.new()
		placeholder.color = Color.SKY_BLUE if effect.kind == StatusEffect.Kind.SPEED else Color.GOLD
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(placeholder)
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 10)
	holder.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN

	_buff_widgets[effect] = {"holder": holder, "label": label}


func _on_effect_removed(effect: StatusEffect) -> void:
	if not _buff_widgets.has(effect):
		return
	var entry: Dictionary = _buff_widgets[effect]
	(entry["holder"] as Control).queue_free()
	_buff_widgets.erase(effect)
