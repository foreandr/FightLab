extends RefCounted
## Presentation-only design tokens, shared by every screen and popup.
const FONT=preload("res://assets/fonts/Rajdhani-SemiBold.ttf")
const BOLD=preload("res://assets/fonts/Rajdhani-Bold.ttf")
const VOID=Color("050b12")
const PANEL=Color("09141f")
const RAISED=Color("102433")
const HOVER=Color("153b4b")
const SELECTED=Color("134652")
const LINE=Color("24576a")
const CYAN=Color("63efff")
const TEXT=Color("dcf5fc")
const MUTED=Color("81a6b9")
const DISABLED=Color("4c6575")
const ORANGE=Color("ffa85b")
static var shared:Theme
static func box(fill:Color=PANEL,border:Color=LINE)->StyleBoxFlat:
 var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border
 style.set_border_width_all(1);style.set_corner_radius_all(3);style.corner_detail=1
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,6)
 return style
static func color(value:Color,role:String="")->Color:
 if value.a<0.01 or value in [VOID,PANEL,RAISED,HOVER,SELECTED,LINE,CYAN,TEXT,MUTED,DISABLED,ORANGE]:return value
 var key:=value.to_html(false).to_lower()
 var palette:={"e8ddc4":PANEL,"e8deca":PANEL,"e8dec4":PANEL,"e8ddc3":PANEL,"eee3cb":RAISED,"e8dec8":PANEL,"e8ddc5":PANEL,"f0e8d5":RAISED,"f1e8d3":RAISED,"f2e9d3":RAISED,"fff8e9":HOVER,"f9edcc":HOVER,"d8c7a4":RAISED,"e3d3b3":HOVER,"c9b38b":SELECTED,"c9af7b":SELECTED,"c5b99f":Color("101b26"),"b5a27f":LINE,"b49c70":LINE,"c3ad82":LINE,"c9b58f":LINE,"765b38":LINE,"59472d":MUTED,"382c1c":TEXT,"655740":MUTED,"84765f":DISABLED,"806d4d":MUTED,"77664d":MUTED,"aa7b32":CYAN,"98703d":CYAN,"ad8333":CYAN,"b08a4b":CYAN,"b38a47":CYAN,"c9b48c":LINE,"98794d":CYAN,"bdb49e":Color("101b26"),"c6bead":Color("132633"),"aaa08c":LINE,"775b34":CYAN,"f2ce85":ORANGE,"fff0a3":CYAN,"302619":VOID}
 var output:Color=palette.get(key,value)
 if output==value and (role.contains("font") or role=="default_color") and not role.contains("shadow") and not role.contains("outline"):
  if role.contains("disabled"):output=DISABLED
  elif value.r>value.g*1.25 and value.r>value.b*1.2:output=Color("ff6d7d")
  elif value.g>value.r*1.15 and value.g>value.b*1.15:output=Color("65e4ac")
  elif value.b>value.r*1.15 and value.r>value.g*1.15:output=Color("c79aff")
  elif value.b>value.r*1.15:output=CYAN
  elif value.v<0.65:output=TEXT
 output.a=value.a
 return output
static func restyle(style:StyleBox)->StyleBox:
 if not style is StyleBoxFlat:return style
 if style.get_meta("cyber_design",false):return style
 var result:StyleBoxFlat=style.duplicate()
 result.bg_color=color(result.bg_color);result.border_color=color(result.border_color)
 result.set_corner_radius_all(mini(3,result.corner_radius_top_left));result.corner_detail=1
 result.set_meta("cyber_design",true)
 return result
static func theme()->Theme:
 if shared!=null:return shared
 shared=Theme.new();shared.default_font=FONT;shared.default_font_size=18
 for type in ["Label","RichTextLabel","Button","OptionButton","CheckBox","CheckButton","LineEdit","TextEdit","SpinBox","PopupMenu","ItemList","Tree","TabBar","TabContainer","TooltipLabel","Window"]:
  for name_ in ["font_color","default_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color","font_selected_color","font_hovered_color"]:shared.set_color(name_,type,TEXT)
  shared.set_color("font_disabled_color",type,DISABLED)
  shared.set_color("font_unselected_color",type,MUTED)
  shared.set_color("font_placeholder_color",type,MUTED)
 for type in ["Panel","PanelContainer","PopupPanel","PopupMenu","AcceptDialog","Window","TooltipPanel","TabContainer"]:shared.set_stylebox("panel",type,box())
 for type in ["Button","OptionButton"]:
  shared.set_stylebox("normal",type,box(RAISED))
  shared.set_stylebox("hover",type,box(HOVER,CYAN))
  shared.set_stylebox("pressed",type,box(SELECTED,CYAN))
  shared.set_stylebox("hover_pressed",type,box(SELECTED,CYAN))
  shared.set_stylebox("disabled",type,box(Color("0c1823"),Color("1b3341")))
  var focus:=box(Color.TRANSPARENT,CYAN);shared.set_stylebox("focus",type,focus)
 for type in ["LineEdit","TextEdit","ItemList","Tree"]:
  shared.set_stylebox("normal",type,box(VOID))
  shared.set_stylebox("focus",type,box(VOID,CYAN))
 for type in ["HSlider","VSlider"]:
  var track:=box(Color("142d3b"),LINE);track.content_margin_top=3;track.content_margin_bottom=3
  shared.set_stylebox("slider",type,track)
  shared.set_stylebox("grabber_area",type,box(Color("2c95ae"),CYAN))
  shared.set_stylebox("grabber_area_highlight",type,box(CYAN,CYAN))
 for type in ["TabBar","TabContainer"]:
  shared.set_stylebox("tab_selected",type,box(SELECTED,CYAN));shared.set_stylebox("tab_unselected",type,box(PANEL));shared.set_stylebox("tab_hovered",type,box(HOVER,CYAN))
 shared.set_stylebox("hover","PopupMenu",box(HOVER,CYAN))
 for type in ["HScrollBar","VScrollBar"]:
  shared.set_stylebox("scroll",type,box(VOID,VOID));shared.set_stylebox("grabber",type,box(LINE,LINE));shared.set_stylebox("grabber_highlight",type,box(CYAN,CYAN));shared.set_stylebox("grabber_pressed",type,box(CYAN,CYAN))
 shared.set_stylebox("background","ProgressBar",box(VOID));shared.set_stylebox("fill","ProgressBar",box(CYAN,CYAN))
 return shared
