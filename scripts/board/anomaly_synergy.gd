extends RefCounted
# Explicit bitmask stored with a newly generated sector. -1 means legacy schedule.
const LEGACY: int=-1
const PHANTOM: int=1
const PARASITE: int=2
const PORTAL: int=4
static func plan(profile: int,sector: int) -> int:
	if sector<3: return 0
	var portal: bool=sector>=5 and sector%3==2
	var single: int=PORTAL if portal else (PARASITE if sector>=4 and sector%2==0 else PHANTOM)
	if profile==0 or sector<6: return single
	if profile==1: return PHANTOM|PORTAL if portal else PHANTOM|PARASITE
	if profile==2: return PARASITE|PORTAL if portal else PHANTOM|PARASITE
	return PHANTOM|PARASITE|PORTAL
static func valid(mask: int,profile: int) -> bool:
	if mask==LEGACY: return true
	if mask<0 or mask>7 or profile<0 or profile>3: return false
	var count: int=int((mask&PHANTOM)!=0)+int((mask&PARASITE)!=0)+int((mask&PORTAL)!=0)
	return count<=[1,2,2,3][profile]
