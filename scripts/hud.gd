# HUD.gd
extends CanvasLayer   # Il nodo radice della scena HUD.tscn DEVE essere di tipo CanvasLayer

# ---------------------------------------------------------------------
# NODI ESISTENTI (statistiche, orologio, ecc.)
# ---------------------------------------------------------------------
@onready var statistiche_sfondo: Panel          = $StatisticheSfondo
@onready var salute_mentale_bar: TextureProgressBar = $StatisticheSfondo/SaluteMentaleBar
@onready var soldi_quantita_label: Label        = $StatisticheSfondo/SoldiIcona/QuantitaSoldi
@onready var orologio_label: Label              = $StatisticheSfondo/OrologioLabel
@onready var notifica_messaggio_label: Label    = $NotificaMessaggioLabel
@onready var stats_manager: Node                = get_node("/root/StatsManager")

# ---------------------------------------------------------------------
# --- TELEFONO (nuovi riferimenti UI) ---------------------------------
# ---------------------------------------------------------------------
@onready var phone_popup: Control  = $PhonePopup
@onready var accept_button: Button = $PhonePopup/AcceptButton
@onready var reject_button: Button = $PhonePopup/RejectButton

var phone_shown: bool = false   # tiene traccia se il telefono è già apparso
# ---------------------------------------------------------------------

func _ready():
	# Collegamenti già presenti
	stats_manager.salute_mentale_cambiata.connect(_on_salute_mentale_cambiata)
	stats_manager.soldi_cambiati.connect(_on_soldi_cambiati)
	stats_manager.tempo_cambiato.connect(_on_tempo_cambiato)
	stats_manager.evento_casuale_triggerato.connect(_on_evento_casuale_triggerato)
	stats_manager.letto_pronto.connect(_on_letto_pronto)

	_on_salute_mentale_cambiata(stats_manager.salute_mentale)
	_on_soldi_cambiati(stats_manager.soldi)
	_on_tempo_cambiato(stats_manager.ora, stats_manager.minuti, stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana])

	# --- TELEFONO: collega i bottoni ---
	accept_button.pressed.connect(_on_accept_button_pressed)
	reject_button.pressed.connect(_on_reject_button_pressed)
	phone_popup.visible = false


# -----------------------------------------------------------------
# --- CALLBACK ESISTENTI DELLO STATS MANAGER ----------------------
# -----------------------------------------------------------------
func _on_salute_mentale_cambiata(nuova_salute: int) -> void:
	salute_mentale_bar.value = nuova_salute

func _on_soldi_cambiati(nuovi_soldi: int) -> void:
	soldi_quantita_label.text = str(nuovi_soldi)

func _on_tempo_cambiato(nuova_ora: int, nuovi_minuti: int, nuovo_giorno_nome: String) -> void:
	var tempo_formattato = "%02d:%02d" % [nuova_ora, nuovi_minuti]
	orologio_label.text = "%s %s" % [nuovo_giorno_nome, tempo_formattato]

	# --- TELEFONO: controlla se è il momento di mostrarlo
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

func _on_letto_pronto(letto_node_ref: Area2D) -> void:
	if is_instance_valid(letto_node_ref):
		letto_node_ref.connect("letto_interagito", _on_letto_interagito)
		print("HUD: Segnale 'letto_interagito' collegato con successo tramite StatsManager.")
	else:
		print("HUD ERROR: Il riferimento al nodo Letto passato da StatsManager non è valido.")

func _on_letto_interagito(messaggio: String, successo: bool) -> void:
	notifica_messaggio_label.text = messaggio
	notifica_messaggio_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.0)


# -----------------------------------------------------------------
# --- SEZIONE TELEFONO: funzioni dedicate -------------------------
# -----------------------------------------------------------------
func _check_phone_popup(ora: int, minuti: int) -> void:
	# Mostra il telefono al minuto 5, una sola volta
	if not phone_shown and minuti == 5:
		phone_shown = true
		phone_popup.visible = true

func _on_accept_button_pressed() -> void:
	phone_popup.visible = false
	print("Richiesta accettata")
	# TODO: aggiungi qui la logica da eseguire quando l’utente accetta

func _on_reject_button_pressed() -> void:
	phone_popup.visible = false
	print("Richiesta rifiutata")
	# Nessuna azione extra in caso di rifiuto (per ora)
