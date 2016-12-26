rio_addcore("bind", function(self)
  local name = rio_pop(types["__quote"]).data
  local datum = rio_pop()
  if rio_isAtype(datum.ty) then
    local info = backend_bind(binding_prefix, name, datum)
    table.insert(curbody, indent_level[1] .. info.code .. "\n")
    rio_addbinding(name, { ty=datum.ty, data=info.name,
      eval=function(self) rio_push(self) end })
  else
    rio_addbinding(name, datum)
  end
end)

rio_addcore("unbind", function(self)
  rio_deletebinding(rio_pop(types["__quote"]).data)
end)

rio_addcore("rebind", function(self)
  local name = rio_pop(types["__quote"])
  local datum = rio_pop()
  rio_push(name)
  rio_getsymbol("unbind"):eval()
  rio_push(datum)
  rio_push(name)
  rio_getsymbol("bind"):eval()
end)
