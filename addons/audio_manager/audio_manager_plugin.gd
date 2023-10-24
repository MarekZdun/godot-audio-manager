tool
extends EditorPlugin

const AUDIO_MANAGER_FILEPATH = "res://addons/audio_manager/audio_manager.tscn"
const AUDIO_MANAGER_AUTLOAD_NAME = "AudioManager"


func enable_plugin():
	add_autoload_singleton(AUDIO_MANAGER_AUTLOAD_NAME, AUDIO_MANAGER_FILEPATH)


func disable_plugin():
	remove_autoload_singleton(AUDIO_MANAGER_AUTLOAD_NAME)
