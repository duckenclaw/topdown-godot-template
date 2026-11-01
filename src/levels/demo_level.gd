extends Node3D

## Demo level: a lit courtyard showing both looks of the top-down controller.
##   Tab  swap the player between the 2.5D sprite (HeroKnight) and the 3D mannequin
##   N    toggle day / night (night = braziers' point-light shadows)
##   P    toggle perspective / orthographic camera
##   R    respawn after dying

@export var player_scenes: Array[PackedScene] = []
@export var day_environment: Environment
@export var night_environment: Environment

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var spawn: Marker3D = $SpawnPoint
@onready var hud = $HUD

var player: TopDownPlayer
var _look: int = 0
var _night: bool = false

func _ready() -> void:
	player = get_node_or_null("Player")
	if player == null and not player_scenes.is_empty():
		_spawn(player_scenes[0], spawn.global_position)
	hud.bind(player)
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_TAB:
			if player_scenes.size() > 1:
				_look = (_look + 1) % player_scenes.size()
				_swap(player_scenes[_look])
		KEY_N:
			_night = not _night
			world_env.environment = night_environment if _night else day_environment
			sun.visible = not _night
		KEY_P:
			var rig := player.camera_rig
			if rig:
				rig.projection_mode = TopDownCamera.ProjectionMode.ORTHOGONAL \
					if rig.projection_mode == TopDownCamera.ProjectionMode.PERSPECTIVE \
					else TopDownCamera.ProjectionMode.PERSPECTIVE
		KEY_R:
			if player.is_dead:
				player.respawn(spawn.global_position)
		_:
			return
	_update_status()

func _spawn(scene: PackedScene, at: Vector3) -> void:
	player = scene.instantiate()
	player.name = "Player"
	add_child(player)
	player.global_position = at
	if player.camera_rig:
		player.camera_rig.snap()

## Replace the player with another look, keeping position, facing and camera.
func _swap(scene: PackedScene) -> void:
	var old := player
	var pos := old.global_position
	var old_rig := old.camera_rig
	remove_child(old)
	_spawn(scene, pos)
	player.facing = old.facing
	if old_rig and player.camera_rig:
		player.camera_rig.projection_mode = old_rig.projection_mode
		player.camera_rig.set_yaw_degrees(rad_to_deg(old_rig.get_yaw()), true)
		player.camera_rig.snap()
	if old.health and player.health:
		player.health.current_health = old.health.current_health
	old.queue_free()
	hud.bind(player)

func _update_status() -> void:
	var look := "2D sprite (2.5D)" if player and player.sprite else "3D model"
	var proj := "perspective"
	if player and player.camera_rig and player.camera_rig.projection_mode == TopDownCamera.ProjectionMode.ORTHOGONAL:
		proj = "orthographic"
	hud.set_status("%s · %s · %s" % [look, "night" if _night else "day", proj])
