# Audio Manager(Godot 4.1 version)

An Audio Manager for [Godot Engine](https://godotengine.org/).<br />
Looking for a Godot 3.5 version? [See godot 3.5 branch](https://github.com/MarekZdun/godot-audio-manager/tree/3.5).

## 📄 Features
The Audio Manager enables the user to configure a pool of AudioStreamPlayers associated with playing non-positional sounds, 2D sounds, 3D sounds, and music. When there is a need to play a specific AudioStream, Audio Manager retrieves a suitable AudioStreamPlayer from the pool and plays the requested AudioStream on it. Once the AudioStream playback is completed, the AudioStreamPlayer is automatically returned to the pool. This allows the user to reuse AudioStreamPlayers and avoid an excessive number of AudioStreamPlayers on the scene.
