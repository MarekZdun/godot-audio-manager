extends Node


enum AudioType {
	SOUND,
	MUSIC
}

enum SoundType {
	NON_POSITIONAL,
	POSITIONAL_2D,
	POSITIONAL_3D
}

export(String, FILE, "*.tres") var _audio_bus_default_file_path: String = "res::/src/resources/audio_buses/audio_bus_default.tres"
export(String, DIR) var sound_dir: String = "res://assets/sound"
export(String, DIR) var music_dir: String = "res://assets/music"

var sound_channel_count: int = 0 setget set_sound_channel_count
var sound_2d_channel_count: int = 0 setget set_sound_2d_channel_count
var sound_3d_channel_count: int = 0 setget set_sound_3d_channel_count
var music_channel_count: int = 0 setget set_music_channel_count

var sound_priorities: Dictionary
var sound_2d_priorities: Dictionary
var sound_3d_priorities: Dictionary

var _sound_stream_players: Dictionary
var _sound_2d_stream_players: Dictionary
var _sound_3d_stream_players: Dictionary
var _music_stream_players: Dictionary

var _available_sound_stream_players: Array
var _available_sound_2d_stream_players: Array
var _available_sound_3d_stream_players: Array
var _available_music_stream_players: Array

var _sound_filenames: Array
var _music_filenames: Array
var _loaded_sound_streams: Dictionary
var _loaded_music_streams: Dictionary

onready var sound_root: Node = get_node("Sound")
onready var sound_2d_root: Node = get_node("Sound2D")
onready var sound_3d_root: Node = get_node("Sound3D")
onready var music_root: Node = get_node("Music")


func _ready():
	AudioServer.set_bus_layout(load(_audio_bus_default_file_path))
 
	set_sound_channel_count(sound_channel_count)
	set_sound_2d_channel_count(sound_2d_channel_count)
	set_sound_3d_channel_count(sound_3d_channel_count)
	set_music_channel_count(music_channel_count)
	
	_sound_filenames = _get_filenames(sound_dir)
	_music_filenames = _get_filenames(music_dir)
		
		
func set_sound_channel_count(new_count: int) -> void:
	if new_count < 0:
		return
	var sound_stream_players_count = _sound_stream_players.size()
	
	if new_count > sound_stream_players_count:
		for i in new_count - sound_stream_players_count:
			var stream_player = AudioStreamPlayer.new()
			sound_root.add_child(stream_player)
			_sound_stream_players[stream_player.get_instance_id()] = stream_player
			_available_sound_stream_players.append(stream_player)
			
	elif new_count < sound_stream_players_count:
		for i in range(new_count, sound_stream_players_count):
			if not _available_sound_stream_players.empty():
				var stream_player = _available_sound_stream_players.pop_front()
				var stream_player_id = stream_player.get_instance_id()
				_sound_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				if sound_priorities.has(stream_player_id):
					sound_priorities.erase(stream_player_id)
					
			else:
				var stream_player = _check_priority_and_find_oldest(_sound_stream_players ,sound_priorities, 999)
				var stream_player_id = stream_player.get_instance_id()
				_sound_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				if sound_priorities.has(stream_player_id):
					sound_priorities.erase(stream_player_id)
		
	sound_channel_count = new_count
	
	
func set_sound_2d_channel_count(new_count: int) -> void:
	if new_count < 0:
		return
	var sound_2d_stream_players_count = _sound_2d_stream_players.size()
	
	if new_count > sound_2d_stream_players_count:
		for i in new_count - sound_2d_stream_players_count:
			var stream_player = AudioStreamPlayer2D.new()
			sound_2d_root.add_child(stream_player)
			_sound_2d_stream_players[stream_player.get_instance_id()] = stream_player
			_available_sound_2d_stream_players.append(stream_player)
			
	elif new_count < sound_2d_stream_players_count:
		for i in range(new_count, sound_2d_stream_players_count):
			if not _available_sound_2d_stream_players.empty():
				var stream_player = _available_sound_2d_stream_players.pop_front()
				var stream_player_id = stream_player.get_instance_id()
				_sound_2d_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				if sound_2d_priorities.has(stream_player_id):
					sound_2d_priorities.erase(stream_player_id)
					
			else:
				var stream_player = _check_priority_and_find_oldest(_sound_2d_stream_players, sound_2d_priorities, 999)
				var stream_player_id = stream_player.get_instance_id()
				_sound_2d_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				if sound_2d_priorities.has(stream_player_id):
					sound_2d_priorities.erase(stream_player_id)
		
	sound_2d_channel_count = new_count
	
	
func set_sound_3d_channel_count(new_count: int) -> void:
	if new_count < 0:
		return
	var sound_3d_stream_players_count = _sound_3d_stream_players.size()
	
	if new_count > sound_3d_stream_players_count:
		for i in new_count - sound_3d_stream_players_count:
			var stream_player = AudioStreamPlayer3D.new()
			sound_3d_root.add_child(stream_player)
			_sound_3d_stream_players[stream_player.get_instance_id()] = stream_player
			_available_sound_3d_stream_players.append(stream_player)
			
	elif new_count < sound_3d_stream_players_count:
		for i in range(new_count, sound_3d_stream_players_count):
			if not _available_sound_3d_stream_players.empty():
				var stream_player = _available_sound_3d_stream_players.pop_front()
				var stream_player_id = stream_player.get_instance_id()
				_sound_3d_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				if sound_3d_priorities.has(stream_player_id):
					sound_3d_priorities.erase(stream_player_id)
					
			else:
				var stream_player = _check_priority_and_find_oldest(_sound_3d_stream_players, sound_3d_priorities, 999)
				var stream_player_id = stream_player.get_instance_id()
				_sound_3d_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				if sound_3d_priorities.has(stream_player_id):
					sound_3d_priorities.erase(stream_player_id)
		
	sound_3d_channel_count = new_count
	
	
func set_music_channel_count(new_count: int) -> void:
	if new_count < 0:
		return
	var music_stream_players_count = _music_stream_players.size()
	
	if new_count > music_stream_players_count:
		for i in new_count - music_stream_players_count:
			var stream_player = AudioStreamPlayer.new()
			music_root.add_child(stream_player)
			_music_stream_players[stream_player.get_instance_id()] = stream_player
			_available_music_stream_players.append(stream_player)
			
	elif new_count < music_stream_players_count:
		for i in range(new_count, music_stream_players_count):
			if not _available_music_stream_players.empty():
				var stream_player = _available_music_stream_players.pop_front()
				var stream_player_id = stream_player.get_instance_id()
				_music_stream_players.erase(stream_player_id)
				stream_player.queue_free()
					
			else:
				var stream_player = _music_stream_players[_music_stream_players.keys()[0]]
				var stream_player_id = stream_player.get_instance_id()
				_music_stream_players.erase(stream_player_id)
				stream_player.queue_free()
		
	music_channel_count = new_count
		
		
func load_sounds(audio_names: Array) -> void:
	_loaded_sound_streams = _load_from_files(AudioType.SOUND, audio_names)
	
	
func load_music(audio_names: Array) -> void:
	_loaded_music_streams = _load_from_files(AudioType.MUSIC, audio_names)
	
	
func unload_all_sounds() -> void:
	_loaded_sound_streams = {}
	
	
func unload_all_music() -> void:
	_loaded_music_streams = {}
	
	
func unload_sound(audio_name: String) -> void:
	if _loaded_sound_streams.erase(audio_name):
		return
	else:
		push_error("No loaded sound stream found with name: " + audio_name)
	
	
func unload_music(audio_name: String) -> void:
	if _loaded_music_streams.erase(audio_name):
		return
	else:
		push_error("No loaded music stream found with name: " + audio_name)
	
	
func play_loaded_sound(stream_name: String, sound_type: int, parent: Node = null, 
		priority: int = 0, volume_db: float = 0.0, pitch_scale: float = 1.0) -> Node:
	var stream
	if _loaded_sound_streams.has(stream_name):
		stream = _loaded_sound_streams[stream_name]
	if stream == null:
		push_error("No audio stream resource loaded with name: " + stream_name)
	
	var stream_player = play_sound(stream, sound_type, parent, priority, volume_db, pitch_scale)
	return stream_player
	
	
func play_sound(stream: AudioStream, sound_type: int, parent: Node = null, 
		priority: int = 0, volume_db: float = 0.0, pitch_scale: float = 1.0) -> Node:
	var stream_player = null
	match sound_type:
		SoundType.NON_POSITIONAL:
			if not _available_sound_stream_players.empty():
				stream_player = _available_sound_stream_players.pop_front()
				_remove_finished_connection(stream_player)
				stream_player.connect("finished", self, "_on_sound_stream_player_finished", [stream_player])
				stream_player.bus = "Sound"
				stream_player.stream = stream
				stream_player.volume_db = linear2db(volume_db)
				stream_player.pitch_scale = pitch_scale
				sound_priorities[stream_player.get_instance_id()] = priority
				stream_player.play()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_stream_players, sound_priorities, priority)
				_remove_finished_connection(stream_player)
				stream_player.connect("finished", self, "_on_sound_stream_player_finished", [stream_player])
				stream_player.bus = "Sound"
				stream_player.stream = stream
				stream_player.volume_db = linear2db(volume_db)
				stream_player.pitch_scale = pitch_scale
				sound_priorities[stream_player.get_instance_id()] = priority
				stream_player.play()
			
		SoundType.POSITIONAL_2D:
			if not _available_sound_2d_stream_players.empty():
				stream_player = _available_sound_2d_stream_players.pop_front()
				stream_player.get_parent().remove_child(stream_player)
				parent.add_child(stream_player)
				_remove_finished_connection(stream_player)
				stream_player.connect("finished", self, "_on_sound_2d_stream_player_finished", [stream_player])
				stream_player.bus = "Sound2D"
				stream_player.stream = stream
				stream_player.volume_db = linear2db(volume_db)
				stream_player.pitch_scale = pitch_scale
				sound_2d_priorities[stream_player.get_instance_id()] = priority
				stream_player.play()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_2d_stream_players, sound_2d_priorities, priority)
				stream_player.get_parent().remove_child(stream_player)
				parent.add_child(stream_player)
				_remove_finished_connection(stream_player)
				stream_player.connect("finished", self, "_on_sound_2d_stream_player_finished", [stream_player])
				stream_player.bus = "Sound2D"
				stream_player.stream = stream
				stream_player.volume_db = linear2db(volume_db)
				stream_player.pitch_scale = pitch_scale
				sound_2d_priorities[stream_player.get_instance_id()] = priority
				stream_player.play()
			
		SoundType.POSITIONAL_3D:
			if not _available_sound_3d_stream_players.empty():
				stream_player = _available_sound_3d_stream_players.pop_front()
				stream_player.get_parent().remove_child(stream_player)
				parent.add_child(stream_player)
				_remove_finished_connection(stream_player)
				stream_player.connect("finished", self, "_on_sound_3d_stream_player_finished", [stream_player])
				stream_player.bus = "Sound3D"
				stream_player.stream = stream
				stream_player.unit_db = linear2db(volume_db)
				stream_player.pitch_scale = pitch_scale
				sound_3d_priorities[stream_player.get_instance_id()] = priority
				stream_player.play()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_3d_stream_players, sound_3d_priorities, priority)
				stream_player.get_parent().remove_child(stream_player)
				parent.add_child(stream_player)
				_remove_finished_connection(stream_player)
				stream_player.connect("finished", self, "_on_sound_3d_stream_player_finished", [stream_player])
				stream_player.bus = "Sound3D"
				stream_player.stream = stream
				stream_player.unit_db = linear2db(volume_db)
				stream_player.pitch_scale = pitch_scale
				sound_3d_priorities[stream_player.get_instance_id()] = priority
				stream_player.play()
	
	return stream_player
	

func play_loaded_music(stream_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0,
		transition_in_duration: float = 0) -> AudioStreamPlayer:
	var stream
	if _loaded_music_streams.has(stream_name):
		stream = _loaded_music_streams[stream_name]
	if stream == null:
		push_error("No audio stream resource loaded with name: " + stream_name)
	
	var stream_player = play_music(stream, volume_db, pitch_scale, transition_in_duration)
	return stream_player

	
func play_music(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0,
		transition_in_duration: float = 0) -> AudioStreamPlayer:	
	var stream_player = null
	if not _available_music_stream_players.empty():
		stream_player = _available_music_stream_players.pop_front()
		_remove_finished_connection(stream_player)
		stream_player.connect("finished", self, "_on_music_stream_player_finished", [stream_player])
		stream_player.bus = "Music"
		stream_player.stream = stream
		stream_player.pitch_scale = pitch_scale
		
	else:
		stream_player = _music_stream_players.get(_music_stream_players.keys()[0])
		_remove_finished_connection(stream_player)
		stream_player.connect("finished", self, "_on_music_stream_player_finished", [stream_player])
		stream_player.bus = "Music"
		stream_player.stream = stream
		stream_player.pitch_scale = pitch_scale
		
		for i in stream_player.get_children():
			if i is Tween:
				i.free()

	if transition_in_duration > 0:
		stream_player.volume_db = linear2db(0)
		var tween = create_music_transition_in(stream_player, volume_db, transition_in_duration)
	else:
		stream_player.volume_db = linear2db(volume_db)
		
	stream_player.call_deferred("play")
	return stream_player
	
	
func stop_sound(stream_player: Node) -> void:
	stream_player.stop()
	
	if stream_player is AudioStreamPlayer:
		_on_sound_stream_player_finished(stream_player)
		
	elif stream_player is AudioStreamPlayer2D:
		_on_sound_2d_stream_player_finished(stream_player)
		
	elif stream_player is AudioStreamPlayer3D:
		_on_sound_3d_stream_player_finished(stream_player)
	

func stop_music(stream_player: Node, transition_out_duration: float = 0) -> void:
	for i in stream_player.get_children():
		if i is Tween:
			i.queue_free()

	if transition_out_duration > 0:
		var tween = create_music_transition_out(stream_player, transition_out_duration)
		yield(tween, "tween_completed")

	stream_player.stop()
	_on_music_stream_player_finished(stream_player)
	
	
func create_music_transition_in(stream_player: Node, volume_db: float, duration: float) -> Tween:
	var tween = Tween.new()
	stream_player.add_child(tween)
	tween.connect("tween_completed", self, "_on_music_tween_ended")
	tween.interpolate_property(stream_player, "volume_db", -50, linear2db(volume_db), duration)
	tween.start()
	return tween
	
	
func create_music_transition_out(stream_player: Node, duration: float) -> Tween:
	var tween = Tween.new()
	stream_player.add_child(tween)
	tween.connect("tween_completed", self, "_on_music_tween_ended")
	tween.interpolate_property(stream_player, "volume_db", null, -50, duration)
	tween.start()
	return tween

			
func _remove_finished_connection(stream_player) -> void:
	if not stream_player.get_signal_connection_list("finished").empty():
		var signal_data = stream_player.get_signal_connection_list("finished").front()
		var signal_name = signal_data.signal
		var target = signal_data.target
		var method = signal_data.method
		stream_player.disconnect(signal_name, target, method)
	
	
func _get_filenames(path) -> Array:
	var files = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var filename = dir.get_next()
		while not filename.empty():
			if dir.current_is_dir():
				push_error("No directories in audio folder.")
			elif filename.ends_with(".wav") or filename.ends_with(".ogg"):
				files.append(filename)
			filename = dir.get_next()
	else:
		push_error("An error occurred when trying to access '" + path + "'.")
		
	return files
	
	
func _load_from_files(audio_type: int, audio_names: Array) -> Dictionary:
	var loaded = {}
	for audio_name in audio_names:
		var file_name = _get_filename(audio_type, audio_name)
		var dir = sound_dir if audio_type == AudioType.SOUND else music_dir
		loaded[audio_name] = load(dir + "/" + file_name)
	return loaded
	
	
func _get_filename(audio_type: int, audio_name: String) -> String:
	var file_name = ""
	var files = []
	
	match audio_type:
		AudioType.SOUND:
			files = _sound_filenames
		AudioType.MUSIC:
			files = _music_filenames
			
	if files.size() == 0:
		push_error("No files in folder " + sound_dir if audio_type == AudioType.SOUND else music_dir)
	for fn in files:
		if fn.begins_with(audio_name):
			file_name = fn
			break
	
	return file_name


func _check_priority_and_find_oldest(stream_players: Dictionary, priorities: Dictionary, priority: int) -> Node:
	var lowest_priority_id_list = []
	for id in priorities:
		if priority >= priorities[id]:
			lowest_priority_id_list.append(id)
			
	if lowest_priority_id_list.empty():
		return null
	var oldest_stream_player = stream_players[lowest_priority_id_list.front()]
	for id in range(1, lowest_priority_id_list.size()):
		var stream_player = stream_players[lowest_priority_id_list[id]]
		if oldest_stream_player.get_playback_position() < stream_player.get_playback_position():
			oldest_stream_player == stream_players[lowest_priority_id_list[id]]
			
	return oldest_stream_player
			
			
func _on_sound_stream_player_finished(stream_player):
	_remove_finished_connection(stream_player)
	sound_priorities.erase(stream_player.get_instance_id())
	_available_sound_stream_players.append(stream_player)
	
	
func _on_sound_2d_stream_player_finished(stream_player):
	stream_player.get_parent().remove_child(stream_player)
	sound_2d_root.add_child(stream_player)
	_remove_finished_connection(stream_player)
	sound_2d_priorities.erase(stream_player.get_instance_id())
	_available_sound_2d_stream_players.append(stream_player)
	
	
func _on_sound_3d_stream_player_finished(stream_player):
	stream_player.get_parent().remove_child(stream_player)
	sound_3d_root.add_child(stream_player)
	_remove_finished_connection(stream_player)
	sound_3d_priorities.erase(stream_player.get_instance_id())
	_available_sound_3d_stream_players.append(stream_player)
	
	
func _on_music_stream_player_finished(stream_player):
	_remove_finished_connection(stream_player)
	_available_music_stream_players.append(stream_player)
	
	
func _on_music_tween_ended(object: Object, key: NodePath):
	for i in object.get_children():
		if i is Tween:
			i.queue_free()
