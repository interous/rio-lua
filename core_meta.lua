rio_addcore("___token___token_++", function(self)
  local a = rio_pop()
  local b = rio_pop()
  rio_requiretype(a, types["__token"])
  rio_requiretype(b, types["__token"])
  rio_push({ ty=types["__token"], data=a.data .. b.data,
    eval = function(self) rio_push(self) end })
)

rio_addcore("type-at", function(self)
  local raw = rio_pop()
  rio_requiretype(raw, types["__token"])
  local offset = tonumber(raw)
  if not offset then notanumber(raw) end
  if offset >= stack.n then outofstackbounds() end
  rio_push({ ty=types["__token"], data=types[stack[stack.n - offset].ty],
    eval = function(self) rio_push(self) end })
)
