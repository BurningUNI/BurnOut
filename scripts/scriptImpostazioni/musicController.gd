extends Node

@onready var musica_background_menu = $Music
var current_track_name = ""
var current_stream: AudioStream = null

var hover_sound = preload("res://assets/musiche/minimal-pop-click-ui-1-198301.mp3") 
var click_sound = preload("res://assets/musiche/game-start-6104.mp3")

# Libreria canzoni associate a nome scena
var track_library := {
	"room": preload("res://assets/musiche/room_music.mp3"),
	"park": preload("res://assets/musiche/park_music.mp3"),
	"main_menu": preload("res://assets/musiche/room_music.mp3"),
	"gameover": preload("res://assets/musiche/gameover.mp3"),
	"win": preload("res://assets/musiche/winsound.mp3"),
	"school": preload("res://assets/musiche/school_music.mp3")
}

func play_music(stream: AudioStream, track_name: String, loop: bool = true) -> void:
	if current_track_name != track_name or current_stream != stream:
		if stream is AudioStream:
			var new_stream = stream.duplicate()
			if new_stream is AudioStream:
				new_stream.loop = loop
				musica_background_menu.stream = new_stream
				musica_background_menu.bus = "Music"
				musica_background_menu.play()
				current_track_name = track_name
				current_stream = stream
	elif not musica_background_menu.playing:
		musica_background_menu.play()

func stop_music() -> void:
	musica_background_menu.stop()
	current_track_name = ""
	current_stream = null

func play_hover_sound():
	$Hover.stream = hover_sound
	$Hover.bus = "SFX"
	$Hover.play()

func play_click_sound():
	$Press.stream = click_sound
	$Press.bus = "SFX"
	$Press.play()
