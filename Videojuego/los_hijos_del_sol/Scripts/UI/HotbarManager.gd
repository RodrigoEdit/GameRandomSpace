class_name HotbarManager
extends HBoxContainer
## Lógica de la barra rápida: slots, cantidades, selección y su UI.

signal selected_item_changed(item: ItemData)
signal slots_changed

class HotbarSlot extends RefCounted:
	var item: ItemData = null
	var quantity: int = 0

class SlotView extends RefCounted:
	var panel: PanelContainer
	var icon: TextureRect
	var name_label: Label       # texto de respaldo cuando el ítem no tiene icono
	var quantity_label: Label

@export_range(1, 9) var slot_count: int = 5
@export var slot_size: Vector2 = Vector2(48, 48)
@export var starting_items: Array[ItemData] = [] # SOLO PARA PRUEBAS: bórralo después

var _slots: Array[HotbarSlot] = []
var _views: Array[SlotView] = []
var _selected_index: int = 0


func _ready() -> void:
	for i in slot_count:
		_slots.append(HotbarSlot.new())
		_views.append(_create_view(i))

	Inventory.item_added.connect(_on_inventory_item_added)

	for item in starting_items:
		if item != null:
			add_item(item)

	_refresh_all()


# --- API pública ---------------------------------------------------------

func get_selected_item() -> ItemData:
	return _slots[_selected_index].item


func select_slot(index: int) -> void:
	if index < 0 or index >= slot_count or index == _selected_index:
		return
	_selected_index = index
	_refresh_all()
	selected_item_changed.emit(get_selected_item())


## Devuelve false si no hay espacio.
func add_item(item: ItemData) -> bool:
	# 1) Apilar en un slot que ya tenga el mismo ítem.
	if item.max_stack > 1:
		for i in _slots.size():
			var slot: HotbarSlot = _slots[i]
			if slot.item != null and _is_same(slot.item, item) and slot.quantity < slot.item.max_stack:
				slot.quantity += 1
				_after_change(i, false)
				return true
	# 2) Primer hueco libre.
	for i in _slots.size():
		var slot: HotbarSlot = _slots[i]
		if slot.item == null:
			slot.item = item
			slot.quantity = 1
			_after_change(i, true)
			return true
	return false


## Resta cantidad al slot seleccionado. Devuelve false si no había suficiente.
func consume_selected(amount: int = 1) -> bool:
	var slot: HotbarSlot = _slots[_selected_index]
	if slot.item == null or slot.quantity < amount:
		return false
	slot.quantity -= amount
	var emptied: bool = slot.quantity <= 0
	if emptied:
		slot.item = null
		slot.quantity = 0
	_after_change(_selected_index, emptied)
	return true


# --- Input ---------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	for i in slot_count:
		var action: StringName = StringName("hotbar_%d" % (i + 1))
		if InputMap.has_action(action) and event.is_action_pressed(action):
			select_slot(i)
			get_viewport().set_input_as_handled()
			return


# --- Internos ------------------------------------------------------------

func _is_same(a: ItemData, b: ItemData) -> bool:
	return a == b or (a.item_id != &"" and a.item_id == b.item_id)


func _on_inventory_item_added(item: ItemData) -> void:
	if not add_item(item):
		push_warning("Hotbar llena: no se pudo añadir '%s'." % item.item_name)


## item_changed = el contenido del slot pasó de un ítem a otro (o a vacío).
func _after_change(index: int, item_changed: bool) -> void:
	_refresh_slot(index)
	slots_changed.emit()
	# Solo avisamos al Player si cambió QUÉ ítem hay en el slot activo;
	# si solo cambió la cantidad no hay que interrumpir nada.
	if item_changed and index == _selected_index:
		selected_item_changed.emit(get_selected_item())


func _refresh_all() -> void:
	for i in _slots.size():
		_refresh_slot(i)


func _refresh_slot(index: int) -> void:
	var slot: HotbarSlot = _slots[index]
	var view: SlotView = _views[index]
	var has_item: bool = slot.item != null

	view.icon.texture = slot.item.item_icon if has_item else null
	view.name_label.text = slot.item.item_name.left(4) if has_item and slot.item.item_icon == null else ""
	view.quantity_label.text = ("x%d" % slot.quantity) if has_item and slot.quantity > 1 else ""
	view.panel.add_theme_stylebox_override("panel", _make_style(index == _selected_index))


func _make_style(selected: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.border_color = Color(1.0, 0.85, 0.3) if selected else Color(0.8, 0.8, 0.8, 0.5)
	style.set_border_width_all(3 if selected else 1)
	style.set_corner_radius_all(2)
	return style


func _create_view(index: int) -> SlotView:
	var view: SlotView = SlotView.new()

	view.panel = PanelContainer.new()
	view.panel.custom_minimum_size = slot_size
	view.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view.panel)

	# Control intermedio: permite superponer iconos y textos con anclajes.
	var content: Control = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.panel.add_child(content)

	view.icon = TextureRect.new()
	view.icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(view.icon)
	view.icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)

	view.name_label = Label.new()
	view.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	view.name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	view.name_label.add_theme_font_size_override("font_size", 10)
	content.add_child(view.name_label)
	view.name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var key_label: Label = Label.new()
	key_label.text = str(index + 1)
	key_label.add_theme_font_size_override("font_size", 10)
	content.add_child(key_label)
	key_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 3)

	view.quantity_label = Label.new()
	view.quantity_label.add_theme_font_size_override("font_size", 10)
	content.add_child(view.quantity_label)
	view.quantity_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 3)
	view.quantity_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	view.quantity_label.grow_vertical = Control.GROW_DIRECTION_BEGIN

	return view
