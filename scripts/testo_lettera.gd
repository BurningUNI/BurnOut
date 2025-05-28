extends RichTextLabel

@export var testo_completo := ""
@export var velocità_scrittura := 0.03
@export var velocità_scrittura_veloce := 0.001 # Una velocità molto alta per l'istantaneo

var carattere_attuale := 0
var timer := 0.0
var mouse_premuto := false # Nuova variabile per tenere traccia dello stato del mouse

func _ready():
	bbcode_enabled = true
	text = ""
	carattere_attuale = 0
	timer = 0.0

func _process(delta):
	var velocità_attuale = velocità_scrittura

	# Se il mouse sinistro è premuto, usa la velocità veloce
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		velocità_attuale = velocità_scrittura_veloce

	if carattere_attuale < testo_completo.length():
		timer += delta
		if timer >= velocità_attuale:
			text += testo_completo[carattere_attuale]
			carattere_attuale += 1
			timer = 0.0

func _unhandled_input(event):
	# Aggiorna lo stato del mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_premuto = event.pressed
