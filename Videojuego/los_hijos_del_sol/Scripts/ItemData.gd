class_name ItemData
extends Resource

enum ItemType { MISC, CONSUMABLE, WEAPON }
enum EffectType { NONE, HEAL, SPEED_BOOST, SHIELD }

@export_group("General")
@export var item_id: StringName = &""
@export var item_name: String = ""
@export_multiline var item_description: String = ""
@export var item_icon: Texture2D
@export var item_type: ItemType = ItemType.MISC
@export_range(1, 99) var max_stack: int = 1

@export_group("Consumible")
@export_range(0.1, 10.0, 0.1) var use_time: float = 1.5
@export var effect_type: EffectType = EffectType.NONE
@export var heal_amount: int = 0
@export var speed_multiplier: float = 1.0      # 1.5 = +50 % de velocidad
@export var stamina_multiplier: float = 1.0    # gancho para tu futura estamina
@export var shield_hits: int = 1               # impactos que absorbe
@export var effect_duration: float = 0.0       # segundos (no aplica al escudo)
@export var effect_icon: Texture2D             # icono del buff en la HUD

@export_group("Arma")
@export var weapon_damage: int = 1
@export_range(0.05, 5.0, 0.05) var attack_cooldown: float = 0.5
