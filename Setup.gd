# Jam Timer
# Copyright 2022 (c) Drentsoft Games Ltd

extends Control

var alarms = {}

var show_millis: bool = false

onready var bg_panel = $BGPanel
onready var settings = $Settings

onready var hours = $Settings/HBoxContainer/Hours
onready var mins = $Settings/HBoxContainer/Mins
onready var sec = $Settings/HBoxContainer/Sec

onready var timer_label = $Settings/TimerLabel

onready var alarm_drop = $Settings/Alarm
onready var alarm_preview = $AlarmPreview
onready var trans_bg = $Settings/TransparentBG
onready var timer = $JamTimer

func _ready():
	get_tree().get_root().set_transparent_background(trans_bg.pressed)
	timer.hide()
	load_alarms()
	_on_3Hours_pressed()

func load_alarms():
	alarms["alarm1.wav"] = load("res://audio/alarms/alarm1.wav")
	alarms["alarme.ogg"] = load("res://audio/alarms/alarme.ogg")
	alarms["dootdoot.mp3"] = load("res://audio/alarms/dootdoot.mp3")
#	var dir = Directory.new()
#	var err = dir.open("res://audio/alarms")
#	assert(err == OK)
#	dir.list_dir_begin(true, true)
#	var f = dir.get_next()
#	while f != "":
#		if f.ends_with(".import"):
#			f = dir.get_next()
#			continue
#		var alarm = load("%s/%s" % [dir.get_current_dir(), f])
#		alarms[f] = alarm
#		f = dir.get_next()
	#dir.list_dir_end()
	alarm_drop.add_item("No Alarm")
	for alarm in alarms.keys():
		alarm_drop.add_item(alarm)

func set_preview_audio(id):
	print_debug("Want to preview audio %s" %id)
	if id > -1:
		alarm_preview.stream = alarms.get(alarms.keys()[id])
	else:
		alarm_preview.stream = null

func _on_3Hours_pressed():
	timer.set_time_left(10800.0) # 3 hours in seconds
	timer_label.text = timer.get_time_left_text(timer.time_left)

func _on_SetCustom_pressed():
	timer.set_time_left((hours.value * 3600.0) + (mins.value * 60.0) + sec.value)
	timer_label.text = timer.get_time_left_text(timer.time_left)

func _on_Alarm_item_selected(index):
	set_preview_audio(index - 1)

func _on_Preview_pressed():
	alarm_preview.play()

func _on_TransparentBG_toggled(button_pressed):
	get_tree().get_root().set_transparent_background(button_pressed)

func _on_ShowTimer_pressed():
	settings.hide()
	bg_panel.hide()
	timer.show()
	if alarm_drop.get_selected_id() > 0:
		timer.alarm.stream = alarms.get(alarms.keys()[alarm_drop.get_selected_id() - 1])

func _on_Stop_pressed():
	settings.show()
	bg_panel.show()
