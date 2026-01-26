class_name UIEnergyBar extends VBoxContainer

const max_bars: int = 10

@export_range(0, max_bars) var bars_remaining: int: set = _bars_remaining_changed
@export var label_text: String

var colormap: Array[Color]= _generate_bar_colormap()
var energy_bars: Array[TextureRect] = []

func _ready() -> void:
	$label.text = label_text
	_generate_bars(energy_bars)
	_bars_remaining_changed(bars_remaining)
	
func _generate_bars(arr: Array[TextureRect]) -> void:
	for i in range(max_bars):
		var bar: TextureRect = $energy_bar/energy_bar_pip.duplicate()
		arr.insert(i, bar)
		bar.offset_left = 24 * i
		bar.modulate = colormap.get(i)
		$energy_bar.add_child(bar)

func _generate_bar_colormap() -> Array[Color]:
	var colors: Array[Color] = []
	var half: float = round(max_bars / 2.0)
	for i in range(max_bars):
		var increment = float(i) / 4
		var color
		if (i < (half)): color = Color.RED.lerp(Color.YELLOW, increment)
		else: color = Color.YELLOW.lerp(Color.GREEN, increment)
		colors.insert(i, color)
	return colors

func _bars_remaining_changed(bars: int) -> void:
	bars_remaining = bars
	for i in range(energy_bars.size()):
		energy_bars.get(i).visible = (i < bars)

func _on_character_weapon_energy_updated(new_energy_level: float) -> void:
	bars_remaining = round(new_energy_level)
