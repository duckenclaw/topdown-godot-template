class_name Brazier
extends StaticBody3D

## A fire bowl with a flickering, shadow-casting OmniLight3D. Press interact (F)
## next to it to light / douse it — shows the controller's interact hook and how
## point lights throw real shadows from sprites and models alike.

@export var lit: bool = true:
	set(v):
		lit = v
		_apply()
@export var energy: float = 3.0
@export var flicker: float = 0.35

@onready var light: OmniLight3D = $Light
@onready var flames: CPUParticles3D = $Flames

var _t: float = 0.0

func _ready() -> void:
	_t = randf() * 10.0
	_apply()

func _process(delta: float) -> void:
	if not lit:
		return
	_t += delta
	light.light_energy = energy * (1.0 + flicker * (sin(_t * 13.0) * 0.5 + sin(_t * 7.3) * 0.3 + sin(_t * 23.0) * 0.2))

func interact() -> void:
	lit = not lit

func _apply() -> void:
	if not is_node_ready():
		return
	light.visible = lit
	flames.emitting = lit
