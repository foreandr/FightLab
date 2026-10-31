extends RefCounted
## Every slider spends part of one fixed budget; other shares retain their ratio.
static func normalize(raw:Dictionary,with_effect:bool) -> Dictionary:
	var keys:Array=["size","speed","effect"] if with_effect else ["size","speed"]
	var result:Dictionary={}
	var total:=0.0
	for key in keys:
		result[key]=maxf(0.0,float(raw.get(key,1.0/keys.size())))
		total+=float(result[key])
	for key in keys:result[key]=float(result[key])/total if total>0.00001 else 1.0/keys.size()
	return result

static func change(raw:Dictionary,key:String,value:float,with_effect:bool) -> Dictionary:
	var result:=normalize(raw,with_effect)
	if not result.has(key):return result
	var others:=maxf(0.0,1.0-float(result[key]))
	var peers:=result.size()-1
	result[key]=clampf(value,0.0,1.0)
	for other in result:
		if other==key:continue
		result[other]=(1.0-float(result[key]))*(float(result[other])/others if others>0.00001 else 1.0/peers)
	return result
