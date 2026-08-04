extends Node
## PuzzleSystem.gd - Manages dungeon puzzles: pressure plates, switches, and locked doors.
##
## Attach to a Node in the dungeon scene. Add PressurePlate, Switch, and LockedDoor
## as children. The system tracks puzzle state and triggers door unlocks.

signal puzzle_solved(puzzle_id: String)
signal plate_activated(plate_id: String)
signal switch_toggled(switch_id: String, is_on: bool)
signal door_unlocked(door_id: String)
signal all_puzzles_solved()

## Puzzle state tracking
var activated_plates: Dictionary = {}  # plate_id -> bool
var toggled_switches: Dictionary = {}  # switch_id -> bool
var unlocked_doors: Dictionary = {}    # door_id -> bool
var puzzle_solutions: Dictionary = {}  # puzzle_id -> required plates/switches

## References to puzzle nodes
var pressure_plates: Array = []
var switches: Array = []
var locked_doors: Array = []


func _ready() -> void:
	call_deferred("_find_puzzle_nodes")
	call_deferred("_setup_puzzle_solutions")


func _find_puzzle_nodes() -> void:
	# Find all pressure plates
	pressure_plates = []
	for child in get_children():
		if child.is_in_group("pressure_plate"):
			pressure_plates.append(child)
			activated_plates[child.puzzle_id] = false
			child.activated.connect(_on_plate_activated.bind(child.puzzle_id))
			child.deactivated.connect(_on_plate_deactivated.bind(child.puzzle_id))
	
	# Find all switches
	switches = []
	for child in get_children():
		if child.is_in_group("switch"):
			switches.append(child)
			toggled_switches[child.puzzle_id] = false
			child.toggled.connect(_on_switch_toggled.bind(child.puzzle_id))
	
	# Find all locked doors
	locked_doors = []
	for child in get_children():
		if child.is_in_group("locked_door"):
			locked_doors.append(child)
			unlocked_doors[child.puzzle_id] = false
	
	print("[PuzzleSystem] Found %d plates, %d switches, %d doors" % [
		pressure_plates.size(), switches.size(), locked_doors.size()
	])


func _setup_puzzle_solutions() -> void:
	# Define puzzle solutions: which plates/switches must be activated to unlock doors
	# Puzzle 1: Enter the first room - all 3 plates in entry corridor
	puzzle_solutions["puzzle_entry"] = {
		"type": "plates",
		"required": ["plate_entry_1", "plate_entry_2", "plate_entry_3"],
		"door": "door_corridor"
	}
	
	# Puzzle 2: Skeleton Hall - must hit switches in order
	puzzle_solutions["puzzle_skeleton"] = {
		"type": "switches",
		"required": ["switch_skeleton_1", "switch_skeleton_2", "switch_skeleton_3"],
		"door": "door_boss"
	}
	
	# Puzzle 3: Spike room - stand on specific plates while avoiding spikes
	puzzle_solutions["puzzle_spikes"] = {
		"type": "plates",
		"required": ["plate_spike_safe_1", "plate_spike_safe_2"],
		"door": "door_spike_exit"
	}


func _on_plate_activated(plate_id: String) -> void:
	activated_plates[plate_id] = true
	plate_activated.emit(plate_id)
	AudioManager.play_sfx("puzzle_plate")
	_check_puzzles()
	print("[PuzzleSystem] Plate activated: %s" % plate_id)


func _on_plate_deactivated(plate_id: String) -> void:
	activated_plates[plate_id] = false
	_check_puzzles()
	print("[PuzzleSystem] Plate deactivated: %s" % plate_id)


func _on_switch_toggled(switch_id: String, is_on: bool) -> void:
	toggled_switches[switch_id] = is_on
	switch_toggled.emit(switch_id, is_on)
	AudioManager.play_sfx("puzzle_switch")
	_check_puzzles()
	print("[PuzzleSystem] Switch toggled: %s (on=%s)" % [switch_id, is_on])


func _check_puzzles() -> void:
	for puzzle_id in puzzle_solutions:
		var solution = puzzle_solutions[puzzle_id]
		var is_solved = true
		
		match solution["type"]:
			"plates":
				# All required plates must be activated simultaneously
				for plate_id in solution["required"]:
					if not activated_plates.get(plate_id, false):
						is_solved = false
						break
			"switches":
				# All required switches must be toggled on
				for switch_id in solution["required"]:
					if not toggled_switches.get(switch_id, false):
						is_solved = false
						break
		
		if is_solved and not unlocked_doors.get(solution["door"], false):
			_unlock_door(solution["door"])
			puzzle_solved.emit(puzzle_id)
			AudioManager.play_sfx("puzzle_solved")
			UIManager.show_notification("Puzzle solved! Door unlocked!", "info")
			
			# Check if all puzzles are solved
			var all_solved = true
			for pid in puzzle_solutions:
				if not unlocked_doors.get(puzzle_solutions[pid]["door"], false):
					all_solved = false
					break
			if all_solved:
				all_puzzles_solved.emit()
				UIManager.show_notification("All puzzles solved! The path is clear!", "info")


func _unlock_door(door_id: String) -> void:
	unlocked_doors[door_id] = true
	door_unlocked.emit(door_id)
	
	# Find and unlock the door node
	for door in locked_doors:
		if door.puzzle_id == door_id and door.has_method("unlock"):
			door.unlock()
			print("[PuzzleSystem] Unlocked door: %s" % door_id)
			return
	
	push_warning("[PuzzleSystem] Door not found: %s" % door_id)


func is_puzzle_solved(puzzle_id: String) -> bool:
	if not puzzle_solutions.has(puzzle_id):
		return false
	return unlocked_doors.get(puzzle_solutions[puzzle_id]["door"], false)


func get_puzzle_progress(puzzle_id: String) -> Dictionary:
	if not puzzle_solutions.has(puzzle_id):
		return {"solved": false, "progress": 0, "total": 0}
	
	var solution = puzzle_solutions[puzzle_id]
	var total = solution["required"].size()
	var progress = 0
	
	match solution["type"]:
		"plates":
			for plate_id in solution["required"]:
				if activated_plates.get(plate_id, false):
					progress += 1
		"switches":
			for switch_id in solution["required"]:
				if toggled_switches.get(switch_id, false):
					progress += 1
	
	return {
		"solved": unlocked_doors.get(solution["door"], false),
		"progress": progress,
		"total": total
	}
