extends RefCounted
# Version 4 explicit consent for normal opt-in collection. Old pilot consent is not authorization.
const PATH: String="user://analytics_consent.txt"
static func allowed(path: String=PATH) -> bool:
	var f:=FileAccess.open(path,FileAccess.READ)
	if f==null: return false
	if f.get_length()!=8: return false
	return f.get_as_text()=="v4:allow"
static func write_choice(value: bool,path: String=PATH) -> bool:
	var stage: String=path+".tmp"
	var f:=FileAccess.open(stage,FileAccess.WRITE)
	if f==null: return false
	f.store_string("v4:allow" if value else "v4:deny")
	f.flush()
	var status: Error=f.get_error()
	f.close()
	if status!=OK: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(stage),ProjectSettings.globalize_path(path))==OK
