rio_addcore("bind", function(self)
  local name = rio_pop(types["__quote"]).data
  local datum = rio_pop()
  if rio_isAtype(datum.ty) then
    local info = backend_bind(name, datum)
    table.insert(curbody, indent_level[1] .. info.code .. "\n")
    rio_addsymbol(name, { ty=datum.ty, data=info.name,
      eval=function(self) rio_push(self) end })
  else
    rio_addsymbol(name, datum)
  end
end)
