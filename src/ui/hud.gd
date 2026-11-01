extends CanvasLayer

## Minimal demo HUD: health bar bound to the player's Health, and a controls/status
## panel the demo level updates (look, time of day, projection).

@onready var health_bar: ProgressBar = %HealthBar
@onready var status: Label = %Status

var _health: Health

func bind(player: Node) -> void:
	if _health and _health.health_changed.is_connected(_on_health_changed):
		_health.health_changed.disconnect(_on_health_changed)
	_health = player.get_node_or_null("Health")
	if _health:
		_health.health_changed.connect(_on_health_changed)
		_on_health_changed(_health.current_health, _health.max_health)

func set_status(text: String) -> void:
	status.text = text

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
