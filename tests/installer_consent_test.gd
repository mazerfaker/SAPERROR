extends SceneTree
const UI=preload("res://scripts/ui/terminal_ui.gd")
const Consent=preload("res://scripts/save/analytics_consent.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var path: String=OS.get_environment("SAPERROR_QA_CONSENT_PATH")
	var choice: String=OS.get_environment("SAPERROR_QA_CONSENT_EXPECT")
	if path.is_empty() or not choice in ["allow","deny"] or not FileAccess.file_exists(path):
		printerr("INSTALLER_HANDOFF_QA missing fixture")
		quit(1)
		return
	var expected: bool=choice=="allow"
	var ui:=UI.new()
	ui.analytics_consent_path=path
	ui.require_content_warning=false
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	var valid: bool=Consent.allowed(path)==expected and ui.analytics_allowed==expected and ui.telemetry.enabled()==expected
	print("INSTALLER_HANDOFF_QA ",choice," passed=",valid)
	ui.queue_free()
	quit(0 if valid else 1)
