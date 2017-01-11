rio_addrepr("#binary", "#val")
rio_addtype("#bc", "#binary")
rio_addcore("#t", function(self)
  rio_push({ ty="#bc", data=true,
    eval=function(self) rio_push(self) end })
end)
rio_addcore("#f", function(self)
  rio_push({ ty="#bc", data=false,
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

rio_addcore("derive<", function(self)
  local ty = rio_pop(types["__quote"]).data
  local f, r
  if kinds[types[ty]] == types["^int4"] then
    f = backend_int4_lt
    r = types["^b"]
  elseif kinds[types[ty]] == types["#float8"] then
    f = function(a, b) return a < b end
    r = types["#b"]
  else
    nonnumerickind(kinds[types[ty]])
  end
  rio_addsymbol("_" .. ty .. "_" .. ty .. "_<", { ty=types["__derived"],
    ty=types[ty], f=f, r=r,
    eval = function(self)
      local b = rio_pop(self.ty).data
      local a = rio_pop(self.ty).data
      rio_push({ ty=self.r, data=self.f(a, b),
        eval=function(self) rio_push(self) end })
    end })
end)
