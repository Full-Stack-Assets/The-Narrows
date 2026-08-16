extends Node

const COMMIT_SHA := "local"
const BUILD_DATE := "unknown-date"


func display_string() -> String:
	return format_display(COMMIT_SHA, BUILD_DATE)


static func format_display(commit_sha: String, build_date: String) -> String:
	var short_sha := commit_sha if commit_sha == "local" else commit_sha.left(7)
	return "%s · %s" % [short_sha, build_date]
