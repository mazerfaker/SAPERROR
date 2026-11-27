extends RefCounted
# Deterministic, bounded run economy. No random state, no access to hidden board data.
const MODULES := ["XRAY","CHAIN","CAPACITOR","ASSISTANT","CHRONOMANCER"]
const PRICES := [32,36,28,30,34]
const MAX_MODULES := 4
const MAX_CREDITS := 1000000
var credits: int = 30
var stock: int = 0
var owned: Array[String] = []
var xray_awards: int = 0
var chain_awards: int = 0
var safe_count: int = 0
var rerolls: int = 0
var offer_sector: int = 1
var rewarded_sector: int = 0
func capacity() -> int:
	return 4+(2 if owned.has("CAPACITOR") else 0)
func reset(profile: int) -> void:
	credits = 30
	stock = 2 if profile==1 else 0
	owned.clear()
	rewarded_sector = 0
	begin_sector(1)
func begin_sector(sector: int) -> void:
	offer_sector = maxi(1,sector)
	rerolls = 0
	safe_count = 0
	xray_awards = 0
	chain_awards = 0
func add_stock(n: int) -> void:
	stock = mini(capacity(),stock+maxi(0,n))
func reward(sector: int, opened: int, hits: int) -> int:
	if sector<=rewarded_sector or sector!=offer_sector: return 0
	var amount: int = 25+maxi(0,opened)/5+(10 if hits==0 else 0)
	credits = mini(MAX_CREDITS,credits+amount)
	rewarded_sector = sector
	return amount
func observe(opened: int, clean: bool) -> void:
	if opened<=0 or not clean: return
	safe_count += opened
	if owned.has("XRAY"):
		var target: int = mini(2,safe_count/10)
		add_stock(maxi(0,target-xray_awards))
		xray_awards = target
	if owned.has("CHAIN") and opened>=8 and chain_awards<2:
		chain_awards += 1
		add_stock(1)
func offers() -> Array[String]:
	var out: Array[String] = []
	var start: int = posmod(posmod(offer_sector,5)+rerolls,5)
	for i in range(MODULES.size()):
		var id: String = MODULES[(start+i)%MODULES.size()]
		if not owned.has(id): out.append(id)
		if out.size()==3: break
	return out
func price(id: String) -> int:
	var i: int = MODULES.find(id)
	return PRICES[i] if i>=0 else MAX_CREDITS+1
func buy(id: String) -> bool:
	if owned.size()>=MAX_MODULES or not offers().has(id) or credits<price(id): return false
	credits -= price(id)
	owned.append(id)
	if id=="CAPACITOR": add_stock(1)
	return true
func buy_charge() -> bool:
	if stock>=capacity() or credits<12: return false
	credits -= 12
	add_stock(1)
	return true
func reroll_price() -> int:
	return 8+4*rerolls
func reroll() -> bool:
	if rerolls>=100 or credits<reroll_price() or owned.size()>=MAX_MODULES: return false
	credits -= reroll_price()
	rerolls += 1
	return true
func move_state() -> Dictionary:
	return {"stock":stock,"safe":safe_count,"xray":xray_awards,"chain":chain_awards}
func restore_move(data: Dictionary) -> void:
	stock = clampi(int(data.get("stock",stock)),0,capacity())
	safe_count = clampi(int(data.get("safe",safe_count)),0,10000)
	xray_awards = clampi(int(data.get("xray",xray_awards)),0,2)
	chain_awards = clampi(int(data.get("chain",chain_awards)),0,2)
func snapshot() -> Dictionary:
	var data := move_state()
	data.merge({"credits":credits,"owned":owned.duplicate(),"sector":offer_sector,"rewarded":rewarded_sector,"rerolls":rerolls})
	return data
func restore(data: Dictionary, sector: int, pending: bool) -> void:
	credits = clampi(int(data.get("credits",30)),0,MAX_CREDITS)
	owned.clear()
	var items: Variant = data.get("owned",[])
	if items is Array:
		for id in items:
			if id is String and MODULES.has(id) and not owned.has(id) and owned.size()<MAX_MODULES: owned.append(id)
	begin_sector(sector)
	rewarded_sector = clampi(int(data.get("rewarded",sector if pending else sector-1)),0,sector)
	if pending: rewarded_sector = sector
	else: rewarded_sector = mini(rewarded_sector,sector-1)
	if int(data.get("sector",0))==sector:
		rerolls = clampi(int(data.get("rerolls",0)),0,100)
		restore_move(data)
