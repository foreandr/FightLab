extends RefCounted
## Fit the entire spell visual inside its gameplay sphere, reserving pulse room.
## Cosmetic orientation/orbit changes cannot enlarge collision or damage range.
static func mesh_radius(mesh:Mesh) -> float:
 if mesh==null:return 0.0
 if mesh is SphereMesh:return maxf(mesh.radius,mesh.height*0.5)
 if mesh is CapsuleMesh:return maxf(mesh.radius,mesh.height*0.5)
 if mesh is TorusMesh:return mesh.outer_radius
 if mesh is QuadMesh:return mesh.size.length()*0.5
 if mesh is BoxMesh:return mesh.size.length()*0.5
 if mesh is CylinderMesh:return Vector2(maxf(mesh.top_radius,mesh.bottom_radius),mesh.height*0.5).length()
 var extent:=0.0
 for surface in mesh.get_surface_count():
  var arrays:=mesh.surface_get_arrays(surface)
  for vertex in arrays[Mesh.ARRAY_VERTEX]:extent=maxf(extent,vertex.length())
 return extent
static func hierarchy_radius(node:Node3D) -> float:
 var extent:=mesh_radius(node.mesh) if node is MeshInstance3D else 0.0
 for child in node.get_children():
  if child is Node3D:
   # Conservative for all future rotations, including rotating decorative rings.
   var scale:Vector3=child.scale.abs()
   extent=maxf(extent,child.position.length()+hierarchy_radius(child)*maxf(scale.x,maxf(scale.y,scale.z)))
 return extent
static func fit(body:MeshInstance3D,radius:float,pulse:float) -> void:
 var scale:Vector3=body.scale.abs()
 var extent:float=hierarchy_radius(body)*maxf(scale.x,maxf(scale.y,scale.z))
 var peak:=1.0+absf(pulse)*0.1
 var factor:float=minf(1.0,maxf(0.0,radius)/maxf(0.000001,extent))/peak
 body.scale*=factor
 body.set_meta("visual_base",body.scale)
 body.set_meta("visual_hitbox_radius",radius)
