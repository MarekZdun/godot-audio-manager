@tool
extends Node

## The Audio Manager enables the user to configure a pool of AudioStreamPlayers associated with 
## playing non-positional sounds, 2D sounds, 3D sounds, and music. When there is a need to play 
## a specific AudioStream, Audio Manager retrieves a suitable AudioStreamPlayer from the pool and 
## plays the requested AudioStream on it. Once the AudioStream playback is completed, 
## the AudioStreamPlayer is automatically returned to the pool. This allows the user to reuse 
## AudioStreamPlayers and avoid an excessive number of AudioStreamPlayers on the scene.

enum AudioType {
	SOUND,
	MUSIC
}

enum SoundType {
	NON_POSITIONAL,
	POSITIONAL_2D,
	POSITIONAL_3D
}

const DEFAULT_PITCH_SCALE: float = 1.0
const DEFAULT_VOLUME_LINEAR: float = 1.0  # 1.0 = 0 dB, 0.5 = -6 dB, 0.0 = -80 dB (silence)
const MIN_VOLUME_DB: float = -80.0
const DEFAULT_SOUND_PRIORITY: int = 0
const DEFAULT_VOLUME_FADE_IN_DURATION: float = 0.0
const DEFAULT_VOLUME_FADE_OUT_DURATION: float = 0.0
const MUSIC_BUS_NAME: String = "Music"
const SOUND_BUS_NAME: String = "Sound"
const MUSIC_CHANNEL_COUNT_MAX: int = 64
const SOUND_CHANNEL_COUNT_MAX: int = 64
const SOUND_2D_CHANNEL_COUNT_MAX: int = 64
const SOUND_3D_CHANNEL_COUNT_MAX: int = 64
const DEFAULT_MUSIC_PROCESS_MODE: ProcessMode = PROCESS_MODE_ALWAYS
const DEFAULT_SOUND_PROCESS_MODE: ProcessMode = PROCESS_MODE_PAUSABLE

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
		
@export var music_process_mode: ProcessMode = DEFAULT_MUSIC_PROCESS_MODE:
	set(value):
		music_process_mode = value
		_update_music_process_mode(music_process_mode)
		
@export var sound_process_mode: ProcessMode = DEFAULT_SOUND_PROCESS_MODE:
	set(value):
		sound_process_mode = value
		_update_sound_process_mode(sound_process_mode)

var _sound_stream_players: Dictionary[int, AudioStreamPlayer]
var _sound_2d_stream_players: Dictionary[int, AudioStreamPlayer2D]
var _sound_3d_stream_players: Dictionary[int, AudioStreamPlayer3D]
var _music_stream_players: Dictionary[int, AudioStreamPlayer]

var _available_sound_stream_players: Array[AudioStreamPlayer]
var _available_sound_2d_stream_players: Array[AudioStreamPlayer2D]
var _available_sound_3d_stream_players: Array[AudioStreamPlayer3D]
var _available_music_stream_players: Array[AudioStreamPlayer]

var _sound_stream_players_priorities: Dictionary[int, int]
var _sound_2d_stream_players_priorities: Dictionary[int, int]
var _sound_3d_stream_players_priorities: Dictionary[int, int]

var _sound_filenames: Array[String]
var _music_filenames: Array[String]
var _loaded_sound_streams: Dictionary[String, AudioStream]
var _loaded_music_streams: Dictionary[String, AudioStream]

var _stream_players_tween_volume_transition: Dictionary[int, Tween]
var _playing_nodes_id_access_sound_2d_stream_players: Dictionary[int, Array]
var _playing_nodes_id_access_sound_3d_stream_players: Dictionary[int, Array]
var _audio_bus_layout: AudioBusLayout

@onready var sound_root: Node = get_node("Sound")
@onready var sound_2d_root: Node = get_node("Sound2D")
@onready var sound_3d_root: Node = get_node("Sound3D")
@onready var music_root: Node = get_node("Music")


func _ready():
	if _audio_bus_layout:
		AudioServer.set_bus_layout(_audio_bus_layout)
		
		
func load_sounds(audio_names: Array[String]) -> void:
	_loaded_sound_streams = _load_from_files(AudioType.SOUND, audio_names)
	
	
func load_music(audio_names: Array[String]) -> void:
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
	
	
func play_loaded_sound(stream_name: String, sound_type: SoundType, parent: Node = null, 
		priority: int = DEFAULT_SOUND_PRIORITY, volume_linear: float = DEFAULT_VOLUME_LINEAR, 
		pitch_scale: float = DEFAULT_PITCH_SCALE, override_bus: String = "", 
		override_process_mode: ProcessMode = -1) -> Node:
	var stream: AudioStream
	if _loaded_sound_streams.has(stream_name):
		stream = _loaded_sound_streams[stream_name]
	if stream == null:
		push_error("No audio stream resource loaded with name: " + stream_name)
	
	return play_sound(stream, sound_type, parent, priority, volume_linear, pitch_scale,
		override_bus, override_process_mode)
	
	
func play_sound(stream: AudioStream, sound_type: SoundType, parent: Node = null, 
		priority: int = DEFAULT_SOUND_PRIORITY, volume_linear: float = DEFAULT_VOLUME_LINEAR, 
		pitch_scale: float = DEFAULT_PITCH_SCALE, override_bus: String = "",
		override_process_mode: ProcessMode = -1) -> Node:
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
		stream_player.bus = override_bus if override_bus != "" else SOUND_BUS_NAME
		stream_player.process_mode = override_process_mode if override_process_mode != -1 else PROCESS_MODE_INHERIT
		stream_player.volume_db = linear_to_db(volume_linear)
		stream_player.pitch_scale = pitch_scale
		stream_player.play()
	
	return stream_player
	

func play_loaded_music(stream_name: String, position: float = 0.0, volume_linear: float = DEFAULT_VOLUME_LINEAR, 
		pitch_scale: float = DEFAULT_PITCH_SCALE, volume_transition_in_duration: float = DEFAULT_VOLUME_FADE_IN_DURATION, 
		override_bus: String = "", override_process_mode: ProcessMode = -1) -> AudioStreamPlayer:
	var stream: AudioStream
	if _loaded_music_streams.has(stream_name):
		stream = _loaded_music_streams[stream_name]
	if stream == null:
		push_error("No audio stream resource loaded with name: " + stream_name)
	
	return play_music(stream, position, volume_linear, pitch_scale, volume_transition_in_duration,
		override_bus, override_process_mode)

	
func play_music(stream: AudioStream, position: float = 0.0, volume_linear: float = DEFAULT_VOLUME_LINEAR, 
		pitch_scale: float = DEFAULT_PITCH_SCALE, volume_transition_in_duration: float = DEFAULT_VOLUME_FADE_IN_DURATION, 
		override_bus: String = "", override_process_mode: ProcessMode = -1) -> AudioStreamPlayer:
	if stream == null:
		return
			
	var stream_player: Node
	if not _available_music_stream_players.is_empty():
		stream_player = _available_music_stream_players.pop_front()
	else:
		stream_player = _find_oldest(_music_stream_players)
				
	if stream_player:
		stream_player.stream = stream
		stream_player.bus = override_bus if override_bus != "" else MUSIC_BUS_NAME
		stream_player.process_mode = override_process_mode if override_process_mode != -1 else PROCESS_MODE_INHERIT
		stream_player.pitch_scale = pitch_scale
		
		_remove_tween_volume_transition(stream_player)
		if volume_transition_in_duration > 0:
			stream_player.volume_db = MIN_VOLUME_DB
			create_volume_transition_in(stream_player, volume_linear, volume_transition_in_duration)
		else:
			stream_player.volume_db = linear_to_db(volume_linear)
			
		stream_player.call_deferred("play", position)
		
	return stream_player
	
	
func stop_sound(stream_player: Node) -> void:
	if stream_player:
		if stream_player is AudioStreamPlayer:
			_stop_sound_stream_player(stream_player)
			
		elif stream_player is AudioStreamPlayer2D:
			_stop_sound_2d_stream_player(stream_player)
			
		elif stream_player is AudioStreamPlayer3D:
			_stop_sound_3d_stream_player(stream_player)
			
			
## Stops all sounds of the given type with priority below the specified threshold.
func stop_sounds_by_priority_below(sound_type: SoundType, max_priority: int) -> void:
	var players = _get_players_by_sound_type(sound_type)
	var priorities = _get_priorities_by_sound_type(sound_type)
	
	for id in players:
		var player = players[id]
		var priority = priorities.get(id, DEFAULT_SOUND_PRIORITY)
		
		if is_instance_valid(player) and player.playing and priority < max_priority:
			stop_sound(player)


## Stops all sounds of the given type with priority above the specified threshold.
func stop_sounds_by_priority_above(sound_type: SoundType, min_priority: int) -> void:
	var players = _get_players_by_sound_type(sound_type)
	var priorities = _get_priorities_by_sound_type(sound_type)
	
	for id in players:
		var player = players[id]
		var priority = priorities.get(id, DEFAULT_SOUND_PRIORITY)
		
		if is_instance_valid(player) and player.playing and priority > min_priority:
			stop_sound(player)


## Stops all sounds of the given type with priority equal to the specified value.
func stop_sounds_by_priority_equal(sound_type: SoundType, target_priority: int) -> void:
	var players = _get_players_by_sound_type(sound_type)
	var priorities = _get_priorities_by_sound_type(sound_type)
	
	for id in players:
		var player = players[id]
		var priority = priorities.get(id, DEFAULT_SOUND_PRIORITY)
		
		if is_instance_valid(player) and player.playing and priority == target_priority:
			stop_sound(player)


## Stops all sounds of the given type with priority within the specified range.
func stop_sounds_by_priority_range(sound_type: SoundType, min_priority: int, max_priority: int) -> void:
	var players = _get_players_by_sound_type(sound_type)
	var priorities = _get_priorities_by_sound_type(sound_type)
	
	for id in players:
		var player = players[id]
		var priority = priorities.get(id, DEFAULT_SOUND_PRIORITY)
		
		if is_instance_valid(player) and player.playing and priority >= min_priority and priority <= max_priority:
			stop_sound(player)
	

func stop_music(stream_player: Node, volume_transition_out_duration: float = DEFAULT_VOLUME_FADE_OUT_DURATION):
	_remove_tween_volume_transition(stream_player)
	if volume_transition_out_duration > 0:
		var tween = create_volume_transition_out(stream_player, volume_transition_out_duration)
		await tween.finished

	_stop_music_stream_player(stream_player)
	
	
func create_volume_transition_in(stream_player: Node, volume_linear: float, duration: float) -> Tween:
	var tween := stream_player.create_tween()
	tween.tween_property(stream_player, "volume_db", linear_to_db(volume_linear), duration).from(MIN_VOLUME_DB)
	tween.finished.connect(_remove_tween_volume_transition.bind(stream_player))
	_stream_players_tween_volume_transition[stream_player.get_instance_id()] = tween
	
	return tween
	
	
func create_volume_transition_out(stream_player: Node, duration: float) -> Tween:
	var tween := stream_player.create_tween()
	tween.tween_property(stream_player, "volume_db", MIN_VOLUME_DB, duration)
	tween.finished.connect(_remove_tween_volume_transition.bind(stream_player))
	_stream_players_tween_volume_transition[stream_player.get_instance_id()] = tween
	
	return tween
	
	
## Returns true if the given stream player is currently playing audio.
func is_playing(stream_player: Node) -> bool:
	if not is_instance_valid(stream_player):
		return false
	
	if stream_player is AudioStreamPlayer or \
	   stream_player is AudioStreamPlayer2D or \
	   stream_player is AudioStreamPlayer3D:
		return stream_player.playing
	
	push_error("Invalid stream player type: ", stream_player.get_class())
	return false


## Returns true if any sound with the given stream name is playing.
func is_sound_playing(stream_name: String, sound_type: SoundType) -> bool:
	return is_sound_playing_with_priority(stream_name, sound_type, DEFAULT_SOUND_PRIORITY)


## Returns true if any sound with given name and priority >= min_priority is playing.
func is_sound_playing_with_priority(stream_name: String, sound_type: SoundType, min_priority: int) -> bool:
	var target_stream := _get_loaded_sound(stream_name)
	if not target_stream:
		return false
	
	var players = _get_players_by_sound_type(sound_type)
	var priorities = _get_priorities_by_sound_type(sound_type)
	
	for id in players:
		var player = players[id]
		var player_priority = priorities.get(id, DEFAULT_SOUND_PRIORITY)
		
		if _is_player_playing_sound(player, target_stream) and player_priority >= min_priority:
			return true
	
	return false


## Returns true if any music with the given stream name is playing.
func is_music_playing(stream_name: String) -> bool:
	var target_stream = _loaded_music_streams.get(stream_name)
	if not target_stream:
		push_error("No loaded music stream found with name: " + stream_name)
		return false
	
	for player in _music_stream_players.values():
		if _is_player_playing_sound(player, target_stream):
			return true
	
	return false
	
	
## ============================================================================
## PAUSE / RESUME METHODS
## ============================================================================

## Pauses the given stream player if it's currently playing.
func pause_sound(stream_player: Node) -> bool:
	if not is_instance_valid(stream_player):
		return false
	
	var paused := false
	
	if stream_player is AudioStreamPlayer or \
	   stream_player is AudioStreamPlayer2D or \
	   stream_player is AudioStreamPlayer3D:
		if stream_player.playing and not stream_player.stream_paused:
			stream_player.stream_paused = true
			paused = true
	else:
		push_error("Invalid stream player type: ", stream_player.get_class())
	
	return paused


## Resumes the given stream player if it's paused.
func resume_sound(stream_player: Node) -> bool:
	if not is_instance_valid(stream_player):
		return false
	
	var resumed := false
	
	if stream_player is AudioStreamPlayer or \
	   stream_player is AudioStreamPlayer2D or \
	   stream_player is AudioStreamPlayer3D:
		if stream_player.stream_paused:
			stream_player.stream_paused = false
			resumed = true
	else:
		push_error("Invalid stream player type: ", stream_player.get_class())
	
	return resumed


## Toggles pause state of the given stream player.
func toggle_sound_pause(stream_player: Node) -> bool:
	if not is_instance_valid(stream_player):
		return false
	
	if is_playing(stream_player) and not is_paused(stream_player):
		return pause_sound(stream_player)
	elif is_paused(stream_player):
		return resume_sound(stream_player)
	
	return false


## Returns true if the given stream player is paused.
func is_paused(stream_player: Node) -> bool:
	if not is_instance_valid(stream_player):
		return false
	
	if stream_player is AudioStreamPlayer or \
	   stream_player is AudioStreamPlayer2D or \
	   stream_player is AudioStreamPlayer3D:
		return stream_player.stream_paused
	
	return false


## ============================================================================
## PAUSE/RESUME BY SOUND TYPE
## ============================================================================

## Pauses all sounds of the given type.
func pause_all_sounds_by_type(sound_type: SoundType) -> void:
	var players = _get_players_by_sound_type(sound_type)
	for player in players.values():
		if is_instance_valid(player) and player.playing and not player.stream_paused:
			player.stream_paused = true


## Resumes all sounds of the given type.
func resume_all_sounds_by_type(sound_type: SoundType) -> void:
	var players = _get_players_by_sound_type(sound_type)
	for player in players.values():
		if is_instance_valid(player) and player.stream_paused:
			player.stream_paused = false


## Toggles pause state for all sounds of the given type.
func toggle_all_sounds_by_type(sound_type: SoundType) -> void:
	var players = _get_players_by_sound_type(sound_type)
	var any_playing := false
	var any_paused := false
	
	# Check current state
	for player in players.values():
		if is_instance_valid(player):
			if player.playing and not player.stream_paused:
				any_playing = true
			elif player.stream_paused:
				any_paused = true
	
	# If any are playing, pause all; if all are paused, resume all
	if any_playing and not any_paused:
		pause_all_sounds_by_type(sound_type)
	elif any_paused and not any_playing:
		resume_all_sounds_by_type(sound_type)


## ============================================================================
## PAUSE/RESUME ALL SOUNDS
## ============================================================================

## Pauses all sounds (all types: NON_POSITIONAL, POSITIONAL_2D, POSITIONAL_3D).
func pause_all_sounds() -> void:
	pause_all_sounds_by_type(SoundType.NON_POSITIONAL)
	pause_all_sounds_by_type(SoundType.POSITIONAL_2D)
	pause_all_sounds_by_type(SoundType.POSITIONAL_3D)


## Resumes all sounds (all types).
func resume_all_sounds() -> void:
	resume_all_sounds_by_type(SoundType.NON_POSITIONAL)
	resume_all_sounds_by_type(SoundType.POSITIONAL_2D)
	resume_all_sounds_by_type(SoundType.POSITIONAL_3D)


## Toggles pause state for all sounds.
func toggle_all_sounds() -> void:
	var any_playing := false
	var any_paused := false
	
	# Check all sound types
	for sound_type in [SoundType.NON_POSITIONAL, SoundType.POSITIONAL_2D, SoundType.POSITIONAL_3D]:
		var players = _get_players_by_sound_type(sound_type)
		for player in players.values():
			if is_instance_valid(player):
				if player.playing and not player.stream_paused:
					any_playing = true
				elif player.stream_paused:
					any_paused = true
	
	if any_playing and not any_paused:
		pause_all_sounds()
	elif any_paused and not any_playing:
		resume_all_sounds()


## ============================================================================
## MUSIC PAUSE/RESUME
## ============================================================================

## Pauses the given music player.
func pause_music(stream_player: AudioStreamPlayer) -> bool:
	if not is_instance_valid(stream_player):
		return false
	
	if stream_player.playing and not stream_player.stream_paused:
		stream_player.stream_paused = true
		return true
	
	return false


## Resumes the given music player.
func resume_music(stream_player: AudioStreamPlayer) -> bool:
	if not is_instance_valid(stream_player):
		return false
	
	if stream_player.stream_paused:
		stream_player.stream_paused = false
		return true
	
	return false


## Toggles pause state of the given music player.
func toggle_music_pause(stream_player: AudioStreamPlayer) -> bool:
	if not is_instance_valid(stream_player):
		return false
	
	if stream_player.playing and not stream_player.stream_paused:
		return pause_music(stream_player)
	elif stream_player.stream_paused:
		return resume_music(stream_player)
	
	return false


## Pauses all currently playing music.
func pause_all_music() -> void:
	for player in _music_stream_players.values():
		if is_instance_valid(player) and player.playing and not player.stream_paused:
			player.stream_paused = true


## Resumes all paused music.
func resume_all_music() -> void:
	for player in _music_stream_players.values():
		if is_instance_valid(player) and player.stream_paused:
			player.stream_paused = false


## Toggles pause state for all music.
func toggle_all_music() -> void:
	var any_playing := false
	var any_paused := false
	
	for player in _music_stream_players.values():
		if is_instance_valid(player):
			if player.playing and not player.stream_paused:
				any_playing = true
			elif player.stream_paused:
				any_paused = true
	
	if any_playing and not any_paused:
		pause_all_music()
	elif any_paused and not any_playing:
		resume_all_music()


## ============================================================================
## GLOBAL PAUSE/RESUME (SOUNDS + MUSIC)
## ============================================================================

## Pauses all sounds and music (useful for game pause menu).
func pause_all_audio() -> void:
	pause_all_sounds()
	pause_all_music()


## Resumes all sounds and music.
func resume_all_audio() -> void:
	resume_all_sounds()
	resume_all_music()


## Toggles pause state for all audio (sounds + music).
func toggle_all_audio() -> void:
	var any_playing := false
	var any_paused := false
	
	# Check sounds
	for sound_type in [SoundType.NON_POSITIONAL, SoundType.POSITIONAL_2D, SoundType.POSITIONAL_3D]:
		var players = _get_players_by_sound_type(sound_type)
		for player in players.values():
			if is_instance_valid(player):
				if player.playing and not player.stream_paused:
					any_playing = true
				elif player.stream_paused:
					any_paused = true
	
	# Check music
	for player in _music_stream_players.values():
		if is_instance_valid(player):
			if player.playing and not player.stream_paused:
				any_playing = true
			elif player.stream_paused:
				any_paused = true
	
	if any_playing and not any_paused:
		pause_all_audio()
	elif any_paused and not any_playing:
		resume_all_audio()
	
	
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
	
	
func _update_music_process_mode(p_process_mode: ProcessMode) -> void:
	music_root.process_mode = p_process_mode
	
	
func _update_sound_process_mode(p_process_mode: ProcessMode) -> void:
	sound_root.process_mode = p_process_mode
	
	
func _remove_connection_tree_exiting(stream_player: Node) -> bool:
	var removed_connection := false
	var parent := stream_player.get_parent()
	
	if not is_instance_valid(parent):
		return false
		
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
	if not stream_player:
		return
		
	var stream_player_id := stream_player.get_instance_id()
	
	if _stream_players_tween_volume_transition.has(stream_player_id):
		var tween = _stream_players_tween_volume_transition[stream_player_id]
		
		if tween is Tween:
			if tween.is_valid():
				tween.kill()
		
		_stream_players_tween_volume_transition.erase(stream_player_id)
	
	
func _get_filenames(dir_path: String) -> Array[String]:
	var files: Array[String]
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
	
	
func _load_from_files(audio_type: AudioType, audio_names: Array[String]) -> Dictionary[String, AudioStream]:
	var loaded: Dictionary[String, AudioStream]
	for audio_name in audio_names:
		var file_name := _get_filename(audio_type, audio_name)
		
		if file_name.is_empty():
			push_error("No file found for audio name: " + audio_name)
			continue
			
		var dir := sound_dir_path if audio_type == AudioType.SOUND else music_dir_path
		var audio_stream_file_path := "%s%s" % [dir, file_name]
		
		if ResourceLoader.exists(audio_stream_file_path):
			loaded[audio_name] = ResourceLoader.load(audio_stream_file_path)
		
	return loaded
	
	
func _get_filename(audio_type: AudioType, audio_name: String) -> String:
	var file_name := ""
	var files: Array[String] = []
	
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


func _check_priority_and_find_oldest(stream_players: Dictionary, priorities: Dictionary[int, int], priority: int) -> Node:
	var oldest_player: Node = null
	var max_position: float = -1.0
	
	for id in priorities:
		if priority >= priorities[id]:
			var player = stream_players.get(id)
			
			if player and (player is AudioStreamPlayer or player is AudioStreamPlayer2D or player is AudioStreamPlayer3D):
				var current_pos = player.get_playback_position()
				
				if oldest_player == null or current_pos > max_position:
					max_position = current_pos
					oldest_player = player
					
	return oldest_player
	
	
func _find_oldest(stream_players: Dictionary) -> Node:
	var oldest_player: Node = null
	
	for player in stream_players.values():
		if player is AudioStreamPlayer or player is AudioStreamPlayer2D or player is AudioStreamPlayer3D:
			if oldest_player == null:
				oldest_player = player
			elif player.get_playback_position() > oldest_player.get_playback_position():
				oldest_player = player
				
	return oldest_player
	
	
func _get_players_by_sound_type(sound_type: SoundType) -> Dictionary:
	match sound_type:
		SoundType.NON_POSITIONAL:
			return _sound_stream_players
		SoundType.POSITIONAL_2D:
			return _sound_2d_stream_players
		SoundType.POSITIONAL_3D:
			return _sound_3d_stream_players
		_:
			push_error("Unknown sound type: ", sound_type)
			return {}
			
			
func _get_priorities_by_sound_type(sound_type: SoundType) -> Dictionary:
	match sound_type:
		SoundType.NON_POSITIONAL:
			return _sound_stream_players_priorities
		SoundType.POSITIONAL_2D:
			return _sound_2d_stream_players_priorities
		SoundType.POSITIONAL_3D:
			return _sound_3d_stream_players_priorities
		_:
			push_error("Unknown sound_type: ", sound_type)
			return {}
			
			
func _get_loaded_sound(stream_name: String) -> AudioStream:
	if not _loaded_sound_streams.has(stream_name):
		push_error("No loaded sound stream found with name: " + stream_name)
		return null
	return _loaded_sound_streams[stream_name]


func _is_player_playing_sound(player: Node, target_stream: AudioStream) -> bool:
	return is_instance_valid(player) and player.playing and player.stream == target_stream
	
	
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
			
			
func _on_sound_stream_player_finished(stream_player: AudioStreamPlayer):
	if stream_player:
		_sound_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_stream_players.append(stream_player)
	
	
func _on_sound_2d_stream_player_finished(stream_player: AudioStreamPlayer2D):
	if stream_player:
		_remove_connection_tree_exiting(stream_player)
		stream_player.get_parent().remove_child(stream_player)
		sound_2d_root.add_child(stream_player)
		_sound_2d_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_2d_stream_players.append(stream_player)
	
	
func _on_sound_3d_stream_player_finished(stream_player: AudioStreamPlayer3D):
	if stream_player:
		_remove_connection_tree_exiting(stream_player)
		stream_player.get_parent().remove_child(stream_player)
		sound_3d_root.add_child(stream_player)
		_sound_3d_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_3d_stream_players.append(stream_player)
	
	
func _on_music_stream_player_finished(stream_player: AudioStreamPlayer):
	if stream_player:
		_available_music_stream_players.append(stream_player)
