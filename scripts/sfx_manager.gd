class_name SfxManager
extends Node

const SAMPLE_RATE := 22050

var muted: bool = false:
	set(value):
		muted = value
		_apply_volume()

var volume_percent: int = 100:
	set(value):
		volume_percent = clampi(value, 0, 100)
		_apply_volume()

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_build_streams()
	_apply_volume()

func _apply_volume() -> void:
	var db := -80.0
	if not muted and volume_percent > 0:
		var linear := clampf(float(volume_percent) / 100.0, 0.01, 1.0)
		db = linear_to_db(linear) - 4.0
	for p in _players:
		if is_instance_valid(p):
			p.volume_db = db

func _build_streams() -> void:
	_streams["slice"] = _make_tone_sweep(840.0, 240.0, 0.11, 0.36, true)
	_streams["slice_beam"] = _make_tone_sweep(620.0, 180.0, 0.13, 0.42, true)
	_streams["slice_rope"] = _make_tone_sweep(980.0, 340.0, 0.09, 0.35, true)
	_streams["ui_click"] = _make_tone_sweep(680.0, 880.0, 0.045, 0.25, false)
	_streams["collect"] = _make_tone_sweep(520.0, 1040.0, 0.16, 0.45, false)
	_streams["chain"] = _make_tone_sweep(310.0, 740.0, 0.22, 0.45, false)
	_streams["bounce"] = _make_tone_sweep(240.0, 160.0, 0.06, 0.20, false)
	_streams["win"] = _make_chord([523.25, 659.25, 783.99, 1046.5], 0.48, 0.42)
	_streams["fail"] = _make_tone_sweep(260.0, 110.0, 0.35, 0.45, false)

func play(sound_name: String, pitch_scale: float = 1.0) -> void:
	if muted or volume_percent <= 0:
		return
	if DisplayServer.get_name() == "headless":
		return
	if not _streams.has(sound_name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[sound_name]
			p.pitch_scale = pitch_scale
			p.play()
			return
	_players[0].stream = _streams[sound_name]
	_players[0].pitch_scale = pitch_scale
	_players[0].play()

func _make_tone_sweep(f_start: float, f_end: float, duration: float, amp: float, add_noise: bool) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(max(count - 1, 1))
		var env := sin(t * PI) * (1.0 - t * 0.4)
		var freq := lerpf(f_start, f_end, t)
		phase += TAU * freq / float(SAMPLE_RATE)
		var sample := sin(phase)
		if add_noise:
			sample = sample * 0.62 + randf_range(-0.38, 0.38)
		var val := int(clampf(sample * env * amp, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav

func _make_chord(freqs: Array, duration: float, amp: float) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(max(count - 1, 1))
		var env := (1.0 - t) * minf(t * 12.0, 1.0)
		var sum := 0.0
		for idx in range(freqs.size()):
			var f: float = freqs[idx]
			var delay := float(idx) * 0.06
			if t * duration >= delay:
				sum += sin(TAU * f * (float(i) / float(SAMPLE_RATE)))
		sum /= float(max(freqs.size(), 1))
		var val := int(clampf(sum * env * amp, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav
