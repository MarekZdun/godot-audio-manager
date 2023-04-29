extends Node

var _sound_stream_player_1: AudioStreamPlayer3D
var _sound_stream_player_2: AudioStreamPlayer3D
var _sound_stream_player_3: AudioStreamPlayer3D
var _music_stream_player_1: AudioStreamPlayer
var _music_stream_player_2: AudioStreamPlayer

@onready var actor_1 = $Actor1
@onready var actor_2 = $Actor2
@onready var actor_3 = $Actor3
@onready var sound_3d_channel_count_label = $Sound3dChannelCountLabel


func _ready():
	AudioManager.music_channel_count = 1
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear_to_db(0.25))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(0.25))
#	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound"), true)

	# Music test 1
#	AudioManager.music_channel_count = 1
#	_music_stream_player_1 = AudioManager.play_music(preload("res://assets/music/rain.ogg"), 1, 1, 2)
#	await get_tree().create_timer(5).timeout
#	_music_stream_player_1 = AudioManager.play_music(preload("res://assets/music/bgm.ogg"), 1, 1, 2)
#	await get_tree().create_timer(5).timeout
	
	# Music test 2
#	AudioManager.music_channel_count = 1
#	_music_stream_player_1 = AudioManager.play_music(preload("res://assets/music/rain.ogg"), 1, 1, 2)
#	await get_tree().create_timer(1).timeout
#	_music_stream_player_1 = AudioManager.play_music(preload("res://assets/music/bgm.ogg"), 1, 1, 2)
#	await get_tree().create_timer(5).timeout
#	AudioManager.music_channel_count = 0

	# Music test 3
#	AudioManager.music_channel_count = 2
#	_music_stream_player_1 = AudioManager.play_music(preload("res://assets/music/rain.ogg"), 1, 1, 2)
#	await get_tree().create_timer(5).timeout
#	AudioManager.stop_music(_music_stream_player_1, 2)
#	_music_stream_player_2 = AudioManager.play_music(preload("res://assets/music/bgm.ogg"), 1, 1, 2)
#	await get_tree().create_timer(5).timeout
#	AudioManager.music_channel_count = 0

	# Sound3d test 1
#	AudioManager.sound_3d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(5).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(5).timeout

	# Sound3d test 2
#	AudioManager.sound_3d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(5).timeout

	# Sound3d test 3
#	AudioManager.sound_3d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_3)
#	await get_tree().create_timer(5).timeout

	# Sound3d test 4
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(5).timeout
	
	# Sound3d test 5
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_3)
#	await get_tree().create_timer(5).timeout
	
	# Sound3d test 6
#	AudioManager.sound_3d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.stop_sound(_sound_stream_player_1)
#	await get_tree().create_timer(5).timeout

	# Sound3d test 7
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.stop_sound(_sound_stream_player_1)
#	AudioManager.stop_sound(_sound_stream_player_2)
#	await get_tree().create_timer(5).timeout
	
	# Sound3d test 8
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.stop_sound(_sound_stream_player_1)
#	AudioManager.stop_sound(_sound_stream_player_2)
#	await get_tree().create_timer(5).timeout
	
	# Sound3d test 9
#	AudioManager.sound_3d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_3d_channel_count = 0
#	await get_tree().create_timer(5).timeout

	# Sound3d test 10
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_3d_channel_count = 1
#	await get_tree().create_timer(5).timeout
	
	# Sound3d test 11
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_3d_channel_count = 0
#	await get_tree().create_timer(5).timeout

	# Sound3d test 12
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_3d_channel_count = 1
#	await get_tree().create_timer(5).timeout
	
	# Sound3d test 13
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_3d_channel_count = 0
#	await get_tree().create_timer(5).timeout

	# Sound3d test 14
#	AudioManager.sound_3d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	actor_1.queue_free()
#	await get_tree().create_timer(5).timeout

	# Sound3d test 15
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	actor_1.queue_free()
#	await get_tree().create_timer(5).timeout

	# Sound3d test 16
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	actor_1.queue_free()
#	await get_tree().create_timer(5).timeout
	
	# Sound3d test 17
#	AudioManager.sound_3d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	actor_1.queue_free()
#	actor_3.queue_free()
#	await get_tree().create_timer(5).timeout


func _process(delta):
	sound_3d_channel_count_label.text = "sound 3d channel count: %s" % AudioManager.sound_3d_channel_count
	
	
func _input(event):
	if event is InputEventKey and !event.is_echo():
		if event.pressed:
			if !event.shift_pressed and event.keycode == KEY_1:
				_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/blip.wav"), AudioManager.SoundType.POSITIONAL_3D, actor_1)
#				_sound_stream_player_1.attenuation_filter_db = 0
#				_sound_stream_player_1.unit_size = 10

			elif !event.shift_pressed and event.keycode == KEY_2:
				_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/confirmation.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_2)
#				_sound_stream_player_2.attenuation_filter_db = 0
#				_sound_stream_player_2.unit_size = 10

			elif !event.shift_pressed and event.keycode == KEY_3:
				_sound_stream_player_3 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, actor_3)
#				_sound_stream_player_3.attenuation_filter_db = 0
#				_sound_stream_player_3.unit_size = 10
				
			elif event.shift_pressed and event.keycode == KEY_1:
				AudioManager.stop_sound(_sound_stream_player_1)
				
			elif event.shift_pressed and event.keycode == KEY_2:
				AudioManager.stop_sound(_sound_stream_player_2)
				
			elif event.shift_pressed and event.keycode == KEY_3:
				AudioManager.stop_sound(_sound_stream_player_3)
				
			elif event.keycode == KEY_SPACE:
				if not _music_stream_player_1 or (_music_stream_player_1 and not _music_stream_player_1.playing):
					_music_stream_player_1 = AudioManager.play_music(preload("res://assets/music/bgm.ogg"), 1, 1, 2)
					
				elif _music_stream_player_1 and _music_stream_player_1.playing:
					AudioManager.stop_music(_music_stream_player_1, 2)
					
			elif event.keycode == KEY_UP:
				AudioManager.sound_3d_channel_count += 1
				
			elif event.keycode == KEY_DOWN:
				AudioManager.sound_3d_channel_count -= 1
				
			elif event.keycode == KEY_ESCAPE:
#				AudioManager.sound_3d_channel_count = 0
				actor_1.queue_free()
				actor_2.queue_free()
				actor_3.queue_free()
