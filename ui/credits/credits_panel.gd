extends Control

## The credits / about screen, as a modal over whichever screen opens it
## (title screen and settings both get one - see CREDITS.md's outstanding
## item #4: "None currently exists. Add one reachable from the title screen").
##
## Built in code rather than in a .tscn, matching leaderboard_panel.gd: the
## content is one long static block of BBCode, so there is nothing here that
## benefits from being laid out by hand in the editor.
##
## This is also where BoldPixels' CC BY-SA 4.0 attribution requirement is
## satisfied (see CREDITS.md item #3) - that licence requires the credit
## line appear somewhere the player can reach in-game, not only in a repo
## file nobody playing the game will ever open.

const GOLD := Color(1.0, 0.824, 0.498)
const LINK := Color(0.55, 0.72, 1.0)

const BODY_TEXT := """[color=#ffd27f]TEAM — F.I.R.E.S DEV[/color]
Janelle Ann F. Castillo — Team Leader / Developer
Stefane B. Cerezo — Developer
Romar D. De Asis — QA / Dev Support
Hazel B. Sebastian — Game Designer / Artist
Cristian P. Sudaria — Game Artist / Dev Support
Faculty Coach: Jayson S. Nacorda, MIT

[color=#ffd27f]ENGINE[/color]
Godot Engine — Godot Engine contributors — MIT License

[color=#ffd27f]FONT[/color]
[color=#5aa6ff]BoldPixels Font by Yūki (@YukiPixels)[/color] — CC BY-SA 4.0

[color=#ffd27f]ART & AUDIO PACKS[/color]
Modern Exteriors — LimeZu
Character Templates Pack — EsriEsra
Music Loop Bundle — Tallbeard Studios
Universal UI/Menu Soundpack — CyrexStudios
Full licence terms for every third-party asset are listed in CREDITS.md in the project repository.

[color=#ffd27f]ORIGINAL AUDIO[/color]
Every footstep sample and gameplay sound effect is synthesised from scratch by the team's own tools/generate_audio.py — nothing sampled, recorded, or downloaded.

[color=#ffd27f]AI ASSISTANCE[/color]
Claude — backend code: multiplayer networking, match logic, server-side validation, the series/rotation system, the spectator camera, and the audio synthesis script. Extent: heavy.
Gemini — art concepts and reference material for the game's visual direction. Extent: moderate.
All AI-assisted code was reviewed by the team before inclusion."""

var _body: RichTextLabel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()


func open() -> void:
	visible = true
	_body.scroll_to_line(0)


func close() -> void:
	visible = false


func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(640, 520)
	centre.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title := Label.new()
	title.text = "CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)

	_body = RichTextLabel.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.bbcode_enabled = true
	_body.add_theme_constant_override("line_separation", 2)
	_body.add_theme_font_size_override("normal_font_size", 16)
	_body.add_theme_font_size_override("bold_font_size", 16)
	_body.text = BODY_TEXT
	column.add_child(_body)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(160, 44)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close)
	column.add_child(close_button)
