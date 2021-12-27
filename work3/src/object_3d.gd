extends MeshInstance


func _exit_tree():
	for child in get_children():
		if child is AudioStreamPlayer3D:
			child.stream = null
			AudioManager._on_sound_3d_stream_player_finished(child)
			
