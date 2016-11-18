rio_addcore("as-code", function(self)
  local code = rio_pop()
  rio_requiretype(code, types["__token"])
  rio_push({ ty=types["__token"], data=indent_level .. code.data .. "\n",
    eval = function(self) rio_push(self) end })
end)

rio_addcore("___token___token_++", function(self)
  local a = rio_pop()
  local b = rio_pop()
  rio_requiretype(a, types["__token"])
  rio_requiretype(b, types["__token"])
  rio_push({ ty=types["__token"], data=a.data .. b.data,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("lift", function(self)
  local raw = rio_pop()
  rio_requiretype(raw, types["__token"])
  local offset = tonumber(raw.data);
  if not offset then notanumber(raw) end
  if offset >= stack.n then outofstackbounds() end
  local elem = stack[stack.n - offset]
  for i=stack.n-offset,stack.n-1 do stack[i] = stack[i+1] end
  stack[stack.n] = elem
end)

rio_addcore("type-at", function(self)
  local raw = rio_pop()
  rio_requiretype(raw, types["__token"])
  local offset = tonumber(raw.data)
  if not offset then notanumber(raw) end
  if offset >= stack.n then outofstackbounds() end
  rio_push({ ty=types["__token"], data=types[stack[stack.n - offset].ty],
    eval = function(self) rio_push(self) end })
end)
