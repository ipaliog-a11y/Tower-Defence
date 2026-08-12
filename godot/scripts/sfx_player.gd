class_name SfxPlayer
extends Node
## Lightweight procedural SFX — no asset pack required.

var _players: Array[AudioStreamPlayer] = []
var _i: int = 0
const POOL := 8


func _ready() -> void:
	for j in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)


func play_event(kind: String) -> void:
	match kind:
		"place":
			_play(_tone(520.0, 0.05, 0.25) )
		"link":
			_play(_tone(380.0, 0.07, 0.22))
		"wireless":
			_play(_sweep(300.0, 700.0, 0.1, 0.2))
		"wave":
			_play(_sweep(200.0, 450.0, 0.15, 0.28))
		"hit":
			_play(_noise_blip(0.03, 0.12, 900.0))
		"kill":
			_play(_tone(660.0, 0.06, 0.22))
			_play_delayed(_tone(880.0, 0.05, 0.18), 0.04)
		"burst":
			_play(_sweep(150.0, 900.0, 0.18, 0.35))
		"spike_on":
			_play(_tone(240.0, 0.08, 0.25))
		"spike_off":
			_play(_tone(180.0, 0.06, 0.18))
		"cut":
			_play(_noise_blip(0.08, 0.3, 200.0))
		"fortify":
			_play(_tone(500.0, 0.06, 0.2))
			_play_delayed(_tone(750.0, 0.05, 0.18), 0.05)
		"channel":
			_play(_tone(160.0, 0.1, 0.15))
		"channel_break":
			_play(_sweep(600.0, 250.0, 0.1, 0.25))
		"hack_windup":
			# Rising digital whine — the audible warning before a pulse lands.
			_play(_sweep(220.0, 1200.0, 0.5, 0.22))
		"hack":
			# Everything powering down at once.
			_play(_sweep(900.0, 90.0, 0.4, 0.34))
			_play_delayed(_noise_blip(0.12, 0.26, 160.0), 0.06)
		"hack_link":
			_play(_noise_blip(0.05, 0.16, 1400.0))
		"leak":
			_play(_tone(120.0, 0.14, 0.3))
		"win":
			_play(_sweep(400.0, 800.0, 0.2, 0.3))
			_play_delayed(_tone(1000.0, 0.12, 0.25), 0.15)
		"lose":
			_play(_sweep(400.0, 80.0, 0.35, 0.35))
		"ui":
			_play(_tone(440.0, 0.03, 0.12))
		"error":
			_play(_tone(140.0, 0.08, 0.2))
		_:
			pass


func _play(stream: AudioStream) -> void:
	var p: AudioStreamPlayer = _players[_i]
	_i = (_i + 1) % POOL
	p.stream = stream
	p.play()


func _play_delayed(stream: AudioStream, delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(func(): _play(stream))


func _tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := exp(-3.5 * t / duration) * (1.0 - t / duration)
		var s := int(sin(t * freq * TAU) * 32767.0 * volume * env)
		s = clampi(s, -32767, 32767)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return _wav(data, rate)


func _sweep(f0: float, f1: float, duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(rate)
		var u := t / duration
		var freq := lerpf(f0, f1, u)
		phase += freq / float(rate)
		var env := (1.0 - u) * exp(-2.0 * u)
		var s := int(sin(phase * TAU) * 32767.0 * volume * env)
		s = clampi(s, -32767, 32767)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return _wav(data, rate)


func _noise_blip(duration: float, volume: float, tone_mix: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := exp(-8.0 * t / maxf(duration, 0.001))
		var noise := (randf() * 2.0 - 1.0) * 0.55
		var tone := sin(t * tone_mix * TAU) * 0.45
		var s := int((noise + tone) * 32767.0 * volume * env)
		s = clampi(s, -32767, 32767)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return _wav(data, rate)


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
