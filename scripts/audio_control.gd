extends HSlider

@export var audio_bus_name: String
var audio_bus_id
const SAVE_PATH := "user://settings.cfg"

func _ready():
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	# Carica il volume salvato
	var saved_value = load_saved_volume()
	value = saved_value  # Imposta lo slider
	AudioServer.set_bus_volume_db(audio_bus_id, linear_to_db(saved_value))  # Imposta volume

# Quando lo slider cambia
func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	save_volume(value)

# Salva su file
func save_volume(value: float) -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		config = ConfigFile.new()
	config.set_value("audio", audio_bus_name, value)
	config.save(SAVE_PATH)

# Carica dal file
func load_saved_volume() -> float:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		return 1.0  # Valore di default se non esiste
	return config.get_value("audio", audio_bus_name, 1.0)
