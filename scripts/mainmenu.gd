class_name Main_Menu
extends Control

@onready var star_button = $MainButtons/HBoxContainer/VBoxContainer/Gioca as Button
@onready var settings_button = $MainButtons/HBoxContainer/VBoxContainer/Impostazioni as Button
@onready var exit_button = $MainButtons/HBoxContainer/VBoxContainer/Esci
@onready var start_level = preload("res://scenes/letteraIniziale.tscn") as PackedScene
@onready var main_buttons = $MainButtons
@onready var options= $Opzioni

func _ready():
	var musica = load("res://assets/musiche/puzzle-game-bright-casual-video-game-music-249202.mp3")
	MusicController.play_music(musica, "menu")
	main_buttons.visible=true
	options.visible=false
	star_button.button_down.connect(on_start_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	settings_button.button_down.connect(on_settings_pressed)

func on_start_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_packed(start_level)
	
func on_settings_pressed()-> void:
	await get_tree().create_timer(0.2).timeout	
	main_buttons.visible=false
	options.visible=true
	
#funzione esci
func on_exit_pressed() -> void:
	get_tree().quit()

func _on_gioca_mouse_entered():
	MusicController.play_hover_sound()

func _on_impostazioni_mouse_entered():
	MusicController.play_hover_sound()

func _on_esci_mouse_entered():
	MusicController.play_hover_sound()

func on_button_hovered():
	MusicController.play_click_sound()


func _on_indietro_opzioni_pressed() -> void:
	_ready()


func _on_crediti_buttons_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
