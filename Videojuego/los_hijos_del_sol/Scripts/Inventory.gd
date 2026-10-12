extends Node

signal item_added(item: ItemData)


func add_item(item: ItemData) -> void:
	item_added.emit(item)
