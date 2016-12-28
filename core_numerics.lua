rio_addvaltype("#float8", "__#val", function(s, ty)
  local parsed = tonumber(s)
  if not parsed then badliteral(s, ty, "#float8") end
  rio_push({ ty=types[ty], data=parsed,
    eval=function(self) rio_push(self) end })
end)

rio_addvaltype("^int4", "__^val", function(s, ty)
  local parsed = tonumber(s)
  if not parsed then badliteral(s, ty, "^int4") end
  if math.floor(parsed) ~= parsed then badliteral(s, ty, "^int4") end
  rio_push({ ty=types[ty], data=backend_int4(parsed),
    eval=function(self) rio_push(self) end })
end)

rio_addcore("derive+", function(self)
  local c = rio_pop(types["__quote"]).data
  local b = rio_pop(types["__quote"]).data
  local a = rio_pop(types["__quote"]).data
  rio_requiresamekind(a, b, c)
  local backend
  if kinds[types[a]] == types["^int4"] then
    f = backend_int4_plus
  else
    nonnumerickind(kinds[types[a]])
  end
  rio_addsymbol("_" .. a .. "_" .. b .. "_+", { ty=types["__derived"],
    aty=types[a], bty=types[b], cty=types[c], f=f,
    eval = function(self)
      local b = rio_pop(self.bty).data
      local a = rio_pop(self.aty).data
      rio_push({ ty=self.cty, data=self.f(a, b),
        eval=function(self) rio_push(self) end })
    end })
end)

rio_addcore("derive-", function(self)
  local c = rio_pop(types["__quote"]).data
  local b = rio_pop(types["__quote"]).data
  local a = rio_pop(types["__quote"]).data
  rio_requiresamekind(a, b, c)
  local backend
  if kinds[types[a]] == types["^int4"] then
    f = backend_int4_minus
  else
    nonnumerickind(kinds[types[a]])
  end
  rio_addsymbol("_" .. a .. "_" .. b .. "_-", { ty=types["__derived"],
    aty=types[a], bty=types[b], cty=types[c], f=f,
    eval = function(self)
      local b = rio_pop(self.bty).data
      local a = rio_pop(self.aty).data
      rio_push({ ty=self.cty, data=self.f(a, b),
        eval=function(self) rio_push(self) end })
    end })
end)

rio_addcore("derive*", function(self)
  local c = rio_pop(types["__quote"]).data
  local b = rio_pop(types["__quote"]).data
  local a = rio_pop(types["__quote"]).data
  rio_requiresamekind(a, b, c)
  local f
  if kinds[types[a]] == types["^int4"] then
    f = backend_int4_times
  else
    nonnumerickind(kinds[types[a]])
  end
  rio_addsymbol("_" .. a .. "_" .. b .. "_*", { ty=types["__derived"],
    aty=types[a], bty=types[b], cty=types[c], f=f,
    eval = function(self)
      local b = rio_pop(self.bty).data
      local a = rio_pop(self.aty).data
      rio_push({ ty=self.cty, data=self.f(a, b),
        eval=function(self) rio_push(self) end })
    end })
end)
