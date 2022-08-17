# Jam Timer
# Copyright 2022 (c) Drentsoft Games Ltd

extends Control

signal time_adjusted
signal timeout

var time_left: float
var modified_time: float = 0.0

var running: bool = false

var alarm_triggered: bool = false
var show_controls: bool = true

onready var timer_label = $HBoxContainer/TimerLabel
onready var controls = $HBoxContainer/Controls
onready var mute = $HBoxContainer/Controls/Mute
onready var alarm = $TimeoutAlarm

func _ready():
	connect("timeout", self, "on_timeout")
	connect("time_adjusted", self, "on_time_adjusted")
	mute.visible = false
	timer_label.text = get_time_left_text(time_left)

func set_time_left(time: float):
	time_left = time
	timer_label.text = get_time_left_text(time_left)
	print_debug("Time left set to %s" % time)

func get_time_left_text(time, show_millis: bool = false) -> String:
	var neg: bool = false
	if time < 0.0:
		neg = true
		time = abs(time)
	var time_str = "%02d:%02d:%02d"
	var sec = int(time) % 60
	var mins = int(time / 60.0) % 60
	var hours = int(time / 3600.0) % 24
	var days = (time / 86400.0)
	var millis = fmod(time, 1.0)
	var values = [hours, mins, sec]
	if show_millis:
		values.append(millis)
		time_str += ".%04d"
	if days > 1.0:
		time_str = "%02d:" + time_str
		values.insert(0, days)
	if neg:
		time_str = "-" + time_str
	print(time_str)
	print(values)
	return time_str % values

func _process(delta):
	if running:
		time_left -= delta
		timer_label.text = get_time_left_text(time_left)
		if modified_time > 0.0:
			modified_time -= delta
			if modified_time < 0.0:
				modified_time = 0.0 # Display modified time on the UI
		if time_left <= 0.0:
			if !alarm_triggered:
				emit_signal("timeout")

func _on_Controls_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			show_controls = !show_controls
			for child in controls.get_children():
				child.visible = show_controls
			mute.visible = (alarm_triggered and show_controls)

func _on_StartPause_toggled(button_pressed):
	running = button_pressed
	if alarm_triggered:
		if !running:
			alarm.stop()
		else:
			alarm.play() # Restart after pause

func _on_Mute_pressed():
	pass # Replace with function body.

func _on_Mute_toggled(button_pressed):
	print("Muting?")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Alarm"), button_pressed)

# Returns to setup
func _on_Stop_pressed():
	running = false
	alarm.stop()
	hide()

func on_timeout():
	alarm_triggered = true
	mute.visible = true
	$TimeoutAlarm.play()

func on_time_adjusted():
	timer_label.text = get_time_left_text(time_left)

func _on_TimeoutAlarm_finished():
	if alarm_triggered and running:
		alarm.play() # Just keep repeating

func check_mod_keys():
	var amt = 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		amt = 10.0
	if Input.is_key_pressed(KEY_CONTROL):
		amt *= 5.0 # Might be better at 6 to get full minute adjustments? Maybe 1, 5. 60 rather than 1, 10, 60?
	return amt

func _on_MinusTime_pressed():
	var amt = check_mod_keys()
	time_left -= amt
	emit_signal("time_adjusted")
	if time_left < 0.0 and running and !alarm_triggered:
		emit_signal("timeout")
	modified_time -= amt

func _on_PlusTime_pressed():
	var amt = check_mod_keys()
	time_left += amt
	emit_signal("time_adjusted")
	if time_left > 0.0 and alarm_triggered:
		alarm_triggered = false
		alarm.stop()
	modified_time += amt
