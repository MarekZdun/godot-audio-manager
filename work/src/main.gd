extends Node


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
	
	AudioManager.sound_channel_count = 2
	AudioManager.music_channel_count = 2
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear2db(1))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(1))
#	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound"), true)
	
#	AudioManager.play_loaded_music("bgm", 1, 1)
	
	yield(get_tree().create_timer(4), "timeout")
	AudioManager.unload_all_sounds()
	AudioManager.unload_all_music()
#	AudioManager.sound_channel_count = 0
	
	
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_1:
			AudioManager.play_sound(load("res://assets/sound/blip.wav"), AudioManager.SoundType.NON_POSITIONAL, null, 0, 1, 1)
#            AudioManager.play_loaded_sound("blip", AudioManager.SoundType.NON_POSITIONAL, null, 0, 1, 1)

		elif event.pressed and event.scancode == KEY_2:
			AudioManager.play_sound(load("res://assets/sound/confirmation.ogg"), AudioManager.SoundType.NON_POSITIONAL, null, 0, 1, 1)
#            AudioManager.play_loaded_sound("confirmation", AudioManager.SoundType.NON_POSITIONAL, null, 0, 1, 1)

		elif event.pressed and event.scancode == KEY_3:
			AudioManager.play_sound(load("res://assets/sound/laser.ogg"), AudioManager.SoundType.NON_POSITIONAL, null, 0, 1, 1)
#            AudioManager.play_loaded_sound("laser", AudioManager.SoundType.NON_POSITIONAL, null, 0, 1, 1)

