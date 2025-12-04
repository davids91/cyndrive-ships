# an explosion effect you can play forward or backward or pause

extends Node2D

@onready var fire1: Sprite2D = $fire1
@onready var fire2: Sprite2D = $fire2
@onready var fire3: Sprite2D = $fire3
@onready var fire4: Sprite2D = $fire4
@onready var fire5: Sprite2D = $fire5
@onready var smoke1: Sprite2D = $smoke1
@onready var shockwave1: Sprite2D = $shockwave1
@onready var spikes1: Sprite2D = $spikes1
@onready var burst1: Sprite2D = $burst1
@onready var debris1: Sprite2D = $debris1
@onready var debris2: Sprite2D = $debris2
@onready var debris3: Sprite2D = $debris3
@onready var debris4: Sprite2D = $debris4

var currentGlobalGameTime:float = 0 # TODO: grab from game manager
var spawnTimestamp:float = 0 # game timestamp of when triggered
var lifespan:float = 2 # seconds of life until faded out
var currentAge:float = 0 # can increase and decrease freely

func _ready() -> void:
    # for testing only!
    position = Vector2(256,256)

func _process(delta: float) -> void:

    # TODO:
    # grab from game time manager
    # currentGlobalGameTime = 
    # subtract from spawn time to get fx age
    # currentAge = currentGlobalGameTime - spawnTimestamp

    # - for testing purposes: wobble a fixed time for now
    currentAge = abs(sin(Time.get_unix_time_from_system()/lifespan)) * lifespan
    # print("explosion age:"+str(currentAge))
    
    var hideScale = Vector2(0,0)
    # check if too old or young and hide
    if (currentAge<0 || currentAge>lifespan): # inactive
        fire1.scale = hideScale
        fire2.scale = hideScale
        fire3.scale = hideScale
        fire4.scale = hideScale
        fire5.scale = hideScale
        smoke1.scale = hideScale
        shockwave1.scale = hideScale
        spikes1.scale = hideScale
        burst1.scale = hideScale
        debris1.scale = hideScale
        debris2.scale = hideScale
        debris3.scale = hideScale
        debris4.scale = hideScale
        return
        
    # different lifespans for varying speeds
    var fire1Percent = currentAge/lifespan
    var fire2Percent = currentAge/lifespan
    var fire3Percent = currentAge/lifespan
    var fire4Percent = currentAge/lifespan
    var fire5Percent = currentAge/lifespan
    var smoke1Percent = currentAge*2/lifespan
    var shockwave1Percent = currentAge*4/lifespan
    var spikes1Percent = currentAge*6/lifespan
    var burst1Percent = currentAge*8/lifespan
    var debris1Percent = currentAge*3/lifespan
    var debris2Percent = currentAge*3.33/lifespan
    var debris3Percent = currentAge*2.78/lifespan
    var debris4Percent = currentAge*3.14/lifespan

    # grow over time
    var unitScale = Vector2(1,1)
    fire1.scale = unitScale * fire1Percent * 1.23
    fire2.scale = unitScale * fire2Percent * 0.98
    fire3.scale = unitScale * fire3Percent * 0.11
    fire4.scale = unitScale * fire4Percent * 1.41
    fire5.scale = unitScale * fire5Percent * 1.04
    smoke1.scale = unitScale * smoke1Percent * 4
    shockwave1.scale = unitScale * shockwave1Percent * 8
    spikes1.scale = unitScale * spikes1Percent * 4
    burst1.scale = unitScale * burst1Percent * 6
    debris1.scale = unitScale
    debris2.scale = unitScale
    debris3.scale = unitScale
    debris4.scale = unitScale

    # move over time
    fire1.position = position + (Vector2(61,12)*fire1Percent) 
    fire2.position = position + (Vector2(-18,27)*fire2Percent) 
    fire3.position = position + (Vector2(17,18)*fire3Percent) 
    fire4.position = position + (Vector2(-20,-16)*fire4Percent) 
    fire5.position = position + (Vector2(0,-22)*fire5Percent) 
    smoke1.position = position + (Vector2(14,-33)*smoke1Percent) 
    shockwave1.position = position # + (Vector2(22,-22)*shockwave1Percent) 
    spikes1.position = position #  + (Vector2(-19,20)*spikes1Percent) 
    burst1.position = position # + (Vector2(-16,-16)*burst1Percent) 
    debris1.position = position + (Vector2(-150,-150)*debris1Percent) 
    debris2.position = position + (Vector2(150,-150)*debris2Percent) 
    debris3.position = position + (Vector2(-150,150)*debris3Percent) 
    debris4.position = position + (Vector2(150,150)*debris4Percent) 

    # spin over time        
    fire1.rotation_degrees = 90*fire1Percent
    fire2.rotation_degrees = -90*fire2Percent
    fire3.rotation_degrees = 45*fire3Percent
    fire4.rotation_degrees = -45*fire4Percent
    fire5.rotation_degrees = 90*fire5Percent
    smoke1.rotation_degrees = 15*smoke1Percent
    shockwave1.rotation_degrees = 0*shockwave1Percent
    spikes1.rotation_degrees = 0*spikes1Percent
    burst1.rotation_degrees = 0*burst1Percent
    debris1.rotation_degrees = 720*debris1Percent
    debris2.rotation_degrees = -720*debris2Percent
    debris3.rotation_degrees = 720*debris3Percent
    debris4.rotation_degrees = -720*debris4Percent
    
    # hide if too young (not too old since some go past 1)
    if (fire1Percent<=0): fire1.scale = hideScale
    if (fire2Percent<=0): fire2.scale = hideScale
    if (fire3Percent<=0): fire3.scale = hideScale
    if (fire4Percent<=0): fire4.scale = hideScale
    if (fire5Percent<=0): fire5.scale = hideScale
    if (smoke1Percent<=0): smoke1.scale = hideScale
    if (shockwave1Percent<=0): shockwave1.scale = hideScale
    if (spikes1Percent<=0): spikes1.scale = hideScale
    if (burst1Percent<=0): burst1.scale = hideScale
    if (debris1Percent<=0): debris1.scale = hideScale
    if (debris2Percent<=0): debris2.scale = hideScale
    if (debris3Percent<=0): debris3.scale = hideScale
    if (debris4Percent<=0): debris4.scale = hideScale
    
    # fade out with age
    fire1.self_modulate.a = max(0,min(1,1-fire1Percent))
    fire2.self_modulate.a = max(0,min(1,1-fire2Percent))
    fire3.self_modulate.a = max(0,min(1,1-fire3Percent))
    fire4.self_modulate.a = max(0,min(1,1-fire4Percent))
    fire5.self_modulate.a = max(0,min(1,1-fire5Percent))
    smoke1.self_modulate.a = max(0,min(1,1-smoke1Percent))
    shockwave1.self_modulate.a = max(0,min(1,1-shockwave1Percent))
    spikes1.self_modulate.a = max(0,min(1,1-spikes1Percent))
    burst1.self_modulate.a = max(0,min(1,1-burst1Percent))
    debris1.self_modulate.a = 1 # 1-min(1,debris1Percent)
    debris2.self_modulate.a = 1 # 1-min(1,debris2Percent)
    debris3.self_modulate.a = 1 # 1-min(1,debris3Percent)
    debris4.self_modulate.a = 1 # 1-min(1,debris4Percent)
    
    
