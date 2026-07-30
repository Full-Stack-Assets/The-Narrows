extends RefCounted

const SaveMigrations = preload("res://scripts/save/save_migrations.gd")
const SaveSchema = preload("res://scripts/save/save_schema.gd")
const SaveService = preload("res://scripts/save/save_service.gd")


static func run(t: SceneTree) -> void:
	var legacy := {
		"cash": 725,
		"wanted_level": 2,
		"faction_level": 3,
		"has_pos": true,
		"px": 10.0,
		"py": 2.0,
		"pz": -4.0,
		"yaw": 1.25,
		"scrimshaw_mask": 5,
		"owned_business_mask": 3,
		"campaign_format": 1,
		"campaign_mi": 7,
		"campaign_step": 2,
	}
	var migrated := SaveMigrations.to_current(legacy)
	t.assert_eq(migrated.get("schema_version"), 3, "unversioned saves migrate to schema v3")
	t.assert_eq(migrated["player"]["position"], [10.0, 2.0, -4.0], "legacy position migrates")
	t.assert_eq(migrated["economy"]["cash"], 725, "legacy cash migrates")
	t.assert_eq(migrated["legacy_campaign"]["mission_index"], 8, "v1 campaign index receives inserted mission")

	var campaign_v2 := {
		"campaign_format": 2,
		"opener_complete": true,
		"campaign_mi": 5,
		"campaign_step": 1,
		"campaign_done": false,
	}
	var campaign_migrated := SaveMigrations.to_current(campaign_v2)
	t.assert_eq(campaign_migrated["legacy_campaign"]["format"], 2, "campaign v2 format is retained")
	t.assert_eq(campaign_migrated["legacy_campaign"]["mission_index"], 5, "campaign v2 index is not shifted")
	t.assert_true(SaveMigrations.to_current({"schema_version": 99}).is_empty(), "future saves are rejected")
	t.assert_true(SaveMigrations.from_json("{not json").is_empty(), "corrupt JSON is rejected")

	var incomplete := SaveMigrations.to_current({"schema_version": 3, "economy": {"cash": 10}})
	t.assert_true(SaveSchema.is_valid(incomplete), "missing current-version fields receive defaults")
	t.assert_eq(incomplete["player"]["health"], 100.0, "missing player health receives default")

	var test_dir := "/tmp/the-narrows-codex-save-service-tests"
	var service := SaveService.new(test_dir)
	service.remove_test_files()
	var first := SaveSchema.blank()
	first["economy"]["cash"] = 111
	first["settings"]["graphics"]["quality"] = 2
	first["settings"]["accessibility"]["subtitles"] = false
	first["cheats"] = {"time_phase": 0.75, "force_rain": 1}
	first["mission"]["snapshot"] = {"mission_id": "off_the_boat", "objective_index": 3}
	first["activities"] = {"new_bedford_race": {"best_time": 42.5}}
	t.assert_eq(service.write(first), OK, "first save writes atomically")
	t.assert_true(service.has_valid_save(), "written save validates")
	t.assert_true(not str(service.read()["saved_at"]).is_empty(), "writes include an ISO save timestamp")
	t.assert_true(service.read().has("source_build_sha"), "writes include source build provenance")
	t.assert_eq(service.read()["mission"]["snapshot"]["objective_index"], 3, "open mission snapshot data survives normalization")
	t.assert_eq(service.read()["activities"]["new_bedford_race"]["best_time"], 42.5, "activity results survive normalization")

	var second := first.duplicate(true)
	second["economy"]["cash"] = 222
	t.assert_eq(service.write(second), OK, "second save rotates the primary")
	t.assert_true(service.has_recoverable_backup(), "valid previous primary becomes a backup")
	t.assert_eq(service.read()["economy"]["cash"], 222, "read returns newest primary")

	t.assert_eq(service.write_raw_primary_for_test("{corrupt"), OK, "test can simulate a corrupt primary")
	t.assert_true(not service.has_valid_save(), "corrupt primary is not offered as Continue")
	t.assert_eq(service.recover_backup(), OK, "valid backup can replace corrupt primary")
	t.assert_eq(service.read()["economy"]["cash"], 111, "backup recovery restores previous state")

	t.assert_eq(service.clear_progress_preserve_settings(), OK, "New Game reset succeeds")
	var reset := service.read()
	t.assert_eq(reset["economy"]["cash"], SaveSchema.STARTING_CASH, "New Game clears progress")
	t.assert_eq(reset["settings"]["graphics"]["quality"], 2, "New Game preserves graphics settings")
	t.assert_eq(reset["settings"]["accessibility"]["subtitles"], false, "New Game preserves accessibility settings")
	t.assert_eq(reset["cheats"]["time_phase"], 0.75, "New Game preserves the saved time test setting")
	t.assert_eq(reset["cheats"]["force_rain"], 1, "New Game preserves the saved weather test setting")
	service.remove_test_files()
