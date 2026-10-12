extends Node
## Autoload provisional. Sustitúyelo por tu inventario real cuando lo tengas.

signal item_added(item: ItemData)

var _items: Array[ItemData] = []


func add_item(item: ItemData) -> void:
	_items.append(item)
	item_added.emit(item)
	print("Inventario: +%s (%d ítems)" % [item.item_name, _items.size()])


func get_items() -> Array[ItemData]:
	return _items.duplicate()
