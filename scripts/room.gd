extends Node2D

# ---- COSTANTI ORARIO PER DORMIRE ----
const ORA_MINIMA_PER_DORMIRE = 21
const MINUTI_MINIMI_PER_DORMIRE = 30

# NUOVA COSTANTE: Orario limite massimo per andare a dormire al mattino (escluso)
# Significa che si può dormire fino alle 06:59, ma non dalle 07:00 in poi per "ricominciare il giorno".
const ORA_FINE_PERIODO_SONNO_MATTINO_ESCLUSA = 7 

# NUOVE COSTANTI PER I LIMITI DI STUDIO
# Ora di inizio delle penalità (21:00)
const ORA_INIZIO_PENALTY_STUDIO = 21
const MINUTI_INIZIO_PENALTY_STUDIO = 0

# Orario di inizio e fine della "notte profonda" (es. dalle 00:00 alle 05:59)
# durante la quale non è mai permesso studiare.
const ORA_INIZIO_BLOCCO_NOTTURNO_STUDIO = 0  # Dalle 00:00 (incluso)
const ORA_FINE_BLOCCO_NOTTURNO_STUDIO = 6    # Fino alle 05:59 (6 è escluso, quindi fino a 5:59)


# ---- VARIABILI DI STATO ----
var near_door = false
var near_bed = false
var near_desk = false

# ---- NODI ONREADY ----
@onready var stats_manager = get_node("/root/StatsManager")
@onready var letto_label: Label = $BedArea/LettoLabel
@onready var player: Node2D = $Player
@onready var spawn_room := $SpawnRoom
@onready var label_interazione: Label = $DoorArea/InterazioneLabel
@onready var popup_uscita = $SceltaUscita
@onready var button_corridoio = $SceltaUscita/VBoxContainer/ButtonCorridoio
@onready var button_park = $SceltaUscita/VBoxContainer/ButtonPark

# NODI ONREADY PER LA SCRIVANIA
@onready var desk_area: Area2D = $DeskArea
@onready var desk_interazione_label: Label = $DeskArea/InterazioneLabel
@onready var popup_studio = $DeskArea/PopupStudio
@onready var analisi_bottone = $DeskArea/PopupStudio/AnalisiBottone
@onready var programmazione_bottone = $DeskArea/PopupStudio/ProgrammazioneBottone
@onready var studio_label: Label = $DeskArea/PopupStudio/studioLabel

func _ready():
	await get_tree().process_frame
	MusicController.play_music(MusicController.track_library["room"], "room")
	StatsManager.current_scene_path = get_tree().current_scene.scene_file_path
	if Global.last_exit == "portaCasa" or Global.last_exit == "park":
		player.global_position = spawn_room.global_position

	calcola_limiti_mappa()

	# --- RICONNESSIONE SEGNALI MANCANTI (ESSENZIALE PER LETTO E PORTA!) ---
	$BedArea.connect("body_entered", _on_bed_area_body_entered)
	$BedArea.connect("body_exited", _on_bed_area_body_exited)
	$DoorArea.connect("body_entered", _on_door_area_body_entered)
	$DoorArea.connect("body_exited", _on_door_area_body_exited)

	# Connessioni per la scrivania (che avevi già)
	desk_area.connect("body_entered", _on_desk_area_body_entered)
	desk_area.connect("body_exited", _on_desk_area_body_exited)
	analisi_bottone.pressed.connect(_on_analisi_bottone_pressed)
	programmazione_bottone.pressed.connect(_on_programmazione_bottone_pressed)
	# --- FINE RICONNESSIONE ---

	# Visibilità iniziale delle label e popup
	label_interazione.visible = false
	letto_label.visible = false
	popup_uscita.hide()
	
	desk_interazione_label.visible = false
	popup_studio.hide()

	# Testi per i pulsanti di uscita
	button_corridoio.text = "Vai al Corridoio"
	button_park.text = "Vai al parco"
	button_corridoio.pressed.connect(_vai_al_corridoio)
	button_park.pressed.connect(_vai_al_parco)
	
	# Testo per il popup di studio
	studio_label.text = "Scegli cosa studiare:"


func _process(_delta: float) -> void:
	# Logica per l'uscita dalla stanza
	if near_door and Input.is_action_just_pressed("interact") and not popup_uscita.visible:
		popup_uscita.popup_centered()

	# Logica per dormire
	if near_bed and Input.is_action_just_pressed("interact"):
		tenta_di_dormire()

	# Logica per studiare
	if near_desk and Input.is_action_just_pressed("interact") and not popup_studio.visible:
		var ora_attuale = stats_manager.ora
		var minuti_attuali = stats_manager.minuti

		# Controlla se è nella fascia oraria di blocco notturno (00:00 - 05:59)
		var is_night_block = (ora_attuale >= ORA_INIZIO_BLOCCO_NOTTURNO_STUDIO and ora_attuale < ORA_FINE_BLOCCO_NOTTURNO_STUDIO)

		if is_night_block:
			desk_interazione_label.text = "È troppo tardi per studiare! Devi aspettare il giorno."
			desk_interazione_label.visible = true
			var tween = create_tween()
			tween.tween_interval(3.0)
			tween.tween_property(desk_interazione_label, "modulate:a", 0.0, 1.0)
			tween.finished.connect(func():
				desk_interazione_label.visible = false
				desk_interazione_label.modulate.a = 1.0
			)
		else:
			# Se non è nella fascia notturna, mostra il popup di studio
			popup_studio.popup_centered()


# ---- INTERAZIONE CON PORTA ----
func _on_door_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_door = true
		label_interazione.text = "Premi [SPAZIO] per uscire di casa"
		label_interazione.visible = true

func _on_door_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_door = false
		label_interazione.visible = false
		popup_uscita.hide()

func _vai_al_corridoio():
	Global.last_exit = "portaCasa"
	stats_manager.current_scene_path = "res://scenes/Corridoio.tscn"
	stats_manager.save_game()
	get_tree().change_scene_to_file("res://scenes/Corridoio.tscn")

func _vai_al_parco():
	Global.last_exit = "park"
	stats_manager.current_scene_path = "res://scenes/Park.tscn"
	stats_manager.save_game()
	get_tree().change_scene_to_file("res://scenes/Park.tscn")

# ---- INTERAZIONE CON LETTO ----
func _on_bed_area_body_entered(body: Node2D):
	if body.name == "Player":
		near_bed = true
		letto_label.text = "Premi [SPAZIO] per dormire."
		letto_label.visible = true

func _on_bed_area_body_exited(body: Node2D):
	if body.name == "Player":
		near_bed = false
		letto_label.visible = false

func tenta_di_dormire():
	var ora = stats_manager.ora
	var minuti = stats_manager.minuti

	var sleep_successful = false
	var message = ""

	# Condizione 1: Si può dormire la sera (dalle 21:30 alle 23:59)
	if (ora > ORA_MINIMA_PER_DORMIRE or (ora == ORA_MINIMA_PER_DORMIRE and minuti >= MINUTI_MINIMI_PER_DORMIRE)) and ora <= 23:
		# Se si dorme in questo intervallo, si avanza al giorno successivo.
		stats_manager.giorno += 1
		stats_manager.indice_giorno_settimana = (stats_manager.indice_giorno_settimana + 1) % 7
		sleep_successful = true
		message = "Hai dormito bene! Nuovo giorno: %s Giorno %d" % [
			stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana],
			stats_manager.giorno
		]
	# Condizione 2: Si può dormire al mattino presto (dalle 00:00 fino a ORA_FINE_PERIODO_SONNO_MATTINO_ESCLUSA (es. 06:59))
	elif ora >= ORA_INIZIO_BLOCCO_NOTTURNO_STUDIO and ora < ORA_FINE_PERIODO_SONNO_MATTINO_ESCLUSA:
		# Se si dorme in questo intervallo, il giorno è già passato (mezzanotte),
		# quindi non si incrementa di nuovo il contatore del giorno.
		sleep_successful = true
		message = "Hai dormito bene! Continua il %s Giorno %d" % [ # Messaggio leggermente diverso
			stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana],
			stats_manager.giorno
		]
	else:
		# Se non si rientra in nessuna delle fasce orarie di sonno valide
		message = "Non è l'orario giusto per dormire. Puoi dormire dalle %02d:%02d oppure prima delle %02d:00 del mattino." % [
			ORA_MINIMA_PER_DORMIRE, MINUTI_MINIMI_PER_DORMIRE, ORA_FINE_PERIODO_SONNO_MATTINO_ESCLUSA
		]

	if sleep_successful:
		# Imposta l'ora a 7:00 del mattino (ora di risveglio fissa)
		stats_manager.ora = 7
		stats_manager.minuti = 0
		
		# IMPORTANTE: Non chiamiamo stats_manager.avanza_ore(8) qui.
		# L'avanzamento del giorno è gestito esplicitamente sopra
		# e l'orario di risveglio viene impostato direttamente.
		# Chiamare avanza_ore potrebbe creare doppie incrementazioni del giorno
		# o orari finali inaspettati.

		stats_manager.save_game()
	
	letto_label.text = message
	letto_label.visible = true

# ---- NUOVO: INTERAZIONE CON SCRIVANIA ----
func _on_desk_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_desk = true
		desk_interazione_label.text = "Premi [SPAZIO] per studiare"
		desk_interazione_label.visible = true

func _on_desk_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_desk = false
		desk_interazione_label.visible = false
		popup_studio.hide() # Nascondi il popup se il player si allontana

func _on_analisi_bottone_pressed():
	studia("analisi")

func _on_programmazione_bottone_pressed():
	studia("programmazione")

func studia(materia: String):
	# Chiudi il popup di studio
	popup_studio.hide()

	var ora_attuale = stats_manager.ora
	var minuti_attuali = stats_manager.minuti

	# Controllo di blocco notturno (00:00 - 05:59)
	var is_night_block = (ora_attuale >= ORA_INIZIO_BLOCCO_NOTTURNO_STUDIO and ora_attuale < ORA_FINE_BLOCCO_NOTTURNO_STUDIO)
	
	if is_night_block:
		desk_interazione_label.text = "È troppo tardi per studiare! Devi aspettare il giorno."
		desk_interazione_label.visible = true
		var tween = create_tween()
		tween.tween_interval(3.0)
		tween.tween_property(desk_interazione_label, "modulate:a", 0.0, 1.0)
		tween.finished.connect(func():
			desk_interazione_label.visible = false
			desk_interazione_label.modulate.a = 1.0
		)
		print("Non puoi studiare, è in fascia notturna.")
		return # Interrompe l'esecuzione della funzione qui

	var mental_health_loss = 10
	var study_gain = 5
	var study_message = ""

	# Controlla per le penalità (dalle 21:00 in poi, fino alle 23:59)
	if ora_attuale >= ORA_INIZIO_PENALTY_STUDIO:
		mental_health_loss = 15
		study_gain = 3
		study_message = " Hai studiato fino a tardi!"
	else:
		study_message = " Hai studiato bene!" 

	# Fai passare 4 ore
	stats_manager.avanza_ore(4)

	# Riduci la salute mentale
	stats_manager.diminuisci_salute_mentale(mental_health_loss)

	# Aumenta lo stato di studio
	stats_manager.aumenta_stato_studio(materia, study_gain)

	print("Hai studiato %s per 4 ore. Salute mentale ridotta di %d. Stato studio aumentato di %d." % [materia, mental_health_loss, study_gain])
	print("Stato Analisi:", stats_manager.statoAnalisi)
	print("Stato Programmazione:", stats_manager.statoProgrammazione)
	
	desk_interazione_label.text = "Hai studiato %s per 4 ore!%s" % [materia, study_message]
	desk_interazione_label.visible = true
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(desk_interazione_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): 
		desk_interazione_label.visible = false
		desk_interazione_label.modulate.a = 1.0
	)


# ---- CALCOLO LIMITI MAPPA ----
func calcola_limiti_mappa():
	var tilemap_root = $TileMap
	var tile_size := Vector2i(0, 0)
	var all_used_positions: Array[Vector2i] = []

	for child in tilemap_root.get_children():
		if child is TileMap:
			var tilemap_node: TileMap = child
			for layer_index in range(tilemap_node.get_layers_count()):
				var used: Array[Vector2i] = tilemap_node.get_used_cells(layer_index)
				if used.size() > 0:
					all_used_positions += used
					if tile_size == Vector2i(0, 0) and tilemap_node.tile_set:
						tile_size = tilemap_node.tile_set.tile_size
		elif child is TileMapLayer:
			var layer := child
			var used: Array[Vector2i] = layer.get_used_cells()
			if used.size() > 0:
				all_used_positions += used
				if tile_size == Vector2i(0, 0):
					tile_size = layer.tile_set.tile_size


	if all_used_positions.is_empty():
		print("❌ Nessuna cella trovata in nessun layer. I limiti della mappa potrebbero non essere calcolati correttamente.")
		return

	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for cell in all_used_positions:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)

	var limit_left = min_x * tile_size.x
	var limit_top = min_y * tile_size.y
	var limit_right = (max_x + 1) * tile_size.x
	var limit_bottom = (max_y + 1) * tile_size.y

	# GLOBAL.map_limits = Rect2(Vector2(limit_left, limit_top), Vector2(limit_right - limit_left, limit_bottom - limit_top))
	# print("📐 Limiti mappa impostati in Global: ", GLOBAL.map_limits)

	print("📐 Limiti mappa combinati tra tutti i livelli:")
	print("Left: ", limit_left)
	print("Top: ", limit_top)
	print("Right: ", limit_right)
	print("Bottom: ", limit_bottom)
