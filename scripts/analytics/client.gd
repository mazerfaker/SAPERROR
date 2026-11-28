extends Node
# Ephemeral session summaries only. No local queue, stable identifier, device fingerprint or raw actions.
const PERIOD: float=15.0
const MIN_SEND_INTERVAL: float=5.0
var endpoint: String=""
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
var attempted_session: bool=false
var last_http_code: int=0
var last_transport_result: int=-1
var accepted_seconds: int=0
var in_flight_session_id: String=""
var in_flight_seconds: int=0
static func valid_endpoint(value: String) -> bool:
	var pattern:=RegEx.new()
	pattern.compile("^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$")
	return pattern.search(value)!=null
func configure(value: String) -> void:
	endpoint=value if valid_endpoint(value) else ""
func _ready() -> void:
	request=HTTPRequest.new()
	request.timeout=8.0
	request.use_threads=true
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
	attempted_session=false
	last_http_code=0
	last_transport_result=-1
	accepted_seconds=0
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
	if elapsed>=(PERIOD if attempted_session else MIN_SEND_INTERVAL): _send()
func outcome(instance_id: int,won: bool) -> void:
	if not enabled() or session_id.is_empty() or instance_id==0 or last_result_id==instance_id: return
	last_result_id=instance_id
	if won: wins=mini(10000,wins+1)
	else: losses=mini(10000,losses+1)
	dirty=true
	if elapsed>=MIN_SEND_INTERVAL: _send()
func snapshot() -> Dictionary:
	if not enabled() or session_id.is_empty(): return {}
	return {"schema":2,"id":session_id,"version":str(ProjectSettings.get_setting("application/config/version","0.0.0")),"mode":mode,"difficulty":difficulty,"seconds":floori(active_seconds),"wins":wins,"losses":losses,"sector":sector}
func _send() -> void:
	# Headless QA never touches the network. Failures are discarded, never queued on disk.
	if not enabled() or not dirty or session_id.is_empty() or not is_instance_valid(request) or in_flight or DisplayServer.get_name()=="headless": return
	var body: Dictionary=snapshot()
	if body.is_empty() or (active_seconds<1.0 and wins+losses==0): return
	elapsed=0.0
	var headers:=PackedStringArray(["Content-Type: application/json"])
	var result: Error=request.request(endpoint+"/v2/session",headers,HTTPClient.METHOD_POST,JSON.stringify(body))
	network_attempts+=1
	attempted_session=true
	if result==OK:
		in_flight=true
		in_flight_session_id=session_id
		in_flight_seconds=int(body["seconds"])
		dirty=false
	else:
		last_http_code=0
		last_transport_result=int(result)
		dirty=true
func _exit_tree() -> void:
	set_permission(false)
func _completed(result: int,code: int,_headers: PackedStringArray,_body: PackedByteArray) -> void:
	in_flight=false
	if not enabled() or in_flight_session_id!=session_id: return
	last_http_code=code
	last_transport_result=result
	if result==HTTPRequest.RESULT_SUCCESS and code==204:
		accepted_seconds=maxi(accepted_seconds,in_flight_seconds)
	else:
		dirty=true
