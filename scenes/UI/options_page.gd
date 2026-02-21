extends VBoxContainer

signal exited
func _on_options_back_btn_pressed() -> void: exited.emit()


enum VOLUMES {
	MASTER = 0,
	SFX = 1,
	MUSIC = 2,
}

@onready var vol_master_slider: HSlider = %MasterVolHSlider
@onready var vol_master_label_pct: Label = %MasterVolPercentLabel
@onready var vol_master_label_db: Label = %MasterVolDbLabel

@onready var vol_sfx_slider: HSlider = %SfxVolHSlider
@onready var vol_sfx_label_pct: Label = %SfxVolPercentLabel
@onready var vol_sfx_label_db: Label = %SfxVolDbLabel

@onready var vol_music_slider: HSlider = %MusicVolHSlider
@onready var vol_music_label_pct: Label = %MusicVolPercentLabel
@onready var vol_music_label_db: Label = %MusicVolDbLabel

func _ready() -> void:
	vol_master_slider.drag_ended.connect(_on_volume_slider_drag_ended.bind(VOLUMES.MASTER))
	vol_master_slider.value_changed.connect(_on_volume_slider_value_changed.bind(VOLUMES.MASTER))
	
	vol_sfx_slider.drag_ended.connect(_on_volume_slider_drag_ended.bind(VOLUMES.SFX))
	vol_sfx_slider.value_changed.connect(_on_volume_slider_value_changed.bind(VOLUMES.SFX))
	
	vol_music_slider.drag_ended.connect(_on_volume_slider_drag_ended.bind(VOLUMES.MUSIC))
	vol_music_slider.value_changed.connect(_on_volume_slider_value_changed.bind(VOLUMES.MUSIC))
	
	visibility_changed.connect(_on_visibility_changed)
	
func _on_visibility_changed() -> void:
	if visible:
		reset_music_sliders()

func reset_music_sliders() -> void:
	for idx in VOLUMES.values():
		vol_music_slider.set_value(AudioServer.get_bus_volume_linear(idx) * 100.0)
	
func _on_volume_slider_drag_ended(value_changed: bool, which:VOLUMES) -> void:
	if value_changed:
		match which:
			VOLUMES.MASTER:
				AudioServer.set_bus_volume_linear(VOLUMES.MASTER, vol_master_slider.value / 100.0)
			VOLUMES.SFX:
				AudioServer.set_bus_volume_linear(VOLUMES.SFX, vol_sfx_slider.value / 100.0)
			VOLUMES.MUSIC:
				AudioServer.set_bus_volume_linear(VOLUMES.MUSIC, vol_music_slider.value / 100.0)

func _on_volume_slider_value_changed(value: float, which:VOLUMES) -> void:
	## Called every frame potentially as the slider is moved
	var rounded_percentage_as_text:String = "%d%%" % value
	var db_as_text:String = "%.1f" % linear_to_db(value / 100.0)
	match which:
		VOLUMES.MASTER:
			vol_master_label_pct.text = rounded_percentage_as_text
			vol_master_label_db.text = db_as_text
		VOLUMES.SFX:
			vol_sfx_label_pct.text = rounded_percentage_as_text
			vol_sfx_label_db.text = db_as_text
		VOLUMES.MUSIC:
			vol_music_label_pct.text = rounded_percentage_as_text
			vol_music_label_db.text = db_as_text
