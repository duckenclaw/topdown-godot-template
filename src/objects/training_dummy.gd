class_name TrainingDummy
extends StaticBody3D

## A practice target for the melee combo: wobbles and flashes when hit, topples at
## zero health, then stands back up after `revive_delay` seconds. Shows how any
## entity becomes damageable — give it a Health child (or a take_damage method).

@export var revive_delay: float = 2.0

@onready var health: Health = $Health
@onready var model: Node3D = $Model

var _flash_mat: StandardMaterial3D

func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	var head: MeshInstance3D = $Model/Head
	_flash_mat = (head.get_active_material(0) as StandardMaterial3D).duplicate()
	head.material_override = _flash_mat

func take_damage(amount: float, source: Node = null) -> void:
	health.take_damage(amount, source)

func _on_damaged(_amount: float, source: Node) -> void:
	var away := Vector3.FORWARD
	if source is Node3D:
		away = global_position - (source as Node3D).global_position
		away.y = 0.0
		away = away.normalized()
	# Lean away from the hit, then spring back.
	var axis := Vector3.UP.cross(away).normalized() if away.length() > 0.01 else Vector3.RIGHT
	var t := create_tween()
	t.tween_property(model, "basis", Basis(axis, 0.35), 0.06)
	t.tween_property(model, "basis", Basis(axis, -0.1), 0.12)
	t.tween_property(model, "basis", Basis(), 0.18)
	_flash_mat.emission_enabled = true
	_flash_mat.emission = Color(1, 0.4, 0.3)
	_flash_mat.emission_energy_multiplier = 2.0
	var f := create_tween()
	f.tween_property(_flash_mat, "emission_energy_multiplier", 0.0, 0.25)

func _on_died() -> void:
	var t := create_tween()
	t.tween_interval(0.2)
	t.tween_property(model, "rotation:x", -PI / 2.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_interval(revive_delay)
	t.tween_property(model, "rotation:x", 0.0, 0.4)
	t.tween_callback(health.revive)
