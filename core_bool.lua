rio_addvaltype("#bool", "__#val", function(s, ty)
  local parsed = nil
  if s == "#t" then parsed = true elseif s == "#f" then parsed = false end
  if not parsed then badliteral(s, ty, "#bool") end
  rio_push({ ty=types[ty], data=parsed,
    eval=function(self) rio_push(self) end })
end)
