extends Node

var _sound_stream_player_1: AudioStreamPlayer2D
var _sound_stream_player_2: AudioStreamPlayer2D
var _sound_stream_player_3: AudioStreamPlayer2D
var _music_stream_player_1: AudioStreamPlayer

@onready var actor_1 = $Actor1
@onready var actor_2 = $Actor2
@onready var actor_3 = $Actor3
@onready var sound_2d_channel_count_label = $Sound2dChannelCountLabel


func _ready():
	AudioManager.music_channel_count = 1
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear_to_db(0.5))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(0.5))
#	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound"), true)

	# Sound2d test 1
#	AudioManager.sound_2d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(5).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(5).timeout

	# Sound2d test 2
#	AudioManager.sound_2d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(5).timeout

	# Sound2d test 3
#	AudioManager.sound_2d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_3)
#	await get_tree().create_timer(5).timeout

	# Sound2d test 4
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(5).timeout
	
	# Sound2d test 5
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_3)
#	await get_tree().create_timer(5).timeout
	
	# Sound2d test 6
#	AudioManager.sound_2d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.stop_sound(_sound_stream_player_1)
#	await get_tree().create_timer(5).timeout

	# Sound2d test 7
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.stop_sound(_sound_stream_player_1)
#	AudioManager.stop_sound(_sound_stream_player_2)
#	await get_tree().create_timer(5).timeout
	
	# Sound2d test 8
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.stop_sound(_sound_stream_player_1)
#	AudioManager.stop_sound(_sound_stream_player_2)
#	await get_tree().create_timer(5).timeout
	
	# Sound2d test 9
#	AudioManager.sound_2d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_2d_channel_count = 0
#	await get_tree().create_timer(5).timeout

	# Sound2d test 10
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_2d_channel_count = 1
#	await get_tree().create_timer(5).timeout
	
	# Sound2d test 11
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_2d_channel_count = 0
#	await get_tree().create_timer(5).timeout

	# Sound2d test 12
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_2d_channel_count = 1
#	await get_tree().create_timer(5).timeout
	
	# Sound2d test 13
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	AudioManager.sound_2d_channel_count = 0
#	await get_tree().create_timer(5).timeout

	# Sound2d test 14
#	AudioManager.sound_2d_channel_count = 1
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	actor_1.queue_free()
#	await get_tree().create_timer(5).timeout

	# Sound2d test 15
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	actor_1.queue_free()
#	await get_tree().create_timer(5).timeout

	# Sound2d test 16
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	actor_1.queue_free()
#	await get_tree().create_timer(5).timeout
	
	# Sound2d test 17
#	AudioManager.sound_2d_channel_count = 2
#	_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_1)
#	await get_tree().create_timer(0.25).timeout
#	_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_3)
#	await get_tree().create_timer(0.25).timeout
#	actor_1.queue_free()
#	actor_3.queue_free()
#	await get_tree().create_timer(5).timeout
	

func _process(delta):
	sound_2d_channel_count_label.text = "sound 2d channel count: %s" % AudioManager.sound_2d_channel_count
	
	
func _input(event):
	if event is InputEventKey and !event.is_echo():
		if event.pressed:
			if !event.shift_pressed and event.keycode == KEY_1:
				_sound_stream_player_1 = AudioManager.play_sound(preload("res://assets/sound/blip.wav"), AudioManager.SoundType.POSITIONAL_2D, actor_1)

			elif !event.shift_pressed and event.keycode == KEY_2:
				_sound_stream_player_2 = AudioManager.play_sound(preload("res://assets/sound/confirmation.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_2)

			elif !event.shift_pressed and event.keycode == KEY_3:
				_sound_stream_player_3 = AudioManager.play_sound(preload("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_2D, actor_3)
				
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
				AudioManager.sound_2d_channel_count += 1
				
			elif event.keycode == KEY_DOWN:
				AudioManager.sound_2d_channel_count -= 1
				
			elif event.keycode == KEY_ESCAPE:
				actor_1.queue_free()
				actor_2.queue_free()
				actor_3.queue_free()

