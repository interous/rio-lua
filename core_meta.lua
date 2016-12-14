rio_addcore("backend-code", function(self)
  local code = rio_pop(types["__token"])
  table.insert(curbody, "  " .. code.data .. "\n")
end)

rio_addcore("backend-include", function(self)
  local file = rio_pop(types["__token"])
  backend_include(file.data)
end)

rio_addcore("___token___token_++", function(self)
  local b = rio_pop(types["__token"])
  local a = rio_pop(types["__token"])
  rio_push({ ty=types["__token"], data=a.data .. b.data,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("lift", function(self)
  local idx = rio_pop(types["$idx"])
  if idx.data >= stack.n or idx.data < 0 then outofstackbounds() end
  local elem = stack[stack.n - idx.data]
  for i=stack.n-idx.data,stack.n-1 do stack[i] = stack[i+1] end
  stack[stack.n] = elem
end)

rio_addcore("type-at", function(self)
  local idx = rio_pop(types["$idx"])
  if idx.data >= stack.n or idx.data < 0 then outofstackbounds() end
  rio_push({ ty=types["__type"], data=types[stack[stack.n - idx.data].ty],
    eval = function(self) rio_push(self) end })
end)
