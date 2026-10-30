extends RefCounted
## Small code-native SVG icons, cached without an asset import dependency.
static var textures:Dictionary={}

static func get_icon(action:String) -> Texture2D:
	if textures.has(action):return textures[action]
	var shapes:String={
		"folder":"<path d='M2 5h6l2 2h8v10H2Z M2 5V3h6l2 2h8v2'/>",
		"rename":"<path d='m4 13 9-10 4 4-10 9-4 1Z M11 5l4 4M3 18h14'/>",
		"info":"<circle cx='10' cy='10' r='8'/><path d='M10 9v6M10 5v.5'/>",
		"block":"<circle cx='10' cy='10' r='8'/><path d='m4 4 12 12'/>",
		"person":"<circle cx='10' cy='4' r='2'/><path d='M10 7v6M5 10l5-3 5 3M10 13l-4 5M10 13l4 5'/>",
		"simulation":"<circle cx='4' cy='5' r='2'/><circle cx='16' cy='5' r='2'/><circle cx='10' cy='16' r='2'/><path d='m6 5 8 0M5 7l4 7M15 7l-4 7'/>",
		"story":"<path d='M10 5C7 2 3 3 2 4v13c3-2 6-1 8 1 2-2 5-3 8-1V4c-3-2-6-1-8 1Zm0 0v13'/>",
		"store":"<path d='M3 8v10h14V8M2 8l2-6h12l2 6M2 8q2 4 4 0 2 4 4 0 2 4 4 0 2 4 4 0M8 18v-6h4v6'/>",
		"length_arrows":"<path fill='#382c1c' stroke='#382c1c' d='m5 7 5-5 5 5Z M5 13l5 5 5-5Z'/>",
		"play":"<path fill='#eef4fa' d='m6 3 11 7-11 7Z'/>",
		"favorite":"<path d='m10 2 2.5 5 5.5.8-4 3.9.95 5.5L10 14.6l-4.95 2.6.95-5.5-4-3.9L7.5 7Z'/>",
		"favorited":"<path fill='#f2ce85' d='m10 2 2.5 5 5.5.8-4 3.9.95 5.5L10 14.6l-4.95 2.6.95-5.5-4-3.9L7.5 7Z'/>",
		"add":"<path d='M10 4v12M4 10h12'/>",
		"clone":"<rect x='7' y='7' width='10' height='10' rx='1.5'/><path d='M13 7V4.5A1.5 1.5 0 0 0 11.5 3h-7A1.5 1.5 0 0 0 3 4.5v7A1.5 1.5 0 0 0 4.5 13H7'/>",
		"delete":"<path d='M3.5 6h13M8 6V3.5h4V6M5 6l.7 11h8.6L15 6M8.2 9v5.5M11.8 9v5.5'/>",
		"undo":"<path d='m7 3-4 4 4 4M3 7h8a5 5 0 0 1 0 10H8'/>",
		"cast":"<path d='M11.5 2 4 11h5.5L8.5 18 16 8.5h-5.5Z'/>"
	}.get(action,"")
	var svg:="<svg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 20 20'><g fill='none' stroke='#eef4fa' stroke-width='1.7' stroke-linecap='round' stroke-linejoin='round'>"+shapes+"</g></svg>"
	var image:=Image.new()
	if image.load_svg_from_string(svg)!=OK:return null
	var texture:=ImageTexture.create_from_image(image)
	textures[action]=texture
	return texture
