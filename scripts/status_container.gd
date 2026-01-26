extends HBoxContainer


func _on_energy_systems_boost_energy_updated(new_energy_level: float) -> void:
	$boost_energy.bars_remaining = new_energy_level
