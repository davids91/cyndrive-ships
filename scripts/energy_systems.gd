extends Node

func _ready() -> void:
	laser_energy_updated.emit(boost_energy_remaining)
	boost_energy_updated.emit(laser_energy_remaining)
	
# called from the function by the same name in the battle_character script
var is_boosting: bool
var is_lasering: bool
func process_input_action(action) -> void:
	is_boosting = action["boost"]
	is_lasering = action["pewpew"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
var was_lasering = false
func _process(delta: float) -> void:
	
	if is_boosting: _drain_boost(delta)
	else: _recharge_boost(delta)
	
	if is_lasering and not was_lasering: _update_laser_energy(-1)
	else: _recharge_laser(delta)
	
	was_lasering = is_lasering

######	
#BOOST	
var boost_energy_remaining: int = 10
signal boost_energy_updated(new_energy_level: int)

#Update
func _update_boost_energy(bars: int):
	boost_energy_remaining = clamp(boost_energy_remaining + bars, 0, 10)
	boost_energy_updated.emit(boost_energy_remaining)


#Drain
var boost_time = 0.0
func _drain_boost(delta) -> void:
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
	if boost_energy_remaining < 10: _update_boost_energy(1)
	
#Check
func has_boost_energy() -> bool:
	return boost_energy_remaining > 0
	
######
#LASER
var laser_energy_remaining: int = 10
signal laser_energy_updated(new_energy_level: int)

#Update
func _update_laser_energy(bars: int):
	laser_energy_remaining = clamp(laser_energy_remaining + bars, 0, 10)
	laser_energy_updated.emit(laser_energy_remaining)
	
#Recharge
var laser_recharge_time = 0.0
func _recharge_laser(delta: float) -> void:
	const laser_recharge_per_second = 1
	laser_recharge_time += delta
	var time_to_one_bar = (1.0 / laser_recharge_per_second)
	if (laser_recharge_time < time_to_one_bar): return
	laser_recharge_time = laser_recharge_time - time_to_one_bar
	if laser_energy_remaining < 10: _update_laser_energy(1)
	
#Check
func has_laser_energy() -> bool:
	return laser_energy_remaining > 0

	
	
	
	
