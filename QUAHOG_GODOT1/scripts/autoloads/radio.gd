extends Node

# The Narrows radio — station playlists (WHALE / The Rage / The Anvil / Maré Alta)
# loaded from a committed manifest so it works in the Web export (no runtime
# DirAccess scanning). Drop new .mp3s into assets/audio/music/radio/<station>/
# and regenerate the manifest to add them. OFF = -1.

const MANIFEST: = "res://assets/audio/music/radio/manifest.json"

signal station_changed(index: int, station_name: String)
signal now_playing(title: String)

var stations: Array = []       # [{key, name, tracks:[res:// paths]}]
var current: int = -1          # -1 = OFF
var muted: bool = false

var _player: AudioStreamPlayer
var _order: Array = []
var _order_i: int = 0


func _ready() -> void :
    _player = AudioStreamPlayer.new()
    _player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
    # The web export is a NO-THREADS build. Audio must be routed through the Web
    # Audio worklet via PLAYBACK_TYPE_STREAM (same as the car engine audio, which
    # works); the default type mixes on the main thread and aborts the WASM
    # runtime when streaming a multi-MB mp3 — that was the radio "force close".
    _player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    _player.finished.connect(_on_finished)
    add_child(_player)
    _load_manifest()


func _load_manifest() -> void :
    if not FileAccess.file_exists(MANIFEST):
        return
    var f: = FileAccess.open(MANIFEST, FileAccess.READ)
    if f == null:
        return
    var data: Variant = JSON.parse_string(f.get_as_text())
    if data is Array:
        stations = data


func reload_content() -> void:
    stations.clear()
    _load_manifest()


func station_count() -> int:
    return stations.size()


func station_name(i: int) -> String:
    if i < 0 or i >= stations.size():
        return "OFF"
    return str(stations[i].get("name", "?"))


func set_station(i: int) -> void :
    current = i
    if i < 0 or i >= stations.size():
        current = -1
        _player.stop()
        _player.stream = null
        _set_score_muted(false)
        station_changed.emit(-1, "OFF")
        now_playing.emit("")
        return
    _set_score_muted(true)
    _build_order()
    station_changed.emit(current, station_name(current))
    _play_current()


func _set_score_muted(muted: bool) -> void :
    var am: = get_node_or_null("/root/AudioManager")
    if am and am.has_method("set_score_muted"):
        am.set_score_muted(muted)


# OFF -> station 0 -> 1 ... -> last -> OFF
func cycle() -> void :
    var nxt: = current + 1
    set_station(nxt if nxt < stations.size() else -1)


func toggle_mute() -> void :
    muted = not muted
    _player.volume_db = -80.0 if muted else 0.0


func _build_order() -> void :
    var n: int = (stations[current]["tracks"] as Array).size()
    _order = range(n)
    _order.shuffle()
    _order_i = 0


# Pick and play the next loadable track. Loop-based (NOT recursive): a station
# whose tracks all fail to load must not recurse _play_current -> _advance ->
# _play_current forever and crash the web export — we try each track at most once.
func _play_current() -> void :
    if current < 0 or current >= stations.size():
        return
    var tracks: Array = stations[current]["tracks"]
    if tracks.is_empty() or _order.is_empty():
        return
    var tried: int = 0
    while tried < _order.size():
        var path: String = str(tracks[_order[_order_i]])
        var st: Variant = load(path) if ResourceLoader.exists(path) else null
        if st != null:
            _player.stream = st
            _player.volume_db = -80.0 if muted else 0.0
            _player.play()
            now_playing.emit(_title(path))
            return
        # this track is unloadable — step to the next and try again
        _step_order()
        tried += 1
    # nothing on this station loaded; go quiet rather than spin
    now_playing.emit("")


func _step_order() -> void :
    _order_i += 1
    if _order_i >= _order.size():
        _build_order()


func _advance() -> void :
    if current < 0 or _order.is_empty():
        return
    _step_order()
    _play_current()


func _on_finished() -> void :
    if current >= 0:
        _advance()


func _title(path: String) -> String:
    return path.get_file().get_basename().replace("_", " ")
