function rio_addEnumeric(ty)
  rio_addrepr(ty, "#val")
  rio_addcore(ty, function(self)
    local s = rio_pop("__quote").data
    local parsed = tonumber(s)
    if not parsed then badliteral(s, ty) end
    rio_push({ ty=ty, data=parsed,
      eval=function(self) rio_push(self) end })
  end)
end

rio_addEnumeric("#float8")

rio_addcore("_#float8_#float8_+", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#float8", data=a+b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_-", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#float8", data=a-b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_*", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#float8", data=a*b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_/", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#float8", data=a/b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_=", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#binary", data=a==b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_/=", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#binary", data=a~=b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_<", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#binary", data=a<b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_<=", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#binary", data=a<=b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_>", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#binary", data=a>b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#float8_#float8_>=", function(self)
  local b = rio_pop("#float8").data
  local a = rio_pop("#float8").data
  rio_push({ ty="#binary", data=a>=b,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("___block_#float8_push", function(self)
  local elem = rio_pop("#float8")
  listpush(rio_peek("__block").data, elem)
end)
