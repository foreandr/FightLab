extends RefCounted
## Reads original InterHuman numeric NPY arrays without Python, pickle or body-model assets.
const BONES=["Hips","LeftUpLeg","RightUpLeg","Spine","LeftLeg","RightLeg","Spine1","LeftFoot","RightFoot","Spine2","LeftToeBase","RightToeBase","Neck","LeftShoulder","RightShoulder","Head","LeftArm","RightArm","LeftForeArm","RightForeArm","LeftHand","RightHand"]
static func parse(path:String,include_frames:=true) -> Dictionary:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null:return {"error":"Cannot open joint array"}
	var magic:=file.get_buffer(6)
	if magic!=PackedByteArray([147,78,85,77,80,89]):return {"error":"Not a NPY file"}
	var major:=file.get_8()
	file.get_8()
	var header_length:=file.get_16() if major==1 else file.get_32()
	var header:=file.get_buffer(header_length).get_string_from_ascii()
	if not header.contains("'<f4'") or header.contains("True"):return {"error":"Unsupported NPY dtype/order"}
	var regex:=RegEx.new()
	regex.compile("'shape':\\s*\\((\\d+),\\s*(\\d+)\\)")
	var shape:=regex.search(header)
	if shape==null:return {"error":"Invalid NPY shape"}
	var count:=int(shape.get_string(1))
	var width:=int(shape.get_string(2))
	if count<2 or width<66 or file.get_length()-file.get_position()!=count*width*4:return {"error":"Truncated or unsupported joint array"}
	var nodes:Array[Dictionary]=[]
	for index in BONES.size():nodes.append({"name":BONES[index],"parent":-1,"offset":Vector3.ZERO,"channels":["Xposition","Yposition","Zposition"],"first":index*3})
	var frames:Array[PackedFloat32Array]=[]
	if include_frames:
		var values:=file.get_buffer(count*width*4).to_float32_array()
		for frame in count:frames.append(values.slice(frame*width,frame*width+66))
	return {"nodes":nodes,"frames":frames,"frame_count":count,"frame_time":1.0/30.0,"duration":float(count-1)/30.0,"channels":66,"up_axis":"Z"}
