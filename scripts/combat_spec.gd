extends RefCounted
## Mutable gameplay fields are isolated; immutable credit graphs can be shared.
static func copy(source:Dictionary) -> Dictionary:
 var fields:=source.duplicate(false)
 var credits:Variant=fields.get("provenance")
 fields.erase("provenance")
 var result:=fields.duplicate(true)
 if credits is Dictionary:
  result["provenance"]=credits if credits.is_read_only() else credits.duplicate(true)
 elif source.has("provenance"):result["provenance"]=credits
 return result
