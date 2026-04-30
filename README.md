# Audio Manager(Godot 4.6 version)

An Audio Manager for [Godot Engine](https://godotengine.org/).<br />
Looking for a Godot 3.5 version? [See godot 3.5 branch](https://github.com/MarekZdun/godot-audio-manager/tree/3.5).

## 📄 Features
Audio Manager - efficient pooling and playback system for sounds and music.  
(c) Pioneer Games  
v 2.0

Key features:
- Automatic player pooling and recycling
- Priority system: low-priority sounds are replaced when channels are full
- Polyphony: single player can play multiple simultaneous sounds (configurable)
- Fade in/out for volume transitions
- Pause/resume for all audio or specific types
- Playback state queries (is_playing, is_paused, is_sound_playing)
- Priority-based batch stopping
- Signals for sound/music completion

## 📄 Description
This manager maintains pools of AudioStreamPlayers for different audio types:
- NON_POSITIONAL: Standard 2D sounds (UI, global effects)
- POSITIONAL_2D: 2D positional sounds (footsteps, explosions in 2D space)
- POSITIONAL_3D: 3D positional sounds (footsteps, explosions in 3D space)
- MUSIC: Background music with crossfade support

## 📄 Requirements:
- Two audio buses must exist in the project's Audio Bus Layout:
  - Music - for all music playback
  - Sound - for all sound effects (non-positional, 2D, 3D)
- Two directories should be set in the Inspector (optional, for auto-discovery):
  - sound_dir_path - directory containing sound files (e.g., res://audio/sounds/)
  - music_dir_path - directory containing music files (e.g., res://audio/music/)

## 📄 Signals:
- `any_sound_finished(stream_player, sound_type, stream_name)` - emitted when any sound finishes playing; returns the player, sound type, and stream name (if loaded from files)
- `any_music_finished(stream_player, stream_name)` - emitted when any music finishes playing; returns the player and stream name (if loaded from files)

## 📄 Usage
1. Setup Audio Manager:
  - Set sound_dir_path and music_dir_path in the Inspector (optional, for auto-discovery)
  - Configure channel counts and polyphony values for your game's needs

2. Load audio files:
  - Use auto-discovery by setting directories, or load manually:
```gdscript
	AudioManager.load_sounds(["explosion", "footstep", "laser"])
	AudioManager.load_music(["battle_theme", "menu_theme"])
```
3. Play sounds:
```gdscript
  # Play a loaded sound
  var player = AudioManager.play_loaded_sound("explosion", SoundType.POSITIONAL_2D, get_parent())
  # Play with custom priority, volume, pitch
  AudioManager.play_loaded_sound("footstep", SoundType.POSITIONAL_2D, player, 5, 0.7, 1.2)
  # Play from AudioStream resource directly
  AudioManager.play_sound(stream, SoundType.NON_POSITIONAL)
```
4. Play music:
```gdscript
  # Play with fade-in (1.5 seconds)
  AudioManager.play_loaded_music("battle_theme", 0.0, 0.8, 1.0, 1.5)
  # Stop with fade-out (2.0 seconds)
  AudioManager.stop_music(music_player, 2.0)
```
5. Control playback:
```gdscript
  # Pause/resume individual sound
  AudioManager.pause_sound(player)
  AudioManager.resume_sound(player) 
  # Pause/resume all sounds (music keeps playing)
  AudioManager.pause_all_sounds()
  AudioManager.resume_all_sounds()
  # Pause/resume everything (game menu)
  AudioManager.pause_all_audio()
  AudioManager.resume_all_audio()
```
6. Priority-based stopping:
```gdscript
  # Stop sounds with priority below 5 (low-priority ambient sounds)
  AudioManager.stop_sounds_by_priority_below(SoundType.NON_POSITIONAL, 5)
  # Stop sounds within priority range 2-7
  AudioManager.stop_sounds_by_priority_range(SoundType.POSITIONAL_2D, 2, 7)
```
7. Check playback state:
```gdscript
  if AudioManager.is_playing(player):
	  print("Sound is playing")
  if AudioManager.is_sound_playing("explosion", SoundType.POSITIONAL_3D):
	  print("Explosion already playing - skipping to avoid overlap")
```
8. Connect to signals:
```gdscript
  AudioManager.any_sound_finished.connect(_on_sound_finished)
  AudioManager.any_music_finished.connect(_on_music_finished)
  func _on_sound_finished(player, sound_type, sound_name):
	  print("Sound finished:", sound_name)
	  if sound_name == "footstep":
		  play_next_footstep()
  func _on_music_finished(player, music_name):
	  print("Music finished:", music_name)
	  AudioManager.play_loaded_music("next_track")
```
9. Optimize with polyphony (v2.0 feature):
```gdscript
  # Set sound_2d_polyphony = 5 in Inspector
  # Enemy shoots 10 times rapidly - same player reused for all shots!
  for i in range(10):
	  AudioManager.play_loaded_sound("laser", SoundType.POSITIONAL_2D, enemy)
```
10. Unload audio (free memory):
```gdscript
  AudioManager.unload_sound("explosion")
  AudioManager.unload_all_sounds()
  AudioManager.unload_all_music()
```
