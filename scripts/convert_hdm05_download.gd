extends SceneTree
## Convert the publisher's already segmented HDM05 coordinate clips to BVH.
## One output per original source clip ID; never creates arbitrary extra cuts.
const SOURCE:="res://work/animation_acquisition/data/HDM05-122/HDM05-122-objects-annotations-specific-coords_normPOS.data"
const OUTPUT:="res://assets/animations/community/raw/hdm05"
const NAMES=["Hips","LeftUpLeg","LeftLeg","LeftFoot","LeftToeBase","LeftToeTip","RightUpLeg","RightLeg","RightFoot","RightToeBase","RightToeTip","Spine","Spine1","Spine2","Neck","Head","HeadTip","LeftArm","LeftForeArm","LeftForeArmTwist","LeftHand","LeftFingerBase","LeftFingerTip","LeftThumb","RightArm","RightForeArm","RightForeArmTwist","RightHand","RightFingerBase","RightFingerTip","RightThumb"]
var labels:Dictionary={}
var current_id:=""
var current_label:=""
var expected:=0
var frames:PackedStringArray=[]
var count:=0
func _initialize():call_deferred("run")
func run():
	for line in FileAccess.get_file_as_string("res://work/animation_acquisition/data/hdm05_action_descriptions.txt").split("\n"):
		var parts:=line.strip_edges().split(";",false)
		if parts.size()>=2:labels[int(parts[0])]=parts[1].trim_prefix("hdm05_").trim_prefix("hdm05_spec_")
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var file:=FileAccess.open(SOURCE,FileAccess.READ)
	assert(file!=null)
	while not file.eof_reached():
		var line:=file.get_line().strip_edges()
		if line.begins_with("#objectKey"):
			flush()
			current_id=line.get_slice(" ",line.get_slice_count(" ")-1)
			var pieces:=current_id.split("_")
			assert(pieces.size()==4)
			current_label=str(labels.get(int(pieces[1]),"action "+pieces[1]))
			expected=int(pieces[3])
		elif line.contains("ObjectMocapPose"):continue
		elif not line.is_empty() and not current_id.is_empty():frames.append(line)
		if count>0 and count%100==0 and frames.is_empty():
			print("HDM05 source clips converted: ",count)
			await process_frame
	flush()
	print("HDM05 CONVERTED: ",count," original source clips, root-normalized pose motion, 120fps")
	quit()
func flush():
	if current_id.is_empty():return
	assert(frames.size()==expected,"Source frame count mismatch for "+current_id)
	var destination:=OUTPUT.path_join(current_label.replace("/"," ")+" "+current_id+".bvh")
	if not FileAccess.file_exists(destination):
		var out:=FileAccess.open(destination,FileAccess.WRITE)
		out.store_line("HIERARCHY\nROOT Hips\n{\n OFFSET 0 0 0\n CHANNELS 6 Xposition Yposition Zposition Xrotation Yrotation Zrotation")
		for index in range(1,NAMES.size()):out.store_line(" JOINT "+NAMES[index]+"\n {\n OFFSET 0 0 0\n CHANNELS 3 Xposition Yposition Zposition\n End Site\n {\n OFFSET 0 0 0\n }\n }")
		for name_ in ["LeftShoulder","RightShoulder"]:out.store_line(" JOINT "+name_+"\n {\n OFFSET 0 0 0\n CHANNELS 3 Xposition Yposition Zposition\n End Site\n {\n OFFSET 0 0 0\n }\n }")
		out.store_line("}\nMOTION\nFrames: "+str(frames.size())+"\nFrame Time: 0.00833333333333333")
		for frame in frames:
			var points:=frame.split(";",false)
			assert(points.size()==31)
			var values:PackedStringArray=[points[0].replace(","," "),"0 0 0"]
			for index in range(1,31):values.append(points[index].replace(","," "))
			values.append(points[13].replace(","," "));values.append(points[13].replace(","," "))
			out.store_line(" ".join(values))
		out.close()
	count+=1
	frames.clear()
