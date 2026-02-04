class_name WeaponSlot extends Node

signal weapon_changed(slot: int)

@export var weapons: Array[BattleShipWeapon]
var current_slot: int = 0

func reset() -> void:
	if abs(current_slot) < weapons.size() and null != weapons[current_slot] and "reset" in weapons[current_slot]:
		weapons[current_slot].reset()

func shutdown():
	if "shutdown" in weapons[current_slot]:
		weapons[current_slot].shutdown()

func select_slot(slot: int) -> void:
	if( # Slot not within bounds
		slot < 0 or slot >= weapons.size()
		# Weapon not unlocked or alreeady selected
		or weapons[slot] == null or current_slot == slot
	):
		return
	if "shutdown" in weapons[current_slot]:
		weapons[current_slot].shutdown()
	current_slot = slot
	weapon_changed.emit(slot)

func get_weapon_name() -> String:
	if weapons[current_slot]: return weapons[current_slot].name 
	else: return "UNDEFINED"

func get_energy_cost() -> float:
	if weapons[current_slot]: return weapons[current_slot].energy_cost
	else: return 1.

func process_input_action(action: Dictionary) -> void:
	if abs(current_slot) < weapons.size() and null != weapons[current_slot]:
		weapons[current_slot].process_input_action(action)

var is_shooting: bool = false
func _process(_delta: float) -> void:
	if abs(current_slot) < weapons.size() and null != weapons[current_slot]:
		is_shooting = weapons[current_slot].is_shooting
