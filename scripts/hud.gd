extends CanvasLayer

# ---------------------------------------------------------------------
# COSTANTI
# ---------------------------------------------------------------------
const PAUSE_MODE_PROCESS = 2
const GIORNO_ESAME = 15 # Definisci il giorno dell'esame qui, come costante globale

# ---------------------------------------------------------------------
# NODI ESISTENTI
# ---------------------------------------------------------------------
@onready var statistiche_sfondo: Panel = $StatisticheSfondo
@onready var salute_mentale_bar: TextureProgressBar = $StatisticheSfondo/SaluteMentaleBar
@onready var soldi_quantita_label: Label = $StatisticheSfondo/SoldiIcona/QuantitaSoldi
@onready var orologio_label: Label = $StatisticheSfondo/OrologioLabel
@onready var notifica_messaggio_label: Label = $NotificaMessaggioLabel
@onready var stats_manager: Node = get_node("/root/StatsManager")

# TELEFONO
@onready var phone_popup: Control = $PhonePopup
@onready var chiudi_button: Button = $PhonePopup/ChiudiBottone # Questo è il chiudi del telefono

var phone_shown: bool = false
var last_popup_day: int = -1

# MENU PAUSA
@onready var impostazioni_button: TextureButton = $ImpostazioniButton
@onready var menu_pause: Control = $MenuPause
@onready var riprendi_button: Button = $MenuPause/Panel/RiprendiButton
@onready var torna_al_menu_button: Button = $MenuPause/Panel/TornaAlMenuButton

# STATO STUDIO
@onready var stato_studio_button: TextureButton = $StatoStudioButton # Il pulsante che apre il pannello

# Riferimenti al pannello e ai suoi figli, basandosi sulla tua gerarchia mostrata:
@onready var pannello_stato_studio: Panel = $StatoStudioButton/Panel
@onready var label_stato_analisi: Label = $StatoStudioButton/Panel/StatoAnalisi
@onready var label_stato_programmazione: Label = $StatoStudioButton/Panel/StatoProgrammazione
@onready var chiudi_pannello_stato_studio_button: TextureButton = $StatoStudioButton/Panel/ChiudiButton
@onready var scritta1_label: Label = $StatoStudioButton/Panel/Scritta1
@onready var counter_esame_label: Label = $StatoStudioButton/Panel/CounterEsame


# ---------------------------------------------------------------------
func _ready():
	print("HUD: _ready() iniziato")

	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	print("HUD: pause_mode impostato su PROCESS_MODE_ALWAYS")

	if is_instance_valid(stats_manager):
		stats_manager.salute_mentale_cambiata.connect(_on_salute_mentale_cambiata)
		stats_manager.soldi_cambiati.connect(_on_soldi_cambiati)
		stats_manager.tempo_cambiato.connect(_on_tempo_cambiato)
		stats_manager.evento_casuale_triggerato.connect(_on_evento_casuale_triggerato)
		stats_manager.letto_pronto.connect(_on_letto_pronto)
		print("HUD: Segnali StatsManager collegati con successo.")
	else:
		print("HUD ERROR: StatsManager non valido.")

	_on_salute_mentale_cambiata(stats_manager.salute_mentale)
	_on_soldi_cambiati(stats_manager.soldi)
	_on_tempo_cambiato(
		stats_manager.ora,
		stats_manager.minuti,
		stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana]
	)

	if is_instance_valid(chiudi_button) and not chiudi_button.pressed.is_connected(_on_chiudi_button_pressed):
		chiudi_button.pressed.connect(_on_chiudi_button_pressed)
		print("HUD: Segnale CHIUDI telefono collegato.")
	phone_popup.visible = false

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

	# Collega StatoStudioButton e il suo pulsante di chiusura
	if is_instance_valid(stato_studio_button) and not stato_studio_button.pressed.is_connected(_on_stato_studio_button_pressed):
		stato_studio_button.pressed.connect(_on_stato_studio_button_pressed)
		print("HUD: Segnale STATO STUDIO BUTTON collegato.")

	# NOTA: Il ChiudiButton del pannello di studio è ora un fratello del Panel, non un figlio del Panel
	if is_instance_valid(chiudi_pannello_stato_studio_button) and not chiudi_pannello_stato_studio_button.pressed.is_connected(_on_chiudi_pannello_stato_studio_button_pressed):
		chiudi_pannello_stato_studio_button.pressed.connect(_on_chiudi_pannello_stato_studio_button_pressed)
		print("HUD: Segnale CHIUDI PANNELLO STATO STUDIO BUTTON collegato.")

	pannello_stato_studio.visible = false # Assicurati che il pannello sia nascosto all'avvio
	print("HUD: Inizializzazione completa.")

# ---------------------------------------------------------------------
# CALLBACK STATS MANAGER
# ---------------------------------------------------------------------
func _on_salute_mentale_cambiata(nuova_salute: int) -> void:
	salute_mentale_bar.value = nuova_salute

func _on_soldi_cambiati(nuovi_soldi: int) -> void:
	soldi_quantita_label.text = str(nuovi_soldi)

func _on_tempo_cambiato(nuova_ora: int, nuovi_minuti: int, nuovo_giorno_nome: String) -> void:
	var tempo_formattato = "%02d:%02d" % [nuova_ora, nuovi_minuti]
	orologio_label.text = "%s Giorno %d - %s" % [
		nuovo_giorno_nome,
		stats_manager.giorno,
		tempo_formattato
	]

	_check_phone_popup(nuova_ora, nuovi_minuti, stats_manager.indice_giorno_settimana, stats_manager.giorno)

	# NON AGGIORNARE scritta1_label e counter_esame_label QUI.
	# L'aggiornamento avviene quando il pannello dello stato studio viene aperto (vedi _aggiorna_percentuali_stato_studio).

func _on_evento_casuale_triggerato(tipo_evento: String, messaggio: String, importo: int) -> void:
	var full_message = "Evento: %s! %s" % [tipo_evento, messaggio]
	if importo != 0:
		full_message += " (Importo: %s%d$)" % ["+" if importo > 0 else "", importo]

	notifica_messaggio_label.text = full_message
	notifica_messaggio_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.5)
	tween.finished.connect(func(): notifica_messaggio_label.text = "")

func _on_letto_pronto(letto_node_ref: Area2D) -> void:
	if is_instance_valid(letto_node_ref) and not letto_node_ref.letto_interagito.is_connected(_on_letto_interagito):
		letto_node_ref.letto_interagito.connect(_on_letto_interagito)

func _on_letto_interagito(messaggio: String, successo: bool) -> void:
	notifica_messaggio_label.text = messaggio
	notifica_messaggio_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): notifica_messaggio_label.text = "")

# ---------------------------------------------------------------------
# TELEFONO
# ---------------------------------------------------------------------
func _check_phone_popup(ora: int, minuti: int, giorno_della_settimana: int, giorno: int) -> void:
	if giorno != last_popup_day:
		phone_shown = false

	if not phone_shown and ora == 8 and minuti == 5 and giorno_della_settimana < 5:
		phone_shown = true
		last_popup_day = giorno
		phone_popup.visible = true
		print("HUD: Popup telefono mostrato alle ", ora, ":", minuti)

func _on_chiudi_button_pressed() -> void: # Questo è il chiudi del telefono
	phone_popup.visible = false
	print("HUD: Popup telefono chiuso.")

# ---------------------------------------------------------------------
# MENU PAUSA
# ---------------------------------------------------------------------
func _on_impostazioni_button_pressed() -> void:
	menu_pause.visible = true
	get_tree().paused = true
	print("HUD: Impostazioni aperte, gioco in pausa.")

func _on_riprendi_button_pressed() -> void:
	menu_pause.visible = false
	get_tree().paused = false
	print("HUD: Riprendi premuto, gioco ripreso.")

func _on_torna_al_menu_button_pressed() -> void:
	get_tree().paused = false
	print("HUD: Torna al menu premuto, cambio scena...")
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")

# ---------------------------------------------------------------------
# STATO STUDIO
# ---------------------------------------------------------------------
func _on_stato_studio_button_pressed() -> void:
	pannello_stato_studio.visible = true
	chiudi_pannello_stato_studio_button.visible = true
	get_tree().paused = true # Metti in pausa il gioco quando il pannello è aperto
	_aggiorna_percentuali_stato_studio() # Aggiorna le percentuali E le nuove label quando il pannello viene aperto
	print("HUD: Pannello stato studio aperto.")

func _on_chiudi_pannello_stato_studio_button_pressed() -> void:
	pannello_stato_studio.visible = false
	chiudi_pannello_stato_studio_button.visible = false
	get_tree().paused = false # Riprendi il gioco quando il pannello viene chiuso
	print("HUD: Pannello stato studio chiuso.")

func _aggiorna_percentuali_stato_studio() -> void:
	if is_instance_valid(stats_manager):
		label_stato_analisi.text = "Analisi: %d%%" % stats_manager.statoAnalisi
		label_stato_programmazione.text = "Programmazione: %d%%" % stats_manager.statoProgrammazione

		# NUOVO: Aggiorna le label "scritta1" e "CounterEsame"
		if is_instance_valid(scritta1_label):
			scritta1_label.text = str(stats_manager.giorno) + "° giorno"

		if is_instance_valid(counter_esame_label):
			var giorni_rimanenti = GIORNO_ESAME - stats_manager.giorno
			counter_esame_label.text = "Mancano " + str(max(0, giorni_rimanenti)) + " giorni all'esame"

		print("HUD: Percentuali studio e stato agenda aggiornate da StatsManager.")
	else:
		print("HUD ERRORE: impossibile aggiornare percentuali e stato agenda, StatsManager non valido.")
