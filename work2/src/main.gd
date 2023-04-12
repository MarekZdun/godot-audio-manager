extends Node2D

var stream_player
var object_1
var object_2
var object_3


func _ready():
	var sounds = [
		"blip",
		"confirmation",
		"laser"
	]
	
	var music = [
		"bgm",
		"rain"
	]
	
	AudioManager.load_sounds(sounds)
	AudioManager.load_music(music)

	AudioManager.sound_2d_channel_count = 4
	AudioManager.music_channel_count = 2
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound2D"), linear2db(1))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(1))
	
	AudioManager.play_loaded_music("bgm", 1, 1)
	
	var scene_2d = load("res://work2/src/scene_2d.tscn").instance()
	add_child(scene_2d)
	
	object_1 = scene_2d.get_node("Object1")
	object_2 = scene_2d.get_node("Object2")
	object_3 = scene_2d.get_node("Object3")
	
#	yield(get_tree().create_timer(4), "timeout")
#	AudioManager.unload_all_sounds()
#	AudioManager.unload_all_music()
#	AudioManager.sound_2d_channel_count = 0
	
	
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_1:
			AudioManager.play_sound(load("res://assets/sound/blip.wav"), AudioManager.SoundType.POSITIONAL_2D, object_1, 0, 1, 1)
#            AudioManager.play_loaded_sound("blip", AudioManager.SoundType.POSITIONAL_2D, object_1, 0, 1, 1)

		elif event.pressed and event.scancode == KEY_2:
			stream_player = AudioManager.play_sound(load("res://assets/sound/confirmation.ogg"), AudioManager.SoundType.POSITIONAL_2D, object_2, 0, 1, 1)
#            AudioManager.play_loaded_sound("confirmation", AudioManager.SoundType.POSITIONAL_2D, object_2, 0, 1, 1)

		elif event.pressed and event.scancode == KEY_3:
			AudioManager.play_sound(load("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, object_3, 0, 1, 1)
#            AudioManager.play_loaded_sound("laser", AudioManager.SoundType.POSITIONAL_2D, object_3, 0, 1, 1)

		elif event.pressed and event.scancode == KEY_SPACE:
			AudioManager.stop_sound(stream_player)
#            object_1.queue_free()


func _on_Button_button_down():
	AudioManager.play_loaded_sound("blip", AudioManager.SoundType.POSITIONAL_2D, object_1, 0, 1, 1)


func _on_Button2_button_down():
	AudioManager.play_loaded_sound("confirmation", AudioManager.SoundType.POSITIONAL_2D, object_2, 0, 1, 1)


func _on_Button3_button_down():
	AudioManager.play_loaded_sound("laser", AudioManager.SoundType.POSITIONAL_2D, object_3, 0, 1, 1)
