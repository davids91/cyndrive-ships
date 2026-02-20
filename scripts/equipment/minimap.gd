extends TileMapLayer

@export var map_extent: Rect2
@export var monitor_nodes: Array[Node]
@export var icon_template: Array[TextureRect]

var minimap_icons: Dictionary = {}
func _process(_delta: float) -> void:
	for i in range(monitor_nodes.size()): for node in monitor_nodes[i].get_children():
		# check if still in battle, erase if not
		if not node.in_battle() and minimap_icons.has(node):
			minimap_icons[node].queue_free()
			minimap_icons.erase(node)
		elif node.in_battle() and not minimap_icons.has(node):
			minimap_icons[node] = icon_template[i].duplicate()
			if "team" in node and node.team.team_id == 1: # team 1 is the player!
				minimap_icons[node].self_modulate = Color.LIME
			elif "color" in node: minimap_icons[node].self_modulate = node.color
			minimap_icons[node].set_visible(true)
			$area.add_child(minimap_icons[node])

		# Update icons position
		if minimap_icons.has(node):
			minimap_icons[node].position = get_position_within_panel(node.get_global_position())

## Caclulate the position within the minimap
func get_position_within_panel(pos: Vector2) -> Vector2:
	var position_in_minimap: Vector2 = (pos - map_extent.position).clamp(Vector2.ZERO, map_extent.size)
	position_in_minimap = position_in_minimap / map_extent.size * $area.size
	return position_in_minimap
