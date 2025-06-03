extends Control

# Collegamento ai nodi UI
@onready var dialogo_label = $DialogBox/DialogoLabel
@onready var analisi1 = $DialogBox/VBoxContainer/analisi1
@onready var programmazione1 = $DialogBox/VBoxContainer/programmazione1

@onready var domanda_box = $DomandaBox
@onready var domanda_label = $DomandaBox/DomandaLabel
@onready var rispostaA = $DomandaBox/rispostaA
@onready var rispostaB = $DomandaBox/rispostaB

# Variabili del quiz
var domande_correnti = []
var indice_domanda = 0

func _ready():
	# Nasconde il box delle domande
	domanda_box.visible = false
	mostra_scelta_iniziale()

	# Collega i pulsanti delle risposte
	rispostaA.pressed.connect(func(): check_risposta("A"))
	rispostaB.pressed.connect(func(): check_risposta("B"))

func mostra_scelta_iniziale():
	dialogo_label.text = "Scegli un corso:"
	analisi1.visible = true
	programmazione1.visible = true

	analisi1.pressed.connect(start_analisi)
	programmazione1.pressed.connect(start_programmazione)

func start_analisi():
	domande_correnti = [
		{"testo": "Quanto fa la derivata di x^2?", "A": "2x", "B": "x^2", "corretta": "A"},
		{"testo": "Qual è l'integrale di 1/x?", "A": "ln|x|", "B": "1/x^2", "corretta": "A"},
	]
	inizia_domande()

func start_programmazione():
	domande_correnti = [
		{"testo": "Quale parola chiave definisce una funzione in Python?", "A": "def", "B": "func", "corretta": "A"},
		{"testo": "Come si stampa qualcosa in console?", "A": "echo()", "B": "print()", "corretta": "B"},
	]
	inizia_domande()

func inizia_domande():
	indice_domanda = 0
	$DialogBox.visible = false
	domanda_box.visible = true
	mostra_domanda()

func mostra_domanda():
	if indice_domanda < domande_correnti.size():
		var domanda = domande_correnti[indice_domanda]
		domanda_label.text = domanda["testo"]
		rispostaA.text = domanda["A"]
		rispostaB.text = domanda["B"]
	else:
		# Tutte le risposte corrette → cambia scena
		get_tree().change_scene_to_file("res://scenes/room.tscn")

func check_risposta(risposta_scelta):
	var domanda = domande_correnti[indice_domanda]
	if risposta_scelta == domanda["corretta"]:
		indice_domanda += 1
		mostra_domanda()
	else:
		# Risposta sbagliata → messaggio e reset
		dialogo_label.text = "Risposta sbagliata. Riprova."
		$DialogBox.visible = true
		domanda_box.visible = false
