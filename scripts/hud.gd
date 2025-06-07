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
@onready var stats_manager: Node = get_node("/root/StatsManager")

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
	print("HUD: pause_mode impostato su PROCESS (2)")

	# DEBUG nodi
	print("DEBUG: riprendi_button = ", riprendi_button)
	print("DEBUG: torna_al_menu_button = ", torna_al_menu_button)
	print("DEBUG: impostazioni_button = ", impostazioni_button)
	print("DEBUG: menu_pause = ", menu_pause)

	# Collegamenti al StatsManager
	stats_manager.salute_mentale_cambiata.connect(_on_salute_mentale_cambiata)
	stats_manager.soldi_cambiati.connect(_on_soldi_cambiati)
	stats_manager.tempo_cambiato.connect(_on_tempo_cambiato)
	stats_manager.evento_casuale_triggerato.connect(_on_evento_casuale_triggerato)
	stats_manager.letto_pronto.connect(_on_letto_pronto)

	_on_salute_mentale_cambiata(stats_manager.salute_mentale)
	_on_soldi_cambiati(stats_manager.soldi)
	_on_tempo_cambiato(
		stats_manager.ora,
		stats_manager.minuti,
		stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana]
	)

	# TELEFONO
	if not chiudi_button.pressed.is_connected(_on_chiudi_button_pressed):
		chiudi_button.pressed.connect(_on_chiudi_button_pressed)
		print("Segnale CHIUDI collegato")
	phone_popup.visible = false

	# MENU PAUSA
	if not impostazioni_button.pressed.is_connected(_on_impostazioni_button_pressed):
		impostazioni_button.pressed.connect(_on_impostazioni_button_pressed)
		print("Segnale IMPOSTAZIONI collegato")

	if not riprendi_button.pressed.is_connected(_on_riprendi_button_pressed):
		riprendi_button.pressed.connect(_on_riprendi_button_pressed)
		print("Segnale RIPRENDI collegato")

	if not torna_al_menu_button.pressed.is_connected(_on_torna_al_menu_button_pressed):
		torna_al_menu_button.pressed.connect(_on_torna_al_menu_button_pressed)
		print("Segnale TORNA AL MENU collegato")

	menu_pause.visible = false
	get_tree().paused = false

# ---------------------------------------------------------------------
# CALLBACK STATS MANAGER
# ---------------------------------------------------------------------
func _on_salute_mentale_cambiata(nuova_salute: int) -> void:
	print("Salute mentale aggiornata: ", nuova_salute)
	salute_mentale_bar.value = nuova_salute

func _on_soldi_cambiati(nuovi_soldi: int) -> void:
	print("Soldi aggiornati: ", nuovi_soldi)
	soldi_quantita_label.text = str(nuovi_soldi)

func _on_tempo_cambiato(nuova_ora: int, nuovi_minuti: int, nuovo_giorno_nome: String) -> void:
	var tempo_formattato = "%02d:%02d" % [nuova_ora, nuovi_minuti]
	orologio_label.text = "%s %s" % [nuovo_giorno_nome, tempo_formattato]
	print("Tempo aggiornato: ", orologio_label.text)

	_check_phone_popup(nuova_ora, nuovi_minuti)

func _on_evento_casuale_triggerato(tipo_evento: String, messaggio: String, importo: int) -> void:
	var full_message = "Evento: %s! %s" % [tipo_evento, messaggio]
	if importo != 0:
		full_message += " (Importo: %d$)" % importo

	notifica_messaggio_label.text = full_message
	notifica_messaggio_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.5)

	print("Evento casuale mostrato: ", full_message)

func _on_letto_pronto(letto_node_ref: Area2D) -> void:
	if is_instance_valid(letto_node_ref):
		letto_node_ref.connect("letto_interagito", _on_letto_interagito)
		print("HUD: Segnale 'letto_interagito' collegato con successo.")
	else:
		print("HUD ERROR: Nodo letto non valido!")

func _on_letto_interagito(messaggio: String, successo: bool) -> void:
	notifica_messaggio_label.text = messaggio
	notifica_messaggio_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.0)

	print("Interazione letto: ", messaggio)

# ---------------------------------------------------------------------
# TELEFONO
# ---------------------------------------------------------------------
func _check_phone_popup(ora: int, minuti: int) -> void:
	if not phone_shown and minuti == 5:
		phone_shown = true
		phone_popup.visible = true
		print("Popup telefono mostrato alle ", ora, ":", minuti)

func _on_chiudi_button_pressed() -> void:
	phone_popup.visible = false
	print("Popup telefono chiuso")

# ---------------------------------------------------------------------
# MENU PAUSA
# ---------------------------------------------------------------------
func _on_impostazioni_button_pressed() -> void:
	menu_pause.visible = true
	get_tree().paused = true
	print("Impostazioni aperte, gioco in pausa")

func _on_riprendi_button_pressed() -> void:
	menu_pause.visible = false
	get_tree().paused = false
	print("Riprendi premuto, gioco ripreso")

func _on_torna_al_menu_button_pressed() -> void:
	get_tree().paused = false
	print("Torna al menu premuto, cambio scena...")
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
