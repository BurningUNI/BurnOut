extends Node2D

@onready var musica_background_menu = $Music
var current_track_name = ""

var hover_sound = load("res://assets/musiche/minimal-pop-click-ui-1-198301.mp3") 
var click_sound = load("res://assets/musiche/game-start-6104.mp3")

func play_music(stream: AudioStream, track_name: String) -> void:
	# Se la musica è diversa da quella attuale, la cambio
	if current_track_name != track_name:
		musica_background_menu.stream = stream
		musica_background_menu.bus= "Music"
		musica_background_menu.play()
		current_track_name = track_name
	# Se è la stessa musica ma è ferma, la faccio ripartire
	elif not musica_background_menu.playing:
		musica_background_menu.play()
		
		
func stop_music() -> void:
	musica_background_menu	.stop()
	current_track_name = ""
	
func play_hover_sound():
	$Hover.stream = hover_sound
	$Hover.play()
	$Hover.bus = "SFX"

func play_click_sound():
	$Press.stream = click_sound
	$Press.bus = "SFX"
