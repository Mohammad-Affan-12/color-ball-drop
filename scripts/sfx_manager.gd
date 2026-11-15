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

var music_muted: bool = false:
	set(value):
		music_muted = value
		_apply_music_volume()

var music_volume_percent: int = 75:
	set(value):
		music_volume_percent = clampi(value, 0, 100)
		_apply_music_volume()

var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null
var _streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -18.0
	add_child(_music_player)

	_build_streams()
	_apply_volume()
	_apply_music_volume()

func _apply_volume() -> void:
	var db := -80.0
	if not muted and volume_percent > 0:
		var linear := clampf(float(volume_percent) / 100.0, 0.01, 1.0)
		db = linear_to_db(linear) - 4.0
	for p in _players:
		if is_instance_valid(p):
			p.volume_db = db

func _apply_music_volume() -> void:
	if _music_player == null or not is_instance_valid(_music_player):
		return
	if music_muted or music_volume_percent <= 0 or DisplayServer.get_name() == "headless":
		_music_player.volume_db = -80.0
		if _music_player.playing:
			_music_player.stop()
	else:
		var linear := clampf(float(music_volume_percent) / 100.0, 0.01, 1.0)
		_music_player.volume_db = linear_to_db(linear) - 15.0
		if not _music_player.playing and _streams.has("music_loop"):
			_music_player.stream = _streams["music_loop"]
			_music_player.play()

func _build_streams() -> void:
	_streams["swipe"] = _make_tone_sweep(540.0, 760.0, 0.06, 0.18, true)
	_streams["slice"] = _make_tone_sweep(840.0, 240.0, 0.11, 0.36, true)
	_streams["slice_beam"] = _make_tone_sweep(620.0, 180.0, 0.13, 0.42, true)
	_streams["slice_rope"] = _make_tone_sweep(980.0, 340.0, 0.09, 0.35, true)
	_streams["reject"] = _make_tone_sweep(190.0, 145.0, 0.12, 0.38, true)
	_streams["ui_click"] = _make_tone_sweep(680.0, 880.0, 0.045, 0.25, false)
	_streams["collect"] = _make_tone_sweep(520.0, 1040.0, 0.16, 0.45, false)
	_streams["chain"] = _make_tone_sweep(310.0, 740.0, 0.22, 0.45, false)
	_streams["gate"] = _make_tone_sweep(660.0, 990.0, 0.14, 0.32, false)
	_streams["portal"] = _make_tone_sweep(420.0, 1180.0, 0.18, 0.36, false)
	_streams["bounce"] = _make_tone_sweep(320.0, 480.0, 0.07, 0.26, false)
	_streams["star"] = _make_tone_sweep(784.0, 1174.66, 0.15, 0.38, false)
	_streams["win"] = _make_chord([523.25, 659.25, 783.99, 1046.5], 0.48, 0.42)
	_streams["fail"] = _make_tone_sweep(260.0, 110.0, 0.35, 0.45, false)
	_streams["music_loop"] = _make_ambient_loop(3.2, 0.22)

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

func _make_ambient_loop(duration: float, amp: float) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	var notes := [261.63, 329.63, 392.00, 493.88]
	for i in range(count):
		var sec := float(i) / float(SAMPLE_RATE)
		var lfo := 0.75 + 0.25 * sin(TAU * sec / duration)
		var sum := 0.0
		for f in notes:
			sum += sin(TAU * float(f) * sec)
		sum /= float(notes.size())
		var val := int(clampf(sum * lfo * amp, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = count
	wav.data = data
	return wav
