rio_addcore("unit", function(self)
  local kind = rio_pop(types["__quote"])
  local ty = rio_pop(types["__quote"])
  if not types[kind.data] then notatype(kind.data) end
  rio_addtype(ty.data, kind.data)
  rio_addsymbol(ty.data, { ty=types["__constructor"],
    name=ty.data, kind=kind.data, eval=function(self)
      local val = rio_pop(types["__quote"])
      literalparsers[self.kind](val.data, self.name)
    end})
end)
