extends RefCounted
# Version 2 explicit consent for the documented analytics fields. Old v1 is not authorization.
const PATH: String="user://analytics_consent.txt"
static func allowed(path: String=PATH) -> bool:
	var f:=FileAccess.open(path,FileAccess.READ)
	if f==null: return false
	if f.get_length()!=8: return false
	return f.get_as_text()=="v2:allow"
static func write_choice(value: bool,path: String=PATH) -> bool:
	var stage: String=path+".tmp"
	var f:=FileAccess.open(stage,FileAccess.WRITE)
	if f==null: return false
	f.store_string("v2:allow" if value else "v2:deny")
	f.flush()
	var status: Error=f.get_error()
	f.close()
	if status!=OK: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(stage),ProjectSettings.globalize_path(path))==OK
