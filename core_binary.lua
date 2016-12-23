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

rio_addcore("derive=", function(self)
  local ty = rio_pop(types["__quote"]).data
  local f, r
  if kinds[types[ty]] == types["^int4"] then
    f = backend_int4_equal
    r = types["^b"]
  else
    nonnumerickind(kinds[types[ty]])
  end
  rio_addsymbol("_" .. ty .. "_" .. ty .. "_=", { ty=types["__derived"],
    ty=types[ty], f=f, r=r,
    eval = function(self)
      local b = rio_pop(self.ty).data
      local a = rio_pop(self.ty).data
      rio_push({ ty=self.r, data=self.f(a, b),
        eval=function(self) rio_push(self) end })
    end })
end)
