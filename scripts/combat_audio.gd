extends Node3D
## Original deterministic synthesized impact Foley, cached once; no downloads.
var streams := {}
var voices: Array[AudioStreamPlayer3D] = []
var cursor := 0
var played := {}
var muted := false

func _ready() -> void:
	for kind in ["punch", "kick", "heavy", "shield", "shatter", "ice", "dash", "land"]:
		streams[kind] = synthesize(kind)
	for i in 12:
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size = 7
		voice.max_distance = 35
		voice.volume_db = -18
		add_child(voice)
		voices.append(voice)

func synthesize(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var length_ := 0.28 if kind in ["heavy", "shatter", "land"] else 0.16
	var count := int(rate * length_)
	var data := PackedByteArray()
	data.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 713 + kind.hash()
	var low := 0.0
	for i in count:
		var t := float(i) / rate
		var noise := random.randf_range(-1, 1)
		low = lerpf(low, noise, 0.16)
		var bass := sin(TAU * (95 * t - 90 * t * t)) * exp(-t * 27)
		var snap := noise * exp(-t * 95) * 0.36
		var value := bass * 0.65 + low * exp(-t * 30) * 0.4 + snap
		if kind in ["shield", "shatter", "ice"]:
			value = (sin(TAU * 1430 * t) + sin(TAU * 2173 * t) * 0.5) * exp(-t * 32) * 0.24 + noise * exp(-t * 45) * 0.22
		if kind == "dash":
			value = low * sin(PI * t / length_) * exp(-t * 10) * 0.65
		if kind in ["heavy", "land", "kick"]:
			value += sin(TAU * 57 * t) * exp(-t * 19) * 0.25
		value *= minf(1, t * 2000) * minf(1, (length_ - t) * 200)
		data.encode_s16(i * 2, int(clampf(value, -0.92, 0.92) * 22000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream

func impact(kind: String, point: Vector3, strength := 1.0) -> void:
	played[kind] = played.get(kind, 0) + 1
	if muted or voices.is_empty():
		return
	var voice := voices[cursor % voices.size()]
	cursor += 1
	voice.stop()
	voice.position = point
	voice.stream = streams.get(kind, streams.punch)
	voice.volume_db = -14 + clampf(strength, 0, 1.0) * 7
	voice.pitch_scale = 0.93 + (cursor % 4) * 0.045
	voice.play()

func stop_all() -> void:
	for voice in voices:
		voice.stop()
		voice.stream=null
