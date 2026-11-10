extends RefCounted
class_name Layouts

const COUNT := 5

static func make_slots(_layout: int, rng: RandomNumberGenerator) -> Array:
	var slots: Array = []
	# One continuous foundation, with two independently positioned towers on
	# top. This keeps the base readable while making each deal feel different.
	for row in range(6):
		for col in range(6):
			slots.append(Vector3(col, row, 0))
	var first_pile := Vector2i(0, rng.randi_range(0, 1))
	var second_pile := Vector2i(1, rng.randi_range(3, 4))
	_add_top_pile(slots, first_pile.x, first_pile.y)
	_add_top_pile(slots, second_pile.x, second_pile.y)
	# Move two foundation tiles into the raised piles. Deals can widen both
	# piles or give one pile a stepped extension, avoiding a rigid rectangle.
	if rng.randi_range(0, 1) == 0:
		_add_pile_extension(slots, first_pile.x, first_pile.y, 1)
		_add_pile_extension(slots, second_pile.x, second_pile.y, -1)
	elif rng.randi_range(0, 1) == 0:
		_add_pile_extension(slots, first_pile.x, first_pile.y, 1)
		_add_pile_extension(slots, first_pile.x, first_pile.y, 1, true)
	else:
		_add_pile_extension(slots, second_pile.x, second_pile.y, -1)
		_add_pile_extension(slots, second_pile.x, second_pile.y, -1, true)
	_remove_two_uncovered_base_tiles(slots, rng)
	return slots

static func _add_top_pile(slots: Array, start_col: int, start_row: int) -> void:
	# Two broad lower steps and a narrow peak form one five-high tower.
	# Each step narrows by one tile, so a raised tile always bridges exactly two
	# lower tiles and never extends beyond the pile beneath it.
	for row in range(2):
		for col in range(4): slots.append(Vector3(start_col + col, start_row + row, 1))
	for col in range(3): slots.append(Vector3(start_col + col, start_row + 1, 2))
	for col in range(2): slots.append(Vector3(start_col + col, start_row + 1, 3))
	slots.append(Vector3(start_col, start_row + 1, 4))

static func _add_pile_extension(slots: Array, start_col: int, start_row: int, direction: int, upper_step := false) -> void:
	# The lower tile bridges two base tiles. Its matching upper tile bridges it
	# and the existing lower row, so every added tile remains fully supported.
	if upper_step:
		var upper_col := start_col + (3 if direction > 0 else -1)
		slots.append(Vector3(upper_col, start_row + 1, 2))
	else:
		var lower_col := start_col + (4 if direction > 0 else -1)
		slots.append(Vector3(lower_col, start_row + 1, 1))

static func _remove_two_uncovered_base_tiles(slots: Array, rng: RandomNumberGenerator) -> void:
	var protected_base: Dictionary = {}
	for slot: Vector3 in slots:
		if int(slot.z) != 1:
			continue
		# A layer-one tile at x + 0.5 bridges base positions x and x + 1.
		protected_base[Vector2i(int(slot.x), int(slot.y))] = true
		protected_base[Vector2i(int(slot.x) + 1, int(slot.y))] = true
	var candidates: Array[int] = []
	for index in range(slots.size()):
		var slot: Vector3 = slots[index]
		if int(slot.z) == 0 and not protected_base.has(Vector2i(int(slot.x), int(slot.y))):
			candidates.append(index)
	candidates.shuffle()
	var first := candidates[0]
	var second := candidates[1]
	if first < second:
		slots.remove_at(second)
		slots.remove_at(first)
	else:
		slots.remove_at(first)
		slots.remove_at(second)

static func make_classic_slots(layout: int) -> Array:
	var slots: Array = []
	if layout == 0:
		for row in range(7):
			for col in range(6): slots.append(Vector3(col, row, 0))
		for row in range(2, 6):
			for col in range(1, 5): slots.append(Vector3(col, row, 1))
		for row in range(3, 5):
			for col in range(2, 4): slots.append(Vector3(col, row, 2))
	elif layout == 1:
		for col in range(1, 5): slots.append(Vector3(col, 0, 0))
		for row in range(1, 6):
			for col in range(6): slots.append(Vector3(col, row, 0))
		for col in range(1, 5): slots.append(Vector3(col, 6, 0))
		for row in range(2, 5):
			for col in range(1, 5): slots.append(Vector3(col, row, 1))
		for row in range(3, 5):
			for col in range(2, 4): slots.append(Vector3(col, row, 2))
	elif layout == 2:
		for row in range(7):
			var start := 1 if row == 2 or row == 4 else 0
			var finish := 5 if row == 2 or row == 4 else 6
			for col in range(start, finish): slots.append(Vector3(col, row, 0))
		for row in range(1, 5):
			for col in range(1, 5): slots.append(Vector3(col, row, 1))
		for row in range(3, 5):
			for col in range(2, 4): slots.append(Vector3(col, row, 2))
	elif layout == 3:
		for row in range(7):
			var pad: int = mini(absi(row - 3), 2)
			for col in range(pad, 6 - pad): slots.append(Vector3(col, row, 0))
		for row in range(2, 5):
			for col in range(1, 5): slots.append(Vector3(col, row, 1))
		for row in range(3, 5):
			for col in range(2, 4): slots.append(Vector3(col, row, 2))
	else:
		for row in range(7):
			if row == 0 or row == 1 or row == 5 or row == 6:
				for col in range(2, 4): slots.append(Vector3(col, row, 0))
			else:
				for col in range(6): slots.append(Vector3(col, row, 0))
		for row in range(2, 5):
			for col in range(1, 5): slots.append(Vector3(col, row, 1))
		for row in range(3, 5):
			for col in range(2, 4): slots.append(Vector3(col, row, 2))
	# Extend every board into a five-layer tower.
	for row in range(3, 5):
		slots.append(Vector3(1, row, 2))
	for row in range(3, 5):
		for col in range(1, 3): slots.append(Vector3(col, row, 3))
	for row in range(3, 5):
		slots.append(Vector3(1, row, 4))
	return slots
