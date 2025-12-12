extends HBoxContainer


func _on_energy_systems_boost_energy_updated(new_energy_level: int) -> void:
	$boost_energy.bars_remaining = new_energy_level

func _on_energy_systems_laser_energy_updated(new_energy_level: int) -> void:
	$laser_energy.bars_remaining = new_energy_level
