rio_addrepr("#binary", "#val")
rio_addcore("#binary", function(self)
  local s = rio_pop("__quote").data
  local parsed = nil
  if s == "0" then parsed = false elseif s == "1" then parsed = true end
  if not parsed then badliteral(s, ty) end
  rio_push({ ty="#binary", data=parsed,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#binary_#binary_=", function(self)
  rio_push({ ty="#binary", data=rio_pop().data == rio_pop().data,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#binary_#binary_/=", function(self)
  rio_push({ ty="#binary", data=rio_pop().data ~= rio_pop().data,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#binary_#binary_and", function(self)
  rio_push({ ty="#binary", data=rio_pop().data and rio_pop().data,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#binary_#binary_or", function(self)
  rio_push({ ty="#binary", data=rio_pop().data or rio_pop().data,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("_#binary_not", function(self)
  rio_push({ ty="#binary", data=not rio_pop().data,
    eval=function(self) rio_push(self) end })
end)
