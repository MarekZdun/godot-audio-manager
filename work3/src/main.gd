extends Node


var stream_player = null
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

	AudioManager.sound_3d_channel_count = 4
	AudioManager.music_channel_count = 2
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound3D"), linear2db(1))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(0.05))
	
	var scene_3d = load("res://work3/src/scene_3d.tscn").instance()
	add_child(scene_3d)
	
	object_1 = scene_3d.get_node("Object1")
	object_2 = scene_3d.get_node("Object2")
	object_3 = scene_3d.get_node("Object3")
	
	var music_player = AudioManager.play_loaded_music("bgm", 1, 1, 3)
	yield(get_tree().create_timer(10), "timeout")
	AudioManager.stop_music(music_player, 3)
	music_player = AudioManager.play_loaded_music("rain", 1, 1, 3)

#	var music_player = AudioManager.play_loaded_music("bgm", 1, 1, 3)
#	yield(get_tree().create_timer(1), "timeout")
#	music_player = AudioManager.play_loaded_music("rain", 1, 1, 3)
#	yield(get_tree().create_timer(1), "timeout")
#	music_player = AudioManager.play_loaded_music("bgm", 1, 1, 3)
	
	
func _input(event):
    if event is InputEventKey:
        if event.pressed and event.scancode == KEY_1:
#            AudioManager.play_sound(load("res://assets/sound/blip.wav"), AudioManager.SoundType.POSITIONAL_3D, object_1, 0, 2, 1)
            stream_player = AudioManager.play_loaded_sound("blip", AudioManager.SoundType.POSITIONAL_3D, object_1, 0, 1, 1)
#            stream_player.unit_size = 1

        elif event.pressed and event.scancode == KEY_2:
#            AudioManager.play_sound(load("res://assets/sound/confirmation.ogg"), AudioManager.SoundType.POSITIONAL_3D, object_2, 0, 2, 1)
            stream_player = AudioManager.play_loaded_sound("confirmation", AudioManager.SoundType.POSITIONAL_3D, object_2, 0, 1, 1)

        elif event.pressed and event.scancode == KEY_3:
#            AudioManager.play_sound(load("res://assets/sound/laser.ogg"), AudioManager.SoundType.POSITIONAL_3D, object_3, 0, 2, 1)
            stream_player = AudioManager.play_loaded_sound("laser", AudioManager.SoundType.POSITIONAL_3D, object_3, 0, 1, 1)

        elif event.pressed and event.scancode == KEY_SPACE:
            if stream_player and stream_player.playing:
                AudioManager.stop_sound(stream_player)
