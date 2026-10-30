extends RefCounted
static var trail_cache:Dictionary={}
static func mesh(points:PackedVector2Array,radius:float) -> ArrayMesh:
 if points.size()<3:return null
 var triangles:PackedInt32Array=Geometry2D.triangulate_polygon(points)
 if triangles.is_empty():return null
 var center:=Vector2.ZERO
 for point in points:center+=point
 center/=points.size()
 var extent:=0.001
 for point in points:extent=maxf(extent,point.distance_to(center))
 var vertices:=PackedVector3Array()
 var normals:=PackedVector3Array()
 var uv:=PackedVector2Array()
 for side in 2:
  for index in triangles:
   var p:Vector2=(points[index]-center)/extent*radius
   vertices.append(Vector3(p.x,-p.y,(0.12 if side==0 else -0.12)*radius))
   normals.append(Vector3.FORWARD if side==0 else Vector3.BACK)
   uv.append(points[index])
 for i in points.size():
  var j:int=(i+1)%points.size()
  var a:Vector2=(points[i]-center)/extent*radius
  var b:Vector2=(points[j]-center)/extent*radius
  var face:Array=[Vector3(a.x,-a.y,-0.12*radius),Vector3(b.x,-b.y,-0.12*radius),Vector3(b.x,-b.y,0.12*radius),Vector3(a.x,-a.y,-0.12*radius),Vector3(b.x,-b.y,0.12*radius),Vector3(a.x,-a.y,0.12*radius)]
  for v in face:
   vertices.append(v)
   normals.append(Vector3(b.y-a.y,b.x-a.x,0).normalized())
   uv.append(Vector2(v.x/radius*0.5+0.5,v.y/radius*0.5+0.5))
 var arrays:Array=[]
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices
 arrays[Mesh.ARRAY_NORMAL]=normals
 arrays[Mesh.ARRAY_TEX_UV]=uv
 var output:=ArrayMesh.new()
 output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 return output
static func trail_texture(points:PackedVector2Array) -> Texture2D:
 var key:int=hash(points)
 if trail_cache.has(key):return trail_cache[key]
 var image:=Image.create(256,128,false,Image.FORMAT_RGBA8)
 image.fill(Color(1,1,1,0))
 for i in range(1,points.size()):
  var a:Vector2=points[i-1]*Vector2(255,127)
  var b:Vector2=points[i]*Vector2(255,127)
  var steps:int=maxi(1,ceili(a.distance_to(b)))
  for step in steps+1:
   var center:Vector2=a.lerp(b,float(step)/steps)
   for x in range(-4,5):
    for y in range(-4,5):
     var pixel:=Vector2i(center)+Vector2i(x,y)
     if pixel.x<0 or pixel.y<0 or pixel.x>255 or pixel.y>127:continue
     var alpha:float=clampf(1.0-Vector2(x,y).length()/4.0,0,1)
     if alpha>image.get_pixelv(pixel).a:image.set_pixelv(pixel,Color(1,1,1,alpha))
 var texture:=ImageTexture.create_from_image(image)
 if trail_cache.size()>=24:trail_cache.erase(trail_cache.keys()[0])
 trail_cache[key]=texture
 return texture
