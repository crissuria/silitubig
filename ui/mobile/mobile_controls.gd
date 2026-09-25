extends Control
class_name MobileControls

## Touch overlay for phones and tablets: a movement stick plus Run and Rescue.
##
## HOW IT TALKS TO THE GAME
##
## It doesn't. Nothing here knows what a Tubig is. Every control presses or
## releases one of the INPUT ACTIONS the keyboard already presses - left, right,
## up, down, run, rescue - through Input.action_press/action_release. The player
## scripts read those actions and cannot tell a thumb from a key, which is what
## buys everything below for free:
##
##   - No change to tubig.gd or sili.gd. The code that reads WASD reads this.
##   - Multiplayer authority takes care of itself: only the phone in your hand
##     has a touchscreen, so only your own body ever moves.
##   - The spectator camera cycles on left/right, so a flick of the stick
##     cycles it, with nothing written for that.
##   - One scene covers Sili, Tubig and spectating alike, instead of a copy in
##     each player scene that vanishes with your body when you are eliminated.
##
## WHY EVERY TOUCH IS TRACKED BY INDEX
##
## Godot emulates a mouse from the FIRST finger only. Steering with one thumb
## while pressing Run with the other is the normal way to play, and the second
## finger never reaches a Button through mouse emulation - so this reads
## InputEventScreenTouch/Drag directly and assigns each finger, by its index,
## to the control it landed on. A finger keeps its control until it lifts, even
## if it drags off the edge, so the stick never drops out mid-corner.
##
## WHY THE STICK SENDS A UNIT VECTOR
##
## Input.get_vector applies its deadzone to the LENGTH of the combined vector,
## then returns it as-is if that length is 1. Sending the normalised direction's
## components means any tilt past this control's own small deadzone moves the
## character at full speed in exactly the direction of the thumb - no snapping
## to eight ways, no crawl on a shallow tilt. Speed is not analog in this game
## anyway; Run is a separate button, same as Shift on a keyboard.
##
## FOR THE DESIGNER
##
## Restyle or restructure the .tscn freely. The script finds its parts by
## unique name (the % prefix), so the only contract is that these four exist
## somewhere under this node:
##
##   %Joystick      the touch area the stick lives in (its rect is the hit zone)
##   %JoystickKnob  the part that moves under the thumb, a child of %Joystick
##   %RunButton     any Control; its rect is the hit zone
##   %RescueButton  any Control; its rect is the hit zone
##
## Everything else - textures, colours, sizes, anchors - is yours. Two layout
## facts worth knowing: the event feed owns the bottom-right strip (about 430px
## wide, from 240px to 80px above the bottom edge), and the settings and guide
## buttons sit top-right. The defaults keep clear of both.

## The stick ignores the first few pixels of tilt, so a thumb resting on it
## does not creep the character. In knob-travel units (0..1).
@export_range(0.0, 0.5) var deadzone: float = 0.18

## How far the knob may travel from centre, in pixels. Zero means "the base's
## own radius", read from %Joystick at runtime so a resized base still feels
## right without a matching edit here.
@export var knob_travel: float = 0.0

const MOVE_ACTIONS := {
	"left": Vector2.LEFT, "right": Vector2.RIGHT,
	"up": Vector2.UP, "down": Vector2.DOWN,
}

## Touch feedback: a held knob or button shrinks slightly and its panel goes
## more opaque (reads as "darker" against the black theme), so a thumb gets a
## visible response without needing to look away from the stick.
const PRESS_SCALE := 0.92
const PRESS_ALPHA_BOOST := 0.25

@onready var _joystick: Control = %Joystick
@onready var _knob: Control = %JoystickKnob
@onready var _run_button: Control = %RunButton
@onready var _rescue_button: Control = %RescueButton

## finger index -> "stick" | "run" | "rescue". A finger not in here is doing
## something that is not ours (a menu button, say) and is left alone.
var _fingers: Dictionary = {}
var _stick_vector := Vector2.ZERO
var _knob_rest := Vector2.ZERO

## Control -> its own StyleBoxFlat, one pair each so darkening the pressed
## Run button never bleeds into Rescue - the two Panels share a StyleBoxFlat
## resource in the .tscn until _ready() gives each one a private copy.
var _normal_styles: Dictionary = {}
var _pressed_styles: Dictionary = {}


## Whether this device has a touchscreen to put an overlay on. This is the gate
## for BUILDING it at all - a desktop never gets one, so the settings toggle
## below has nothing to switch off there and is not offered. Mobile export, a
## touchscreen, or "--touch" on the command line, which forces it on a desktop
## for mouse testing (one finger only, then - see the note on emulation).
##
## Deliberately NOT the user's on/off setting. The overlay is always built where
## it could apply and hides itself from the setting, so flipping the toggle
## mid-match takes effect on the spot instead of at the next round.
static func device_supports_touch() -> bool:
	if OS.has_feature("mobile"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	return OS.get_cmdline_user_args().has("--touch")


func _ready() -> void:
	# Let touches through to the HUD buttons underneath everywhere this overlay
	# is NOT one of its three controls. The hit-testing is done by hand below.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_knob_rest = _knob.position
	if knob_travel <= 0.0:
		knob_travel = _joystick.size.x * 0.5 - _knob.size.x * 0.5
	_setup_press_styles()

	_apply_safe_area_padding()
	_apply_settings()
	GameSettings.touch_controls_changed.connect(_apply_settings)


## Nudges the stick and buttons in from whichever edges the OS reports as
## unsafe - a notch or camera cutout, curved corners, the iOS home indicator,
## an Android gesture-nav bar - so a thumb resting where the .tscn placed it
## does not land under a system overlay that eats the touch. Only ever moves
## controls FURTHER from the edge, never closer, and does nothing on the
## (most common) screen that reports no cutout at all, including desktop
## --touch testing.
func _apply_safe_area_padding() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var full := DisplayServer.screen_get_size(screen)
	if full.x <= 0 or full.y <= 0:
		return
	var usable := DisplayServer.screen_get_usable_rect(screen)
	# Screen pixels -> this Control's own units, so the padding matches
	# whatever the canvas_items stretch scale is doing to everything else.
	var px_scale: Vector2 = get_viewport().get_visible_rect().size / Vector2(full)
	var pad_left: float = usable.position.x * px_scale.x
	var pad_right: float = (full.x - usable.end.x) * px_scale.x
	var pad_bottom: float = (full.y - usable.end.y) * px_scale.y

	if pad_left > 0.0:
		_joystick.offset_left += pad_left
	if pad_right > 0.0:
		for edge_anchored in [_run_button, _rescue_button]:
			edge_anchored.offset_left -= pad_right
			edge_anchored.offset_right -= pad_right
	if pad_bottom > 0.0:
		for bottom_anchored in [_joystick, _run_button, _rescue_button]:
			bottom_anchored.offset_top -= pad_bottom
			bottom_anchored.offset_bottom -= pad_bottom


## Gives the knob and both buttons their own StyleBoxFlat (duplicated off
## whatever the .tscn set, so a designer's colours/corners carry over) plus a
## pre-darkened twin for the pressed state, and a centred pivot so the press
## shrink scales in place instead of drifting toward a corner.
func _setup_press_styles() -> void:
	for ctrl in [_knob, _run_button, _rescue_button]:
		ctrl.pivot_offset = ctrl.size * 0.5
		var base_style: StyleBox = ctrl.get_theme_stylebox("panel")
		var normal: StyleBoxFlat = (base_style as StyleBoxFlat).duplicate()
		ctrl.add_theme_stylebox_override("panel", normal)
		var pressed: StyleBoxFlat = normal.duplicate()
		pressed.bg_color.a = clampf(pressed.bg_color.a + PRESS_ALPHA_BOOST, 0.0, 1.0)
		if pressed.border_color.a > 0.0:
			pressed.border_color.a = clampf(pressed.border_color.a + PRESS_ALPHA_BOOST, 0.0, 1.0)
		_normal_styles[ctrl] = normal
		_pressed_styles[ctrl] = pressed


## Swaps a control between its normal and pressed look. `target` is the same
## "stick" | "run" | "rescue" vocabulary _fingers uses.
func _set_touch_visual(target: String, pressed: bool) -> void:
	var ctrl: Control = {"stick": _knob, "run": _run_button, "rescue": _rescue_button}.get(target)
	if ctrl == null or not _normal_styles.has(ctrl):
		return
	ctrl.scale = Vector2.ONE * (PRESS_SCALE if pressed else 1.0)
	ctrl.add_theme_stylebox_override("panel", _pressed_styles[ctrl] if pressed else _normal_styles[ctrl])


## Reads the two touch settings. Called on the spot whenever either changes, so
## the opacity slider in the in-match panel is a live preview and the toggle
## does not need a restart. Switching off also lets go of anything held: a
## thumb on Run when the overlay vanishes would otherwise sprint forever.
func _apply_settings() -> void:
	var enabled := GameSettings.touch_controls_enabled
	modulate.a = GameSettings.touch_controls_opacity
	if visible == enabled:
		return
	visible = enabled
	set_process_input(enabled)
	if not enabled:
		_release_everything()


func _exit_tree() -> void:
	# Dropping the overlay mid-press (a scene change, a round ending) must not
	# leave the character sprinting into a wall on an action nobody can lift.
	_release_everything()


## The top edge of the highest control, as a bottom-anchored offset (negative,
## like the .tscn's own offset_top values), so a HUD that shares the bottom of
## the screen can stay clear of the buttons however they get rearranged.
func highest_control_offset() -> float:
	return minf(_run_button.offset_top, _rescue_button.offset_top)


## Appends the two touch rows - the on/off toggle and the opacity slider - to a
## settings VBox, so the main Settings screen and the in-match panel build the
## exact same rows from one place and can never drift apart. `like` is a Label
## from an existing row, borrowed for its font so the rows match whatever the
## panel is styled with; `before` keeps the panel's own buttons at the bottom.
##
## Callers gate this on device_supports_touch(): a row that toggles nothing is
## worse than no row.
static func add_settings_rows(vbox: Control, like: Label, before: Node = null) -> void:
	var font := like.get_theme_font("font")
	var font_size := like.get_theme_font_size("font_size")

	# --- On / off ---
	var toggle_row := HBoxContainer.new()
	toggle_row.name = "TouchToggleRow"
	var toggle_label := Label.new()
	toggle_label.text = "Touch controls"
	toggle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle_label.add_theme_font_override("font", font)
	toggle_label.add_theme_font_size_override("font_size", font_size)
	toggle_row.add_child(toggle_label)
	var toggle := CheckButton.new()
	toggle.name = "TouchToggle"
	toggle.button_pressed = GameSettings.touch_controls_enabled
	toggle.toggled.connect(GameSettings.set_touch_controls_enabled)
	toggle_row.add_child(toggle)

	# --- Opacity ---
	var opacity_row := HBoxContainer.new()
	opacity_row.name = "TouchOpacityRow"
	var opacity_label := Label.new()
	opacity_label.text = "Touch opacity"
	opacity_label.custom_minimum_size = like.custom_minimum_size
	opacity_label.add_theme_font_override("font", font)
	opacity_label.add_theme_font_size_override("font_size", font_size)
	opacity_row.add_child(opacity_label)
	var slider := HSlider.new()
	slider.name = "TouchOpacitySlider"
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = GameSettings.TOUCH_OPACITY_MIN
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = GameSettings.touch_controls_opacity
	opacity_row.add_child(slider)
	var readout := Label.new()
	readout.name = "TouchOpacityValue"
	readout.custom_minimum_size = Vector2(52, 0)
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	readout.add_theme_font_override("font", font)
	readout.add_theme_font_size_override("font_size", maxi(font_size - 3, 8))
	readout.text = "%d%%" % roundi(slider.value * 100.0)
	opacity_row.add_child(readout)
	slider.value_changed.connect(GameSettings.set_touch_controls_opacity)
	slider.value_changed.connect(func(value: float):
		readout.text = "%d%%" % roundi(value * 100.0))

	for row in [toggle_row, opacity_row]:
		vbox.add_child(row)
		if before != null:
			vbox.move_child(row, before.get_index())


func _input(event: InputEvent) -> void:
	# _apply_settings also stops input processing, but that only stops the
	# ENGINE calling this. Hidden means off, whoever is asking.
	if not visible:
		return
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var hit := _control_at(event.position)
		if hit == "":
			return
		_fingers[event.index] = hit
		match hit:
			"stick":
				_move_stick(event.position)
			"run":
				Input.action_press("run")
			"rescue":
				Input.action_press("rescue")
		_set_touch_visual(hit, true)
		get_viewport().set_input_as_handled()
		return

	if not _fingers.has(event.index):
		return
	var released: String = _fingers[event.index]
	_fingers.erase(event.index)
	match released:
		"stick":
			_reset_stick()
		"run":
			Input.action_release("run")
		"rescue":
			Input.action_release("rescue")
	_set_touch_visual(released, false)
	get_viewport().set_input_as_handled()


func _on_drag(event: InputEventScreenDrag) -> void:
	if _fingers.get(event.index, "") != "stick":
		return
	_move_stick(event.position)
	get_viewport().set_input_as_handled()


func _control_at(point: Vector2) -> String:
	if _joystick.get_global_rect().has_point(point):
		return "stick"
	if _run_button.get_global_rect().has_point(point):
		return "run"
	if _rescue_button.get_global_rect().has_point(point):
		return "rescue"
	return ""


## Moves the knob toward the finger, clamped to knob_travel, and turns the
## offset into movement actions.
func _move_stick(finger: Vector2) -> void:
	var centre := _joystick.get_global_rect().get_center()
	var offset := finger - centre
	if offset.length() > knob_travel:
		offset = offset.normalized() * knob_travel
	_knob.global_position = centre + offset - _knob.size * 0.5

	var tilt := offset / knob_travel  # 0..1 in each axis
	if tilt.length() < deadzone:
		_set_stick_vector(Vector2.ZERO)
	else:
		_set_stick_vector(tilt.normalized())


func _reset_stick() -> void:
	_knob.position = _knob_rest
	_set_stick_vector(Vector2.ZERO)


## Presses each direction with the matching component of the unit vector and
## releases the ones that point the other way, so a thumb sweeping round the
## stick never leaves a stale direction held.
func _set_stick_vector(v: Vector2) -> void:
	_stick_vector = v
	for action in MOVE_ACTIONS:
		var strength: float = v.dot(MOVE_ACTIONS[action])
		if strength > 0.0:
			Input.action_press(action, strength)
		else:
			Input.action_release(action)


func _release_everything() -> void:
	_fingers.clear()
	_set_stick_vector(Vector2.ZERO)
	Input.action_release("run")
	Input.action_release("rescue")
	if is_instance_valid(_knob):
		_knob.position = _knob_rest
	for target in ["stick", "run", "rescue"]:
		_set_touch_visual(target, false)


## What the stick is currently steering, for tests and for anything that wants
## to draw it. A unit vector, or zero.
func stick_vector() -> Vector2:
	return _stick_vector
