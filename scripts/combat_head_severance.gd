extends RefCounted
## Split only this corpse's skin; shared wardrobe assets remain untouched.
var originals:Array[Dictionary]=[]
var removed_bridge_triangles:=0
var head_triangles:=0

func restore() -> void:
	for record in originals:
		if is_instance_valid(record.node):record.node.mesh=record.mesh
	originals.clear()
	removed_bridge_triangles=0
	head_triangles=0

func bone_index(node:MeshInstance3D,skeleton:Skeleton3D,bind:int) -> int:
	if node.skin!=null and bind<node.skin.get_bind_count():
		var name_:=node.skin.get_bind_name(bind)
		if not name_.is_empty():return skeleton.find_bone(name_)
		return node.skin.get_bind_bone(bind)
	return bind if bind<skeleton.get_bone_count() else -1

func split(actor:Node) -> bool:
	if not originals.is_empty():return true
	var skeleton:Skeleton3D=actor.skeleton
	var head:int=skeleton.find_bone("Head")
	if head<0:return false
	for node:MeshInstance3D in skeleton.find_children("*","MeshInstance3D",true,false):
		if not node.mesh is ArrayMesh or not node.is_visible_in_tree():continue
		var source:ArrayMesh=node.mesh
		var result:=ArrayMesh.new()
		var changed:=false
		for surface in source.get_surface_count():
			var arrays:Array=source.surface_get_arrays(surface)
			if source.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:
				copy_surface(result,source,surface,arrays)
				continue
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var binds:PackedInt32Array=arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES]!=null else PackedInt32Array()
			var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS] if arrays[Mesh.ARRAY_WEIGHTS]!=null else PackedFloat32Array()
			if binds.is_empty() or vertices.is_empty():
				copy_surface(result,source,surface,arrays)
				continue
			var stride:int=binds.size()/vertices.size()
			var head_bind:=-1
			var head_binds:Dictionary={}
			for bind in binds:
				if head_binds.has(bind):continue
				var bone:=bone_index(node,skeleton,bind)
				if bone>=skeleton.get_bone_count():bone=-1
				if bone==head:head_bind=bind
				while bone>=0 and bone!=head:bone=skeleton.get_bone_parent(bone)
				head_binds[bind]=bone==head
			if head_bind<0:
				copy_surface(result,source,surface,arrays)
				continue
			var is_head:=PackedByteArray()
			is_head.resize(vertices.size())
			for vertex in vertices.size():
				var share:=0.0
				for influence in stride:
					var slot:=vertex*stride+influence
					if head_binds.get(binds[slot],false):share+=weights[slot]
				is_head[vertex]=1 if share>=0.5 else 0
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array(range(vertices.size()))
			if indices.is_empty():indices=PackedInt32Array(range(vertices.size()))
			var kept:=PackedInt32Array()
			var surface_heads:=0
			var bridges:=0
			for triangle in range(0,indices.size(),3):
				var count:=int(is_head[indices[triangle]])+int(is_head[indices[triangle+1]])+int(is_head[indices[triangle+2]])
				if count>0 and count<3:
					bridges+=1
					continue
				if count==3:surface_heads+=1
				kept.append_array(indices.slice(triangle,triangle+3))
			if surface_heads==0:
				copy_surface(result,source,surface,arrays)
				continue
			changed=true
			removed_bridge_triangles+=bridges
			head_triangles+=surface_heads
			# Head skin follows the now-independent head body rigidly. Remove head
			# influence from torso vertices so no neck triangles stretch after separation.
			for vertex in vertices.size():
				var total:=0.0
				for influence in stride:
					var slot:=vertex*stride+influence
					if is_head[vertex]:
						binds[slot]=head_bind
						weights[slot]=1.0 if influence==0 else 0.0
					elif head_binds.get(binds[slot],false):weights[slot]=0.0
					total+=weights[slot]
				if total>0:
					for influence in stride:weights[vertex*stride+influence]/=total
			arrays[Mesh.ARRAY_BONES]=binds
			arrays[Mesh.ARRAY_WEIGHTS]=weights
			arrays[Mesh.ARRAY_INDEX]=kept
			copy_surface(result,source,surface,arrays)
		if changed:
			originals.append({"node":node,"mesh":source})
			node.mesh=result
	return not originals.is_empty()

func copy_surface(target:ArrayMesh,source:ArrayMesh,index:int,arrays:Array) -> void:
	for custom in range(Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM3+1):arrays[custom]=null
	var flags:int=source.surface_get_format(index)&Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
	target.add_surface_from_arrays(source.surface_get_primitive_type(index),arrays,[],{},flags)
	var material:Material=source.surface_get_material(index)
	if material==null:material=StandardMaterial3D.new()
	target.surface_set_material(target.get_surface_count()-1,material)
