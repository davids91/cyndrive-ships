extends BattleCharacter


func _ready() -> void:
	super()
	phase_in()

# DEBUG	
func _unhandled_key_input(event: InputEvent) -> void:
	phase_in()
