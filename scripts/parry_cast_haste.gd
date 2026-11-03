extends RefCounted
## Short cast-animation reward. Status time stays in real simulation seconds.
const DURATION:=1.0
const SPEED_PER_STACK:=0.10
var stacks:=0
var time_left:=0.0
func grant(count:int=1)->void:
 stacks+=maxi(0,count);time_left=DURATION
func multiplier()->float:return 1.0+SPEED_PER_STACK*stacks if time_left>0.0 else 1.0
func step(delta:float)->void:
 time_left=maxf(0.0,time_left-delta)
 if time_left<=0.0:stacks=0
func clear()->void:
 stacks=0;time_left=0.0
