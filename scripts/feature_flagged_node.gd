class_name FeatureFlaggedNode extends Node
## Attach as child of any node. Removes parent node at runtime if flag is disabled.
##
## Usage: Add this node as a child, set flag_name in inspector.
## If the flag is disabled (or doesn't exist), the parent node is removed.

@export var flag_name: String
@export var node_enabled_by_flag: bool = true
@export var node_removed_by_flag: bool = false

func _ready() -> void:
	if (
		FeatureFlags.is_enabled(flag_name) != node_enabled_by_flag
		or FeatureFlags.is_enabled(flag_name) == node_removed_by_flag
	): get_parent().queue_free()
