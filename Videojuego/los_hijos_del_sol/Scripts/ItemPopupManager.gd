extends CanvasLayer
## Autoload. Sin `class_name` (chocaría con el nombre del Autoload).
## API asíncrona: usar con `await`.

signal popup_opened
signal popup_closed
signal item_accepted(item: ItemData)
signal _decision_made(accepted: bool)

enum View { PICKUP, MESSAGE }

const QUESTION_FORMAT: String = "¿Deseas añadir '%s' a tu inventario?"

@onready var _name_label: Label = $CenterContainer/PopupPanel/MarginContainer/VBoxContainer/NameLabel
@onready var _icon_rect: TextureRect = $CenterContainer/PopupPanel/MarginContainer/VBoxContainer/IconRect
@onready var _description_label: Label = $CenterContainer/PopupPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var _question_label: Label = $CenterContainer/PopupPanel/MarginContainer/VBoxContainer/QuestionLabel
@onready var _yes_button: Button = $CenterContainer/PopupPanel/MarginContainer/VBoxContainer/ButtonsContainer/YesButton
@onready var _no_button: Button = $CenterContainer/PopupPanel/MarginContainer/VBoxContainer/ButtonsContainer/NoButton

var _is_open: bool = false
var _open_frame: int = -1
var _view: View = View.PICKUP
var _current_item: ItemData = null


func _ready() -> void:
	# Toda la UI debe seguir respondiendo con el juego pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false

	$Dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$CenterContainer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)


# --- API pública ---------------------------------------------------------

## Pregunta si añadir el ítem. Devuelve true si el jugador eligió "Sí".
func ask_pickup(item: ItemData) -> bool:
	if _is_open or item == null:
		return false

	_view = View.PICKUP
	_current_item = item

	_name_label.text = item.item_name
	_name_label.visible = true
	_icon_rect.texture = item.item_icon
	_icon_rect.visible = item.item_icon != null
	_description_label.text = item.item_description
	_description_label.visible = not item.item_description.is_empty()
	_question_label.text = QUESTION_FORMAT % item.item_name
	_yes_button.text = "Sí"
	_no_button.visible = true

	_open()
	var accepted: bool = await _decision_made
	return accepted


## Muestra un mensaje con un único botón "Aceptar".
func show_message(text: String) -> void:
	if _is_open:
		return

	_view = View.MESSAGE
	_current_item = null

	_name_label.visible = false
	_icon_rect.visible = false
	_description_label.visible = false
	_question_label.text = text
	_yes_button.text = "Aceptar"
	_no_button.visible = false

	_open()
	await _decision_made


# --- Apertura / cierre ---------------------------------------------------

func _open() -> void:
	_is_open = true
	_open_frame = Engine.get_process_frames()
	visible = true
	get_tree().paused = true
	_yes_button.grab_focus.call_deferred()
	popup_opened.emit()


func _finish(accepted: bool) -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	get_tree().paused = false

	var item: ItemData = _current_item
	_current_item = null

	if accepted and item != null:
		Inventory.add_item(item)
		item_accepted.emit(item)

	popup_closed.emit()
	_decision_made.emit(accepted)


func _on_yes_pressed() -> void:
	_finish(true)


func _on_no_pressed() -> void:
	_finish(false)


# --- Input (teclado / gamepad) -------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	# Ignora el frame de apertura (la misma pulsación de E que abrió el popup).
	if Engine.get_process_frames() == _open_frame:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		var focused: Control = get_viewport().gui_get_focus_owner()
		if focused is Button:
			(focused as Button).pressed.emit()
	elif event.is_action_pressed("ui_cancel") and _view == View.PICKUP:
		get_viewport().set_input_as_handled()
		_finish(false)
