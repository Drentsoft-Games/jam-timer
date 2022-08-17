# Jam Timer
# Copyright 2022 (c) Drentsoft Games Ltd

extends Control

const ACCEPTED_AUDIO_FORMATS = [".wav", ".ogg", ".mp3"]

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
	#load_alarms_from_folder("res://audio/alarms")
	load_alarms_from_folder("./") # Allow for custom audio if put in the folder with the 
	alarm_drop.add_item("No Alarm")
	for alarm in alarms.keys():
		alarm_drop.add_item(alarm)
	if alarm_drop.get_item_count() > 1:
		alarm_drop.select(1)
		_on_Alarm_item_selected(1)

func load_alarms_from_folder(path: String):
	var dir = Directory.new()
	var err = dir.open(path)
	assert(err == OK)
	dir.list_dir_begin(true, true)
	var f = dir.get_next()
	while f != "":
		if f.ends_with(".import"):
			f = dir.get_next()
			continue
		var accepted: bool = false
		for format in ACCEPTED_AUDIO_FORMATS:
			if f.ends_with(format):
				accepted = true
				break
		if !accepted:
			f = dir.get_next()
			continue
		var alarm
		if path.begins_with("res://"):
			alarm = load("%s/%s" % [dir.get_current_dir(), f])
		else:
			alarm = load_custom_audio(f, "%s/" % dir.get_current_dir())
		if alarm:
			alarms[f] = alarm
		f = dir.get_next()
	dir.list_dir_end()

func load_custom_audio(f, path) -> AudioStream:
	print("Trying to load custom audio file %s" % f)
	var file = File.new()
	file.open("%s/%s" % [path, f], File.READ)
	if f.ends_with(".wav"):
		return load_wave(file)
	if f.ends_with(".ogg"):
		return load_ogg(file)
	if f.ends_with(".mp3"):
		return load_mp3(file)
	return null

func load_wave(file: File) -> AudioStream:
	var bytes = file.get_buffer(file.get_len())
	var stream = AudioStreamSample.new()
	for i in range(0, 100):
		var head = str(char(bytes[i])+char(bytes[i+1])+char(bytes[i+2])+char(bytes[i+3]))
		if head == "RIFF":
			print("RIFF OK at bytes %s-%s" % [i, (i+3)])
		if head == "WAVE":
			print("WAVE OK at bytes %s-%s" % [i, (i+3)])
		if head == "fmt ":
			print("fmt OK at bytes %s-%s" % [i, (i+3)])
			var fmt_sub_chunk_size = bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)
			print("Format subchunk size: %s" % fmt_sub_chunk_size)
			var fsc0 = i+8
			var format_code = bytes[fsc0] + (bytes[fsc0+1] << 8)
			var format_name
			if format_code == 0: format_name = "8_BITS"
			elif format_code == 1: format_name = "16_BITS"
			elif format_code == 2: format_name = "IMA_ADPCM"
			print("Format: %s %s" % [format_code, format_name])
			stream.format = format_code
			
			var channel_num = bytes[fsc0+2] + (bytes[fsc0+3] << 8)
			print("Number of channels: %s" % channel_num)
			if channel_num == 2: stream.stereo = true
			
			var sample_rate = bytes[fsc0+4] + (bytes[fsc0+5] << 8) + (bytes[fsc0+6] << 16) + (bytes[fsc0+7] << 24)
			print("Sample rate: %s" % sample_rate)
			stream.mix_rate = sample_rate
			
			var byte_rate = bytes[fsc0+8] + (bytes[fsc0+9] << 8) + (bytes[fsc0+10] << 16) + (bytes[fsc0+11] << 24)
			print("Byte rate: %s" % byte_rate)
			
			var bits_sample_channel = bytes[fsc0+12] + (bytes[fsc0+13] << 8)
			print("Bits per sample * channe; / 8: %s" % bits_sample_channel)
			
			var bits_per_sample = bytes[fsc0+14] + (bytes[fsc0+15] << 8)
			print("Bits per sample: %s" % bits_per_sample)
		
		if head == "data":
			var audio_data_size = bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)
			print("Audio data/stream size is %s bytes" % audio_data_size)
			var data_entry_point = (i+8)
			print("Audio starts at byte %s" % data_entry_point)
			stream.data = bytes.subarray(data_entry_point, data_entry_point + audio_data_size-1)
		var sample_num = stream.data.size() / 4
		stream.loop_end = 0#sample_num
		stream.loop_mode = 0
	return stream
	
func load_ogg(file: File) -> AudioStream:
	var stream = AudioStreamOGGVorbis.new()
	stream.loop = false
	stream.data = file.get_buffer(file.get_len())
	return stream

func load_mp3(file: File) -> AudioStream:
	var stream = AudioStreamMP3.new()
	stream.loop = false
	stream.data = file.get_buffer(file.get_len())
	return stream

func set_preview_audio(id):
	print_debug("Want to preview audio %s" %id)
	if id > -1:
		alarm_preview.stream = alarms.get(alarms.keys()[id])
	else:
		alarm_preview.stream = null

func _on_3Hours_pressed():
	timer.set_time_left(10800.0) # 3 hours in seconds
	timer_label.text = timer.get_time_left_text(timer.time_left)

func _on_24Hours_pressed():
	timer.set_time_left(172800.0) # 3 hours in seconds
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
