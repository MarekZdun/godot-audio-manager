extends Sprite


func _exit_tree():
	for child in get_children():
		if child is AudioStreamPlayer2D:
			child.stream = null
			AudioManager._on_sound_2d_stream_player_finished(child)
