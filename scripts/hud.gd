extends CanvasLayer

# ---------------------------------------------------------------------
# COSTANTI
# ---------------------------------------------------------------------
const PAUSE_MODE_PROCESS = 2

# ---------------------------------------------------------------------
# NODI ESISTENTI (statistiche, orologio, ecc.)
# ---------------------------------------------------------------------
@onready var statistiche_sfondo: Panel = $StatisticheSfondo
@onready var salute_mentale_bar: TextureProgressBar = $StatisticheSfondo/SaluteMentaleBar
@onready var soldi_quantita_label: Label = $StatisticheSfondo/SoldiIcona/QuantitaSoldi
@onready var orologio_label: Label = $StatisticheSfondo/OrologioLabel
@onready var notifica_messaggio_label: Label = $NotificaMessaggioLabel
@onready var stats_manager: Node = get_node("/root/StatsManager") # Assicurati che StatsManager sia un Autoload

# ---------------------------------------------------------------------
# TELEFONO
# ---------------------------------------------------------------------
@onready var phone_popup: Control = $PhonePopup
@onready var chiudi_button: Button = $PhonePopup/ChiudiBottone
var phone_shown: bool = false

# ---------------------------------------------------------------------
# MENU PAUSA
# ---------------------------------------------------------------------
@onready var impostazioni_button: TextureButton = $ImpostazioniButton
@onready var menu_pause: Control = $MenuPause
@onready var riprendi_button: Button = $MenuPause/Panel/RiprendiButton
@onready var torna_al_menu_button: Button = $MenuPause/Panel/TornaAlMenuButton

# ---------------------------------------------------------------------
func _ready():
	print("HUD: _ready() iniziato")

	# Assicura che il CanvasLayer riceva input anche in pausa
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	print("HUD: pause_mode impostato su PROCESS_MODE_ALWAYS")

	# DEBUG nodi (utile per risolvere problemi come "null instance")
	print("DEBUG: riprendi_button = ", riprendi_button)
	print("DEBUG: torna_al_menu_button = ", torna_al_menu_button)
	print("DEBUG: impostazioni_button = ", impostazioni_button)
	print("DEBUG: menu_pause = ", menu_pause)
	print("DEBUG: phone_popup = ", phone_popup)
	print("DEBUG: chiudi_button = ", chiudi_button)


	# Collegamenti al StatsManager
	# Questi collegamenti sono FONDAMENTALI per aggiornare l'HUD
	if is_instance_valid(stats_manager):
		stats_manager.salute_mentale_cambiata.connect(_on_salute_mentale_cambiata)
		stats_manager.soldi_cambiati.connect(_on_soldi_cambiati)
		stats_manager.tempo_cambiato.connect(_on_tempo_cambiato) # Questo è il segnale per l'orologio
		stats_manager.evento_casuale_triggerato.connect(_on_evento_casuale_triggerato)
		stats_manager.letto_pronto.connect(_on_letto_pronto)
		print("HUD: Segnali StatsManager collegati con successo.")
	else:
		print("HUD ERROR: StatsManager non valido. Assicurati che sia un Autoload.")

	# Inizializza l'HUD con i valori attuali allo start della scena
	_on_salute_mentale_cambiata(stats_manager.salute_mentale)
	_on_soldi_cambiati(stats_manager.soldi)
	_on_tempo_cambiato(
		stats_manager.ora,
		stats_manager.minuti,
		stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana]
	)
	print("HUD: Valori iniziali aggiornati.")

	# TELEFONO
	# Controlli per evitare errori di connessione multipla, se si ricarica la scena
	if is_instance_valid(chiudi_button) and not chiudi_button.pressed.is_connected(_on_chiudi_button_pressed):
		chiudi_button.pressed.connect(_on_chiudi_button_pressed)
		print("HUD: Segnale CHIUDI telefono collegato.")
	phone_popup.visible = false

	# MENU PAUSA
	if is_instance_valid(impostazioni_button) and not impostazioni_button.pressed.is_connected(_on_impostazioni_button_pressed):
		impostazioni_button.pressed.connect(_on_impostazioni_button_pressed)
		print("HUD: Segnale IMPOSTAZIONI collegato.")

	if is_instance_valid(riprendi_button) and not riprendi_button.pressed.is_connected(_on_riprendi_button_pressed):
		riprendi_button.pressed.connect(_on_riprendi_button_pressed)
		print("HUD: Segnale RIPRENDI collegato.")

	if is_instance_valid(torna_al_menu_button) and not torna_al_menu_button.pressed.is_connected(_on_torna_al_menu_button_pressed):
		torna_al_menu_button.pressed.connect(_on_torna_al_menu_button_pressed)
		print("HUD: Segnale TORNA AL MENU collegato.")

	menu_pause.visible = false
	get_tree().paused = false
	print("HUD: Menu pausa e stato di pausa inizializzati.")

# ---------------------------------------------------------------------
# CALLBACK STATS MANAGER (ricevono i segnali dal StatsManager)
# ---------------------------------------------------------------------
func _on_salute_mentale_cambiata(nuova_salute: int) -> void:
	print("HUD: Salute mentale aggiornata (segnale): ", nuova_salute)
	salute_mentale_bar.value = nuova_salute

func _on_soldi_cambiati(nuovi_soldi: int) -> void:
	print("HUD: Soldi aggiornati (segnale): ", nuovi_soldi)
	soldi_quantita_label.text = str(nuovi_soldi)

func _on_tempo_cambiato(nuova_ora: int, nuovi_minuti: int, nuovo_giorno_nome: String) -> void:
	# Questa funzione viene chiamata quando il StatsManager emette il segnale 'tempo_cambiato'.
	# Aggiorna la Label dell'orologio con l'ora e il giorno formattati.
	var tempo_formattato = "%02d:%02d" % [nuova_ora, nuovi_minuti]
	# Puoi decidere come mostrare il giorno (es. solo giorno della settimana, o giorno + numero giorno)
	# Per includere anche il numero del giorno:
	orologio_label.text = "%s Giorno %d - %s" % [nuovo_giorno_nome, stats_manager.giorno, tempo_formattato]
	
	
	# Controlla il popup del telefono in base all'orario
	_check_phone_popup(nuova_ora, nuovi_minuti)

func _on_evento_casuale_triggerato(tipo_evento: String, messaggio: String, importo: int) -> void:
	var full_message = "Evento: %s! %s" % [tipo_evento, messaggio]
	if importo != 0:
		# Formatta l'importo con un segno per indicare guadagno/perdita
		full_message += " (Importo: %s%d$)" % ["+" if importo > 0 else "", importo] 

	notifica_messaggio_label.text = full_message
	notifica_messaggio_label.modulate.a = 1.0 # Rendi visibile

	var tween = create_tween()
	tween.tween_interval(3.0) # Mostra per 3 secondi
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.5) # Scompare in 1.5 secondi
	tween.finished.connect(func(): notifica_messaggio_label.text = "") # Pulisci il testo alla fine

	print("HUD: Evento casuale mostrato: ", full_message)

func _on_letto_pronto(letto_node_ref: Area2D) -> void:
	# Questo segnale viene emesso dal StatsManager quando il letto è pronto.
	# Qui colleghi il segnale 'letto_interagito' dal nodo letto stesso,
	# se è il nodo letto a emetterlo.
	# (Verifica che il nodo letto emetta effettivamente 'letto_interagito' con messaggio e successo)
	if is_instance_valid(letto_node_ref):
		if not letto_node_ref.letto_interagito.is_connected(_on_letto_interagito): # Previene connessioni multiple
			letto_node_ref.letto_interagito.connect(_on_letto_interagito)
			print("HUD: Segnale 'letto_interagito' collegato con successo al letto registrato.")
	else:
		print("HUD ERROR: Nodo letto non valido ricevuto per la registrazione del segnale!")

func _on_letto_interagito(messaggio: String, successo: bool) -> void:
	# Mostra il messaggio dell'interazione con il letto
	notifica_messaggio_label.text = messaggio
	notifica_messaggio_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): notifica_messaggio_label.text = "") # Pulisci il testo alla fine

	print("HUD: Interazione letto: ", messaggio)

# ---------------------------------------------------------------------
# TELEFONO
# ---------------------------------------------------------------------
func _check_phone_popup(ora: int, minuti: int) -> void:
	# Controlla se il popup del telefono deve essere mostrato.
	# Attualmente mostrato solo una volta quando i minuti sono 5.
	if not phone_shown and minuti == 5:
		phone_shown = true # Assicurati che venga mostrato solo una volta per questo specifico minuto
		phone_popup.visible = true
		print("HUD: Popup telefono mostrato alle ", ora, ":", minuti)

func _on_chiudi_button_pressed() -> void:
	phone_popup.visible = false
	print("HUD: Popup telefono chiuso.")

# ---------------------------------------------------------------------
# MENU PAUSA
# ---------------------------------------------------------------------
func _on_impostazioni_button_pressed() -> void:
	menu_pause.visible = true
	get_tree().paused = true # Mette in pausa il gioco
	print("HUD: Impostazioni aperte, gioco in pausa.")

func _on_riprendi_button_pressed() -> void:
	menu_pause.visible = false
	get_tree().paused = false # Riprende il gioco
	print("HUD: Riprendi premuto, gioco ripreso.")

func _on_torna_al_menu_button_pressed() -> void:
	get_tree().paused = false # Assicurati che il gioco non sia in pausa prima di cambiare scena
	print("HUD: Torna al menu premuto, cambio scena...")
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
