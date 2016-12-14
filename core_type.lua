rio_addcore("type", function(self)
  local kind = rio_pop(types["__token"])
  local ty = rio_pop(types["__token"])
  if not types[kind.data] then notatype(kind.data) end
  rio_addtype(ty.data, types[kind.data])
  rio_addsymbol(ty.data, { ty=types["__constructor"],
    name=ty.data, kind=kind.data, eval=function(self)
      local val = rio_pop(types["__token"])
      literalparsers[self.kind](val.data, self.name)
    end})
end)
