extends Control

@export var map_extent: Rect2
@export var monitor_nodes: Array[Node]
@export var icon_template: Array[TextureRect]
@export var garbage_clean_interval_sec: float = 1.

var time_to_clean: float = garbage_clean_interval_sec
var minimap_icons: Dictionary = {}
func _process(delta: float) -> void:
	time_to_clean -= delta
	if time_to_clean <= 0.:
		time_to_clean = garbage_clean_interval_sec
		for node in minimap_icons.keys(): if not node or not node.visible:
			minimap_icons[node].queue_free()
			minimap_icons.erase(node)
	for i in monitor_nodes.size(): for node in monitor_nodes[i].get_children():
		if (not node.in_battle() or not node.visible) and minimap_icons.has(node):
			# check if still in battle, erase if not
			minimap_icons[node].queue_free()
			minimap_icons.erase(node)
		elif node.in_battle() and node.visible and 0. < node.modulate.a and not minimap_icons.has(node):
			# Add icon if it just appeared in battle
			minimap_icons[node] = icon_template[i].duplicate()
			if "team" in node:
				# team 1 is the player!
				if node.team.team_id == 1: minimap_icons[node].self_modulate = Color.LIME
				else: minimap_icons[node].self_modulate = node.team.color
			elif "color" in node: minimap_icons[node].self_modulate = node.color
			minimap_icons[node].set_visible(true)
			$area.add_child(minimap_icons[node])

		# Update icons position and scale
		if minimap_icons.has(node):
			var unclamped_position_in_minimap: Vector2 = (node.get_global_position() - map_extent.position)
			var position_in_minimap: Vector2 = unclamped_position_in_minimap.clamp(Vector2.ZERO, map_extent.size)
			var icon_scale : Vector2 = Vector2.ONE
			if position_in_minimap != unclamped_position_in_minimap: icon_scale *= 0.5
			if node is PlayerShip: icon_scale *= 1.2
			position_in_minimap = position_in_minimap / map_extent.size * $area.size
			minimap_icons[node].position = position_in_minimap
			minimap_icons[node].scale = icon_scale
