# TUO_CHECKBUTTON_FULLSCREEN.gd (il nome del tuo script CheckButton)
extends CheckButton

# Riferimento al SettingsManager
@onready var settings_manager: Node = get_node("/root/SettingsManager")

func _ready() -> void:
	# Inizializza il CheckButton con lo stato salvato tramite SettingsManager
	button_pressed = settings_manager.get_saved_fullscreen_state()

func _on_toggled(toggled_on: bool):
	# Delega la logica di applicazione e salvataggio a SettingsManager
	settings_manager.update_and_save_fullscreen(toggled_on)
