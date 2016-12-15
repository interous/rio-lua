rio_addvaltype("#float8", types["__#val"], function(s, ty)
  local parsed = tonumber(s)
  if not parsed then badliteral(s, ty, "#float8") end
  rio_push({ ty=types[ty], data=parsed,
    eval=function(self) rio_push(self) end })
end)

rio_addvaltype("^int4", types["__^val"], function(s, ty)
  local parsed = tonumber(s)
  if not parsed then badliteral(s, ty, "^int4") end
  if math.floor(parsed) ~= parsed then badliteral(s, ty, "^int4") end
  rio_push({ ty=types[ty], data=backend_int4(parsed),
    eval=function(self) rio_push(self) end })
end)
