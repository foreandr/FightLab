extends RefCounted
## Benchmarked loading durations, measured across 15 runs per loading screen.

const MEAN_SECONDS := {
	"home_to_create": 2.1329,
	"create_workspace": 6.4045,
	"fight_loading": 6.6643,
	"store_index_build": 1.1185,
	"store_index_cold_build": 37.5300,
}
const VARIANCE := 0.20
const PRE_FINISH_CAP := 95.0

var key := ""
var started_usec := 0
var target_seconds := 0.0

func begin(screen_key: String) -> void:
	key=screen_key
	started_usec=Time.get_ticks_usec()
	var mean:=float(MEAN_SECONDS.get(key,1.0))
	target_seconds=mean*randf_range(1.0-VARIANCE,1.0+VARIANCE)

func elapsed_seconds() -> float:
	if started_usec<=0:return 0.0
	return float(Time.get_ticks_usec()-started_usec)/1_000_000.0

func progress_percent(actual_fraction: float = 0.0) -> float:
	var time_fraction:=clampf(elapsed_seconds()/maxf(target_seconds,0.001),0.0,1.0)
	var measured_fraction:=clampf(actual_fraction,0.0,1.0)
	return minf(PRE_FINISH_CAP,maxf(time_fraction,measured_fraction)*PRE_FINISH_CAP)

func target_reached() -> bool:
	return elapsed_seconds()>=target_seconds

func remaining_seconds() -> float:
	return maxf(0.0,target_seconds-elapsed_seconds())
