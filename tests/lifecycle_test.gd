extends SceneTree
const Life = preload("res://scripts/ui/crt_lifecycle.gd")
var failures: int = 0
var checks: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)
func _initialize() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	call_deferred("run")
func run() -> void:
	var life := Life.new()
	check(not life.accepts_input() and life.power() == 0.0,"cold boot lock")
	life.begin_shutdown()
	check(life.phase == Life.Phase.BOOT,"shutdown ignored during boot")
	life.advance(0.3)
	check(life.power()>0.0 and life.beam()>0.0 and life.beam()<1.0,"beam warmup")
	life.advance(3.0)
	check(life.accepts_input() and life.power()==1.0 and life.beam()==1.0,"boot complete")
	life.begin_shutdown()
	check(not life.accepts_input(),"shutdown input lock")
	life.skip_boot()
	check(life.phase == Life.Phase.SHUTDOWN,"skip cannot restart shutdown")
	life.advance(0.3)
	check(life.beam()<1.0,"beam collapse")
	life.advance(1.0)
	check(life.phase == Life.Phase.OFF and life.power()==0.0 and not life.accepts_input(),"power off")
	var skip := Life.new()
	skip.skip_boot()
	check(skip.accepts_input() and skip.power()==1.0,"skip boot")
	for lang in ["uk","en"]:
		TranslationServer.set_locale(lang)
		check(TranslationServer.translate("VIS_SKIP_BOOT")!="VIS_SKIP_BOOT","localized boot hint")
		check(TranslationServer.translate("VIS_WIN_BANNER")!="VIS_WIN_BANNER","localized outcome")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	check(scene != null,"game scene loads")
	if scene != null:
		var game = scene.instantiate()
		root.add_child(game)
		check(game.lifecycle.accepts_input(),"headless scene ready")
		game.ui.begin_boot()
		game.ui.update_boot(0.65)
		check(is_instance_valid(game.ui.boot_overlay),"boot overlay")
		game.ui.end_boot()
		check(game.ui.boot_overlay == null,"boot overlay removed")
		game.ui._show("game")
		game.ui._show_outcome(true)
		check(is_instance_valid(game.ui.outcome_banner),"outcome banner")
		game.ui._reset()
		game.queue_free()
	print("LIFECYCLE_QA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
