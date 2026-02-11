extends TextureButton

@export var label_text: String = ""

func _ready() -> void:
	$label.set_text(label_text)
