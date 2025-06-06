# SettingsManager.gd
extends Node

const SETTINGS_SAVE_PATH = "user://settings.cfg"

# Funzione per caricare e applicare tutte le impostazioni all'avvio del gioco
func _ready():
	_load_and_apply_all_settings()

func _load_and_apply_all_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_SAVE_PATH)
	if err != OK:
		print("SettingsManager: Nessun file di impostazioni trovato o errore nel caricamento. Applicherò i valori di default.")
		_apply_default_settings()
		save_settings(config) # Salva i default per la prossima volta
		return

	# Carica e applica il volume per ogni bus audio
	# Assicurati che questi nomi corrispondano ai tuoi bus in Godot (Master, Music, SFX)
	var bus_names = ["Master", "Music", "SFX"]
	for bus_name in bus_names:
		var saved_volume = config.get_value("audio", bus_name, 1.0) # Default a 1.0 (volume massimo)
		var audio_bus_id = AudioServer.get_bus_index(bus_name)
		if audio_bus_id != -1:
			AudioServer.set_bus_volume_db(audio_bus_id, linear_to_db(saved_volume))
			print("SettingsManager: Volume bus '", bus_name, "' caricato: ", saved_volume)
	
	# Carica e applica la modalità schermo intero
	var is_fullscreen = config.get_value("video", "fullscreen", false) # Default a false (finestra)
	_apply_fullscreen_setting(is_fullscreen)
	print("SettingsManager: Modalità fullscreen caricata: ", is_fullscreen)

func _apply_default_settings():
	# Applica i volumi di default (o 1.0)
	var bus_names = ["Master", "Music", "SFX"]
	for bus_name in bus_names:
		var audio_bus_id = AudioServer.get_bus_index(bus_name)
		if audio_bus_id != -1:
			AudioServer.set_bus_volume_db(audio_bus_id, linear_to_db(1.0)) # Default a 1.0 (volume massimo)

	# Applica la modalità finestra di default
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Funzione generica per salvare le impostazioni
func save_settings(config: ConfigFile):
	var err = config.save(SETTINGS_SAVE_PATH)
	if err != OK:
		print("SettingsManager: Errore nel salvataggio delle impostazioni: ", err)
	else:
		print("SettingsManager: Impostazioni salvate con successo in: ", SETTINGS_SAVE_PATH)

# Funzione per aggiornare e salvare un singolo volume (chiamata dagli slider)
func update_and_save_volume(bus_name: String, value: float):
	var audio_bus_id = AudioServer.get_bus_index(bus_name)
	if audio_bus_id != -1:
		AudioServer.set_bus_volume_db(audio_bus_id, linear_to_db(value))
		var config = ConfigFile.new()
		var err = config.load(SETTINGS_SAVE_PATH)
		if err != OK:
			config = ConfigFile.new() # Crea un nuovo file se non esiste
		config.set_value("audio", bus_name, value)
		save_settings(config)

# Funzione per aggiornare e salvare la modalità schermo intero
func update_and_save_fullscreen(is_fullscreen: bool):
	_apply_fullscreen_setting(is_fullscreen)
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_SAVE_PATH)
	if err != OK:
		config = ConfigFile.new() # Crea un nuovo file se non esiste
	config.set_value("video", "fullscreen", is_fullscreen)
	save_settings(config)

# Funzione per applicare la modalità schermo intero
func _apply_fullscreen_setting(is_fullscreen: bool):
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Funzione per ottenere il valore salvato di un bus audio (per inizializzare gli slider)
func get_saved_volume(bus_name: String) -> float:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_SAVE_PATH)
	if err != OK:
		return 1.0 # Valore di default
	return config.get_value("audio", bus_name, 1.0)

# Funzione per ottenere lo stato salvato del fullscreen (per inizializzare il CheckButton)
func get_saved_fullscreen_state() -> bool:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_SAVE_PATH)
	if err != OK:
		return false # Valore di default
	return config.get_value("video", "fullscreen", false)
