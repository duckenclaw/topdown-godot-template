extends SceneTree

## Headless tests for the top-down controller: input provisioning, walk/run toggle,
## camera-relative movement, both looks (3D model + 2.5D sprite with directional
## animation picking), the sprite-sheet helper, modular mechanics (flags + removable
## states), the melee hitbox and Health reactions.
## Run: godot --headless --path . --script tests/test_topdown.gd

const PLAYER_3D := "res://addons/topdown_controller/player/player_3d.tscn"
const PLAYER_SPRITE := "res://src/player/player_heroknight.tscn"
const DUMMY := "res://src/objects/training_dummy.tscn"
const LEVEL := "res://src/levels/demo_level.tscn"

var _failures := 0

func check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: " + msg)
	else:
		_failures += 1
		print("FAIL: " + msg)

func _initialize() -> void:
	_run()

func _run() -> void:
	await _test_core()
	await _test_camera_relative()
	await _test_looks()
	_test_sprite_directions()
	_test_sprite_sheet_layout()
	await _test_removal()
	await _test_dash()
	await _test_attack_hits()
	await _test_health_reactions()
	await _test_level_loads()
	print("RESULT: %d failures" % _failures)
	quit(1 if _failures > 0 else 0)

func _spawn(path: String, at := Vector3.ZERO) -> Node:
	var p: Node = (load(path) as PackedScene).instantiate()
	p.position = at  # before entering the tree: static bodies shouldn't be teleported
	root.add_child(p)
	await process_frame
	await physics_frame
	return p

func _test_core() -> void:
	var p := await _spawn(PLAYER_3D)
	for a in ["move_left", "move_right", "move_up", "move_down", "attack", "dash", "sprint",
			"interact", "walk_run_toggle", "aim_left", "aim_up", "camera_rotate_left", "camera_zoom_in"]:
		check(InputMap.has_action(a), "action provisioned: " + a)

	p.is_running = true
	check(is_equal_approx(p.base_move_speed(), p.config.run_speed), "run mode uses run_speed")
	p.is_running = false
	check(is_equal_approx(p.base_move_speed(), p.config.walk_speed), "walk mode uses walk_speed")

	for s in ["IdleState", "MovingState", "DashingState", "AttackState", "HurtState", "DeathState"]:
		check(p.state_machine.has_state(s), "state present: " + s)
	check(p.can_dash() and p.can_attack(), "optional mechanics enabled by default")
	p.config.enable_attack = false
	check(not p.can_attack(), "config.enable_attack=false disables attack")
	p.config.enable_aim = false
	check(p.get_aim_direction() == Vector3.ZERO, "config.enable_aim=false: no aim, faces movement")
	p.free()

func _test_camera_relative() -> void:
	var p := await _spawn(PLAYER_3D)
	Input.action_press("move_up")
	await physics_frame
	check(p.move_dir.distance_to(Vector3(0, 0, -1)) < 0.01, "yaw 0: 'up' moves along -Z (away from camera)")
	p.camera_rig.set_yaw_degrees(90.0, true)
	await physics_frame
	check(p.move_dir.distance_to(Vector3(-1, 0, 0)) < 0.01, "yaw 90: 'up' follows the rotated camera (-X)")
	for i in 10:
		await physics_frame
	check(p.state_machine.get_current_state_name() == "MovingState", "move input enters MovingState")
	check(p.facing.distance_to(Vector3(-1, 0, 0)) < 0.01, "facing follows movement when not aiming")
	Input.action_release("move_up")
	p.free()

func _test_looks() -> void:
	var m := await _spawn(PLAYER_3D)
	check(m.sprite == null and m.anim_player != null, "3D look: AnimationPlayer found under Visual")
	for a in ["idle", "run", "walk", "attack1", "attack2", "attack3", "roll", "hurt", "death"]:
		check(m.anim_player.has_animation(a), "mannequin has animation: " + a)
	m.play_anim("roll", true)
	check(m.anim_player.current_animation == "roll", "play_anim drives the AnimationPlayer")
	m.free()

	var s := await _spawn(PLAYER_SPRITE)
	check(s.sprite is CameraFacingSprite3D, "sprite look: CameraFacingSprite3D found under Visual")
	check(s.sprite.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and s.sprite.shaded, "sprite is lit and casts shadows")
	check(s.sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, "sprite uses alpha scissor (crisp shadow silhouette)")
	s.play_anim("roll", true)
	check(String(s.sprite.animation) == "roll", "play_anim drives the sprite")
	check(s.anim_duration("attack1") > 0.2, "anim_duration reads sprite frame timing")
	s.free()

func _make_frames(names: Array) -> SpriteFrames:
	var f := SpriteFrames.new()
	for n in names:
		f.add_animation(n)
		f.add_frame(n, PlaceholderTexture2D.new())
	return f

func _test_sprite_directions() -> void:
	var spr := CameraFacingSprite3D.new()
	root.add_child(spr)  # no camera -> yaw 0
	spr.sprite_frames = _make_frames(["run_down", "run_up", "run_side", "idle"])
	spr.direction = Vector3(0, 0, 1)
	spr.play_directional(["run"])
	check(String(spr.animation) == "run_down", "4-dir sheet: toward camera -> run_down")
	spr.direction = Vector3(0, 0, -1)
	spr.play_directional(["run"])
	check(String(spr.animation) == "run_up", "4-dir sheet: away from camera -> run_up")
	spr.direction = Vector3(-1, 0, 0)
	spr.play_directional(["run"])
	check(String(spr.animation) == "run_side" and spr.flip_h, "4-dir sheet: left -> run_side flipped")
	spr.direction = Vector3(1, 0, 0)
	spr.play_directional(["run"])
	check(not spr.flip_h, "4-dir sheet: right -> run_side unflipped")
	spr.play_directional(["idle"])
	check(String(spr.animation) == "idle", "falls back to the plain name (side-view art)")
	spr.play_directional(TopDownPlayer.anim_candidates("attack3"))
	check(String(spr.animation) == "idle", "missing animation leaves the current one playing")
	spr.free()

func _test_sprite_sheet_layout() -> void:
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	var layout := SpriteSheetLayout.new()
	layout.texture = ImageTexture.create_from_image(img)
	layout.cell_size = Vector2i(32, 32)
	var a := SpriteSheetAnim.new()
	a.name = &"walk_down"
	a.row = 1
	a.count = 3
	a.fps = 8.0
	layout.animations = [a]
	var frames := layout.build()
	check(frames.has_animation(&"walk_down") and frames.get_frame_count(&"walk_down") == 3, "SpriteSheetLayout builds a 3-frame animation")
	var t := frames.get_frame_texture(&"walk_down", 2) as AtlasTexture
	check(t != null and t.region == Rect2(64, 32, 32, 32), "SpriteSheetLayout cuts the right cell (row 1, col 2)")
	check(not frames.has_animation(&"default"), "no stray 'default' animation")

func _test_removal() -> void:
	var p: Node = (load(PLAYER_3D) as PackedScene).instantiate()
	p.get_node("StateMachine/DashingState").free()
	root.add_child(p)
	await process_frame
	await physics_frame
	check(not p.can_dash(), "deleting DashingState disables dash")
	check(p.can_attack(), "other mechanics unaffected")
	p.free()

func _test_dash() -> void:
	var p := await _spawn(PLAYER_3D)
	p.state_machine.transition_to("DashingState")
	check(p.health.invulnerable, "dodge roll grants i-frames")
	for i in 30:
		await physics_frame
	check(not p.health.invulnerable, "i-frames end with the roll")
	check(p.state_machine.get_current_state_name() == "IdleState", "roll returns to IdleState")
	p.free()

func _test_attack_hits() -> void:
	var p := await _spawn(PLAYER_3D)
	var d := await _spawn(DUMMY, Vector3(0, 0, -1.0))  # in front: facing defaults to -Z
	for i in 3:
		await physics_frame
	var before: float = d.health.current_health
	p.state_machine.transition_to("AttackState")
	for i in 40:
		await physics_frame
	check(d.health.current_health < before, "melee swing damages a target in the hitbox")
	check(p.health.current_health == p.health.max_health, "the hitbox never hits the attacker")
	d.free()
	p.free()

func _test_health_reactions() -> void:
	var p := await _spawn(PLAYER_SPRITE)
	p.health.take_damage(10.0)
	await physics_frame
	check(p.state_machine.get_current_state_name() == "HurtState", "damage enters HurtState")
	p.health.take_damage(1000.0)
	await physics_frame
	check(p.is_dead and p.state_machine.get_current_state_name() == "DeathState", "lethal damage enters DeathState")
	p.respawn(Vector3(1, 0, 1))
	await physics_frame
	check(not p.is_dead and p.health.current_health == p.health.max_health, "respawn restores health")
	check(p.state_machine.get_current_state_name() == "IdleState", "respawn returns to IdleState")
	p.free()

func _test_level_loads() -> void:
	var lvl: Node = (load(LEVEL) as PackedScene).instantiate()
	root.add_child(lvl)
	await process_frame
	await physics_frame
	check(lvl.player is TopDownPlayer, "demo level spawns a TopDownPlayer")
	check(lvl.get_node("Sun").shadow_enabled, "sun casts shadows")
	lvl._swap(lvl.player_scenes[1])
	await process_frame
	check(lvl.player.sprite == null, "Tab swap: 3D model look")
	lvl._swap(lvl.player_scenes[0])
	await process_frame
	check(lvl.player.sprite != null, "Tab swap back: sprite look")
	lvl.free()
