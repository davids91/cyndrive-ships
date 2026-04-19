extends Node2D

@export var name_list: Array[String] = [
	"A Game by\nDávid Tóth - Davids91",
	"Christer Kaitila - McFunkyPants",
	"Philippe Vaillancourt - snowfrogdev",
	"Noah Wizard",
	"Jason W - Jalent",
	"Drew Finstrom - dgf179",
	"Leooftheblack - Crimsongod",
	"Michael Avrie - TarnishedMoth",
	"Attila Bányai",
	"Ryan Malm - Rybar",
	"Tim Ruswick",
	"Grestyák Dominik - Gresi17",
	"lunaquarius",
	"Chris Deleon",
	"LenWinkler - LenWinkler",
	"J Patrick McKeown - Jpmckeown",
	"Travis Barnette - Barnettet31",
	"ArtyT",
	"Dragon",
	"Thank you! <3"
]

@export var nameplate_speed = -50.
@export var nameplate_enter_y = 300.
@export var nameplate_exit_y = -300.

@onready var nameplates: Array[Node] = $nameplates.get_children()

func _ready() -> void:
	var i: int = 0
	for n in nameplates:
		n.set_nameplate(name_list[i], "")
		i += 1

var index_of_top_nameplate: int = 0
var index_of_name_to_display: int = 4
const exit_y_of_nameplate: float = 500.
func _process(delta: float) -> void:
	if index_of_name_to_display >= name_list.size(): index_of_name_to_display = 0 # DEBUG
	for n in nameplates:
		n.position.y += delta * nameplate_speed
		if n.phase_tween: continue
		if n.phased and n.position.y < nameplate_exit_y: n.phase_out()
		elif not n.phased and n.position.y > nameplate_enter_y: n.phase_in()
	if(
		index_of_name_to_display >= name_list.size()
		or nameplates[index_of_top_nameplate].position.y > -exit_y_of_nameplate
		or nameplates[index_of_top_nameplate].phase_tween
	):
		return

	# Assign a name to the chosen nameplate and position it below view
	nameplates[index_of_top_nameplate].set_nameplate(name_list[index_of_name_to_display], "")
	nameplates[index_of_top_nameplate].position.y = exit_y_of_nameplate
	index_of_name_to_display += 1
	index_of_top_nameplate = (index_of_top_nameplate + 1) % nameplates.size()
