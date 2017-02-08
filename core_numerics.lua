function rio_addEnumeric(ty)
  rio_addtype(ty)
  rio_addcore(ty, function(self)
    local s = rio_pop("__quote").data
    local parsed = tonumber(s)
    if not parsed then badliteral(s, ty) end
    rio_push({ ty=ty, data=parsed,
      eval=function(self) rio_push(self) end })
  end)
  
  local namebase = "_" .. ty .. "_" .. ty .. "_"
  
  rio_addcore(namebase .. "+", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty=ty, data=a+b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. "-", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty=ty, data=a-b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. "*", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty=ty, data=a*b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. "/", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty=ty, data=a/b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. "=", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty="#binary", data=a==b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. "/=", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty="#binary", data=a~=b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. "<", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty="#binary", data=a<b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. "<=", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty="#binary", data=a<=b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. ">", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty="#binary", data=a>b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore(namebase .. ">=", function(self)
    local b = rio_pop(ty).data
    local a = rio_pop(ty).data
    rio_push({ ty="#binary", data=a>=b,
      eval=function(self) rio_push(self) end })
  end)

  rio_addcore("___block_" .. ty .. "_push", function(self)
    local elem = rio_pop(ty)
    listpush(rio_peek("__block").data, elem)
  end)
end

rio_addEnumeric("#float8")
