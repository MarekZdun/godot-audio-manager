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
## Linear volume: 1.0 = 0 dB (full volume), 0.5 ≈ -6 dB, 0.0 = silence
const DEFAULT_VOLUME_LINEAR: float = 1.0
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

## Sentinel value indicating no process_mode override — not a valid ProcessMode enum value
const PROCESS_MODE_NO_OVERRIDE: int = -1

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


func _ready() -> void:
	if _audio_bus_layout:
		AudioServer.set_bus_layout(_audio_bus_layout)


# ============================================================================
# LOADING / UNLOADING
# ============================================================================

func load_sounds(audio_names: Array[String]) -> void:
	_loaded_sound_streams = _load_from_files(AudioType.SOUND, audio_names)


func load_music(audio_names: Array[String]) -> void:
	_loaded_music_streams = _load_from_files(AudioType.MUSIC, audio_names)


func unload_all_sounds() -> void:
	_loaded_sound_streams = {}


func unload_all_music() -> void:
	_loaded_music_streams = {}


func unload_sound(audio_name: String) -> void:
	if not _loaded_sound_streams.erase(audio_name):
		push_error("No loaded sound stream found with name: " + audio_name)


func unload_music(audio_name: String) -> void:
	if not _loaded_music_streams.erase(audio_name):
		push_error("No loaded music stream found with name: " + audio_name)


# ============================================================================
# SOUND PLAYBACK
# ============================================================================

func play_loaded_sound(stream_name: String, sound_type: SoundType, parent: Node = null,
		priority: int = DEFAULT_SOUND_PRIORITY, volume_linear: float = DEFAULT_VOLUME_LINEAR,
		pitch_scale: float = DEFAULT_PITCH_SCALE, override_bus: String = "",
		override_process_mode: int = PROCESS_MODE_NO_OVERRIDE) -> Node:
	var stream: AudioStream = null
	if _loaded_sound_streams.has(stream_name):
		stream = _loaded_sound_streams[stream_name]
	if stream == null:
		push_error("No audio stream resource loaded with name: " + stream_name)
		return null

	return play_sound(stream, sound_type, parent, priority, volume_linear, pitch_scale,
		override_bus, override_process_mode)


func play_sound(stream: AudioStream, sound_type: SoundType, parent: Node = null,
		priority: int = DEFAULT_SOUND_PRIORITY, volume_linear: float = DEFAULT_VOLUME_LINEAR,
		pitch_scale: float = DEFAULT_PITCH_SCALE, override_bus: String = "",
		override_process_mode: int = PROCESS_MODE_NO_OVERRIDE) -> Node:
	if stream == null:
		return null

	var stream_player: Node = null

	match sound_type:
		SoundType.NON_POSITIONAL:
			if not _available_sound_stream_players.is_empty():
				stream_player = _available_sound_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(
					_sound_stream_players, _sound_stream_players_priorities, priority)

			if stream_player:
				_sound_stream_players_priorities[stream_player.get_instance_id()] = priority

		SoundType.POSITIONAL_2D:
			if not _available_sound_2d_stream_players.is_empty():
				stream_player = _available_sound_2d_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(
					_sound_2d_stream_players, _sound_2d_stream_players_priorities, priority)

			if stream_player:
				_remove_connection_tree_exiting(stream_player)
				if is_instance_valid(parent):
					var parent_id := parent.get_instance_id()
					stream_player.get_parent().remove_child(stream_player)
					parent.add_child(stream_player)

					if not _playing_nodes_id_access_sound_2d_stream_players.has(parent_id):
						_playing_nodes_id_access_sound_2d_stream_players[parent_id] = []
					_playing_nodes_id_access_sound_2d_stream_players[parent_id].append(stream_player)

					if not parent.tree_exiting.is_connected(_on_playing_node_with_sound_2d_stream_players_exiting_tree):
						parent.tree_exiting.connect(
							_on_playing_node_with_sound_2d_stream_players_exiting_tree.bind(parent),
							CONNECT_ONE_SHOT)

				_sound_2d_stream_players_priorities[stream_player.get_instance_id()] = priority

		SoundType.POSITIONAL_3D:
			if not _available_sound_3d_stream_players.is_empty():
				stream_player = _available_sound_3d_stream_players.pop_front()
			else:
				stream_player = _check_priority_and_find_oldest(
					_sound_3d_stream_players, _sound_3d_stream_players_priorities, priority)

			if stream_player:
				_remove_connection_tree_exiting(stream_player)
				if is_instance_valid(parent):
					var parent_id := parent.get_instance_id()
					stream_player.get_parent().remove_child(stream_player)
					parent.add_child(stream_player)

					if not _playing_nodes_id_access_sound_3d_stream_players.has(parent_id):
						_playing_nodes_id_access_sound_3d_stream_players[parent_id] = []
					_playing_nodes_id_access_sound_3d_stream_players[parent_id].append(stream_player)

					if not parent.tree_exiting.is_connected(_on_playing_node_with_sound_3d_stream_players_exiting_tree):
						parent.tree_exiting.connect(
							_on_playing_node_with_sound_3d_stream_players_exiting_tree.bind(parent),
							CONNECT_ONE_SHOT)

				_sound_3d_stream_players_priorities[stream_player.get_instance_id()] = priority

	if stream_player:
		stream_player.stream = stream
		stream_player.bus = override_bus if override_bus != "" else SOUND_BUS_NAME
		stream_player.process_mode = override_process_mode if override_process_mode != PROCESS_MODE_NO_OVERRIDE else PROCESS_MODE_INHERIT
		stream_player.volume_db = linear_to_db(volume_linear)
		stream_player.pitch_scale = pitch_scale
		stream_player.play()

	return stream_player


# ============================================================================
# MUSIC PLAYBACK
# ============================================================================

func play_loaded_music(stream_name: String, position: float = 0.0,
		volume_linear: float = DEFAULT_VOLUME_LINEAR, pitch_scale: float = DEFAULT_PITCH_SCALE,
		volume_transition_in_duration: float = DEFAULT_VOLUME_FADE_IN_DURATION,
		override_bus: String = "", override_process_mode: int = PROCESS_MODE_NO_OVERRIDE) -> AudioStreamPlayer:
	var stream: AudioStream = null
	if _loaded_music_streams.has(stream_name):
		stream = _loaded_music_streams[stream_name]
	if stream == null:
		push_error("No audio stream resource loaded with name: " + stream_name)
		return null

	return play_music(stream, position, volume_linear, pitch_scale,
		volume_transition_in_duration, override_bus, override_process_mode)


func play_music(stream: AudioStream, position: float = 0.0,
		volume_linear: float = DEFAULT_VOLUME_LINEAR, pitch_scale: float = DEFAULT_PITCH_SCALE,
		volume_transition_in_duration: float = DEFAULT_VOLUME_FADE_IN_DURATION,
		override_bus: String = "", override_process_mode: int = PROCESS_MODE_NO_OVERRIDE) -> AudioStreamPlayer:
	if stream == null:
		return null

	var stream_player: AudioStreamPlayer = null
	if not _available_music_stream_players.is_empty():
		stream_player = _available_music_stream_players.pop_front()
	else:
		stream_player = _find_oldest(_music_stream_players)

	if stream_player:
		stream_player.stream = stream
		stream_player.bus = override_bus if override_bus != "" else MUSIC_BUS_NAME
		stream_player.process_mode = override_process_mode if override_process_mode != PROCESS_MODE_NO_OVERRIDE else PROCESS_MODE_INHERIT
		stream_player.pitch_scale = pitch_scale

		_remove_tween_volume_transition(stream_player)
		if volume_transition_in_duration > 0.0:
			stream_player.volume_db = MIN_VOLUME_DB
			create_volume_transition_in(stream_player, volume_linear, volume_transition_in_duration)
		else:
			stream_player.volume_db = linear_to_db(volume_linear)

		stream_player.call_deferred("play", position)

	return stream_player


# ============================================================================
# STOPPING SOUNDS
# ============================================================================

func stop_sound(stream_player: Node) -> void:
	if not is_instance_valid(stream_player):
		return

	if stream_player is AudioStreamPlayer:
		_stop_sound_stream_player(stream_player)
	elif stream_player is AudioStreamPlayer2D:
		_stop_sound_2d_stream_player(stream_player)
	elif stream_player is AudioStreamPlayer3D:
		_stop_sound_3d_stream_player(stream_player)


## Stops all sounds of the given type with priority strictly below [param max_priority].
func stop_sounds_by_priority_below(sound_type: SoundType, max_priority: int) -> void:
	var players := _get_players_by_sound_type(sound_type)
	var priorities := _get_priorities_by_sound_type(sound_type)

	for id in players:
		var player: Node = players[id]
		var priority: int = priorities.get(id, DEFAULT_SOUND_PRIORITY)

		if is_instance_valid(player) and player.playing and priority < max_priority:
			stop_sound(player)


## Stops all sounds of the given type with priority strictly above [param min_priority].
func stop_sounds_by_priority_above(sound_type: SoundType, min_priority: int) -> void:
	var players := _get_players_by_sound_type(sound_type)
	var priorities := _get_priorities_by_sound_type(sound_type)

	for id in players:
		var player: Node = players[id]
		var priority: int = priorities.get(id, DEFAULT_SOUND_PRIORITY)

		if is_instance_valid(player) and player.playing and priority > min_priority:
			stop_sound(player)


## Stops all sounds of the given type with priority equal to [param target_priority].
func stop_sounds_by_priority_equal(sound_type: SoundType, target_priority: int) -> void:
	var players := _get_players_by_sound_type(sound_type)
	var priorities := _get_priorities_by_sound_type(sound_type)

	for id in players:
		var player: Node = players[id]
		var priority: int = priorities.get(id, DEFAULT_SOUND_PRIORITY)

		if is_instance_valid(player) and player.playing and priority == target_priority:
			stop_sound(player)


## Stops all sounds of the given type with priority within [param min_priority]..[param max_priority] (inclusive).
func stop_sounds_by_priority_range(sound_type: SoundType, min_priority: int, max_priority: int) -> void:
	var players := _get_players_by_sound_type(sound_type)
	var priorities := _get_priorities_by_sound_type(sound_type)

	for id in players:
		var player: Node = players[id]
		var priority: int = priorities.get(id, DEFAULT_SOUND_PRIORITY)

		if is_instance_valid(player) and player.playing \
				and priority >= min_priority and priority <= max_priority:
			stop_sound(player)


# ============================================================================
# STOPPING MUSIC
# ============================================================================

func stop_music(stream_player: AudioStreamPlayer,
		volume_transition_out_duration: float = DEFAULT_VOLUME_FADE_OUT_DURATION) -> void:
	if not is_instance_valid(stream_player):
		return

	_remove_tween_volume_transition(stream_player)

	if volume_transition_out_duration > 0.0:
		var tween := create_volume_transition_out(stream_player, volume_transition_out_duration)
		await tween.finished
		## FIX: re-check validity after await — the node may have been freed during the fade-out
		if not is_instance_valid(stream_player):
			return

	_stop_music_stream_player(stream_player)


# ============================================================================
# VOLUME TRANSITIONS (FADE)
# ============================================================================

func create_volume_transition_in(stream_player: Node, volume_linear: float, duration: float) -> Tween:
	var tween := stream_player.create_tween()
	tween.tween_property(stream_player, "volume_db", linear_to_db(volume_linear), duration) \
		.from(MIN_VOLUME_DB)
	tween.finished.connect(_remove_tween_volume_transition.bind(stream_player))
	_stream_players_tween_volume_transition[stream_player.get_instance_id()] = tween
	return tween


func create_volume_transition_out(stream_player: Node, duration: float) -> Tween:
	var tween := stream_player.create_tween()
	tween.tween_property(stream_player, "volume_db", MIN_VOLUME_DB, duration)
	tween.finished.connect(_remove_tween_volume_transition.bind(stream_player))
	_stream_players_tween_volume_transition[stream_player.get_instance_id()] = tween
	return tween


# ============================================================================
# PLAYBACK STATE QUERIES
# ============================================================================

## Returns true if the given stream player is currently playing audio.
func is_playing(stream_player: Node) -> bool:
	if not is_instance_valid(stream_player):
		return false

	if stream_player is AudioStreamPlayer \
			or stream_player is AudioStreamPlayer2D \
			or stream_player is AudioStreamPlayer3D:
		return stream_player.playing

	push_error("Invalid stream player type: ", stream_player.get_class())
	return false


## Returns true if any sound with the given stream name is currently playing.
## Note: only detects sounds with priority >= DEFAULT_SOUND_PRIORITY (0).
## Use [method is_sound_playing_with_priority] with a negative min_priority
## if you use negative priorities.
func is_sound_playing(stream_name: String, sound_type: SoundType) -> bool:
	return is_sound_playing_with_priority(stream_name, sound_type, DEFAULT_SOUND_PRIORITY)


## Returns true if any sound with the given name and priority >= [param min_priority] is playing.
func is_sound_playing_with_priority(stream_name: String, sound_type: SoundType, min_priority: int) -> bool:
	var target_stream := _get_loaded_sound(stream_name)
	if not target_stream:
		return false

	var players := _get_players_by_sound_type(sound_type)
	var priorities := _get_priorities_by_sound_type(sound_type)

	for id in players:
		var player: Node = players[id]
		var player_priority: int = priorities.get(id, DEFAULT_SOUND_PRIORITY)

		if _is_player_playing_sound(player, target_stream) and player_priority >= min_priority:
			return true

	return false


## Returns true if music with the given stream name is currently playing.
func is_music_playing(stream_name: String) -> bool:
	var target_stream: AudioStream = _loaded_music_streams.get(stream_name)
	if not target_stream:
		push_error("No loaded music stream found with name: " + stream_name)
		return false

	for player in _music_stream_players.values():
		if _is_player_playing_sound(player, target_stream):
			return true

	return false


# ============================================================================
# PAUSE / RESUME — SINGLE PLAYER
# ============================================================================

## Pauses the given stream player if it is currently playing.
func pause_sound(stream_player: Node) -> bool:
	if not is_instance_valid(stream_player):
		return false

	if stream_player is AudioStreamPlayer \
			or stream_player is AudioStreamPlayer2D \
			or stream_player is AudioStreamPlayer3D:
		if stream_player.playing and not stream_player.stream_paused:
			stream_player.stream_paused = true
			return true
	else:
		push_error("Invalid stream player type: ", stream_player.get_class())

	return false


## Resumes the given stream player if it is paused.
func resume_sound(stream_player: Node) -> bool:
	if not is_instance_valid(stream_player):
		return false

	if stream_player is AudioStreamPlayer \
			or stream_player is AudioStreamPlayer2D \
			or stream_player is AudioStreamPlayer3D:
		if stream_player.stream_paused:
			stream_player.stream_paused = false
			return true
	else:
		push_error("Invalid stream player type: ", stream_player.get_class())

	return false


## Toggles the pause state of the given stream player.
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

	if stream_player is AudioStreamPlayer \
			or stream_player is AudioStreamPlayer2D \
			or stream_player is AudioStreamPlayer3D:
		return stream_player.stream_paused

	return false


# ============================================================================
# PAUSE / RESUME — BY SOUND TYPE
# ============================================================================

## Pauses all sounds of the given type.
func pause_all_sounds_by_type(sound_type: SoundType) -> void:
	var players := _get_players_by_sound_type(sound_type)
	for player in players.values():
		if is_instance_valid(player) and player.playing and not player.stream_paused:
			player.stream_paused = true


## Resumes all sounds of the given type.
func resume_all_sounds_by_type(sound_type: SoundType) -> void:
	var players := _get_players_by_sound_type(sound_type)
	for player in players.values():
		if is_instance_valid(player) and player.stream_paused:
			player.stream_paused = false


## Toggles the pause state for all sounds of the given type.
func toggle_all_sounds_by_type(sound_type: SoundType) -> void:
	var players := _get_players_by_sound_type(sound_type)
	var state := _get_players_pause_state(players)

	## If anything is playing — pause all; if all are paused — resume all
	if state.any_playing and not state.any_paused:
		pause_all_sounds_by_type(sound_type)
	elif state.any_paused and not state.any_playing:
		resume_all_sounds_by_type(sound_type)


# ============================================================================
# PAUSE / RESUME — ALL SOUNDS
# ============================================================================

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


## Toggles the pause state for all sounds.
func toggle_all_sounds() -> void:
	var state := _get_combined_pause_state([
		_sound_stream_players,
		_sound_2d_stream_players,
		_sound_3d_stream_players,
	])

	if state.any_playing and not state.any_paused:
		pause_all_sounds()
	elif state.any_paused and not state.any_playing:
		resume_all_sounds()


# ============================================================================
# PAUSE / RESUME — MUSIC
# ============================================================================

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


## Toggles the pause state of the given music player.
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


## Toggles the pause state for all music.
func toggle_all_music() -> void:
	var state := _get_players_pause_state(_music_stream_players)

	if state.any_playing and not state.any_paused:
		pause_all_music()
	elif state.any_paused and not state.any_playing:
		resume_all_music()


# ============================================================================
# GLOBAL PAUSE / RESUME (SOUNDS + MUSIC)
# ============================================================================

## Pauses all sounds and music — useful for a game pause menu.
func pause_all_audio() -> void:
	pause_all_sounds()
	pause_all_music()


## Resumes all sounds and music.
func resume_all_audio() -> void:
	resume_all_sounds()
	resume_all_music()


## Toggles the pause state for all audio (sounds + music).
func toggle_all_audio() -> void:
	var state := _get_combined_pause_state([
		_sound_stream_players,
		_sound_2d_stream_players,
		_sound_3d_stream_players,
		_music_stream_players,
	])

	if state.any_playing and not state.any_paused:
		pause_all_audio()
	elif state.any_paused and not state.any_playing:
		resume_all_audio()


# ============================================================================
# INTERNAL — STOPPING
# ============================================================================

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


# ============================================================================
# INTERNAL — AUDIO BUS CONFIGURATION
# ============================================================================

func _update_audio_bus_from_file_path() -> void:
	if ResourceLoader.exists(audio_bus_default_file_path):
		_audio_bus_layout = ResourceLoader.load(audio_bus_default_file_path, "", 0) as AudioBusLayout
	else:
		_audio_bus_layout = null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not _check_audio_bus_layout_existence():
		warnings.append("Give proper file path to AudioBusLayout resource file")
	elif not _check_audio_bus_layout_validity():
		warnings.append("Audio bus layout must contain one bus named %s and one bus named %s" \
			% [MUSIC_BUS_NAME, SOUND_BUS_NAME])
	return warnings


func _check_audio_bus_layout_existence() -> bool:
	if audio_bus_default_file_path.is_empty():
		return false
	_update_audio_bus_from_file_path()
	return _audio_bus_layout != null


func _check_audio_bus_layout_validity() -> bool:
	var buses: PackedStringArray = []
	var i: int = 0
	while _audio_bus_layout.get("bus/%s/name" % i) != null:
		buses.append(_audio_bus_layout.get("bus/%s/name" % i))
		i += 1
	return buses.has(MUSIC_BUS_NAME) and buses.has(SOUND_BUS_NAME)


# ============================================================================
# INTERNAL — CHANNEL MANAGEMENT
# ============================================================================

func _update_music_channels(count: int) -> void:
	if count < 0:
		return

	var current_count := _music_stream_players.size()
	if count > current_count:
		for i in count - current_count:
			var sp := AudioStreamPlayer.new()
			sp.bus = MUSIC_BUS_NAME
			sp.finished.connect(_on_music_stream_player_finished.bind(sp))
			music_root.add_child(sp)
			_music_stream_players[sp.get_instance_id()] = sp
			_available_music_stream_players.append(sp)

	elif count < current_count:
		for i in range(count, current_count):
			var sp: AudioStreamPlayer
			if not _available_music_stream_players.is_empty():
				sp = _available_music_stream_players.pop_front()
			else:
				sp = _find_oldest(_music_stream_players)

			if sp:
				_remove_tween_volume_transition(sp)
				_music_stream_players.erase(sp.get_instance_id())
				sp.queue_free()


func _update_sound_channels(count: int) -> void:
	if count < 0:
		return

	var current_count := _sound_stream_players.size()
	if count > current_count:
		for i in count - current_count:
			var sp := AudioStreamPlayer.new()
			sp.bus = SOUND_BUS_NAME
			sp.finished.connect(_on_sound_stream_player_finished.bind(sp))
			sound_root.add_child(sp)
			_sound_stream_players[sp.get_instance_id()] = sp
			_available_sound_stream_players.append(sp)

	elif count < current_count:
		for i in range(count, current_count):
			var sp: AudioStreamPlayer
			if not _available_sound_stream_players.is_empty():
				sp = _available_sound_stream_players.pop_front()
			else:
				sp = _check_priority_and_find_oldest(_sound_stream_players, _sound_stream_players_priorities, 9999)

			if sp:
				var sp_id := sp.get_instance_id()
				_sound_stream_players.erase(sp_id)
				_sound_stream_players_priorities.erase(sp_id)
				sp.queue_free()


func _update_sound_2d_channels(count: int) -> void:
	if count < 0:
		return

	var current_count := _sound_2d_stream_players.size()
	if count > current_count:
		for i in count - current_count:
			var sp := AudioStreamPlayer2D.new()
			sp.bus = SOUND_BUS_NAME
			sp.finished.connect(_on_sound_2d_stream_player_finished.bind(sp))
			sound_2d_root.add_child(sp)
			_sound_2d_stream_players[sp.get_instance_id()] = sp
			_available_sound_2d_stream_players.append(sp)

	elif count < current_count:
		for i in range(count, current_count):
			var sp: AudioStreamPlayer2D
			if not _available_sound_2d_stream_players.is_empty():
				sp = _available_sound_2d_stream_players.pop_front()
			else:
				sp = _check_priority_and_find_oldest(_sound_2d_stream_players, _sound_2d_stream_players_priorities, 9999)

			if sp:
				var sp_id := sp.get_instance_id()
				_remove_connection_tree_exiting(sp)
				_sound_2d_stream_players.erase(sp_id)
				_sound_2d_stream_players_priorities.erase(sp_id)
				sp.queue_free()


func _update_sound_3d_channels(count: int) -> void:
	if count < 0:
		return

	var current_count := _sound_3d_stream_players.size()
	if count > current_count:
		for i in count - current_count:
			var sp := AudioStreamPlayer3D.new()
			sp.bus = SOUND_BUS_NAME
			sp.finished.connect(_on_sound_3d_stream_player_finished.bind(sp))
			sound_3d_root.add_child(sp)
			_sound_3d_stream_players[sp.get_instance_id()] = sp
			_available_sound_3d_stream_players.append(sp)

	elif count < current_count:
		for i in range(count, current_count):
			var sp: AudioStreamPlayer3D
			if not _available_sound_3d_stream_players.is_empty():
				sp = _available_sound_3d_stream_players.pop_front()
			else:
				sp = _check_priority_and_find_oldest(_sound_3d_stream_players, _sound_3d_stream_players_priorities, 9999)

			if sp:
				var sp_id := sp.get_instance_id()
				_remove_connection_tree_exiting(sp)
				_sound_3d_stream_players.erase(sp_id)
				_sound_3d_stream_players_priorities.erase(sp_id)
				sp.queue_free()


# ============================================================================
# INTERNAL — FILE AND LOADING
# ============================================================================

func _update_music_filenames(p_music_dir_path: String) -> void:
	_music_filenames = _get_filenames(p_music_dir_path)


func _update_sound_filenames(p_sound_dir_path: String) -> void:
	_sound_filenames = _get_filenames(p_sound_dir_path)


func _update_sound_process_mode(p_process_mode: ProcessMode) -> void:
	sound_root.process_mode = p_process_mode
	sound_2d_root.process_mode = p_process_mode
	sound_3d_root.process_mode = p_process_mode


func _update_music_process_mode(p_process_mode: ProcessMode) -> void:
	music_root.process_mode = p_process_mode


func _get_filenames(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir():
				push_error("Found directory in audio folder: " + file_name)
			elif file_name.ends_with(".import"):
				files.append(file_name.replace(".import", ""))
			file_name = dir.get_next()
	else:
		push_error("An error occurred when trying to access '" + dir_path + "'.")
	return files


func _load_from_files(audio_type: AudioType, audio_names: Array[String]) -> Dictionary[String, AudioStream]:
	var loaded: Dictionary[String, AudioStream] = {}
	for audio_name in audio_names:
		var file_name := _get_filename(audio_type, audio_name)

		if file_name.is_empty():
			push_error("No file found for audio name: " + audio_name)
			continue

		var dir := sound_dir_path if audio_type == AudioType.SOUND else music_dir_path
		var path := "%s%s" % [dir, file_name]

		if ResourceLoader.exists(path):
			loaded[audio_name] = ResourceLoader.load(path)

	return loaded


func _get_filename(audio_type: AudioType, audio_name: String) -> String:
	var files: Array[String] = _sound_filenames if audio_type == AudioType.SOUND else _music_filenames

	if files.is_empty():
		var dir := sound_dir_path if audio_type == AudioType.SOUND else music_dir_path
		push_error("No files in folder: " + dir)
		return ""

	for available_file_name in files:
		if available_file_name.begins_with(audio_name):
			return available_file_name

	return ""


# ============================================================================
# INTERNAL — POOL AND PRIORITIES
# ============================================================================

func _remove_connection_tree_exiting(stream_player: Node) -> bool:
	var parent := stream_player.get_parent()
	if not is_instance_valid(parent):
		return false

	var parent_id := parent.get_instance_id()
	var removed := false

	if stream_player is AudioStreamPlayer2D:
		if _playing_nodes_id_access_sound_2d_stream_players.has(parent_id):
			var arr := _playing_nodes_id_access_sound_2d_stream_players[parent_id] as Array
			arr.erase(stream_player)
			if arr.is_empty():
				_playing_nodes_id_access_sound_2d_stream_players.erase(parent_id)
				if parent.tree_exiting.is_connected(_on_playing_node_with_sound_2d_stream_players_exiting_tree) \
						and not parent.is_queued_for_deletion():
					parent.tree_exiting.disconnect(_on_playing_node_with_sound_2d_stream_players_exiting_tree)
					removed = true

	elif stream_player is AudioStreamPlayer3D:
		if _playing_nodes_id_access_sound_3d_stream_players.has(parent_id):
			var arr := _playing_nodes_id_access_sound_3d_stream_players[parent_id] as Array
			arr.erase(stream_player)
			if arr.is_empty():
				_playing_nodes_id_access_sound_3d_stream_players.erase(parent_id)
				if parent.tree_exiting.is_connected(_on_playing_node_with_sound_3d_stream_players_exiting_tree) \
						and not parent.is_queued_for_deletion():
					parent.tree_exiting.disconnect(_on_playing_node_with_sound_3d_stream_players_exiting_tree)
					removed = true

	return removed


func _remove_tween_volume_transition(stream_player: Node) -> void:
	if not is_instance_valid(stream_player):
		return

	var sp_id := stream_player.get_instance_id()
	if _stream_players_tween_volume_transition.has(sp_id):
		var tween: Tween = _stream_players_tween_volume_transition[sp_id]
		if tween and tween.is_valid():
			tween.kill()
		_stream_players_tween_volume_transition.erase(sp_id)


func _find_oldest(stream_players: Dictionary) -> Node:
	var oldest: Node = null

	for player in stream_players.values():
		if player is AudioStreamPlayer \
				or player is AudioStreamPlayer2D \
				or player is AudioStreamPlayer3D:
			if oldest == null or player.get_playback_position() > oldest.get_playback_position():
				oldest = player

	return oldest


func _check_priority_and_find_oldest(stream_players: Dictionary, priorities: Dictionary[int, int], priority: int) -> Node:
	var oldest: Node = null
	var max_pos: float = -1.0

	for id in priorities:
		if priority >= priorities[id] and stream_players.has(id):
			var player: Node = stream_players[id]
			if is_instance_valid(player):
				var pos: float = player.get_playback_position()
				if oldest == null or pos > max_pos:
					max_pos = pos
					oldest = player

	return oldest


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
			push_error("Unknown sound type: ", sound_type)
			return {}


func _get_loaded_sound(stream_name: String) -> AudioStream:
	if not _loaded_sound_streams.has(stream_name):
		push_error("No loaded sound stream found with name: " + stream_name)
		return null
	return _loaded_sound_streams[stream_name]


func _is_player_playing_sound(player: Node, target_stream: AudioStream) -> bool:
	return is_instance_valid(player) and player.playing and player.stream == target_stream


func _get_players_pause_state(players: Dictionary) -> Dictionary:
	var any_playing := false
	var any_paused := false

	for player in players.values():
		if is_instance_valid(player):
			if player.playing and not player.stream_paused:
				any_playing = true
			elif player.stream_paused:
				any_paused = true
			if any_playing and any_paused:
				break  # early exit — both flags known

	return { "any_playing": any_playing, "any_paused": any_paused }


## Takes an array of dictionaries (e.g., [_sound_stream_players, _music_stream_players]).
func _get_combined_pause_state(player_dicts: Array) -> Dictionary:
	var any_playing := false
	var any_paused := false

	for players in player_dicts:
		var state := _get_players_pause_state(players)
		if state.any_playing:
			any_playing = true
		if state.any_paused:
			any_paused = true
		if any_playing and any_paused:
			break

	return { "any_playing": any_playing, "any_paused": any_paused }


# ============================================================================
# CALLBACKS — PLAYBACK FINISHED AND TREE EXITING
# ============================================================================

func _on_playing_node_with_sound_2d_stream_players_exiting_tree(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var node_id := node.get_instance_id()
	if _playing_nodes_id_access_sound_2d_stream_players.has(node_id):
		var arr := _playing_nodes_id_access_sound_2d_stream_players[node_id] as Array
		while arr.size() > 0:
			_stop_sound_2d_stream_player(arr[0])


func _on_playing_node_with_sound_3d_stream_players_exiting_tree(node: Node) -> void:
	if not is_instance_valid(node):
		return

	var node_id := node.get_instance_id()
	if _playing_nodes_id_access_sound_3d_stream_players.has(node_id):
		var arr := _playing_nodes_id_access_sound_3d_stream_players[node_id] as Array
		while arr.size() > 0:
			_stop_sound_3d_stream_player(arr[0])


func _on_sound_stream_player_finished(stream_player: AudioStreamPlayer) -> void:
	if stream_player:
		_sound_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_stream_players.append(stream_player)


func _on_sound_2d_stream_player_finished(stream_player: AudioStreamPlayer2D) -> void:
	if stream_player:
		_remove_connection_tree_exiting(stream_player)
		stream_player.get_parent().remove_child(stream_player)
		sound_2d_root.add_child(stream_player)
		_sound_2d_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_2d_stream_players.append(stream_player)


func _on_sound_3d_stream_player_finished(stream_player: AudioStreamPlayer3D) -> void:
	if stream_player:
		_remove_connection_tree_exiting(stream_player)
		stream_player.get_parent().remove_child(stream_player)
		sound_3d_root.add_child(stream_player)
		_sound_3d_stream_players_priorities.erase(stream_player.get_instance_id())
		_available_sound_3d_stream_players.append(stream_player)


func _on_music_stream_player_finished(stream_player: AudioStreamPlayer) -> void:
	if stream_player:
		_available_music_stream_players.append(stream_player)
