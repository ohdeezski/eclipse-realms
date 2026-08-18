extends SceneTree
## End-to-end smoke test for the first playable client slice.

var _failed: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_manager = get_root().get_node_or_null("SceneManager")
	var game_manager = get_root().get_node_or_null("GameManager")
	var game_data = get_root().get_node_or_null("GameData")
	_assert(scene_manager != null, "SceneManager autoload is available")
	_assert(game_manager != null, "GameManager autoload is available")
	_assert(game_data != null, "GameData autoload is available")
	if scene_manager == null or game_manager == null or game_data == null:
		quit(1)
		return
	for visual_id in ["pc_human_adept_01", "npc_village_elder_mira", "npc_blacksmith_dorn", "npc_ranger_silas", "npc_merchant_lira", "npc_innkeeper_bram", "mob_moss_slime", "mob_forest_wolf", "mob_thorn_wisp", "boss_cave_guardian"]:
		_assert(not game_data.get_avatar_visual(visual_id).is_empty(), "Avatar catalog contains %s" % visual_id)

	scene_manager.change_scene("res://scenes/ui/character_creation.tscn", "instant")
	await process_frame

	var creator = get_root().get_node_or_null("CharacterCreation")
	_assert(creator != null, "Character creation scene loads")
	if creator == null:
		quit(1)
		return

	var name_input: LineEdit = creator.get_node("Panel/NameInput")
	var body_select: OptionButton = creator.get_node("Panel/BodySelect")
	var gender_select: OptionButton = creator.get_node("Panel/GenderSelect")
	var pronouns_select: OptionButton = creator.get_node("Panel/PronounsSelect")
	var species_select: OptionButton = creator.get_node("Panel/SpeciesSelect")
	var job_summary: Label = creator.get_node("Panel/JobSummaryLabel")
	var create_button: Button = creator.get_node("ButtonContainer/CreateButton")
	_assert(gender_select.get_item_text(0) == "Woman", "Character creation includes Woman")
	_assert(gender_select.get_item_text(1) == "Man", "Character creation includes Man")
	_assert(gender_select.get_item_text(2) == "Nonbinary", "Character creation includes Nonbinary")
	_assert(gender_select.get_item_text(3) == "Genderfluid", "Character creation includes Genderfluid")
	name_input.text = "Aurora"
	body_select.select(2) # Muscular presentation is cosmetic only.
	gender_select.select(3) # Genderfluid
	pronouns_select.select(0) # They/them
	creator.call("_on_body_changed", 2)
	creator.call("_on_gender_identity_changed", 3)
	creator.call("_on_pronouns_changed", 0)
	creator.call("_on_next_pressed")
	_assert(species_select.visible, "Creator advances from Basics to Ancestry")
	creator.call("_on_back_pressed")
	_assert(name_input.visible, "Creator back navigation preserves the Basics step")
	creator.call("_on_next_pressed")
	creator.call("_on_next_pressed")
	_assert(job_summary.visible and job_summary.text.contains("Adept"), "Creator only offers the playable Adept calling")
	creator.call("_on_next_pressed")
	_assert(create_button.visible and not create_button.disabled, "Creator presents a review before character creation")
	creator.call("_on_create_pressed")
	await process_frame

	var character: Dictionary = game_manager.session_data.get("character", {})
	var player_data: Dictionary = game_manager.session_data.get("player", {})
	_assert(character.get("name", "") == "Aurora", "Created character name is stored")
	_assert(character.get("gender_identity", "") == "Genderfluid", "Gender identity is stored separately from appearance")
	_assert(character.get("pronouns", "") == "They/them", "Pronouns are stored")
	_assert(character.get("stats", {}).get("attack", 0) == 10, "Body presentation does not modify stats")
	_assert(player_data.get("avatar_id", "") == "pc_human_adept_01", "Player avatar uses the visual catalog")
	_assert(player_data.get("species_id", "") == "human", "Selected ancestry is persisted")
	_assert(player_data.get("job_id", "") == "adept", "Adept calling is persisted")
	_assert(player_data.get("character_schema_version", 0) == 2, "New saves use character schema v2")
	_assert(not player_data.get("profile_sharing_enabled", true), "Identity sharing defaults to private")
	_assert(player_data.get("gold", 0) == 100, "New character receives starting gold")
	_assert(player_data.get("inventory", []).size() == 4, "New character receives job starter supplies")
	_assert(player_data.get("equipment", {}).get("weapon", "") == "wooden_sword", "Adept receives starter weapon")

	var oakrest = get_root().get_node_or_null("OakrestVillage")
	var player = get_root().get_node_or_null("OakrestVillage/Player")
	_assert(oakrest != null, "Oakrest scene loads after character creation")
	_assert(player != null, "Oakrest player instance exists")
	if player != null:
		_assert(player.get("gold") == 100, "Oakrest player receives created gold")
		_assert(player.get("character_name") == "Aurora", "Oakrest player keeps created name")
		_assert(player.get("inventory").size() == 4, "Oakrest player receives job starter supplies")
		_assert(player.get("gender_identity") == "Genderfluid", "Oakrest player keeps the selected identity")
		_assert(player.get("species_id") == "human", "Oakrest player keeps selected ancestry")
		_assert(player.get("job_id") == "adept", "Oakrest player keeps selected calling")

	quit(1 if _failed else 0)


func _assert(condition: bool, description: String) -> void:
	if condition:
		print("  [PASS] %s" % description)
	else:
		_failed = true
		print("  [FAIL] %s" % description)
