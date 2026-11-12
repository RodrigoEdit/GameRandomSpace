extends Node

const LEVEL_1_TRACK := preload("res://Audio/musica_l_1.mp3")
# Segundo ambiente disponible mientras se prepara una pista exclusiva del nivel 2.
const LEVEL_2_TRACK := preload("res://Audio/Koi-discovery - Atlas_Shoulders.mp3.mp3")

var _player: AudioStreamPlayer
var _current_track: AudioStream

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -18.0
	add_child(_player)

func play_level(level: int) -> void:
	var track: AudioStream = LEVEL_1_TRACK if level == 1 else LEVEL_2_TRACK
	if _current_track == track and _player.playing:
		return
	_current_track = track
	_player.stream = track
	_player.play()

func stop_music() -> void:
	if _player:
		_player.stop()
