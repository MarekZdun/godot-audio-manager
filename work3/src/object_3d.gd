extends MeshInstance


func _exit_tree():
	for child in get_children():
		if child is AudioStreamPlayer3D:
			AudioManager.stop_sound(child)
			
