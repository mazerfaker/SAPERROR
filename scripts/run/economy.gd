extends RefCounted
# Deterministic, bounded run economy. No random state, no access to hidden board data.
const MODULES := ["XRAY","CHAIN","CAPACITOR","ASSISTANT","CHRONOMANCER","SECOND_LIFE","FUSE","AUDITOR","RESONANCE","PROFIT","THIRD_EYE","SHIELDING","HOTFIX","STABILIZER","ARCHIVIST"]
const PRICES := [32,36,28,30,34,40,35,34,32,45,30,28,26,30,30]
const MAX_MODULES := 3
const LEGACY_MAX_MODULES := 4
const BOSS_REWARD := 24
const SIMPLE_MODULES := ["ASSISTANT","CHRONOMANCER","SECOND_LIFE","THIRD_EYE","STABILIZER","ARCHIVIST"]
var streamlined: bool=false
var compact: bool=false
const COMPACT_REPAIR_COST := [15,20,30,30]
const COMPACT_SHOP_ORDER := {2:["ASSISTANT","SECOND_LIFE"],4:["STABILIZER","CHRONOMANCER"],7:["THIRD_EYE","ARCHIVIST"],8:["ARCHIVIST","SECOND_LIFE"]}
const MAX_CREDITS := 1000000
# Provisional product-beta economy tuning; Standard stays identical.
const START_CREDITS := [40,30,25,20]
const START_STOCK := [3,2,0,0]
const REPAIR_COST := [20,30,30,30]
var difficulty: int=1
var credits: int = 30
var stock: int = 0
var owned: Array[String] = []
var xray_awards: int = 0
var chain_awards: int = 0
var safe_count: int = 0
var rerolls: int = 0
var offer_sector: int = 1
var rewarded_sector: int = 0
var shield_stock: int = 0
var shield_armed: bool = false
var second_used: bool = false
var fuse_used: bool = false
var clean_streak: int = 0
var auditor_awards: int = 0
var resonance_value: int = 0
var resonance_streak: int = 0
var third_used: bool = false
var earned: int = 0
var spent: int = 0
func slot_limit() -> int:
	return MAX_MODULES
func shop_locked() -> bool:
	return owned.size()>=slot_limit()
func capacity() -> int:
	return 4+(2 if owned.has("CAPACITOR") else 0)
func reset(profile: int) -> void:
	streamlined=false
	compact=false
	difficulty=clampi(profile,0,3)
	credits=START_CREDITS[difficulty]
	stock=START_STOCK[difficulty]
	owned.clear()
	shield_stock = 0
	earned = 0
	spent = 0
	rewarded_sector = 0
	begin_sector(1)
func begin_sector(sector: int) -> void:
	offer_sector = maxi(1,sector)
	rerolls = 0
	safe_count = 0
	xray_awards = 0
	chain_awards = 0
	shield_armed = false
	second_used = false
	fuse_used = false
	clean_streak = 0
	auditor_awards = 0
	resonance_value = 0
	resonance_streak = 0
	third_used = false
func replenish_campaign_stock() -> void:
	# Called only for a genuine sector transition, never during restore/retry.
	if compact and difficulty<=1: stock=maxi(stock,1)
func add_stock(n: int) -> void:
	stock = mini(capacity(),stock+maxi(0,n))
func reward(sector: int, opened: int, hits: int) -> int:
	if sector<=rewarded_sector or sector!=offer_sector: return 0
	var amount: int = 12+maxi(0,opened)/8+(6 if hits==0 else 0)
	if owned.has("PROFIT"):
		# At one HP the nominal -1 HP penalty cannot apply. Reduce the bonus.
		amount=amount*5/4 if difficulty==3 else amount*3/2
	_gain(amount)
	rewarded_sector = sector
	return amount
func boss_reward(sector: int) -> int:
	# Fixed reward for the complete encounter; phases have independent HP.
	if not compact or sector<=rewarded_sector or sector!=offer_sector: return 0
	_gain(BOSS_REWARD)
	rewarded_sector=sector
	return BOSS_REWARD
func observe(opened: int, clean: bool, clue: int = 0) -> void:
	if not clean:
		clean_streak = 0
		resonance_value = 0
		resonance_streak = 0
		return
	if opened<=0: return
	if owned.has("RESONANCE"):
		if clue<=0:
			resonance_value = 0
			resonance_streak = 0
		elif clue==resonance_value:
			resonance_streak += 1
		else:
			resonance_value = clue
			resonance_streak = 1
		if resonance_streak>=3:
			_gain(4)
			resonance_streak = 0
	safe_count += opened
	clean_streak += opened
	if owned.has("AUDITOR"):
		while clean_streak>=15 and auditor_awards<2:
			clean_streak -= 15
			auditor_awards += 1
			_gain(6)
	if owned.has("XRAY"):
		var target: int = mini(2,safe_count/10)
		add_stock(maxi(0,target-xray_awards))
		xray_awards = target
	if owned.has("CHAIN") and opened>=8 and chain_awards<2:
		chain_awards += 1
		add_stock(1)
func offers() -> Array[String]:
	var out: Array[String] = []
	if compact and COMPACT_SHOP_ORDER.has(offer_sector):
		for id in COMPACT_SHOP_ORDER[offer_sector]:
			if not owned.has(id): out.append(id)
		for id in SIMPLE_MODULES:
			if out.size()>=2: break
			if not owned.has(id) and not out.has(id): out.append(id)
		return out
	var pool: Array=SIMPLE_MODULES if streamlined else MODULES
	var start: int=posmod(offer_sector-2 if streamlined else offer_sector+rerolls,pool.size())
	for i in range(pool.size()):
		var id: String=pool[(start+i)%pool.size()]
		if not owned.has(id): out.append(id)
		if out.size()==(2 if streamlined else 3): break
	return out
func price(id: String) -> int:
	var i: int = MODULES.find(id)
	return PRICES[i] if i>=0 else MAX_CREDITS+1
func buy(id: String) -> bool:
	if shop_locked() or not offers().has(id) or credits<price(id): return false
	_spend(price(id))
	owned.append(id)
	if id=="CAPACITOR": add_stock(1)
	return true
func buy_charge() -> bool:
	if shop_locked() or streamlined or stock>=capacity() or credits<12: return false
	_spend(12)
	add_stock(1)
	return true
func reroll_price() -> int:
	return 8+4*rerolls
func reroll() -> bool:
	if shop_locked() or streamlined or rerolls>=100 or credits<reroll_price(): return false
	_spend(reroll_price())
	rerolls += 1
	return true
func move_state() -> Dictionary:
	return {"stock":stock,"safe":safe_count,"xray":xray_awards,"chain":chain_awards,"credits":credits,"shield_stock":shield_stock,"armed":shield_armed,"second":second_used,"fuse":fuse_used,"streak":clean_streak,"auditor":auditor_awards,"res_value":resonance_value,"res_streak":resonance_streak,"third":third_used,"earned":earned,"spent":spent}
func restore_move(data: Dictionary) -> void:
	stock = clampi(int(data.get("stock",stock)),0,capacity())
	safe_count = clampi(int(data.get("safe",safe_count)),0,10000)
	xray_awards = clampi(int(data.get("xray",xray_awards)),0,2)
	chain_awards = clampi(int(data.get("chain",chain_awards)),0,2)
	credits = clampi(int(data.get("credits",credits)),0,MAX_CREDITS)
	shield_stock = clampi(int(data.get("shield_stock",shield_stock)),0,1)
	shield_armed = bool(data.get("armed",false))
	second_used = bool(data.get("second",false))
	fuse_used = bool(data.get("fuse",false))
	clean_streak = clampi(int(data.get("streak",0)),0,10000)
	auditor_awards = clampi(int(data.get("auditor",0)),0,2)
	resonance_value = clampi(int(data.get("res_value",0)),0,24)
	resonance_streak = clampi(int(data.get("res_streak",0)),0,2)
	third_used = bool(data.get("third",false))
	earned = maxi(0,int(data.get("earned",earned)))
	spent = maxi(0,int(data.get("spent",spent)))
func snapshot() -> Dictionary:
	var data := move_state()
	data.merge({"credits":credits,"owned":owned.duplicate(),"sector":offer_sector,"rewarded":rewarded_sector,"rerolls":rerolls})
	return data
func restore(data: Dictionary, sector: int, pending: bool) -> void:
	credits = clampi(int(data.get("credits",START_CREDITS[difficulty])),0,MAX_CREDITS)
	owned.clear()
	var items: Variant = data.get("owned",[])
	if items is Array:
		for id in items:
			if id is String and MODULES.has(id) and not owned.has(id) and owned.size()<LEGACY_MAX_MODULES: owned.append(id)
	begin_sector(sector)
	rewarded_sector = clampi(int(data.get("rewarded",sector if pending else sector-1)),0,sector)
	if pending: rewarded_sector = sector
	else: rewarded_sector = mini(rewarded_sector,sector-1)
	if int(data.get("sector",0))==sector:
		rerolls = clampi(int(data.get("rerolls",0)),0,100)
		restore_move(data)

func repair(hp: int, maximum: int) -> int:
	if hp<1 or hp>=maximum or credits<repair_price(): return hp
	_spend(repair_price())
	return hp+1
func buy_shield() -> bool:
	if shop_locked() or streamlined or credits<18 or shield_stock>=1 or shield_armed: return false
	_spend(18)
	shield_stock = 1
	return true
func arm_shield() -> bool:
	if shield_stock<=0 or shield_armed: return false
	shield_stock -= 1
	shield_armed = true
	return true
func can_protect() -> bool:
	return shield_armed or (owned.has("SECOND_LIFE") and not second_used) or (owned.has("FUSE") and not fuse_used and safe_count>=12)
func consume_protection() -> String:
	if shield_armed:
		shield_armed = false
		return "SHIELD"
	if owned.has("SECOND_LIFE") and not second_used:
		second_used = true
		return "SECOND_LIFE"
	if owned.has("FUSE") and not fuse_used and safe_count>=12:
		fuse_used = true
		return "FUSE"
	return ""
func _gain(amount: int) -> void:
	var old: int = credits
	credits = mini(MAX_CREDITS,credits+maxi(0,amount))
	earned += credits-old
func _spend(amount: int) -> void:
	credits -= amount
	spent += amount
func max_hp(base: int) -> int:
	return maxi(1,base-(1 if owned.has("PROFIT") else 0))
func use_third() -> bool:
	if not owned.has("THIRD_EYE") or third_used: return false
	third_used = true
	return true
func use_analyzer() -> bool:
	if stock<=0: return false
	stock -= 1
	return true

# Caller grants once per recorded optional archive; no repeatable reward.
func archive_reward() -> int:
	var value: int=8+(5 if owned.has("ARCHIVIST") else 0)
	_gain(value)
	return value

func repair_price() -> int:
	return COMPACT_REPAIR_COST[difficulty] if compact else REPAIR_COST[difficulty]
