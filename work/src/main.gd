extends Node

var _sound_stream_player_1: AudioStreamPlayer
var _sound_stream_player_2: AudioStreamPlayer
var _sound_stream_player_3: AudioStreamPlayer
var _music_stream_player_1: AudioStreamPlayer

@onready var sound_channel_count_label = $SoundChannelCountLabel


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
	
#	AudioManager.sound_channel_count = 1
	AudioManager.music_channel_count = 1
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear_to_db(0.25))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(0.25))
#	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound"), true)

#	await get_tree().create_timer(5).timeout
#	AudioManager.music_channel_count = 0

	# test; set the pause mode for AudioStreamPlayer while the sound stream is playing
	#AudioManager.sound_channel_count = 1
	#await get_tree().create_timer(2).timeout
	#AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.NON_POSITIONAL, null,
		#0, 1.0, 1.0, "", PROCESS_MODE_ALWAYS)
	#await get_tree().create_timer(0.5).timeout
	#pause_tree(true)
	#await get_tree().create_timer(1).timeout
	#pause_tree(false)
	
	# test; set the bus for AudioStreamPlayer while the sound stream is playing
	#AudioManager.sound_channel_count = 1
	#await get_tree().create_timer(2).timeout
	#AudioServer.set_bus_bypass_effects(AudioServer.get_bus_index("SoundMuffle"), true)
	#AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.NON_POSITIONAL, null,
		#0, 1.0, 1.0, "SoundReverb")
	#await get_tree().create_timer(3).timeout
	#AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.NON_POSITIONAL, null,
		#0, 1.0, 1.0)
		
	# test; set the pause mode and bus for AudioStreamPlayer while the music stream is playing
	#AudioServer.set_bus_bypass_effects(AudioServer.get_bus_index("MusicMuffle"), true)
	#AudioManager.play_music(preload("res://assets/music/bgm.ogg"), 0.0, 1, 1, 2, "MusicReverb", PROCESS_MODE_PAUSABLE)
	#await get_tree().create_timer(4).timeout
	#pause_tree(true)
	#await get_tree().create_timer(2).timeout
	#pause_tree(false)


func _process(delta):
	sound_channel_count_label.text = "sound channel count: %s" % AudioManager.sound_channel_count
	
	
func _input(event: InputEvent):
	if event is InputEventKey and !event.is_echo():
		if event.pressed:
			if !event.shift_pressed and event.keycode == KEY_1:
				_sound_stream_player_1 = AudioManager.play_loaded_sound("blip", AudioManager.SoundType.NON_POSITIONAL)

			elif !event.shift_pressed and event.keycode == KEY_2:
				_sound_stream_player_2 = AudioManager.play_loaded_sound("confirmation", AudioManager.SoundType.NON_POSITIONAL)

			elif !event.shift_pressed and event.keycode == KEY_3:
				_sound_stream_player_3 = AudioManager.play_loaded_sound("laser", AudioManager.SoundType.NON_POSITIONAL)
				
			elif event.shift_pressed and event.keycode == KEY_1:
				AudioManager.stop_sound(_sound_stream_player_1)
				
			elif event.shift_pressed and event.keycode == KEY_2:
				AudioManager.stop_sound(_sound_stream_player_2)
				
			elif event.shift_pressed and event.keycode == KEY_3:
				AudioManager.stop_sound(_sound_stream_player_3)
				
			elif event.keycode == KEY_SPACE:
				if not _music_stream_player_1 or (_music_stream_player_1 and not _music_stream_player_1.playing):
					_music_stream_player_1 = AudioManager.play_loaded_music("bgm", 0.0, 1, 1, 2)
					
				elif _music_stream_player_1 and _music_stream_player_1.playing:
					AudioManager.stop_music(_music_stream_player_1, 2)
					
			elif event.keycode == KEY_UP:
				AudioManager.sound_channel_count += 1
				
			elif event.keycode == KEY_DOWN:
				AudioManager.sound_channel_count -= 1
				
			elif event.keycode == KEY_P:
				get_tree().paused = !get_tree().paused
				
			elif event.keycode == KEY_ESCAPE:
				AudioManager.unload_all_sounds()
				AudioManager.unload_all_music()
				
				
func pause_tree(pause: bool) -> void:
	get_tree().paused = pause
