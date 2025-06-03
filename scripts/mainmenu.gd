# Main_Menu.gd
class_name mainmenu
extends Control

@onready var play_button = $MainButtons/HBoxContainer/VBoxContainer/Gioca as Button # Rimane "Gioca" come testo
@onready var settings_button = $MainButtons/HBoxContainer/VBoxContainer/Impostazioni as Button
@onready var exit_button = $MainButtons/HBoxContainer/VBoxContainer/Esci
@onready var main_buttons = $MainButtons
@onready var options = $Opzioni

# Precarica la nuova scena di selezione partita
@onready var seleziona_partita_scene = preload("res://scenes/Seleziona_Partita.tscn") as PackedScene # AGGIORNATO QUI

# Riferimento al nodo GameState (assicurati che sia un autoload!)
@onready var game_state: Node = get_node("/root/GameState")

func _ready():
	var musica = load("res://assets/musiche/puzzle-game-bright-casual-video-game-music-249202.mp3")
	MusicController.play_music(musica, "menu")

	main_buttons.visible = true
	options.visible = false

	# Connetti i segnali dei pulsanti
	play_button.button_down.connect(on_play_button_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	settings_button.button_down.connect(on_settings_pressed)


# Questa funzione ora cambia scena alla schermata di selezione
func on_play_button_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	MusicController.play_click_sound()
	get_tree().change_scene_to_packed(seleziona_partita_scene) # AGGIORNATO QUI

func on_settings_pressed()-> void:
	await get_tree().create_timer(0.2).timeout
	MusicController.play_click_sound()
	main_buttons.visible=false
	options.visible=true

func on_exit_pressed() -> void:
	MusicController.play_click_sound()
	get_tree().quit()

func _on_gioca_mouse_entered():
	MusicController.play_hover_sound()

func _on_impostazioni_mouse_entered():
	MusicController.play_hover_sound()

func _on_esci_mouse_entered():
	MusicController.play_hover_sound()

func on_button_hovered(): # Funzione generica per i suoni al click
	MusicController.play_click_sound()

func _on_indietro_opzioni_pressed() -> void:
	_ready()

func _on_crediti_buttons_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	MusicController.play_click_sound()
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
