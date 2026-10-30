extends Node3D

# Small, original offline arena prototype. Godot 4.x.
var player: CharacterBody3D
var camera: Camera3D
var bots: Array[CharacterBody3D] = []
var friends: Array[CharacterBody3D] = []
var bot_health: Dictionary = {}
var mode := "FOLLOW"
var score := 0
var health := 100
var move_axis := Vector2.ZERO
var fire_held := false
var last_shot := 0.0
var hud: Label
var status: Label
var command_panel: PanelContainer
var rng := RandomNumberGenerator.new()
var touch_origin := Vector2.ZERO
var touch_id := -1
var mouse_aim := false

func _ready() -> void:
	rng.randomize()
	_make_world()
	player = _actor(Vector3(0, 1, 0), Color(0.25, 0.55, 1.0), true)
	camera = Camera3D.new()
	player.add_child(camera)
	camera.position = Vector3(0, 2.6, 5.5)
	camera.rotation_degrees.x = -12
	camera.current = true
	for i in range(3):
		var ally := _actor(Vector3(-3 + i * 3, 1, 3), Color(0.2, 0.85, 0.45), false)
		friends.append(ally)
	for i in range(12):
		_spawn_enemy()
	_make_ui()
	_refresh()

func _make_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.2
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.76, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.85, 0.95)
	add_child(env)
	_box(Vector3(0, -0.55, 0), Vector3(95, 1, 95), Color(0.3, 0.55, 0.3), true)
	for i in range(30):
		var pos := Vector3(rng.randf_range(-42, 42), 0, rng.randf_range(-42, 42))
		if pos.length() < 8:
			continue
		var sz := Vector3(rng.randf_range(2, 6), rng.randf_range(2, 7), rng.randf_range(2, 6))
		_box(Vector3(pos.x, sz.y / 2, pos.z), sz, Color(0.55, 0.5, 0.43), true)
	for i in range(10):
		var angle := TAU * i / 10.0
		var p := Vector3(cos(angle) * 37, 0, sin(angle) * 37)
		_box(p + Vector3.UP * 2, Vector3(1.1, 4, 1.1), Color(0.2, 0.85, 0.95), false)

func _box(pos: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	if collision:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
	add_child(body)

func _actor(pos: Vector3, color: Color, is_player: bool) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.position = pos
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	collision.shape = capsule
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.45
	cap.height = 1.8
	mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)
	return body

func _spawn_enemy() -> void:
	var p := Vector3(rng.randf_range(-38, 38), 1, rng.randf_range(-38, 38))
	if p.distance_to(player.position) < 10:
		p.x += 13
	var bot := _actor(p, Color(0.95, 0.25, 0.25), false)
	bots.append(bot)
	bot_health[bot] = 3

func _physics_process(delta: float) -> void:
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3(move_axis.x + keyboard.x, 0, move_axis.y + keyboard.y)
	if direction.length() > 1:
		direction = direction.normalized()
	player.velocity = direction * 9
	player.velocity.y = -1
	player.move_and_slide()
	for i in range(friends.size()):
		var ally := friends[i]
		var target := player.position + Vector3(-2 + i * 2, 0, 3)
		if mode == "HOLD":
			continue
		if mode == "ATTACK" and bots.size() > 0:
			target = _nearest_enemy(ally.position).position
		_move_bot(ally, target, 5.5, delta)
	for enemy in bots:
		if not is_instance_valid(enemy):
			continue
		var target := player.position
		if friends.size() > 0 and rng.randf() < 0.01:
			target = friends[rng.randi_range(0, friends.size() - 1)].position
		if enemy.position.distance_to(target) > 4:
			_move_bot(enemy, target, 2.0, delta)
		elif rng.randf() < delta * 0.08:
			health = max(0, health - 5)
	if fire_held:
		_shoot()
	if health <= 0:
		health = 100
		player.position = Vector3(0, 1, 0)
		status.text = "Respawned (prototype)"
	_refresh()

func _move_bot(bot: CharacterBody3D, target: Vector3, speed: float, _delta: float) -> void:
	var d := target - bot.position
	d.y = 0
	if d.length() > 1.6:
		bot.velocity = d.normalized() * speed
		bot.velocity.y = -1
		bot.move_and_slide()

func _nearest_enemy(pos: Vector3) -> CharacterBody3D:
	var best: CharacterBody3D = null
	var dist := INF
	for b in bots:
		var d := b.position.distance_to(pos)
		if d < dist:
			dist = d
			best = b
	return best

func _shoot() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_shot < 0.28:
		return
	last_shot = now
	if bots.is_empty():
		return
	var enemy := _nearest_enemy(player.position)
	if enemy == null or enemy.position.distance_to(player.position) > 28:
		status.text = "No enemy in range"
		return
	bot_health[enemy] -= 1
	status.text = "Hit! Enemy HP: %d" % bot_health[enemy]
	if bot_health[enemy] <= 0:
		bots.erase(enemy)
		bot_health.erase(enemy)
		enemy.queue_free()
		score += 1
		status.text = "Elimination! +1"
		_spawn_enemy()

func _make_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	hud = Label.new()
	hud.position = Vector2(14, 12)
	hud.add_theme_font_size_override("font_size", 20)
	ui.add_child(hud)
	status = Label.new()
	status.position = Vector2(14, 48)
	ui.add_child(status)
	var hint := Label.new()
	hint.text = "PC: arrows/WASD to move | mobile: D-pad | FIRE to shoot"
	hint.position = Vector2(14, 76)
	ui.add_child(hint)
	var pad := GridContainer.new()
	pad.columns = 3
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.position = Vector2(18, -182)
	ui.add_child(pad)
	for txt in ["", "▲", "", "◀", "●", "▶", "", "▼", ""]:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(52, 52)
		btn.text = txt
		pad.add_child(btn)
		var axis := Vector2.ZERO
		match txt:
			"▲": axis = Vector2(0, -1)
			"▼": axis = Vector2(0, 1)
			"◀": axis = Vector2(-1, 0)
			"▶": axis = Vector2(1, 0)
		if axis != Vector2.ZERO:
			btn.button_down.connect(func(): move_axis = axis)
			btn.button_up.connect(func(): move_axis = Vector2.ZERO)
	var actions := VBoxContainer.new()
	actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.position = Vector2(-170, -190)
	ui.add_child(actions)
	var fire := Button.new()
	fire.text = "FIRE"
	fire.custom_minimum_size = Vector2(145, 58)
	actions.add_child(fire)
	fire.button_down.connect(func(): fire_held = true)
	fire.button_up.connect(func(): fire_held = false)
	var cmd := Button.new()
	cmd.text = "COMMANDS"
	cmd.custom_minimum_size = Vector2(145, 52)
	actions.add_child(cmd)
	command_panel = PanelContainer.new()
	command_panel.set_anchors_preset(Control.PRESET_CENTER)
	command_panel.position = Vector2(-100, -110)
	command_panel.visible = false
	ui.add_child(command_panel)
	var menu := VBoxContainer.new()
	command_panel.add_child(menu)
	for name in ["FOLLOW", "ATTACK", "HOLD", "COVER", "REVIVE", "NEED AMMO", "SHARE LOOT", "DRIVE"]:
		var b := Button.new()
		b.text = name
		menu.add_child(b)
		b.pressed.connect(_command.bind(name))
	cmd.pressed.connect(func(): command_panel.visible = not command_panel.visible)

func _command(name: String) -> void:
	mode = name
	command_panel.visible = false
	status.text = "Squad command: " + name
	_refresh()

func _refresh() -> void:
	if hud != null:
		hud.text = "HP: %d  |  Kills: %d  |  Enemies: %d  |  Squad: %s" % [health, score, bots.size(), mode]
