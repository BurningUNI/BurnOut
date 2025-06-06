# Main_Menu.gd
class_name mainmenu
extends Control

@onready var play_button = $MainButtons/HBoxContainer/VBoxContainer/Gioca as Button
@onready var settings_button = $MainButtons/HBoxContainer/VBoxContainer/Impostazioni as Button
@onready var exit_button = $MainButtons/HBoxContainer/VBoxContainer/Esci

@onready var seleziona_partita_scene = preload("res://scenes/Seleziona_Partita.tscn") as PackedScene
@onready var impostazioni = preload("res://scenes/impostazioni.tscn") as PackedScene
# Aggiorna il riferimento a StatsManager
@onready var stats_manager: Node = get_node("/root/StatsManager") # Usiamo StatsManager per lo stato del gioco

func _ready():
	var musica = load("res://assets/musiche/puzzle-game-bright-casual-video-game-music-249202.mp3")
	MusicController.play_music(musica, "menu")
	# Connetti i segnali dei pulsanti
	play_button.button_down.connect(on_play_button_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	settings_button.button_down.connect(on_settings_pressed)

func on_play_button_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	MusicController.play_click_sound()
	get_tree().change_scene_to_packed(seleziona_partita_scene)

func on_settings_pressed()-> void:
	await get_tree().create_timer(0.2).timeout
	MusicController.play_click_sound()
	get_tree().change_scene_to_packed(impostazioni)

func on_exit_pressed() -> void:
	MusicController.play_click_sound()
	get_tree().quit()

func _on_gioca_mouse_entered():
	MusicController.play_hover_sound()

func _on_impostazioni_mouse_entered():
	MusicController.play_hover_sound()

func _on_esci_mouse_entered():
	MusicController.play_hover_sound()

func on_button_hovered(): # Funzione generica per i suoni al click (duplicata, puoi rimuoverla se _on_XYZ_mouse_entered bastano)
	MusicController.play_click_sound()
