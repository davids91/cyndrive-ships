class_name EnergySystems extends Node

signal boost_energy_updated(new_energy_level: float)
signal weapon_energy_updated(new_energy_level: float)

@export var max_boost: float = 10.
@export var boost_recharge_per_sec: float = 10.
@export var max_weapon: float = 10.
@export var weapon_recharge_per_sec: float = 10.
@export var weapon_system: WeaponSlot

func temporal_snapshot() -> Dictionary:
	return { "weapon_energy": weapon_energy_remaining, "boost_energy": boost_energy_remaining }

func temporal_correction(snapshot: Dictionary) -> void:
	if "weapon_energy" in snapshot:
		weapon_energy_remaining = snapshot["weapon_energy"]
	if "boost_energy" in snapshot:
		boost_energy_remaining = snapshot["boost_energy"]

func _ready() -> void:
	weapon_energy_updated.emit(weapon_energy_remaining)
	boost_energy_updated.emit(boost_energy_remaining)

func reset() -> void:
	boost_energy_remaining = max_boost
	weapon_energy_remaining = max_weapon
	weapon_energy_updated.emit(weapon_energy_remaining)
	boost_energy_updated.emit(boost_energy_remaining)

# called from the function by the same name in the battle_character script
var pending_energy_cost: float = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not get_parent().in_battle(): return
	if $"../controller".is_boosting: _drain_boost(delta)
	else: _recharge_boost(delta)
	if weapon_system.is_shooting: _update_weapon_energy(-weapon_system.get_energy_cost())
	else: _recharge_weapon(delta)

######
#BOOST
var boost_energy_remaining: float = max_boost

#Update
func _update_boost_energy(bars: int):
	boost_energy_remaining = round(clamp(boost_energy_remaining + bars, 0, max_boost))
	boost_energy_updated.emit(boost_energy_remaining)

#Drain
var boost_time = 0.0
func _drain_boost(delta: float) -> void:
	const boost_depletion_per_second = 8
	var time_to_one_bar = (1.0 / boost_depletion_per_second)
	boost_time += delta
	if boost_time < time_to_one_bar: return
	boost_time = boost_time - time_to_one_bar
	_update_boost_energy(-1)
	

#Recharge
var boost_recharge_time = 0.0
func _recharge_boost(delta: float) -> void:
	const boost_recharge_per_second = 1.0
	boost_recharge_time += delta
	var time_to_one_bar = (1.0 / boost_recharge_per_second)
	if boost_recharge_time < time_to_one_bar: return
	boost_recharge_time = boost_recharge_time - time_to_one_bar
	if boost_energy_remaining < max_boost: _update_boost_energy(1)
	
#Check
func has_boost_energy() -> bool:
	return boost_energy_remaining > 0
	
######
#weapon
var weapon_energy_remaining: float = max_weapon

#Update
func _update_weapon_energy(bars: float) -> void:
	weapon_energy_remaining = clamp(weapon_energy_remaining + bars, 0, max_weapon)
	weapon_energy_updated.emit(weapon_energy_remaining)
	
#Recharge
var weapon_recharge_time = 0.0
func _recharge_weapon(delta: float) -> void:
	const weapon_recharge_per_second: float = 1
	weapon_recharge_time += delta
	var time_to_one_bar = (1.0 / weapon_recharge_per_second)
	if (weapon_recharge_time < time_to_one_bar): return
	weapon_recharge_time = weapon_recharge_time - time_to_one_bar
	if weapon_energy_remaining < max_weapon: _update_weapon_energy(1)
	
#Check
func has_weapon_energy() -> bool:
	return weapon_energy_remaining > weapon_system.get_energy_cost()
