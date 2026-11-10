extends Node3D

const Layouts = preload("res://core/Layouts.gd")
const TileArt = preload("res://ui/ChristmasTileArt.gd")

const TILE_W := 1.0
const TILE_D := 1.32
const TILE_THICK := 0.46
const GAP := 0.03
const STEP_X := TILE_W + GAP
const STEP_Z := TILE_D + GAP

var tiles: Array = []
var history: Array = []
var rng := RandomNumberGenerator.new()
var selected := -1
var hint_pair := [-1, -1]
var hint_until := 0.0
var score := 0
var pairs := 0
var moves := 0
var hints_used := 0
var started_at := 0.0
var feedback := ""
var finished := false
var stuck := false

# Board-view controls. A tap still selects a tile; dragging or pinching
# switches to camera control so the player can inspect crowded layouts.
var board_center := Vector3.ZERO
var camera_base_size := 10.0
var camera_zoom := 1.0
var camera_yaw := 0.0
var camera_pitch := 68.0
var active_touches: Dictionary = {}
var touch_moved := false
var pinch_distance := 0.0
var mouse_down := false
var mouse_start := Vector2.ZERO
var mouse_moved := false

var zen_mode := false
var level_id := ""
var layout_id := 0
var palette: Dictionary = {}
var last_stars := 0
var last_reward := 0
var overlay_buttons: Array = []
var title_text := ""
var next_tile_id := 0

var sfx_player: AudioStreamPlayer
var sfx_playback: AudioStreamGeneratorPlayback

@onready var camera: Camera3D = $Camera3D
@onready var light: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var table: MeshInstance3D = $Table
@onready var board_root: Node3D = $Board
@onready var hud: Node2D = $HudLayer/Hud

var _shared_body_mesh: BoxMesh
var _shared_face_mesh: PlaneMesh
var _shared_glow_mesh: PlaneMesh
var _shared_overlay_mesh: PlaneMesh

func _ready() -> void:
	rng.randomize()
	var params := Nav.take_params()
	zen_mode = params.get("zen", false)
	level_id = params.get("level_id", "")
	hud.game = self
	_setup_audio()
	_setup_scene()
	new_deal()

func _setup_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.2
	sfx_player.stream = gen
	sfx_player.volume_db = -4.0
	add_child(sfx_player)
	sfx_player.play()
	var pb := sfx_player.get_stream_playback()
	if pb is AudioStreamGeneratorPlayback:
		sfx_playback = pb

func play_tone(freq: float, duration: float, volume: float = 0.2) -> void:
	if not SaveData.data.settings.sfx or sfx_playback == null:
		return
	var mix_rate := 44100.0
	var sample_count := int(duration * mix_rate)
	var available := sfx_playback.get_frames_available()
	var to_fill: int = mini(sample_count, available)
	for i in range(to_fill):
		var t := float(i) / mix_rate
		var envelope := 1.0 - float(i) / float(max(sample_count, 1))
		var sample := sin(t * freq * TAU) * volume * envelope
		sfx_playback.push_frame(Vector2(sample, sample))

func _setup_scene() -> void:
	_shared_body_mesh = BoxMesh.new()
	_shared_body_mesh.size = Vector3(TILE_W, TILE_THICK, TILE_D)
	_shared_face_mesh = PlaneMesh.new()
	_shared_face_mesh.size = Vector2(TILE_W * 0.98, TILE_D * 0.98)
	_shared_face_mesh.orientation = PlaneMesh.FACE_Y
	_shared_glow_mesh = PlaneMesh.new()
	_shared_glow_mesh.size = Vector2(TILE_W * 1.1, TILE_D * 1.1)
	_shared_glow_mesh.orientation = PlaneMesh.FACE_Y
	_shared_overlay_mesh = PlaneMesh.new()
	_shared_overlay_mesh.size = Vector2(TILE_W * 0.98, TILE_D * 0.98)
	_shared_overlay_mesh.orientation = PlaneMesh.FACE_Y

	var table_mesh := BoxMesh.new()
	table_mesh.size = Vector3(14.0, 0.06, 14.0)
	table.mesh = table_mesh
	var table_mat := StandardMaterial3D.new()
	table_mat.albedo_color = Color(palette.get("panel", Color("0b3030")))
	table_mat.roughness = 0.85
	table.material_override = table_mat
	table.position = Vector3(0, -0.04, 0)

	light.rotation_degrees = Vector3(-72, -18, 0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	light.shadow_blur = 0.5
	light.directional_shadow_max_distance = 20.0

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.65
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	world_env.environment = env

	# Orthogonal + a mostly-top-down pitch keeps every tile the same size and
	# undistorted (no keystoning toward screen edges, no shrinking toward the
	# back rows) so artwork and suit marks stay legible everywhere on the
	# board — matching how real mahjong solitaire apps render their tiles.
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH

func _apply_theme_colors() -> void:
	var bg: Color = palette.get("bg", Color("071015"))
	var panel: Color = palette.get("panel", Color("0b3030"))
	world_env.environment.background_color = bg
	var table_mat: StandardMaterial3D = table.material_override
	table_mat.albedo_color = panel

func layout_camera() -> void:
	var min_c := 999.0
	var max_c := -999.0
	var min_r := 999.0
	var max_r := -999.0
	for t in tiles:
		min_c = minf(min_c, t.col)
		max_c = maxf(max_c, t.col)
		min_r = minf(min_r, t.row)
		max_r = maxf(max_r, t.row)
	var center := Vector3((min_c + max_c) * 0.5 * STEP_X, 0.35, (min_r + max_r) * 0.5 * STEP_Z)
	var span_x := (max_c - min_c + 2.6) * STEP_X
	var span_z := (max_r - min_r + 2.3) * STEP_Z
	var pitch := deg_to_rad(camera_pitch)
	# Apparent on-screen vertical extent of the board once projected through
	# the pitch angle (mostly top-down, so this is close to span_z itself).
	var apparent_z := span_z * sin(pitch) + 1.6
	var vp_size := get_viewport().get_visible_rect().size
	# Only the gap between the header and the bottom controls card is actually
	# visible board area — the same constraint the old 2D layout had to
	# respect, now expressed in camera-zoom terms instead of pixel math.
	var available_h := maxf(vp_size.y - 126.0 - 198.0, 200.0)
	var aspect := available_h / maxf(vp_size.x, 1.0)
	# A mobile-focused zoom keeps the whole layout safely visible while making
	# tiles about 11% larger than the original portrait layout.
	camera_base_size = maxf(span_x, apparent_z / aspect) * 0.893
	board_center = center
	camera_zoom = 1.0
	camera_yaw = 0.0
	_update_board_camera()
	table.position = Vector3(center.x, -0.04, center.z)

func _update_board_camera() -> void:
	var pitch := deg_to_rad(camera_pitch)
	var dist := 10.0
	var horizontal := dist * cos(pitch)
	camera.size = camera_base_size * camera_zoom
	camera.position = board_center + Vector3(sin(camera_yaw) * horizontal, dist * sin(pitch), cos(camera_yaw) * horizontal)
	camera.look_at(board_center, Vector3.UP)
	camera.v_offset = -0.05

func new_deal() -> void:
	var theme := ThemeData.equipped()
	palette = theme.palette
	if zen_mode:
		layout_id = rng.randi_range(0, Layouts.COUNT - 1)
		title_text = "ZEN WORKSHOP"
	else:
		var lvl := LevelData.get_level(level_id)
		layout_id = lvl.layout_id
		title_text = lvl.display_name.to_upper()
	_apply_theme_colors()

	for t in tiles:
		if t.node != null and is_instance_valid(t.node):
			t.node.queue_free()
	tiles.clear()

	var slots := Layouts.make_slots(layout_id, rng)
	for i in range(slots.size()):
		var slot: Vector3 = slots[i]
		# Each raised row straddles two lower tiles: half of its face sits over
		# the tile on the left and half over the tile on the right.
		var layer := int(slot.z)
		var t := {
			"id": next_tile_id, "col": slot.x + layer * 0.5, "row": slot.y, "layer": layer,
			"value": 0, "removed": false, "node": null,
			"face_mat": null, "glow": null, "glow_mat": null, "overlay": null,
		}
		next_tile_id += 1
		tiles.append(t)
	if not _assign_solvable_values():
		push_error("Could not create a solvable mahjong deal.")

	selected = -1
	hint_pair = [-1, -1]
	score = 1000
	pairs = 0
	moves = 0
	hints_used = 0
	started_at = Time.get_ticks_msec() / 1000.0
	finished = false
	stuck = false
	feedback = "A fresh snowfall is ready."
	layout_camera()
	for i in range(tiles.size()):
		_spawn_tile(tiles[i], i)
	_refresh_overlays()

func _spawn_tile(t: Dictionary, index: int) -> void:
	var root3 := Node3D.new()
	# Small per-tile jitter/rotation gives an organic "scattered pile" look
	# instead of a perfectly rigid grid — gameplay logic still uses the
	# clean col/row/layer values below, so free-tile rules are unaffected.
	var target_pos := Vector3(t.col * STEP_X, t.layer * TILE_THICK, t.row * STEP_Z)
	root3.position = target_pos
	board_root.add_child(root3)
	t.node = root3

	var body := MeshInstance3D.new()
	body.mesh = _shared_body_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(palette.get("tile_bottom", Color("e3dcc2")))
	body_mat.roughness = 0.5
	body.material_override = body_mat
	body.position = Vector3(0, TILE_THICK * 0.5, 0)
	root3.add_child(body)

	var face := MeshInstance3D.new()
	face.mesh = _shared_face_mesh
	var face_mat := StandardMaterial3D.new()
	face_mat.albedo_texture = TileArt.get_texture(t.value)
	face_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	face_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Crop out the baked-in card frame. The illustration sits directly on the
	# tile face instead of appearing inside a second rigid rectangle.
	face_mat.uv1_scale = Vector3(0.84, 0.86, 1.0)
	face_mat.uv1_offset = Vector3(0.08, 0.07, 0.0)
	face.material_override = face_mat
	face.position = Vector3(0, TILE_THICK + 0.005, 0)
	root3.add_child(face)
	t.face_mat = face_mat

	var overlay := MeshInstance3D.new()
	overlay.mesh = _shared_overlay_mesh
	var overlay_mat := StandardMaterial3D.new()
	overlay_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay_mat.albedo_color = Color(0.03, 0.06, 0.07, 0.42)
	overlay.material_override = overlay_mat
	overlay.position = Vector3(0, TILE_THICK + 0.009, 0)
	overlay.visible = false
	root3.add_child(overlay)
	t.overlay = overlay

	var glow := MeshInstance3D.new()
	glow.mesh = _shared_glow_mesh
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color = Color(palette.get("gold", Color("f3c86b")))
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(palette.get("gold", Color("f3c86b")))
	glow_mat.emission_energy_multiplier = 1.6
	glow.material_override = glow_mat
	glow.position = Vector3(0, TILE_THICK + 0.002, 0)
	glow.visible = false
	root3.add_child(glow)
	t.glow = glow
	t.glow_mat = glow_mat

	var area := Area3D.new()
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TILE_W, TILE_THICK, TILE_D)
	col_shape.shape = shape
	col_shape.position = Vector3(0, TILE_THICK * 0.5, 0)
	area.add_child(col_shape)
	area.set_meta("tile_id", t.id)
	root3.add_child(area)

	root3.scale = Vector3(0.55, 0.55, 0.55)
	root3.position.y = target_pos.y + 3.0
	var tw := create_tween()
	tw.tween_interval(index * 0.018)
	tw.tween_property(root3, "position:y", target_pos.y, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(root3, "scale", Vector3.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _tile_by_id(id: int) -> Dictionary:
	for t in tiles:
		if t.id == id: return t
	return {}

func ensure_move() -> void:
	for _attempt in range(120):
		if has_moves(): return
		var values: Array = []
		for t in tiles: values.append(t.value)
		values.shuffle()
		for i in range(tiles.size()): tiles[i].value = values[i]

func _assign_solvable_values() -> bool:
	# Pair two open tiles, temporarily remove them, and repeat. Giving each
	# such pair one value guarantees a complete one-player solution path.
	var original_removed: Array = []
	for t in tiles:
		original_removed.append(t.removed)
	var removal_order: Array = []
	while true:
		var open: Array = []
		for t in tiles:
			if is_free(t):
				open.append(t)
		if open.is_empty():
			break
		if open.size() < 2:
			for i in range(tiles.size()):
				var tile: Dictionary = tiles[i]
				tile.removed = original_removed[i]
				tiles[i] = tile
			return false
		open.shuffle()
		var first: Dictionary = open.pop_back()
		var second: Dictionary = open.pop_back()
		_set_tile_removed(first.id, true)
		_set_tile_removed(second.id, true)
		removal_order.append(first.id)
		removal_order.append(second.id)
	for i in range(tiles.size()):
		var tile: Dictionary = tiles[i]
		tile.removed = original_removed[i]
		tiles[i] = tile
	if removal_order.is_empty():
		return false
	var pair_values: Array = []
	for pair_index in range(removal_order.size() / 2):
		pair_values.append(TileArt.PAIR_ART_IDS[pair_index % TileArt.PAIR_ART_IDS.size()])
	pair_values.shuffle()
	for i in range(removal_order.size()):
		_set_tile_value(removal_order[i], pair_values[i / 2])
	return true

func _set_tile_removed(tile_id: int, is_removed: bool) -> void:
	for i in range(tiles.size()):
		var tile: Dictionary = tiles[i]
		if tile.id == tile_id:
			tile.removed = is_removed
			tiles[i] = tile
			return

func _set_tile_value(tile_id: int, value: int) -> void:
	for i in range(tiles.size()):
		var tile: Dictionary = tiles[i]
		if tile.id == tile_id:
			tile.value = value
			tiles[i] = tile
			return

func is_free(t: Dictionary) -> bool:
	if t.removed: return false
	for other in tiles:
		if other.removed or other.layer <= t.layer: continue
		if abs(other.col - t.col) < 0.92 and abs(other.row - t.row) < 0.86: return false
	var left := false
	var right := false
	for other in tiles:
		if other.removed or other.layer != t.layer: continue
		if abs(other.row - t.row) < 0.62 and abs(other.col - t.col) < 0.95:
			if other.col < t.col: left = true
			if other.col > t.col: right = true
	return not (left and right)

func has_moves() -> bool:
	var open: Array = []
	for t in tiles:
		if is_free(t): open.append(t)
	for i in range(open.size()):
		for j in range(i + 1, open.size()):
			if open[i].value == open[j].value: return true
	return false

func has_active_tiles() -> bool:
	for t in tiles:
		if not t.removed: return true
	return false

func _refresh_overlays() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var gold: Color = palette.get("gold", Color("f3c86b"))
	for t in tiles:
		if t.removed or t.overlay == null: continue
		var free := is_free(t)
		t.overlay.visible = not free
		if t.glow == null or t.glow_mat == null: continue
		var is_sel: bool = t.id == selected
		var is_hint: bool = t.id in hint_pair and hint_until > now
		if is_sel or is_hint:
			t.glow.visible = true
			t.glow_mat.albedo_color = gold
			t.glow_mat.emission = gold
			t.glow_mat.emission_energy_multiplier = 1.8
		elif free:
			t.glow.visible = false
		else:
			t.glow.visible = false

func _process(_delta: float) -> void:
	if hint_until > 0.0 and Time.get_ticks_msec() / 1000.0 > hint_until:
		hint_pair = [-1, -1]
		hint_until = 0.0
		_refresh_overlays()
	hud.queue_redraw()

func _on_level_complete() -> void:
	var elapsed := int(Time.get_ticks_msec() / 1000.0 - started_at)
	if zen_mode:
		var reward := 20 + pairs * 2
		Economy.add_coins(reward)
		last_stars = 0
		last_reward = reward
		feedback = "The workshop is tidy again. +%d coins." % reward
	else:
		var lvl := LevelData.get_level(level_id)
		var stars := LevelData.stars_for(level_id, elapsed)
		SaveData.set_level_result(level_id, stars, elapsed, moves)
		var reward: int = lvl.reward + stars * 15
		Economy.add_coins(reward)
		last_stars = stars
		last_reward = reward
		feedback = "Cleared with %d star(s). +%d coins." % [stars, reward]
	play_tone(1320.0, 0.18, 0.22)
	_show_interstitial_ad()

func _show_interstitial_ad() -> void:
	# Android-only bridge into the custom Godot activity. The call is a no-op
	# on desktop and if an ad has not finished loading yet.
	if OS.get_name() != "Android":
		return
	var godot_lib := JavaClassWrapper.wrap("org/godotengine/godot/GodotLib")
	var activity = godot_lib.getActivity()
	if activity != null:
		activity.showInterstitial()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			if active_touches.size() == 1:
				touch_moved = false
			else:
				touch_moved = true
				pinch_distance = _touch_distance()
		else:
			var is_tap := active_touches.size() == 1 and not touch_moved
			active_touches.erase(event.index)
			if active_touches.size() < 2:
				pinch_distance = 0.0
			if is_tap:
				_try_tile_tap(event.position)
		return
	if event is InputEventScreenDrag:
		if not active_touches.has(event.index):
			return
		active_touches[event.index] = event.position
		_handle_touch_gesture(event.relative)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_down = event.pressed
		if event.pressed:
			mouse_start = event.position
			mouse_moved = false
		elif not mouse_moved:
			_try_tile_tap(event.position)
		return
	if event is InputEventMouseMotion and mouse_down:
		if event.relative.length() > 0.0:
			mouse_moved = mouse_moved or event.position.distance_to(mouse_start) > 10.0
			if mouse_moved:
				_orbit_camera(event.relative)

func _touch_distance() -> float:
	if active_touches.size() < 2:
		return 0.0
	var points := active_touches.values()
	var first: Vector2 = points[0]
	var second: Vector2 = points[1]
	return first.distance_to(second)

func _handle_touch_gesture(relative: Vector2) -> void:
	if active_touches.size() >= 2:
		touch_moved = true
		var current_distance := _touch_distance()
		if pinch_distance > 0.0 and current_distance > 0.0:
			camera_zoom = clampf(camera_zoom * pinch_distance / current_distance, 0.68, 1.35)
			_update_board_camera()
		pinch_distance = current_distance
	else:
		touch_moved = true
		_orbit_camera(relative)

func _orbit_camera(delta: Vector2) -> void:
	camera_yaw -= delta.x * 0.006
	camera_pitch = clampf(camera_pitch + delta.y * 0.12, 48.0, 78.0)
	_update_board_camera()

func _try_tile_tap(pos: Vector2) -> void:
	if finished or stuck:
		return
	var from := camera.project_ray_origin(pos)
	var to := from + camera.project_ray_normal(pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty(): return
	var area: Area3D = result.collider
	var tile_id: int = area.get_meta("tile_id")
	_handle_tile_tap(tile_id)

func _handle_tile_tap(tile_id: int) -> void:
	var tapped := _tile_by_id(tile_id)
	if tapped.is_empty(): return
	if not is_free(tapped):
		feedback = "That tile is locked. Open a side first."
		return
	if selected < 0:
		selected = tile_id
		feedback = "Now find its twin."
		play_tone(880.0, 0.04, 0.12)
	elif selected == tile_id:
		selected = -1
		feedback = "Selection cleared."
	else:
		var sel := _tile_by_id(selected)
		history.append(snapshot())
		moves += 1
		if sel.value == tapped.value and is_free(sel):
			pairs += 1
			score += 120
			feedback = "A merry match. The gifts keep coming."
			selected = -1
			play_tone(1100.0, 0.07, 0.18)
			_animate_remove(sel)
			_animate_remove(tapped)
			_refresh_overlays()
			await get_tree().create_timer(0.3).timeout
			_refresh_overlays()
			if not has_active_tiles():
				finished = true
				_on_level_complete()
			elif not has_moves():
				stuck = true
				feedback = "No open pair remains."
			return
		else:
			score = maxi(0, score - 8)
			_animate_shake(sel)
			_animate_shake(tapped)
			selected = tile_id
			feedback = "Not a pair. Keep searching the tree."
			play_tone(220.0, 0.08, 0.16)
	_refresh_overlays()

func _animate_remove(t: Dictionary) -> void:
	t.removed = true
	var node: Node3D = t.node
	if node == null or not is_instance_valid(node): return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector3(0.05, 0.05, 0.05), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(node, "position:y", node.position.y + 0.7, 0.28)
	tw.chain().tween_callback(node.queue_free)

func _animate_shake(t: Dictionary) -> void:
	var node: Node3D = t.node
	if node == null or not is_instance_valid(node): return
	var base_x := node.position.x
	var tw := create_tween()
	tw.tween_property(node, "position:x", base_x + 0.08, 0.05)
	tw.tween_property(node, "position:x", base_x - 0.08, 0.05)
	tw.tween_property(node, "position:x", base_x, 0.05)

func _run_overlay_action(action: String) -> void:
	match action:
		"restart": new_deal()
		"shuffle": try_shuffle()
		"menu": Nav.go_to("res://scenes/MainMenu.tscn")
		"levels": Nav.go_to("res://scenes/LevelSelect.tscn")
		"next":
			var next_id := _next_level_id()
			if next_id != "":
				Nav.go_to("res://scenes/Game.tscn", {"level_id": next_id})
			else:
				Nav.go_to("res://scenes/LevelSelect.tscn")

func _next_level_id() -> String:
	var idx := -1
	for i in range(LevelData.levels.size()):
		if LevelData.levels[i].id == level_id:
			idx = i
			break
	if idx >= 0 and idx + 1 < LevelData.levels.size():
		return LevelData.levels[idx + 1].id
	return ""

func go_to_menu() -> void:
	Nav.go_to("res://scenes/MainMenu.tscn")

func show_hint() -> void:
	var open: Array = []
	for t in tiles:
		if is_free(t): open.append(t)
	for i in range(open.size()):
		for j in range(i + 1, open.size()):
			if open[i].value == open[j].value:
				if Economy.has_free_hint():
					Economy.use_free_hint()
				elif not Economy.spend_coins(Economy.HINT_COST):
					feedback = "Not enough coins for a hint."
					return
				hint_pair = [open[i].id, open[j].id]
				hint_until = Time.get_ticks_msec() / 1000.0 + 2.2
				hints_used += 1
				feedback = "A small nudge: these two belong together."
				play_tone(660.0, 0.06, 0.15)
				_refresh_overlays()
				return
	stuck = true
	feedback = "No open pair remains."

func snapshot() -> Dictionary:
	var state := {"score": score, "pairs": pairs, "moves": moves, "values": [], "removed": []}
	for t in tiles:
		state.values.append(t.value)
		state.removed.append(t.removed)
	return state

func undo() -> void:
	if history.is_empty():
		feedback = "There is nothing to undo yet."
		return
	if Economy.has_free_undo():
		Economy.use_free_undo()
	elif not Economy.spend_coins(Economy.UNDO_COST):
		feedback = "Not enough coins to undo."
		return
	var state: Dictionary = history.pop_back()
	score = state.score
	pairs = state.pairs
	moves = state.moves
	for i in range(tiles.size()):
		var t = tiles[i]
		var was_removed: bool = t.removed
		t.value = state.values[i]
		t.removed = state.removed[i]
		if was_removed and not t.removed:
			_spawn_tile(t, i)
	selected = -1
	finished = false
	stuck = false
	feedback = "Last move restored."
	_refresh_overlays()

func try_shuffle() -> void:
	if not Economy.spend_coins(Economy.SHUFFLE_COST):
		feedback = "Not enough coins to shuffle."
		return
	if not _assign_solvable_values():
		feedback = "The tiles could not be reshuffled."
		return
	for t in tiles:
		if not t.removed and t.face_mat != null: t.face_mat.albedo_texture = TileArt.get_texture(t.value)
	stuck = false
	feedback = "Tiles reshuffled."
	play_tone(500.0, 0.08, 0.18)
	_refresh_overlays()

func time_text() -> String:
	var elapsed := int(Time.get_ticks_msec() / 1000.0 - started_at)
	return "%02d:%02d" % [elapsed / 60, elapsed % 60]
