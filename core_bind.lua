rio_addcore("commit", function(self)
  local name = rio_pop("__quote").data
  local datum = rio_pop()
  if rio_isAtype(datum.ty) then
    local backend_name = binding_prefix .. rio_sanitize(name) .. "_" .. rio_sanitize(datum.ty)
    if not declarationtable[name] then
      rio_push(rio_strtoquote(backend_name))
      rio_eval(rio_getsymbol("_" .. reprs[datum.ty] .. "_declare"))
      declarationtable[name] = true
    end
    rio_push(rio_strtoquote(backend_name))
    rio_push(datum)
    rio_eval(rio_getsymbol("_" .. reprs[datum.ty] .. "_commit"))
    rio_addbinding(name, { ty=datum.ty, data=backend_name,
      aliases={name=true}, eval=function(self) rio_push(self) end })
  else
    rio_addbinding(name, datum)
  end
end)

rio_addcore("bind", function(self)
  local name = rio_pop("__quote").data
  local datum = rio_pop()
  rio_addbinding(name, datum)
end)

rio_addcore("delete", function(self)
  rio_deletebinding(rio_pop("__quote").data)
end)
