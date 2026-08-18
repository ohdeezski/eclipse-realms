## MonsterSpawner.gd - Scene-local monster spawning for authored world scenes.
## A world scene opts in by assigning a Monster scene and a spawn parent.

extends Node
class_name MonsterSpawner

@export var monster_scene: PackedScene
@export var spawn_parent: NodePath

var active_monsters: Array[CharacterBody2D] = []


func spawn_monster(monster_id: String, spawn_position: Vector2) -> CharacterBody2D:
	if monster_scene == null:
		push_warning("[MonsterSpawner] No monster scene is assigned")
		return null
	var instance = monster_scene.instantiate()
	if not instance is CharacterBody2D:
		push_warning("[MonsterSpawner] Assigned scene is not a CharacterBody2D")
		instance.free()
		return null
	var parent: Node = get_node_or_null(spawn_parent) if not spawn_parent.is_empty() else get_parent()
	if parent == null:
		push_warning("[MonsterSpawner] No spawn parent is available")
		instance.free()
		return null
	parent.add_child(instance)
	instance.global_position = spawn_position
	if instance.has_method("configure"):
		instance.configure(GameData.get_monster(monster_id))
	active_monsters.append(instance)
	instance.tree_exited.connect(_forget_monster.bind(instance))
	return instance


func clear_monsters() -> void:
	for monster in active_monsters.duplicate():
		if is_instance_valid(monster):
			monster.queue_free()
	active_monsters.clear()


func get_active_count() -> int:
	return active_monsters.size()


func _forget_monster(monster: CharacterBody2D) -> void:
	active_monsters.erase(monster)
