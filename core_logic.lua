rio_addcore("decision-type", function(self)
  rio_makedecisiontype(rio_pop("__quote").data, "A")
end)

rio_addcore("#decision-type", function(self)
  rio_makedecisiontype(rio_pop("__quote").data, "E")
end)

rio_addtype("#bc")
rio_makedecisiontype("#bc", "E")
rio_addcore("#bc", function(self)
  local s = rio_pop("__quote").data
  local parsed = nil
  if s == "0" then parsed = false elseif s == "1" then parsed = true end
  if parsed == nil then badliteral(s, "#bc") end
  rio_push({ ty="#bc", data=parsed, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#bc_#bc_=", function(self)
  local b = rio_pop("#bc").data
  local a = rio_pop("#bc").data
  rio_push({ ty="#bc", data=a == b, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#bc_#bc_/=", function(self)
  local b = rio_pop("#bc").data
  local a = rio_pop("#bc").data
  rio_push({ ty="#bc", data=a ~= b, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#bc_#bc_and", function(self)
  local b = rio_pop("#bc").data
  local a = rio_pop("#bc").data
  rio_push({ ty="#bc", data=a and b, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#bc_#bc_or", function(self)
  local b = rio_pop("#bc").data
  local a = rio_pop("#bc").data
  rio_push({ ty="#bc", data=a or b, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#bc_not", function(self)
  local a = rio_pop("#bc").data
  rio_push({ ty="#bc", data=not a, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)
