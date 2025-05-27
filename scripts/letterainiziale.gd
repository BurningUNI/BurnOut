extends CanvasLayer

@onready var testo_lettera = $TextureRect/TestoLettera
@onready var label_avvio = $LabelAvvio
@onready var timer_lampeggio = $TimerLampeggio

var testo_finito := false

func _ready():
	label_avvio.visible = false
	timer_lampeggio.stop()
	label_avvio.text = "Premi SPAZIO per iniziare"

func _process(_delta):
	if not testo_finito and testo_lettera.carattere_attuale >= testo_lettera.testo_completo.length():
		testo_finito = true
		label_avvio.visible = true
		timer_lampeggio.start()

func _on_TimerLampeggio_timeout():
	print("Timer chiamato")  # <-- Controllo
	label_avvio.visible = not label_avvio.visible

func _unhandled_input(event):
	if testo_finito and event.is_action_pressed("interact"):
		get_tree().change_scene_to_file("res://scenes/room.tscn")  # Cambia con il tuo percorso reale


func _on_timer_lampeggio_timeout() -> void:
	pass # Replace with function body.
