extends Control #enables a pause menu that completley stops the rest of the game while open

var game_is_paused = false

@onready var battle: Node2D = $"../.."

func _ready() -> void:	
	self.hide()	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause menu") and !game_is_paused:
		self.show()
		self.process_mode = Node.PROCESS_MODE_ALWAYS #keeps menu working while rest of game is paused
		game_is_paused = true		
		get_tree().paused = true
	elif event.is_action_pressed("pause menu") and game_is_paused:		
		unpause_game()
		
func unpause_game():
	game_is_paused = false
	get_tree().paused = false
	self.hide()

func _on_resume_btn_pressed() -> void:
	unpause_game()


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_restart_btn_pressed() -> void:
	get_tree().paused = false
	battle.reset_game()


func _on_restart_round_btn_pressed() -> void:
	get_tree().paused = false
	self.hide()
	battle.restart_round()
