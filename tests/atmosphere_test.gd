extends SceneTree
const Atmosphere=preload("res://scripts/audio/atmosphere.gd")
const Audio=preload("res://scripts/audio/terminal_audio.gd")
const UI=preload("res://scripts/ui/terminal_ui.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var signatures: Array[int]=[]
	for id in Atmosphere.THEMES:
		var stream:=Atmosphere.synth(id)
		check(stream!=null and is_equal_approx(stream.get_length(),32.0),"32 second loop "+id)
		if stream==null: continue
		var data: PackedByteArray=stream.data
		var bytes: int=Atmosphere.RATE*Atmosphere.PERIOD*2
		var cycle: PackedByteArray=data.slice(0,bytes)
		check(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_end==data.size()/2,"native loop")
		for i in range(1,Atmosphere.COPIES):
			check(data.slice(i*bytes,(i+1)*bytes)==cycle,"exact repeated cycle")
		var seam: int=data.decode_s16(0)-data.decode_s16(data.size()-2)
		check(absi(seam)<180 and absi(data.decode_s16(2)-data.decode_s16(0)-seam)<8,"continuous seam and slope")
		var peak: int=0
		for i in range(0,bytes,64): peak=maxi(peak,absi(data.decode_s16(i)))
		check(peak>100 and peak<6554,"quiet nonclipped score")
		var signature: int=hash(cycle)
		check(not signatures.has(signature),"distinct cue")
		signatures.append(signature)
	check(signatures.size()==11,"all original score cues")
	check(Atmosphere.scene_theme("menu",true,0,"","")=="","silent menu")
	check(Atmosphere.scene_theme("game",false,0,"","")=="","free run original ambience")
	for i in range(4):
		check(Atmosphere.scene_theme("campaign_intro",true,i,"","") == ["act_boot","act_corruption","act_echo","act_admin"][i],"act routing")
	for boss in ["WATCHER","LIAR","LOOP","ADMIN"]:
		check(Atmosphere.scene_theme("campaign_boss",true,3,boss,"")=="boss_"+boss.to_lower(),"boss routing")
	check(Atmosphere.scene_theme("admin_intro",true,3,"ADMIN","")=="boss_admin","same intro and phase music")
	for id in ["SHUTDOWN","CONTAINMENT","REWRITE"]:
		check(Atmosphere.scene_theme("ending_scene",true,3,"",id)=="end_"+id.to_lower(),"ending theme")
		check(Atmosphere.scene_theme("gallery_preview",false,0,"",id)=="end_"+id.to_lower(),"gallery theme")
	var audio:=Audio.new()
	root.add_child(audio)
	audio.set_music_level(2.0)
	audio.select_music("act_boot")
	check(audio.music_level==1.0 and audio.music.desired()=="act_boot","music clamp")
	audio.set_levels(0.0,0.0,true)
	check(audio.music.desired()=="act_boot","independent SFX and hum")
	audio.set_levels(0.5,0.3,false)
	check(audio.music.desired()=="","global mute")
	audio.set_levels(0.5,0.3,true)
	audio.set_music_level(0.0)
	check(audio.music.desired()=="" and audio.sfx_level==0.5 and audio.hum_level==0.3,"music mute only")
	audio.queue_free()
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._show("audio")
	var slider:=ui.page.find_child("AudioSlider_music",true,false) as HSlider
	check(is_instance_valid(slider),"real music slider")
	if is_instance_valid(slider):
		slider.value=0.4
		check(is_equal_approx(ui.audio.music_level,0.4),"slider updates music")
	var preview:=ui.page.find_child("MusicPreview",true,false) as Button
	check(is_instance_valid(preview),"preview control")
	if is_instance_valid(preview):
		preview.pressed.emit()
		check(ui.audio.music.requested=="act_boot","preview plays")
		preview.pressed.emit()
		check(ui.audio.music.requested=="","preview stops")
	ui._show("menu")
	check(ui.audio.music.requested=="","leaving audio resets preview")
	ui.queue_free()
	print("ATMOSPHERE_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
