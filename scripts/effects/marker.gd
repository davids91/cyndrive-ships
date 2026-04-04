class_name BattleMarker extends Area2D

# Minimap color
@export var color: Color = Color.ORANGE_RED

# Sonar sensor blip color
@export var blip_color: Color = Color.ORANGE_RED

# How long the marker should stay active on the radar
@export var sonar_blip_lifetime: float = SonarBlip.INFINITE_LIFETIME

# Functions required for marker to be integrated into the scene
func in_battle() -> bool: return true
