extends BaseBattle

#TODO: set Laupeerium indicator( and increase it when the heist is complete )
#TODO: Play dialouge when Laupeerium is reached, and summon boss

func _ready() -> void:
	super()
	spawn_position = $combatants/player_carrier.global_position
	player_input.input_disabled = true
	GUI.set_objective("")
	GUI.set_disabled_weapons_mask(0xC)
	$dialogues/intro.start()
	$dialogues/intro.connect(
		"dialogue_signal_0",
		func(): GUI.set_objective("Destroy Silo Door\nCollect Laupeerium\nSurvive")
	)

func _on_player_carrier_phased(phased_in: bool) -> void:
	%character.visible = phased_in

func _on_intro_dialouge_finished() -> void:
	player_input.input_disabled = false
