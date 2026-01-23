extends CanvasLayer

@onready var dialogText = %main_dialogue
@onready var dialogIcon = %npc_icon

const npc_L_texture = preload("res://textures/npc_1.png")
const npc_I_texture = preload("res://textures/npc_2.png")
const npc_M_texture = preload("res://textures/npc_4.png")
const npc_P_texture = preload("res://textures/npc_3.png")

const seconds_per_letter = 0.06
const DIALOG_TXT: Array[String] = [ \
"I: If you were really the leader you claim you are, you would fly that ship yourself, instead of subjecting this innocent pilot to losing his memories!", \
"L: The intercom is on! He can hear you!", \
"I: He should hear me! I’m issuing a warning! His life is in danger of never being the same!", \
"P: I’m excited to be here! Just let me know when you want me to launch into space! I haven’t flown a ship quite like this before, but it shouldn’t be harder than anything else I’ve piloted.", \
"L: …Sounds like he didn’t hear you anyway, which is a skill I should try to learn from him if he survives this test flight.", \
"I: Survive?! You think he won’t survive?", \
"L: Yes, I, I risked everything to steal your technology and put it on this one, irreplaceable space ship, and I set up an obstacle course to decapitate the pilot, and smash our collective life’s work into smithereens. I had all of the hull removed before we began today, just to make sure it was extra-sure to crumple into dust.", \
"I: Joke all you want, but you sound like Team Pocket when you talk like that—", \
"L: How dare you!—", \
"I: Even if your far-fetched plan works and we somehow win this thing, it’s comforting to know that we’ll be moving from one evil dictator who thinks his loyal subjects are expendable to, whatever the hell kind of leader you think you are.", \
"L: Before I intervened, your plan was to let everyone go on suffering; you’re a boot-lick agent of the status quo with your cowardice running the show like that; where’s the I who dared to believe she could turn back the clock? That’s who we’ll need to win this war, not doctor wet blanket’s pity procedures. All the pilots were briefed on the level of danger for this mission. (Which is minimal.) We may not have the resources that Team Pocket pours down the drain, but I don’t skimp on the safety of my crew. That ship would stand a good chance in a firefight even if it couldn’t go back in time to fight the battle again, and you would know that if you came out of your stupor to attend mission briefings now and again!", \
"P: Everything looks good here in the hangar bay! Everything is a hundred percent full of safety! And I’m ready to show you what a real pilot can do!", \
"I: ‘Full of safety?’ What safety checks have you even—", \
"L: Launch now, Pilot! We’re in grave danger of dying from old age if we keep listening to ‘Curse of the Expert’ over here!", \
"I: No!—", \
"I: Be careful, that is a one of a kind spaceship that we cannot—", \
"L: Don’t worry about a thing Pilot, no matter what happens to you, we can reverse time in the region and let you try again; there has never been a safer test flight in the history of the galaxy." \
]

var current_letter = 0
var current_line = 0
var delay_remaining = 0.0

func _ready() -> void:
	if FeatureFlags.is_enabled('dialogue'):
		self.visible = true
	else: 
		self.visible = false

func _process(delta: float) -> void:
	
	delay_remaining -= delta
	
	if delay_remaining > 0: #still waiting?
		return
	
	var line = DIALOG_TXT[current_line]
	current_letter += 1
	var txt = line.substr(0, current_letter)
	
	# print("DIALOG line:"+str(current_line)+ " letter:"+str(current_letter) + " TXT:"+txt)
	dialogText.text = txt
	
	# which npc avatar to use?
	if line[0] == "I":
		dialogIcon.texture = npc_I_texture
	elif line[0] == "L":
		dialogIcon.texture = npc_L_texture
	elif line[0] == "M":
		dialogIcon.texture = npc_M_texture
	else: 
		dialogIcon.texture = npc_P_texture

	if current_letter > line.length():
		current_line += 1
		current_letter = 0

	if DIALOG_TXT.size() < current_line: # dialog completed?
		print("DIALOG completed!")
		self.visible = false
		delay_remaining = 9999999999
	else:
		delay_remaining = seconds_per_letter
		
	
