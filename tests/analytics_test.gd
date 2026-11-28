extends SceneTree
const Client=preload("res://scripts/analytics/client.gd")
const Consent=preload("res://scripts/save/analytics_consent.gd")
const UI=preload("res://scripts/ui/terminal_ui.gd")
var privacy_checks: int=0
func privacy_check(value: bool,msg: String) -> void:
	privacy_checks+=1
	check(value,msg)
var failures: int=0
func check(value: bool,msg: String) -> void:
	if not value:
		failures+=1
		printerr("ANALYTICS FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var node:=Client.new()
	root.add_child(node)
	node.configure("https://saperror.example.test")
	node.observe("campaign",1,2,1.0)
	check(node.snapshot().is_empty(),"default off")
	node.set_permission(true)
	node.configure("")
	node.observe("campaign",1,2,1.0)
	check(node.snapshot().is_empty(),"missing endpoint off")
	check(not Client.valid_endpoint("http://example.test") and not Client.valid_endpoint("https://example.test@evil.test"),"HTTPS host only")
	node.configure("https://saperror.example.test")
	node.observe("campaign",1,2,1.0)
	var initial: String=node.session_id
	check(initial.length()==32 and node.snapshot().size()==9,"ephemeral strict payload")
	node.outcome(42,true)
	node.outcome(42,true)
	node.outcome(43,false)
	check(node.wins==1 and node.losses==1,"dedupe results")
	node.observe("",4,0,1.0)
	node.observe("campaign",1,3,1.0,false)
	check(node.active_seconds==1.0,"paused time excluded")
	node.observe("classic",0,0,1.0)
	check(node.session_id!=initial and node.wins==0,"new mode fresh session")
	node.set_permission(false)
	check(node.snapshot().is_empty() and node.session_id.is_empty() and node.network_attempts==0,"revocation and no headless traffic")
	node.observe("classic",0,0,65.0)
	node._completed(HTTPRequest.RESULT_SUCCESS,204,PackedStringArray(),PackedByteArray())
	check(node.snapshot().is_empty() and not node.dirty and node.network_attempts==0,"revoked cannot restart on update or late callback")
	node.set_permission(true)
	node.observe("classic",0,0,1.0)
	check(node.enabled() and node.session_id!=initial and node.wins==0,"fresh explicit consent")
	node.set_permission(false)
	check(not node.enabled() and not node.in_flight,"revocation clears in-flight state")
	node.set_permission(true)
	node.observe_clock("classic",0,0,1000,true)
	for i in range(1,301): node.observe_clock("classic",0,0,1000+i*1000,true)
	check(int(node.snapshot()["seconds"])==300,"monotonic five minutes independent of frame delta")
	node.observe_clock("classic",0,0,302000,false)
	node.observe_clock("classic",0,0,303000,true)
	node.observe_clock("classic",0,0,304000,true)
	check(int(node.snapshot()["seconds"])==301,"focus loss and return do not credit background")
	node.observe_clock("classic",0,0,324000,true)
	check(int(node.snapshot()["seconds"])==301,"suspend gap excluded")
	node.set_permission(false)
	check(node.final_summaries.is_empty(),"revocation clears final summary buffer")
	node.set_permission(true)
	node.observe("classic",0,0,7.0)
	var switched_id: String=node.session_id
	node.in_flight=true
	node.in_flight_session_id=switched_id
	node.observe("campaign",1,1,2.0)
	check(node.final_summaries.size()==1 and node.final_summaries[0]["id"]==switched_id and node.final_summaries[0]["seconds"]==7,"mode switch retains cumulative snapshot during in-flight request")
	check(node.session_id!=switched_id and node.active_seconds==2.0,"next session independent")
	for i in range(12): node.observe("classic" if i%2==0 else "campaign",0,0,2.0)
	check(node.final_summaries.size()==Client.MAX_FINAL_SUMMARIES,"bounded RAM buffer")
	node.set_permission(false)
	check(node.final_summaries.is_empty() and not node.in_flight,"revocation discards buffered summaries")
	node.queue_free()
	await process_frame
	await privacy_regression()
	print("RC8_PRIVACY_QA checks=",privacy_checks," failures=",failures)
	print("ANALYTICS_QA failures=",failures)
	quit(0 if failures==0 else 1)

func isolated_ui(consent_path: String,save_path: String) -> UI:
	var ui:=UI.new()
	ui.analytics_consent_path=consent_path
	ui.session_path=save_path
	ui.require_content_warning=false
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	return ui
func clean_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func privacy_regression() -> void:
	var prefix: String="user://qa_rc8_"+str(OS.get_process_id())
	var consent_path: String=prefix+"_consent.txt"
	var save_path: String=prefix+"_session.cfg"
	for suffix in ["",".tmp"]: clean_file(consent_path+suffix)
	for suffix in ["",".bak",".tmp",".bak.tmp"]: clean_file(save_path+suffix)
	privacy_check(not Consent.allowed(consent_path),"missing consent defaults off")
	var old:=FileAccess.open(consent_path,FileAccess.WRITE)
	privacy_check(old!=null,"isolated consent fixture writable")
	if old!=null:
		old.store_string("v2:allow")
		old.close()
	privacy_check(not Consent.allowed(consent_path),"retired consent rejected")
	var ui:=isolated_ui(consent_path,save_path)
	privacy_check(not ui.analytics_allowed and not ui.telemetry.enabled(),"old consent does not activate client")
	ui._show("privacy")
	var toggle:=ui.page.find_child("AnalyticsConsent",true,false) as Button
	privacy_check(is_instance_valid(toggle),"actual privacy toggle exists")
	if is_instance_valid(toggle): toggle.pressed.emit()
	privacy_check(ui.analytics_allowed and ui.telemetry.enabled() and Consent.allowed(consent_path),"explicit opt-in persists")
	ui.queue_free()
	await process_frame
	ui=isolated_ui(consent_path,save_path)
	privacy_check(ui.analytics_allowed and ui.telemetry.enabled(),"opt-in restored after UI restart")
	ui.telemetry.observe("classic",0,0,1.0)
	var previous: String=ui.telemetry.session_id
	privacy_check(previous.length()==32,"ephemeral session allocated")
	for _i in range(299): ui.telemetry.observe("classic",0,0,1.0)
	privacy_check(int(ui.telemetry.snapshot()["seconds"])==300,"five minutes active time captured")
	ui.telemetry.in_flight_session_id=previous
	ui.telemetry.in_flight_seconds=300
	ui.telemetry._completed(HTTPRequest.RESULT_SUCCESS,204,PackedStringArray(),PackedByteArray())
	privacy_check(ui.telemetry.accepted_seconds==300 and ui.telemetry.last_http_code==204,"acknowledged active seconds exposed")
	ui.telemetry._completed(HTTPRequest.RESULT_CANT_CONNECT,0,PackedStringArray(),PackedByteArray())
	privacy_check(ui.telemetry.dirty and not ui.telemetry.in_flight,"simulated offline completion does not block client")
	ui._show("classic")
	privacy_check(ui.screen=="classic" and is_instance_valid(ui.page),"classic UI reachable after simulated offline failure")
	ui._show("privacy")
	toggle=ui.page.find_child("AnalyticsConsent",true,false) as Button
	privacy_check(is_instance_valid(toggle),"real revocation toggle")
	if is_instance_valid(toggle): toggle.pressed.emit()
	privacy_check(not ui.analytics_allowed and not Consent.allowed(consent_path) and ui.telemetry.snapshot().is_empty(),"revocation persists and clears session")
	ui.telemetry._completed(HTTPRequest.RESULT_CANT_CONNECT,0,PackedStringArray(),PackedByteArray())
	ui.telemetry.observe("classic",0,0,1.0)
	privacy_check(not ui.telemetry.dirty and ui.telemetry.network_attempts==0,"late network error cannot resume revoked session")
	ui.queue_free()
	await process_frame
	ui=isolated_ui(consent_path,save_path)
	privacy_check(not ui.analytics_allowed and not ui.telemetry.enabled(),"denial restored after UI restart")
	ui._set_analytics_consent(true)
	ui.telemetry.observe("classic",0,0,1.0)
	privacy_check(ui.telemetry.session_id.length()==32 and ui.telemetry.session_id!=previous,"fresh consent creates fresh session")
	ui._set_analytics_consent(false)
	privacy_check(not ui.telemetry.enabled() and not Consent.allowed(consent_path),"final revoke")
	ui.queue_free()
	await process_frame
	for suffix in ["",".tmp"]: clean_file(consent_path+suffix)
	for suffix in ["",".bak",".tmp",".bak.tmp"]: clean_file(save_path+suffix)
