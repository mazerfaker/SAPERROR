extends Control
# Local diagnostics only. No telemetry, no disk writes, no background collection.
var readout: Label
var elapsed: float=0.0
var frames: int=0
var samples: int=0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	readout=Label.new()
	readout.size=size
	readout.add_theme_font_size_override("font_size",30)
	readout.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(readout)
	_sample(0.0)
func _process(delta: float) -> void:
	elapsed+=maxf(delta,0.0)
	frames+=1
	if elapsed>=1.0:
		_sample(elapsed*1000.0/float(maxi(frames,1)))
		elapsed=0.0
		frames=0
static func mb(value: float) -> String:
	return "%.1f MiB" % (value/1048576.0) if value>0.0 else "N/A"
func _sample(frame_ms: float) -> void:
	samples+=1
	var fps: int=Engine.get_frames_per_second()
	var memory: float=Performance.get_monitor(Performance.MEMORY_STATIC)
	var video: float=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var draw_calls: int=int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var nodes: int=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	readout.text=tr("PERF_FPS")+": %d\n" % fps
	readout.text+=tr("PERF_FRAME")+": "+("%.2f ms" % frame_ms if frame_ms>0.0 else "N/A")+"\n"
	readout.text+=tr("PERF_MEMORY")+": "+mb(memory)+"\n"
	readout.text+=tr("PERF_VIDEO")+": "+mb(video)+"\n"
	readout.text+=tr("PERF_DRAW")+": %d\n" % draw_calls
	readout.text+=tr("PERF_NODES")+": %d\n\n" % nodes
	readout.text+=tr("PERF_NOTE")
