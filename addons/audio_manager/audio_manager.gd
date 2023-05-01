@tool
extends Node

## Audio Manager allows you to set a pool of audio stream players associated with playing non-positioned sounds,
## 2D sounds, 3D sounds and music sounds, and then use these audio stream players when there is a need to play a specific sound.
## In this way, the user obtains the possibility of reusing audio stream players.

enum AudioType {
	SOUND,
	MUSIC
}

enum SoundType {
	NON_POSITIONAL,
	POSITIONAL_2D,
	POSITIONAL_3D
}

const MUSIC_BUS_NAME: String = "Music"
const SOUND_BUS_NAME: String = "Sound"
const MUSIC_CHANNEL_COUNT_MAX: int = 64
const SOUND_CHANNEL_COUNT_MAX: int = 64
const SOUND_2D_CHANNEL_COUNT_MAX: int = 64
const SOUND_3D_CHANNEL_COUNT_MAX: int = 64

@export_file("*.tres") var audio_bus_default_file_path: String:
	set(value):
		audio_bus_default_file_path = value
		_update_audio_bus_from_file_path()
		update_configuration_warnings()
		
@export_dir var music_dir_path: String = "":
	set(value):
		music_dir_path = value
		_update_music_filenames(music_dir_path)
	
@export_dir var sound_dir_path: String = "":
	set(value):
		sound_dir_path = value
		_update_sound_filenames(sound_dir_path)

@export_range(0, MUSIC_CHANNEL_COUNT_MAX) var music_channel_count: int = 0:
	set(value):
		music_channel_count = clamp(value, 0, MUSIC_CHANNEL_COUNT_MAX)
		_update_music_channels(music_channel_count)

@export_range(0, SOUND_CHANNEL_COUNT_MAX) var sound_channel_count: int = 0:
	set(value):
		sound_channel_count = clamp(value, 0, SOUND_CHANNEL_COUNT_MAX)
		_update_sound_channels(sound_channel_count)
		
@export_range(0, SOUND_2D_CHANNEL_COUNT_MAX) var sound_2d_channel_count: int = 0:
	set(value):
		sound_2d_channel_count = clamp(value, 0, SOUND_2D_CHANNEL_COUNT_MAX)
		_update_sound_2d_channels(sound_2d_channel_count)
	
@export_range(0, SOUND_3D_CHANNEL_COUNT_MAX) var sound_3d_channel_count: int = 0:
	set(value):
		sound_3d_channel_count = clamp(value, 0, SOUND_3D_CHANNEL_COUNT_MAX)
		_update_sound_3d_channels(sound_3d_channel_count)

var _sound_stream_players: Dictionary
var _sound_2d_stream_players: Dictionary
var _sound_3d_stream_players: Dictionary
var _music_stream_players: Dictionary

var _available_sound_stream_players: Array
var _available_sound_2d_stream_players: Array
var _available_sound_3d_stream_players: Array
var _available_music_stream_players: Array

var _sound_stream_players_priorities: Dictionary
var _sound_2d_stream_players_priorities: Dictionary
var _sound_3d_stream_players_priorities: Dictionary

var _sound_filenames: Array
var _music_filenames: Array
var _loaded_sound_streams: Dictionary
var _loaded_music_streams: Dictionary

var _stream_players_tween_volume_transition: Dictionary
var _playing_nodes_id_access_sound_2d_stream_players: Dictionary
var _playing_nodes_id_access_sound_3d_stream_players: Dictionary
var _audio_bus_layout: AudioBusLayout

@onready var sound_root: Node = get_node("Sound")
@onready var sound_2d_root: Node = get_node("Sound2D")
@onready var sound_3d_root: Node = get_node("Sound3D")
@onready var music_root: Node = get_node("Music")


func _ready():
	if _audio_bus_layout:
		AudioServer.set_bus_layout(_audio_bus_layout)
		
		
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
		priority: int = 0, volume_db: float = 1.0, pitch_scale: float = 1.0) -> Node:
	var stream: AudioStream
	if _loaded_sound_streams.has(stream_name):
		stream = _loaded_sound_streams[stream_name]
	if stream == null:
		push_error("No audio stream resource loaded with name: " + stream_name)
	
	return play_sound(stream, sound_type, parent, priority, volume_db, pitch_scale)
	
	
func play_sound(stream: AudioStream, sound_type: int, parent: Node = null, 
		priority: int = 0, volume_db: float = 1.0, pitch_scale: float = 1.0) -> Node:
	if stream == null:
		return
			
	var stream_player: Node
	match sound_type:
		SoundType.NON_POSITIONAL:
			if not _available_sound_stream_players.is_empty():
				stream_player = _available_sound_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_stream_players, _sound_stream_players_priorities, priority)
			
			if stream_player:	
				_sound_stream_players_priorities[stream_player.get_instance_id()] = priority
			
		SoundType.POSITIONAL_2D:
			if not _available_sound_2d_stream_players.is_empty():
				stream_player = _available_sound_2d_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_2d_stream_players, _sound_2d_stream_players_priorities, priority)
			
			if stream_player:	
				_remove_connection_tree_exiting(stream_player)
				var parent_id : int
				if is_instance_valid(parent):
					parent_id = parent.get_instance_id()
					stream_player.get_parent().remove_child(stream_player)
					parent.add_child(stream_player)
					
					if not _playing_nodes_id_access_sound_2d_stream_players.has(parent_id):
						_playing_nodes_id_access_sound_2d_stream_players[parent_id] = []
					_playing_nodes_id_access_sound_2d_stream_players[parent_id].append(stream_player)
					
					if not parent.tree_exiting.is_connected(_on_playing_node_with_sound_2d_stream_players_exiting_tree):
						parent.tree_exiting.connect(_on_playing_node_with_sound_2d_stream_players_exiting_tree.bind(parent), CONNECT_ONE_SHOT)

				_sound_2d_stream_players_priorities[stream_player.get_instance_id()] = priority
			
		SoundType.POSITIONAL_3D:
			if not _available_sound_3d_stream_players.is_empty():
				stream_player = _available_sound_3d_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_3d_stream_players, _sound_3d_stream_players_priorities, priority)
			
			if stream_player:
				_remove_connection_tree_exiting(stream_player)
				var parent_id : int
				if is_instance_valid(parent):
					parent_id = parent.get_instance_id()
					stream_player.get_parent().remove_child(stream_player)
					parent.add_child(stream_player)
					
					if not _playing_nodes_id_access_sound_3d_stream_players.has(parent_id):
						_playing_nodes_id_access_sound_3d_stream_players[parent_id] = []
					_playing_nodes_id_access_sound_3d_stream_players[parent_id].append(stream_player)
					
					if not parent.tree_exiting.is_connected(_on_playing_node_with_sound_3d_stream_players_exiting_tree):
						parent.tree_exiting.connect(_on_playing_node_with_sound_3d_stream_players_exiting_tree.bind(parent), CONNECT_ONE_SHOT)

				_sound_3d_stream_players_priorities[stream_player.get_instance_id()] = priority
	
	if stream_player:	
		stream_player.stream = stream
		stream_player.volume_db = linear_to_db(volume_db)
		stream_player.pitch_scale = pitch_scale
		stream_player.play()
	
	return stream_player
	

func play_loaded_music(stream_name: String, volume_db: float = 1.0, pitch_scale: float = 1.0,
		volume_transition_in_duration: float = 0) -> AudioStreamPlayer:
	var stream: AudioStream
	if _loaded_music_streams.has(stream_name):
		stream = _loaded_music_streams[stream_name]
	if stream == null:
		push_error("No audio stream resource loaded with name: " + stream_name)
	
	return play_music(stream, volume_db, pitch_scale, volume_transition_in_duration)

	
func play_music(stream: AudioStream, volume_db: float = 1.0, pitch_scale: float = 1.0,
		volume_transition_in_duration: float = 0) -> AudioStreamPlayer:
	if stream == null:
		return
			
	var stream_player: Node
	if not _available_music_stream_players.is_empty():
		stream_player = _available_music_stream_players.pop_front()
	else:
		stream_player = _find_oldest(_music_stream_players)
				
	if stream_player:
		stream_player.stream = stream
		stream_player.pitch_scale = pitch_scale
		
		_remove_tween_volume_transition(stream_player)
		if volume_transition_in_duration > 0:
			stream_player.volume_db = linear_to_db(-50)
			create_volume_transition_in(stream_player, volume_db, volume_transition_in_duration)
		else:
			stream_player.volume_db = linear_to_db(volume_db)
			
		stream_player.call_deferred("play")
		
	return stream_player
	
	
func stop_sound(stream_player: Node) -> void:
	if stream_player:
		if stream_player is AudioStreamPlayer:
			_stop_sound_stream_player(stream_player)
			
		elif stream_player is AudioStreamPlayer2D:
			_stop_sound_2d_stream_player(stream_player)
			
		elif stream_player is AudioStreamPlayer3D:
			_stop_sound_3d_stream_player(stream_player)
	

func stop_music(stream_player: Node, volume_transition_out_duration: float = 0) -> void:
	_remove_tween_volume_transition(stream_player)
	if volume_transition_out_duration > 0:
		var tween = create_volume_transition_out(stream_player, volume_transition_out_duration)
		await tween.finished

	_stop_music_stream_player(stream_player)
	
	
func create_volume_transition_in(stream_player: Node, volume_db: float, duration: float) -> Tween:
	var tween := stream_player.create_tween()
	tween.tween_property(stream_player, "volume_db", linear_to_db(volume_db), duration).from(-50.0)
	tween.finished.connect(_remove_tween_volume_transition.bind(stream_player))
	_stream_players_tween_volume_transition[stream_player.get_instance_id()] = tween
	
	return tween
	
	
func create_volume_transition_out(stream_player: Node, duration: float) -> Tween:
	var tween := stream_player.create_tween()
	tween.tween_property(stream_player, "volume_db", -50.0, duration)
	tween.finished.connect(_remove_tween_volume_transition.bind(stream_player))
	_stream_players_tween_volume_transition[stream_player.get_instance_id()] = tween
	
	return tween
	
	
func _stop_sound_stream_player(stream_player: AudioStreamPlayer) -> void:
	stream_player.stop()
	_on_sound_stream_player_finished(stream_player)
	
	
func _stop_sound_2d_stream_player(stream_player: AudioStreamPlayer2D) -> void:
	stream_player.stop()
	_on_sound_2d_stream_player_finished(stream_player)
	
	
func _stop_sound_3d_stream_player(stream_player: AudioStreamPlayer3D) -> void:
	stream_player.stop()
	_on_sound_3d_stream_player_finished(stream_player)
	
	
func _stop_music_stream_player(stream_player: AudioStreamPlayer) -> void:
	stream_player.stop()
	_on_music_stream_player_finished(stream_player)
	
	
func _update_audio_bus_from_file_path() -> void:
	if ResourceLoader.exists(audio_bus_default_file_path):
		_audio_bus_layout = ResourceLoader.load(audio_bus_default_file_path, "", 0) as AudioBusLayout
	else:
		_audio_bus_layout = null
		
		
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not _check_audio_bus_layout_existence():
		warnings.append("Give proper file path to AudioBusLayout resource file")
	else:
		if not _check_audio_bus_layout_validity():
			warnings.append("Audio bus layout must contain one bus named %s and one bus named %s" % [MUSIC_BUS_NAME, SOUND_BUS_NAME])
	return warnings
	
	
func _check_audio_bus_layout_existence() -> bool:
	var exist: bool = not audio_bus_default_file_path.is_empty()
	if exist:
		_update_audio_bus_from_file_path()
		exist = _audio_bus_layout != null
	return exist
	
	
func _check_audio_bus_layout_validity() -> bool:	
	var is_valid: bool
	var buses: PackedStringArray = []
	var i: int = 0
	while _audio_bus_layout.get("bus/%s/name" % i) != null:
		buses.append(_audio_bus_layout.get("bus/%s/name" % i))
		i += 1
		
	is_valid = buses.has(MUSIC_BUS_NAME) and buses.has(SOUND_BUS_NAME)
	return is_valid
	
	
func _update_music_channels(count: int) -> void:
	if count < 0:
		return
		
	var music_stream_players_count := _music_stream_players.size()
	if count > music_stream_players_count:
		for i in count - music_stream_players_count:
			var stream_player := AudioStreamPlayer.new()
			stream_player.bus = MUSIC_BUS_NAME
			stream_player.finished.connect(_on_music_stream_player_finished.bind(stream_player))
			music_root.add_child(stream_player)
			_music_stream_players[stream_player.get_instance_id()] = stream_player
			_available_music_stream_players.append(stream_player)
			
	elif count < music_stream_players_count:
		for i in range(count, music_stream_players_count):
			var stream_player: AudioStreamPlayer
			if not _available_music_stream_players.is_empty():
				stream_player = _available_music_stream_players.pop_front()
			else:
				stream_player = _find_oldest(_music_stream_players)
				
			if stream_player:
				var stream_player_id := stream_player.get_instance_id()
				_remove_tween_volume_transition(stream_player)
				_music_stream_players.erase(stream_player_id)
				stream_player.queue_free()
	
	
func _update_sound_channels(count: int) -> void:
	if count < 0:
		return
		
	var sound_stream_players_count := _sound_stream_players.size()
	if count > sound_stream_players_count:
		for i in count - sound_stream_players_count:
			var stream_player := AudioStreamPlayer.new()
			stream_player.bus = SOUND_BUS_NAME
			stream_player.finished.connect(_on_sound_stream_player_finished.bind(stream_player))
			sound_root.add_child(stream_player)
			_sound_stream_players[stream_player.get_instance_id()] = stream_player
			_available_sound_stream_players.append(stream_player)
			
	elif count < sound_stream_players_count:
		for i in range(count, sound_stream_players_count):
			var stream_player: AudioStreamPlayer
			if not _available_sound_stream_players.is_empty():
				stream_player = _available_sound_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_stream_players ,_sound_stream_players_priorities, 9999)
				
			if stream_player:
				var stream_player_id := stream_player.get_instance_id()
				_sound_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				
				if _sound_stream_players_priorities.has(stream_player_id):
					_sound_stream_players_priorities.erase(stream_player_id)
					
					
func _update_sound_2d_channels(count: int) -> void:
	if count < 0:
		return
		
	var sound_2d_stream_players_count := _sound_2d_stream_players.size()
	if count > sound_2d_stream_players_count:
		for i in count - sound_2d_stream_players_count:
			var stream_player := AudioStreamPlayer2D.new()
			stream_player.bus = SOUND_BUS_NAME
			stream_player.finished.connect(_on_sound_2d_stream_player_finished.bind(stream_player))
			sound_2d_root.add_child(stream_player)
			_sound_2d_stream_players[stream_player.get_instance_id()] = stream_player
			_available_sound_2d_stream_players.append(stream_player)
			
	elif count < sound_2d_stream_players_count:
		for i in range(count, sound_2d_stream_players_count):
			var stream_player: AudioStreamPlayer2D
			if not _available_sound_2d_stream_players.is_empty():
				stream_player = _available_sound_2d_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_2d_stream_players, _sound_2d_stream_players_priorities, 9999)
				
			if stream_player:
				var stream_player_id := stream_player.get_instance_id()
				_remove_connection_tree_exiting(stream_player)
				_sound_2d_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				
				if _sound_2d_stream_players_priorities.has(stream_player_id):
					_sound_2d_stream_players_priorities.erase(stream_player_id)
					
					
func _update_sound_3d_channels(count: int) -> void:
	if count < 0:
		return
		
	var sound_3d_stream_players_count := _sound_3d_stream_players.size()
	if count > sound_3d_stream_players_count:
		for i in count - sound_3d_stream_players_count:
			var stream_player := AudioStreamPlayer3D.new()
			stream_player.bus = SOUND_BUS_NAME
			stream_player.finished.connect(_on_sound_3d_stream_player_finished.bind(stream_player))
			sound_3d_root.add_child(stream_player)
			_sound_3d_stream_players[stream_player.get_instance_id()] = stream_player
			_available_sound_3d_stream_players.append(stream_player)
			
	elif count < sound_3d_stream_players_count:
		for i in range(count, sound_3d_stream_players_count):
			var stream_player: AudioStreamPlayer3D
			if not _available_sound_3d_stream_players.is_empty():
				stream_player = _available_sound_3d_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(_sound_3d_stream_players, _sound_3d_stream_players_priorities, 9999)
				
			if stream_player:
				var stream_player_id := stream_player.get_instance_id()
				_remove_connection_tree_exiting(stream_player)
				_sound_3d_stream_players.erase(stream_player_id)
				stream_player.queue_free()
				
				if _sound_3d_stream_players_priorities.has(stream_player_id):
					_sound_3d_stream_players_priorities.erase(stream_player_id)
					
					
func _update_music_filenames(p_music_dir_path: String) -> void:
	_music_filenames = _get_filenames(p_music_dir_path)
	
	
func _update_sound_filenames(p_sound_dir_path: String) -> void:
	_sound_filenames = _get_filenames(p_sound_dir_path)
	
	
func _remove_connection_tree_exiting(stream_player: Node) -> bool:
	var removed_connection := false
	var parent := stream_player.get_parent()
	var parent_id := parent.get_instance_id()
	if is_instance_valid(stream_player) and is_instance_valid(parent):
		if stream_player is AudioStreamPlayer2D:
			if _playing_nodes_id_access_sound_2d_stream_players.has(parent_id):
				var stream_player_arr := _playing_nodes_id_access_sound_2d_stream_players[parent_id] as Array
				stream_player_arr.erase(stream_player)
				if stream_player_arr.is_empty():
					_playing_nodes_id_access_sound_2d_stream_players.erase(parent_id)
					if parent.tree_exiting.is_connected(_on_playing_node_with_sound_2d_stream_players_exiting_tree) and not parent.is_queued_for_deletion():
						parent.tree_exiting.disconnect(_on_playing_node_with_sound_2d_stream_players_exiting_tree)
						removed_connection = true
			
		elif stream_player is AudioStreamPlayer3D:
			if _playing_nodes_id_access_sound_3d_stream_players.has(parent_id):
				var stream_player_arr := _playing_nodes_id_access_sound_3d_stream_players[parent_id] as Array
				stream_player_arr.erase(stream_player)
				if stream_player_arr.is_empty():
					_playing_nodes_id_access_sound_3d_stream_players.erase(parent_id)
					if parent.tree_exiting.is_connected(_on_playing_node_with_sound_3d_stream_players_exiting_tree) and not parent.is_queued_for_deletion():
						parent.tree_exiting.disconnect(_on_playing_node_with_sound_3d_stream_players_exiting_tree)
						removed_connection = true
	
	return removed_connection
	
	
func _remove_tween_volume_transition(stream_player: Node) -> void:
	if stream_player:
		var stream_player_id := stream_player.get_instance_id()
		if _stream_players_tween_volume_transition.has(stream_player_id):
			var tween := _stream_players_tween_volume_transition[stream_player_id] as Tween
			if tween and tween.is_valid():
				tween.kill()
			_stream_players_tween_volume_transition.erase(stream_player_id)
	
	
func _get_filenames(dir_path: String) -> Array:
	var files := []
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir():
				push_error("Found directory in audio folder")
			elif file_name.ends_with(".import"):
				files.append(file_name.replace(".import",""))
			file_name = dir.get_next()
	else:
		push_error("An error occurred when trying to access '" + dir_path + "'.")
	
	return files
	
	
func _load_from_files(audio_type: int, audio_names: Array) -> Dictionary:
	var loaded := {}
	for audio_name in audio_names:
		var file_name := _get_filename(audio_type, audio_name)
		var dir := sound_dir_path if audio_type == AudioType.SOUND else music_dir_path
		var audio_stream_file_path := "%s%s" % [dir, file_name]
		if ResourceLoader.exists(audio_stream_file_path):
			loaded[audio_name] = ResourceLoader.load(audio_stream_file_path)
		
	return loaded
	
	
func _get_filename(audio_type: int, audio_name: String) -> String:
	var file_name := ""
	var files := []
	
	match audio_type:
		AudioType.SOUND:
			files = _sound_filenames
		AudioType.MUSIC:
			files = _music_filenames
			
	if files.size() == 0:
		push_error("No files in folder " + sound_dir_path if audio_type == AudioType.SOUND else music_dir_path)
		
	for available_file_name in files:
		if available_file_name.begins_with(audio_name):
			file_name = available_file_name
			break
	
	return file_name


func _check_priority_and_find_oldest(stream_players: Dictionary, priorities: Dictionary, priority: int) -> Node:
	if stream_players.is_empty():
		return null
	
	var lowest_priority_stream_players := {}
	for id in priorities:
		if priority >= priorities[id]:
			lowest_priority_stream_players[id] = stream_players[id]

	return _find_oldest(lowest_priority_stream_players)
	
	
func _find_oldest(stream_players: Dictionary) -> Node:
	if stream_players.is_empty():
		return null
		
	var oldest_stream_player: Node
	var first_latched := false
	for key in stream_players:
		if not first_latched:
			oldest_stream_player = stream_players[key]
			first_latched = true
		elif oldest_stream_player.get_playback_position() < stream_players[key].get_playback_position():
			oldest_stream_player = stream_players[key]
			
	return oldest_stream_player
	
	
func _on_playing_node_with_sound_2d_stream_players_exiting_tree(node: Node) -> void:
	if is_instance_valid(node):
		var node_id := node.get_instance_id()
		if _playing_nodes_id_access_sound_2d_stream_players.has(node_id):
			var arr := _playing_nodes_id_access_sound_2d_stream_players[node_id] as Array
			while arr.size() > 0:
				_stop_sound_2d_stream_player(arr[0])
	
	
func _on_playing_node_with_sound_3d_stream_players_exiting_tree(node: Node) -> void:
	if is_instance_valid(node):
		var node_id := node.get_instance_id()
		if _playing_nodes_id_access_sound_3d_stream_players.has(node_id):
			var arr := _playing_nodes_id_access_sound_3d_stream_players[node_id] as Array
			while arr.size() > 0:
				_stop_sound_3d_stream_player(arr[0])
			
			
func _on_sound_stream_player_finished(stream_player):
	if stream_player:
		_sound_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_stream_players.append(stream_player)
	
	
func _on_sound_2d_stream_player_finished(stream_player):
	if stream_player:
		_remove_connection_tree_exiting(stream_player)
		stream_player.get_parent().remove_child(stream_player)
		sound_2d_root.add_child(stream_player)
		_sound_2d_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_2d_stream_players.append(stream_player)
	
	
func _on_sound_3d_stream_player_finished(stream_player):
	if stream_player:
		_remove_connection_tree_exiting(stream_player)
		stream_player.get_parent().remove_child(stream_player)
		sound_3d_root.add_child(stream_player)
		_sound_3d_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_3d_stream_players.append(stream_player)
	
	
func _on_music_stream_player_finished(stream_player):
	if stream_player:
		_available_music_stream_players.append(stream_player)
