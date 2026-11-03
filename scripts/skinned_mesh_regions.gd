extends RefCounted
## Immutable region meshes preserve the original skin and shared source assets.
static var cache:Dictionary={}
static func bone_index(node:MeshInstance3D,skeleton:Skeleton3D,bind:int)->int:
 if node.skin!=null and bind<node.skin.get_bind_count():
  var name_:StringName=node.skin.get_bind_name(bind)
  if not name_.is_empty():return skeleton.find_bone(name_)
  return node.skin.get_bind_bone(bind)
 return bind if bind<skeleton.get_bone_count() else -1
static func region(node:MeshInstance3D,skeleton:Skeleton3D,bone_name:String)->ArrayMesh:
 var key:="%d:%d:%s"%[node.mesh.get_instance_id(),node.skin.get_instance_id() if node.skin!=null else 0,bone_name]
 if cache.has(key):return cache[key]
 var result:=ArrayMesh.new()
 var root:=skeleton.find_bone(bone_name)
 if root<0 or not node.mesh is ArrayMesh:return result
 var joint:=bone_name.begins_with("lowerarm") or bone_name.begins_with("calf")
 var center:Vector3=node.global_transform.affine_inverse()*(skeleton.global_transform*skeleton.get_bone_global_rest(root).origin)
 for surface in node.mesh.get_surface_count():
  if node.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:continue
  var arrays:Array=node.mesh.surface_get_arrays(surface)
  var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var binds:PackedInt32Array=arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES]!=null else PackedInt32Array()
  var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS] if arrays[Mesh.ARRAY_WEIGHTS]!=null else PackedFloat32Array()
  if vertices.is_empty() or binds.is_empty():continue
  var selected_binds:Dictionary={}
  for bind in binds:
   if selected_binds.has(bind):continue
   var bone:=bone_index(node,skeleton,bind)
   var matches:bool=joint and bone==skeleton.get_bone_parent(root)
   while bone>=0 and bone!=root:bone=skeleton.get_bone_parent(bone)
   selected_binds[bind]=matches or bone==root
  var stride:int=binds.size()/vertices.size()
  var selected:=PackedByteArray();selected.resize(vertices.size())
  for vertex in vertices.size():
   if joint and vertices[vertex].distance_to(center)>0.16:continue
   var share:=0.0
   for influence in stride:
    var slot:=vertex*stride+influence
    if selected_binds.get(binds[slot],false):share+=weights[slot]
   selected[vertex]=1 if share>=0.4 else 0
  var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array(range(vertices.size()))
  if indices.is_empty():indices=PackedInt32Array(range(vertices.size()))
  var kept:=PackedInt32Array()
  for triangle in range(0,indices.size(),3):
   if int(selected[indices[triangle]])+int(selected[indices[triangle+1]])+int(selected[indices[triangle+2]])<2:continue
   kept.append_array(indices.slice(triangle,triangle+3))
  if kept.is_empty():continue
  arrays[Mesh.ARRAY_INDEX]=kept
  for custom in range(Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM3+1):arrays[custom]=null
  result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},node.mesh.surface_get_format(surface)&Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
 if cache.size()>=64:cache.erase(cache.keys()[0])
 cache[key]=result
 return result
