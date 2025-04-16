@tool
extends EditorPlugin
var TheDock

func _enter_tree() -> void:
	TheDock = preload("res://addons/instance_collision_and_rigidbody/Dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, TheDock)
	


func _exit_tree() -> void:
	remove_control_from_docks(TheDock)
	#TheDock.free()
