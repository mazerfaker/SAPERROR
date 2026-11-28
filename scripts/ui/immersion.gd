extends RefCounted
# Brief deterministic presentation only; no timers or state in the board.
const IDS := ["WATCHER","LIAR","LOOP","ADMIN","DOUBLE","PHANTOM","PARASITE","PORTAL","MIMIC","NULL","INSTABILITY","MAGNET","REWRITE","ECHO","VOICE_ADMIN"]
const TINTS := [Vector3(0.04,0.12,0.04),Vector3(0.16,0.09,0.015),Vector3(0.04,0.10,0.13),Vector3(0.17,0.025,0.015),Vector3(0.025,0.10,0.14),Vector3(0.055,0.08,0.04),Vector3(0.14,0.045,0.01),Vector3(0.015,0.10,0.14),Vector3(0.08,0.10,0.035),Vector3(0.045,0.07,0.11),Vector3(0.13,0.075,0.015),Vector3(0.13,0.045,0.03),Vector3(0.03,0.13,0.12),Vector3(0.025,0.09,0.08),Vector3(0.065,0.10,0.025)]
static func identity(kind: String) -> String:
	if kind=="LOOP_B": return "LOOP"
	if kind=="ADMIN_LINK": return "ADMIN"
	return kind if IDS.has(kind) else ""
static func sound(id: String) -> String:
	return "imm_"+id.to_lower() if IDS.has(id) else ""
static func tint(id: String) -> Vector3:
	var index: int=IDS.find(id)
	return TINTS[index] if index>=0 else Vector3.ZERO
static func mode(id: String) -> float:
	match id:
		"WATCHER","PHANTOM","NULL": return 1.0
		"LOOP","DOUBLE","PORTAL","REWRITE": return 2.0
		"LIAR","INSTABILITY","MIMIC": return 3.0
		"ADMIN","PARASITE","MAGNET": return 4.0
	return 0.0
