extends Node

## Autoload. Owns the persisted audio settings so they apply at boot
## (not just while the settings screen happens to be open), plus the last
## name the player entered on the title screen.

const SETTINGS_PATH := "user://settings.cfg"
const MIN_DB := -80.0

## ONE default for all four sliders, deliberately.
##
## This used to be a spread - Master 1.0, Music 0.5, SFX 0.8, Ambience 0.4 -
## while every slider in settings.tscn and in the in-match popup was authored at
## value = 1.0. The two never agreed. _ready() overwrote the scene values from
## here, so the sliders jumped on open, and worse: the mix was being expressed
## in two places at once, because bus_layout.tres ALREADY carries it (Music
## -0.4 dB, UI -4, Ambience -3, plus AudioManager's -20 dB on the music players
## themselves). Trimming the same channel twice made the real balance impossible
## to reason about from either file alone.
##
## So the split is now clean: the BUS LAYOUT owns the mix, the SLIDERS are the
## player's controls and start neutral. Every slider reads 100% on a fresh
## install, which is also the only state a player can verify at a glance.
const DEFAULT_VOLUME := 1.0

const DEFAULT_MASTER := DEFAULT_VOLUME
const DEFAULT_MUSIC := DEFAULT_VOLUME
const DEFAULT_SFX := DEFAULT_VOLUME
const DEFAULT_AMBIENCE := DEFAULT_VOLUME

var master_volume: float = DEFAULT_MASTER
var music_volume: float = DEFAULT_MUSIC
var sfx_volume: float = DEFAULT_SFX
## Ambience (the ocean loop) rides on its own bus under SFX, so this trims the
## waves without touching footsteps or UI blips.
var ambience_volume: float = DEFAULT_AMBIENCE

## The last name the player actually committed to a game with. Empty until they
## type one - a blank field falls back to a throwaway "Player123" per session,
## and remembering THAT would silently freeze a random number as someone's
## identity forever.
var player_name: String = ""

## --- Touch controls -----------------------------------------------------------
## Only meaningful on a device with a touchscreen; the overlay is never built
## anywhere else, so on a desktop these are stored and ignored.
##
## Enabled by default because a phone with nothing on screen is unplayable, but
## switchable off for the tablet with a Bluetooth controller or keyboard, where
## the overlay is just two thumbs' worth of covered map.
##
## Opacity never goes fully transparent: a control you cannot see but can still
## press is a trap, not an option. The floor is where the stick is still just
## findable by eye over bright sand.
signal touch_controls_changed

const TOUCH_OPACITY_MIN := 0.15
const DEFAULT_TOUCH_ENABLED := true
const DEFAULT_TOUCH_OPACITY := 1.0

var touch_controls_enabled: bool = DEFAULT_TOUCH_ENABLED
var touch_controls_opacity: float = DEFAULT_TOUCH_OPACITY


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err == OK:
		master_volume = config.get_value("audio", "master", DEFAULT_MASTER)
		music_volume = config.get_value("audio", "music", DEFAULT_MUSIC)
		sfx_volume = config.get_value("audio", "sfx", DEFAULT_SFX)
		# Ambience was written by save_settings() but never read back, so the
		# slider reset to full every launch while the file quietly held the
		# player's real choice.
		ambience_volume = config.get_value("audio", "ambience", DEFAULT_AMBIENCE)
		player_name = config.get_value("player", "name", "")
		touch_controls_enabled = config.get_value("touch", "enabled", DEFAULT_TOUCH_ENABLED)
		touch_controls_opacity = clampf(
			config.get_value("touch", "opacity", DEFAULT_TOUCH_OPACITY), TOUCH_OPACITY_MIN, 1.0)
	_apply_bus("Master", master_volume)
	_apply_bus("Music", music_volume)
	_apply_bus("SFX", sfx_volume)
	_apply_bus("Ambience", ambience_volume)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "ambience", ambience_volume)
	# ConfigFile.save() rewrites the whole file, so the name has to be written on
	# every save - including the ones a volume slider triggers - or moving a
	# slider would quietly erase it.
	config.set_value("player", "name", player_name)
	config.set_value("touch", "enabled", touch_controls_enabled)
	config.set_value("touch", "opacity", touch_controls_opacity)
	config.save(SETTINGS_PATH)


func set_master_volume(value: float) -> void:
	master_volume = value
	_apply_bus("Master", value)
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = value
	_apply_bus("Music", value)
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	_apply_bus("SFX", value)
	save_settings()


func set_player_name(value: String) -> void:
	var trimmed := value.strip_edges()
	if trimmed == player_name:
		return
	player_name = trimmed
	save_settings()


func set_touch_controls_enabled(value: bool) -> void:
	if value == touch_controls_enabled:
		return
	touch_controls_enabled = value
	save_settings()
	touch_controls_changed.emit()


func set_touch_controls_opacity(value: float) -> void:
	var clamped := clampf(value, TOUCH_OPACITY_MIN, 1.0)
	if is_equal_approx(clamped, touch_controls_opacity):
		return
	touch_controls_opacity = clamped
	save_settings()
	touch_controls_changed.emit()


func set_ambience_volume(value: float) -> void:
	ambience_volume = value
	_apply_bus("Ambience", value)
	save_settings()


func _apply_bus(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var db: float = linear_to_db(linear_value) if linear_value > 0.0 else MIN_DB
	AudioServer.set_bus_volume_db(idx, db)
