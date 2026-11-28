extends Node
# Ephemeral session summaries only. No local queue, stable identifier, device fingerprint or raw actions.
const PERIOD: float=60.0
const MIN_SEND_INTERVAL: float=5.0
var endpoint: String=""
var pilot_token: String=""
var pilot_version: String=""
var consent: bool=false
var request: HTTPRequest
var session_id: String=""
var mode: String=""
var difficulty: int=4
var active_seconds: float=0.0
var wins: int=0
var losses: int=0
var sector: int=0
var elapsed: float=0.0
var dirty: bool=false
var in_flight: bool=false
var last_result_id: int=0
var network_attempts: int=0
static func valid_endpoint(value: String) -> bool:
	var pattern:=RegEx.new()
	pattern.compile("^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$")
	return pattern.search(value)!=null
func configure(value: String) -> void:
	endpoint=value if valid_endpoint(value) else ""
func configure_pilot(value: String,token: String,version: String) -> void:
	var pattern:=RegEx.new()
	pattern.compile("^[a-f0-9]{64}$")
	pilot_token=token if token.length()==64 and pattern.search(token)!=null else ""
	pilot_version=version if not pilot_token.is_empty() else ""
	configure(value if not pilot_token.is_empty() and not pilot_version.is_empty() else "")
func _ready() -> void:
	request=HTTPRequest.new()
	request.timeout=8.0
	request.max_redirects=0
	request.body_size_limit=4096
	add_child(request)
	request.request_completed.connect(_completed)
func set_permission(value: bool) -> void:
	if consent==value: return
	consent=value
	if not value:
		if is_instance_valid(request): request.cancel_request()
		in_flight=false
		_clear()
func _clear() -> void:
	session_id=""
	mode=""
	difficulty=4
	active_seconds=0.0
	wins=0
	losses=0
	sector=0
	elapsed=0.0
	dirty=false
	last_result_id=0
func enabled() -> bool:
	return consent and not endpoint.is_empty()
func observe(next_mode: String,next_difficulty: int,next_sector: int,delta: float,focused: bool=true,finished_id: int=0) -> void:
	if not enabled(): return
	if not next_mode.is_empty() and (mode!=next_mode or difficulty!=next_difficulty or active_seconds>=86400.0):
		_send()
		_clear()
		session_id=Crypto.new().generate_random_bytes(16).hex_encode()
		mode=next_mode
		difficulty=clampi(next_difficulty,0,4)
		last_result_id=finished_id
	if session_id.is_empty(): return
	elapsed+=clampf(delta,0.0,1.0)
	if not next_mode.is_empty() and focused:
		active_seconds=minf(86400.0,active_seconds+clampf(delta,0.0,1.0))
		sector=maxi(sector,clampi(next_sector,0,10000))
		dirty=true
	if elapsed>=PERIOD: _send()
func outcome(instance_id: int,won: bool) -> void:
	if not enabled() or session_id.is_empty() or instance_id==0 or last_result_id==instance_id: return
	last_result_id=instance_id
	if won: wins=mini(10000,wins+1)
	else: losses=mini(10000,losses+1)
	dirty=true
	if elapsed>=MIN_SEND_INTERVAL: _send()
func snapshot() -> Dictionary:
	if not enabled() or session_id.is_empty(): return {}
	return {"schema":2,"id":session_id,"version":pilot_version if not pilot_version.is_empty() else str(ProjectSettings.get_setting("application/config/version","0.0.0")),"mode":mode,"difficulty":difficulty,"seconds":floori(active_seconds),"wins":wins,"losses":losses,"sector":sector}
func _send() -> void:
	# Headless QA never touches the network. Failures are discarded, never queued on disk.
	if not enabled() or not dirty or session_id.is_empty() or not is_instance_valid(request) or in_flight or DisplayServer.get_name()=="headless": return
	var body: Dictionary=snapshot()
	if body.is_empty() or (active_seconds<1.0 and wins+losses==0): return
	elapsed=0.0
	var headers:=PackedStringArray(["Content-Type: application/json"])
	if not pilot_token.is_empty(): headers.append("X-SAPERROR-Pilot: "+pilot_token)
	var result: Error=request.request(endpoint+"/v2/session",headers,HTTPClient.METHOD_POST,JSON.stringify(body))
	network_attempts+=1
	if result==OK:
		in_flight=true
		dirty=false
func _completed(result: int,code: int,_headers: PackedStringArray,_body: PackedByteArray) -> void:
	in_flight=false
	if enabled() and (result!=HTTPRequest.RESULT_SUCCESS or code!=204): dirty=true
