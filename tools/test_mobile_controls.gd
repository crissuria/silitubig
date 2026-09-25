extends Node

## The touch overlay, driven by synthetic finger events.
##
## What it proves is the contract in mobile_controls.gd's header: fingers turn
## into the same INPUT ACTIONS the keyboard presses, and nothing else. So the
## assertions read Input.is_action_pressed / Input.get_vector - the exact calls
## tubig.gd and sili.gd make - rather than anything on the overlay itself.
##
## The one that matters most is the two-finger case. Godot emulates a mouse
## from the first finger only, so a Button would never see the thumb that lands
## on Run while the other thumb is on the stick. That is the whole reason the
## overlay tracks touches by index.
##
## Run as a SCENE: the overlay reads GameSettings for its on/off and opacity,
## and autoloads only exist when the project boots properly.
##
##     godot --headless --path . res://tools/test_mobile_controls.tscn

var _f := 0
var _controls: MobileControls = null
var _frame := 0
var _saved_enabled := true
var _saved_opacity := 1.0


func _c(l: String, a: Variant, e: Variant) -> void:
	if a == e:
		print("  PASS  %s" % l)
	else:
		_f += 1
		print("  FAIL  %s  (got %s, expected %s)" % [l, a, e])


func _near(l: String, a: Vector2, e: Vector2) -> void:
	_c(l, a.is_equal_approx(e) or a.distance_to(e) < 0.01, true)


func _ready() -> void:
	print("Mobile controls tests")
	# These setters write settings.cfg - the player's real file - so whatever
	# was there goes back at the end. Same lesson as the leaderboard.
	_saved_enabled = GameSettings.touch_controls_enabled
	_saved_opacity = GameSettings.touch_controls_opacity
	GameSettings.set_touch_controls_enabled(true)
	GameSettings.set_touch_controls_opacity(1.0)

	_controls = load("res://ui/mobile/mobile_controls.tscn").instantiate()
	add_child(_controls)


func _touch(index: int, pos: Vector2, down: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = down
	_controls._input(ev)


func _drag(index: int, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	_controls._input(ev)


func _move() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


func _process(_delta: float) -> void:
	_frame += 1
	if _frame < 2:
		return
	set_process(false)

	var stick: Control = _controls.get_node("%Joystick")
	var run: Control = _controls.get_node("%RunButton")
	var rescue: Control = _controls.get_node("%RescueButton")
	var stick_c := stick.get_global_rect().get_center()
	var run_c := run.get_global_rect().get_center()
	var rescue_c := rescue.get_global_rect().get_center()
	var travel: float = _controls.knob_travel

	_c("overlay is in the tree and ready", _controls.is_node_ready(), true)
	_c("nothing pressed before any touch", _move(), Vector2.ZERO)

	# --- Buttons ---
	_touch(0, run_c, true)
	_c("a finger on Run presses run", Input.is_action_pressed("run"), true)
	_touch(0, run_c, false)
	_c("lifting it releases run", Input.is_action_pressed("run"), false)

	_touch(0, rescue_c, true)
	_c("a finger on the E button presses rescue", Input.is_action_pressed("rescue"), true)
	_touch(0, rescue_c, false)
	_c("lifting it releases rescue", Input.is_action_pressed("rescue"), false)

	# --- The stick ---
	_touch(0, stick_c, true)
	_c("a finger resting dead-centre does not move", _move(), Vector2.ZERO)

	_drag(0, stick_c + Vector2(travel, 0))
	_near("full tilt right steers right", _move(), Vector2.RIGHT)

	_drag(0, stick_c + Vector2(0, -travel))
	_near("tilt up steers up (screen y is down)", _move(), Vector2.UP)
	_c("sweeping round the stick released the old direction",
		Input.is_action_pressed("right"), false)

	_drag(0, stick_c + Vector2(travel, -travel))
	_near("a diagonal steers diagonally at full speed",
		_move(), Vector2(1, -1).normalized())

	_drag(0, stick_c + Vector2(travel * 0.5, 0))
	_near("a shallow tilt still moves at full speed", _move(), Vector2.RIGHT)

	_drag(0, stick_c + Vector2(travel * _controls.deadzone * 0.5, 0))
	_c("a nudge inside the deadzone does nothing", _move(), Vector2.ZERO)

	_drag(0, stick_c + Vector2(travel * 4.0, 0))
	_near("dragging off the base keeps steering", _move(), Vector2.RIGHT)
	_c("the knob stays clamped to its travel",
		is_equal_approx((_controls.get_node("%JoystickKnob").get_global_rect().get_center()
			- stick_c).length(), travel), true)

	_touch(0, stick_c + Vector2(travel * 4.0, 0), false)
	_c("lifting the thumb stops the character", _move(), Vector2.ZERO)
	_near("and recentres the knob",
		_controls.get_node("%JoystickKnob").get_global_rect().get_center(), stick_c)

	# --- Two fingers at once: the case mouse emulation cannot do ---
	_touch(0, stick_c, true)
	_drag(0, stick_c + Vector2(travel, 0))
	_touch(1, run_c, true)
	_near("stick still steering with a second finger down", _move(), Vector2.RIGHT)
	_c("and Run is pressed by that second finger", Input.is_action_pressed("run"), true)

	_touch(1, run_c, false)
	_c("lifting the Run finger releases run", Input.is_action_pressed("run"), false)
	_near("without disturbing the stick", _move(), Vector2.RIGHT)

	_touch(0, stick_c, false)
	_c("lifting the stick finger stops the character", _move(), Vector2.ZERO)

	# --- Fingers that are not ours ---
	var elsewhere := Vector2(get_viewport().get_visible_rect().size) * 0.5
	_touch(0, elsewhere, true)
	_c("a touch away from every control presses nothing",
		_move() == Vector2.ZERO and not Input.is_action_pressed("run")
			and not Input.is_action_pressed("rescue"), true)
	_touch(0, elsewhere, false)

	# --- Settings: opacity is live ---
	GameSettings.set_touch_controls_opacity(0.4)
	_c("the opacity slider drives the overlay on the spot",
		is_equal_approx(_controls.modulate.a, 0.4), true)
	GameSettings.set_touch_controls_opacity(0.0)
	_c("opacity cannot reach fully invisible",
		is_equal_approx(_controls.modulate.a, GameSettings.TOUCH_OPACITY_MIN), true)

	# --- Settings: the toggle hides it AND lets go of anything held ---
	_touch(0, run_c, true)
	_touch(1, stick_c, true)
	_drag(1, stick_c + Vector2(travel, 0))
	GameSettings.set_touch_controls_enabled(false)
	_c("switching touch controls off hides the overlay", _controls.visible, false)
	_c("and releases run", Input.is_action_pressed("run"), false)
	_c("and stops the character", _move(), Vector2.ZERO)
	_touch(0, run_c, true)
	_c("a hidden overlay ignores fingers", Input.is_action_pressed("run"), false)
	GameSettings.set_touch_controls_enabled(true)
	_c("switching it back on shows it again", _controls.visible, true)

	# --- The settings rows ---
	var vbox := VBoxContainer.new()
	add_child(vbox)
	var like := Label.new()
	vbox.add_child(like)
	var anchor := Button.new()
	anchor.name = "Anchor"
	vbox.add_child(anchor)
	MobileControls.add_settings_rows(vbox, like, anchor)
	var toggle: CheckButton = vbox.get_node_or_null("TouchToggleRow/TouchToggle")
	var slider: HSlider = vbox.get_node_or_null("TouchOpacityRow/TouchOpacitySlider")
	_c("the builder adds a toggle row", toggle != null, true)
	_c("and an opacity row", slider != null, true)
	_c("both land before the panel's own buttons",
		vbox.get_node("TouchOpacityRow").get_index() < anchor.get_index(), true)
	if toggle and slider:
		_c("the toggle starts on the saved value", toggle.button_pressed, true)
		toggle.button_pressed = false
		_c("flipping the toggle updates the setting",
			GameSettings.touch_controls_enabled, false)
		_c("and the overlay follows", _controls.visible, false)
		toggle.button_pressed = true
		_c("the slider floors at the minimum", slider.min_value, GameSettings.TOUCH_OPACITY_MIN)
		slider.value = 0.6
		_c("dragging the slider updates the setting",
			is_equal_approx(GameSettings.touch_controls_opacity, 0.6), true)
		_c("and the readout", vbox.get_node("TouchOpacityRow/TouchOpacityValue").text, "60%")

	# --- Leaving the tree cannot strand an action ---
	_touch(0, run_c, true)
	_touch(1, stick_c, true)
	_drag(1, stick_c + Vector2(0, travel))
	remove_child(_controls)
	_c("removing the overlay releases run", Input.is_action_pressed("run"), false)
	_c("and stops the character", _move(), Vector2.ZERO)
	_controls.free()

	_finish()


func _finish() -> void:
	GameSettings.set_touch_controls_enabled(_saved_enabled)
	GameSettings.set_touch_controls_opacity(_saved_opacity)
	print("")
	print("ALL TESTS PASSED" if _f == 0 else "%d TEST(S) FAILED" % _f)
	get_tree().quit(1 if _f > 0 else 0)
