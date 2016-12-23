rio_addvaltype("#binary", "__#val", function(s, ty)
  local parsed = nil
  if s == "1" then parsed = true elseif s == "0" then parsed = false end
  if not parsed then badliteral(s, ty, "#binary") end
  rio_push({ ty=types[ty], data=parsed,
    eval=function(self) rio_push(self) end })
end)

rio_addvaltype("^binary", "__#val", function(s, ty)
  local parsed = nil
  if s == "1" then parsed = true elseif s == "0" then parsed = false end
  if not parsed then badliteral(s, ty, "^binary") end
  rio_push({ ty=types[ty], data=backend_binary(parsed),
    eval=function(self) rio_push(self) end })
end)
