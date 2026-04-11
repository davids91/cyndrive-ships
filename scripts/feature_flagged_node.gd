class_name FeatureFlaggedNode extends Node
## Attach as child of any node. Removes parent node at runtime if flag is disabled.
##
## Usage: Add this node as a child, set flag_name in inspector.
## If the flag is disabled (or doesn't exist), the parent node is removed.

@export var flag_name: String

func _ready() -> void:
	if not FeatureFlags.is_enabled(flag_name): get_parent().queue_free()
