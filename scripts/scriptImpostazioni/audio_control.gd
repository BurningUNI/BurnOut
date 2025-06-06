# TUO_SLIDER_DEL_VOLUME.gd (il nome del tuo script HSlider)
extends HSlider

@export var audio_bus_name: String
var audio_bus_id

# Riferimento al SettingsManager
@onready var settings_manager: Node = get_node("/root/SettingsManager")

func _ready():
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	# Inizializza lo slider con il valore salvato tramite SettingsManager
	value = settings_manager.get_saved_volume(audio_bus_name)
	# Applica immediatamente il volume all'AudioServer in caso non fosse già caricato (es. riapertura del menu impostazioni)
	AudioServer.set_bus_volume_db(audio_bus_id, linear_to_db(value))

# Quando lo slider cambia
func _on_value_changed(value: float) -> void:
	# Delega la logica di applicazione e salvataggio a SettingsManager
	settings_manager.update_and_save_volume(audio_bus_name, value)
