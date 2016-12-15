rio_addcore("backend-code", function(self)
  local code = rio_pop(types["__quote"])
  table.insert(curbody, "  " .. code.data .. "\n")
end)

rio_addcore("backend-include", function(self)
  local file = rio_pop(types["__quote"])
  backend_include(file.data)
end)

rio_addcore("poly", function(self)
  local arity = rio_pop(types["#idx"]).data
  local name = rio_peek()
  rio_requiretype(name, types["__quote"])
  name = name.data
  local body = newlist()
  listpush(body, rio_strtoquote("_"))
  local i
  for i = 1, arity do
    listpush(body, rio_strtoquote(tostring(arity + 1 - i)))
    listpush(body, rio_strtosymbol("#idx"))
    listpush(body, rio_strtosymbol("type-at"))
    listpush(body, rio_strtosymbol("type->quote"))
    listpush(body, rio_strtosymbol("___quote___quote_++"))
    listpush(body, rio_strtoquote("_"))
    listpush(body, rio_strtosymbol("___quote___quote_++"))
  end
  listpush(body, rio_strtoquote(name))
  listpush(body, rio_strtosymbol("___quote___quote_++"))
  listpush(body, rio_strtosymbol("eval"))
  rio_push(rio_listtoblock(body))
  rio_getsymbol("procedure"):eval()
end)

rio_addcore("eval", function(self)
  local quote = rio_pop(types["__quote"]).data
  rio_getsymbol(quote):eval()
end)

rio_addcore("___quote___quote_++", function(self)
  local b = rio_pop(types["__quote"])
  local a = rio_pop(types["__quote"])
  rio_push({ ty=types["__quote"], data=a.data .. b.data,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("___quote___quote_=", function(self)
  local b = rio_pop(types["__quote"]).data
  local a = rio_pop(types["__quote"]).data
  rio_push({ ty=types["#bool"], data=a == b,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("___type___type_=", function(self)
  local b = rio_pop(types["__type"]).data
  local a = rio_pop(types["__type"]).data
  rio_push({ ty=types["#bool"], data=a == b,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("lift", function(self)
  local idx = rio_pop(types["#idx"])
  if idx.data >= stack.n or idx.data < 0 then outofstackbounds() end
  local elem = stack[stack.n - idx.data]
  for i=stack.n-idx.data,stack.n-1 do stack[i] = stack[i+1] end
  stack[stack.n] = elem
end)

rio_addcore("type-at", function(self)
  local idx = rio_pop(types["#idx"])
  if idx.data >= stack.n or idx.data < 0 then outofstackbounds() end
  rio_push({ ty=types["__type"], data=stack[stack.n - idx.data].ty,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("kind-at", function(self)
  local idx = rio_pop(types["#idx"])
  if idx.data >= stack.n or idx.data < 0 then outofstackbounds() end
  rio_push({ ty=types["__type"], data=types[stack[stack.n - idx.data].ty].kind,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("quote->type", function(self)
  local ty = rio_pop(types["__quote"])
  if not types[ty.data] then notatype(ty.data) end
  rio_push({ ty=types["__type"], data=types[ty.data],
    eval = function(self) rio_push(self) end })
end)

rio_addcore("type->quote", function(self)
  local ty = rio_pop(types["__type"]).data
  if not types[ty] then notatype(ty) end
  rio_push(rio_strtoquote(types[ty].ty))
end)

rio_addcore("thunk->quote", function(self)
  local thunk = rio_pop()
  rio_requirekind(types[types[types[types[thunk.ty].kind].ty]], types["__^val"])
  rio_push(rio_strtoquote(tostring(thunk.data)))
end)
