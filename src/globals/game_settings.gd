extends SettingsManager
## Top-down settings autoload (registered as "GameSettings").
##
## Inherits all persistence/apply logic from SettingsManager (addons/settings_kit).
## It supplies this game's rebindable action list AND registers the controller's
## default key / mouse / gamepad bindings at startup — before the base _ready() runs
## load_keybinds() — so saved rebinds load correctly and the controller works out of
## the box. (The controller also self-provisions these as a fallback.) The defaults
## live in TopDownPlayer.DEFAULT_KEYS & co. — edit them there or define the actions
## in Project Settings → Input Map, which always wins.

## Actions exposed in the rebind UI and persisted.
const REBINDABLE: Array[String] = [
	"move_left", "move_right", "move_up", "move_down",
	"attack", "dash", "sprint", "interact", "walk_run_toggle",
	"camera_rotate_left", "camera_rotate_right",
]


func _ready() -> void:
	TopDownPlayer.ensure_default_actions()
	rebindable_actions = REBINDABLE
	super()
