extends RefCounted
## One visual card for spell style and audio asset galleries.
static func create(id:String,title:String,texture:Texture2D,tooltip:String="",subtitle:String="")->Button:
 var button:=Button.new()
 button.name=id
 button.custom_minimum_size=Vector2(82,108)
 button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button.focus_mode=Control.FOCUS_ALL;button.toggle_mode=true
 button.tooltip_text=title if tooltip.is_empty() else tooltip
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+side,6)
 margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(margin)
 var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;margin.add_child(column)
 var image:=TextureRect.new();image.name="PreviewImage";image.texture=texture
 image.custom_minimum_size.y=76;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(image)
 var caption:=Label.new();caption.text=title;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.add_theme_font_size_override("font_size",11);caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 caption.clip_text=true;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(caption)
 if not subtitle.is_empty():
  var detail:=Label.new();detail.name="DurationRange";detail.text=subtitle
  detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  detail.add_theme_font_size_override("font_size",10)
  detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(detail)
 return button
