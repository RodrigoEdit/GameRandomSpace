extends Node

const LOG_PATH := "user://los_hijos_del_sol_debug.log"
var _file: FileAccess
var _console: PanelContainer
var _output: RichTextLabel
var _visible := false

func _ready() -> void:
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	log_info("Nueva sesión iniciada")
	log_info("Godot: " + str(Engine.get_version_info().get("string", "desconocido")))
	_crear_consola()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		_visible = not _visible
		_console.visible = _visible
		get_viewport().set_input_as_handled()

func log_info(message: String) -> void:
	_escribir("INFO", message)

func log_warning(message: String) -> void:
	_escribir("WARN", message)

func log_error(message: String) -> void:
	_escribir("ERROR", message)

func get_log_path() -> String:
	return ProjectSettings.globalize_path(LOG_PATH)

func _escribir(level: String, message: String) -> void:
	var line := "[%s] %s: %s" % [Time.get_datetime_string_from_system(), level, message]
	if _file:
		_file.store_line(line)
		_file.flush()
	if _output:
		_output.append_text(line + "\n")

func _crear_consola() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 200
	add_child(layer)

	_console = PanelContainer.new()
	_console.visible = false
	_console.set_anchors_preset(Control.PRESET_FULL_RECT)
	_console.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_console)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_console.add_child(margin)

	var column := VBoxContainer.new()
	margin.add_child(column)

	var title := Label.new()
	title.text = "CONSOLA DE DEPURACIÓN — F8 para cerrar"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)

	_output = RichTextLabel.new()
	_output.bbcode_enabled = false
	_output.fit_content = false
	_output.scroll_following = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_output)

	var buttons := HBoxContainer.new()
	column.add_child(buttons)

	var copy_button := Button.new()
	copy_button.text = "Copiar log"
	copy_button.pressed.connect(_copiar_log)
	buttons.add_child(copy_button)

	var open_hint := Label.new()
	open_hint.text = "Archivo: " + get_log_path()
	buttons.add_child(open_hint)

func _copiar_log() -> void:
	if _file:
		_file.flush()
	var contenido := FileAccess.get_file_as_string(LOG_PATH)
	DisplayServer.clipboard_set(contenido)
	log_info("Log copiado al portapapeles")
