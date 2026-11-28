extends SceneTree
const Audio=preload("res://scripts/audio/terminal_audio.gd")
const UI=preload("res://scripts/ui/terminal_ui.gd")
const Immersion=preload("res://scripts/ui/immersion.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(Audio.EVENTS.size()-1+2>=25,"at least 25 one-shot event types including approved MP3s")
	var signatures: Array[int]=[]
	for id in Audio.EXTRA:
		var stream:=Audio.synth(id)
		var data: PackedByteArray=stream.data
		check(stream.loop_mode==AudioStreamWAV.LOOP_DISABLED and stream.mix_rate==Audio.RATE and not stream.stereo,"one shot format "+id)
		check(data.decode_s16(0)==0 and data.decode_s16(data.size()-2)==0,"zero endpoints "+id)
		var peak: int=0
		for i in range(0,data.size(),2): peak=maxi(peak,absi(data.decode_s16(i)))
		check(peak>100 and peak<11470,"bounded peak "+id)
		var signature: int=hash(data)
		check(not signatures.has(signature),"distinct SFX "+id)
		signatures.append(signature)
		check(Audio.synth(id).data==data,"deterministic SFX "+id)
	for id in Immersion.IDS:
		check(Audio.EVENTS.has(Immersion.sound(id)) and Immersion.tint(id).length()>0.0,"immersion cue registered "+id)
	check(Immersion.identity("LOOP_B")=="LOOP" and Immersion.identity("ADMIN_LINK")=="ADMIN","phase identity")
	var busy: Array[bool]=[true,true,true,true,true,true]
	var priorities: Array[int]=[3,2,3,1,0,2]
	check(Audio.pick_voice(busy,priorities,0,0)==-1,"click cannot steal active sound")
	check(Audio.pick_voice(busy,priorities,0,3)==4,"important sound replaces weakest")
	priorities.assign([3,3,3,3,3,3])
	check(Audio.pick_voice(busy,priorities,0,3)==-1,"no equal critical sound theft")
	busy[3]=false
	check(Audio.pick_voice(busy,priorities,0,0)==3,"free voice preferred")
	check(Audio.priority("admin_intro")>Audio.priority("key"),"ADMIN protected from clicks")
	check(is_equal_approx(Audio.gain_db(0.5,0.5,true),linear_to_db(0.25)),"linear master attenuation")
	check(Audio.gain_db(1.0,0.0,true)==-80.0 and Audio.gain_db(1.0,1.0,false)==-80.0,"master mute")
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._show("menu")
	var power:=ui.page.find_child("PowerOff",true,false) as Button
	var before_clicks: int=ui.audio.ui_click_requests
	if is_instance_valid(power): power.pressed.emit()
	check(ui.screen=="menu" and ui.audio.ui_click_requests==before_clicks+1,"direct power click uses shared MP3 request")
	ui._show("tutorial")
	before_clicks=ui.audio.ui_click_requests
	ui.tutorial.tiles[1].pressed.emit()
	check(ui.audio.ui_click_requests==before_clicks,"tutorial cell excludes UI sound")
	ui.tutorial.next_button.pressed.emit()
	check(ui.audio.ui_click_requests==before_clicks+1,"tutorial next uses shared sound")
	ui._show("audio")
	var master:=ui.page.find_child("AudioSlider_master",true,false) as HSlider
	check(is_instance_valid(master),"real master slider")
	if is_instance_valid(master):
		master.value=0.5
		check(ui.audio.master_level==0.5 and ui.audio.music.master==0.5,"master routes to score")
		check(is_equal_approx(ui.audio.effective_sfx(),ui.audio.sfx_level*0.5),"lamp and SFX gain")
		var old_music: float=ui.audio.music_level
		master.value=0.0
		check(ui.audio.effective_sfx()==0.0 and ui.audio.music_level==old_music,"channel settings retained when muted")
		master.value=1.0
	ui._start_profile(1)
	ui._reveal(0)
	check(ui.board!=null and not ui.board.finished(),"active game")
	if ui.board!=null and not ui.board.finished():
		ui._cycle_rule()
		check(ui.audio.last_event=="rule","actual rule sound")
		ui._begin_protocol()
		ui._process(4.0)
		ui._process(2.0)
		ui._show("shop")
		var offer: String=ui.economy.offers()[0]
		ui._buy_module(offer)
		check(ui.audio.last_event=="module","actual module sound")
		ui._buy_charge()
		check(ui.audio.last_event=="purchase","actual purchase sound")
	ui.queue_free()
	print("AUDIO_ULTIMATE_QA checks=",checks," failures=",failures," extra=",Audio.EXTRA.size()," one_shots=",Audio.EVENTS.size()-1+2)
	quit(0 if failures==0 else 1)
