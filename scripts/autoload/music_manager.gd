extends Node

const SILENT_DB := -60.0

var _players: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func play(stream: AudioStream, volume: float = 0.5, fade: float = 2.0, exclusive: bool = true) -> void:
	if stream == null:
		return
	if exclusive:
		for other in _players:
			if other != stream:
				stop(other, fade)
	var player: AudioStreamPlayer = _players.get(stream)
	if player == null:
		player = AudioStreamPlayer.new()
		player.stream = stream
		player.bus = &"Music"
		player.volume_db = SILENT_DB
		add_child(player)
		_players[stream] = player
	if not player.playing:
		player.volume_db = SILENT_DB
		player.play()
	_fade(player, linear_to_db(volume), fade, false)


func stop(stream: AudioStream, fade: float = 1.0) -> void:
	var player: AudioStreamPlayer = _players.get(stream)
	if player != null and player.playing:
		_fade(player, SILENT_DB, fade, true)


func stop_all(fade: float = 1.0) -> void:
	for stream in _players:
		stop(stream, fade)


func _fade(player: AudioStreamPlayer, to_db: float, duration: float, stop_after: bool) -> void:
	if player.has_meta(&"fade"):
		var old: Tween = player.get_meta(&"fade")
		if old != null and old.is_valid():
			old.kill()
	var tween := create_tween()
	player.set_meta(&"fade", tween)
	tween.tween_property(player, "volume_db", to_db, maxf(duration, 0.01))
	if stop_after:
		tween.tween_callback(player.stop)
