rio_addcore("backend-code", function(self)
  local code = rio_pop("__quote").data
  table.insert(curbody, indent_level .. code .. "\n")
end)

rio_addcore("backend-raw-code", function(self)
  table.insert(curbody, rio_pop("__quote").data)
end)

rio_addcore("backend-declare", function(self)
  local decl = rio_pop("__quote").data
  if not declarationtable[decl] then
    table.insert(curdecls, indent_step .. decl .. "\n")
    declarationtable[decl] = true
  end
end)

rio_addcore("backend-header", function(self)
  local level = rio_pop("#level").data
  local text = rio_pop("__quote").data
  if not preamble[level] then preamble[level] = {} end
  table.insert(preamble[level], text .. "\n")
end)

rio_addcore("eval", function(self)
  local datum = rio_pop()
  if datum.ty == "__quote" then
    rio_eval(rio_strtosymbol(datum.data, rio_errorbase.file, rio_errorbase.line, rio_errorbase.col))
  elseif datum.ty == "__symbol" then
    rio_eval(datum)
  end
end)

rio_addcore("get-by-fqn", function(self)
  local name = rio_pop("__quote").data
  if not bindingtable[name] then notbound(name) end
  rio_push(bindingtable[name])
end)

rio_addcore("flatten", function(self)
  rio_invokewithtrace(rio_pop("__block").data)
end)

rio_addcore("compile-error", function(self)
  usererror(rio_pop("__quote").data)
end)

rio_addcore("___quote___quote_++", function(self)
  local b = rio_pop("__quote")
  local a = rio_pop("__quote")
  rio_push(rio_strtoquote(a.data .. b.data))
end)

rio_addcore("___quote___quote_=", function(self)
  local b = rio_pop("__quote").data
  local a = rio_pop("__quote").data
  rio_push({ ty="#bc", data=a == b, aliases={}, mut=true,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("___quote___quote_/=", function(self)
  local b = rio_pop("__quote").data
  local a = rio_pop("__quote").data
  rio_push({ ty="#bc", data=a ~= b, aliases={}, mut=true,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("quote->char", function(self)
  local quote = rio_pop("__quote").data
  if quote:len() ~= 1 then quotewronglength(quote) end
  rio_push({ ty="#latin1-char", data=quote:byte(1), mut=true,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("char->quote", function(self)
  local char = rio_pop("#latin1-char").data
  if char < 0 or char > 255 then charoutofbounds(char) end
  rio_push(rio_strtoquote(string.char(char)))
end)

rio_addcore("___quote_len", function(self)
  local quote = rio_pop("__quote").data
  rio_push({ ty="#idx", data=quote:len(), aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("___quote_#idx_at", function(self)
  local idx = rio_pop("#idx").data + 1
  local quote = rio_pop("__quote").data
  if idx < 0 or idx > quote:len() then outofquotebounds(quote, idx) end
  rio_push({ ty="#latin1-char", data=quote:byte(idx), mut=true,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("___quote_#idx_#idx_slice", function(self)
  local b = rio_pop("#idx").data
  local a = rio_pop("#idx").data
  if a >= 0 then a = a + 1 end
  if b >= 0 then b = b + 1 end
  local quote = rio_pop("__quote").data
  rio_push(rio_strtoquote(quote:sub(a, b)))
end)

rio_addcore("block-push", function(self)
  local elem = rio_pop()
  listpush(rio_peek("__block").data, elem)
end)

rio_addcore("block-push-as-symbol", function(self)
  local elem = rio_pop("__quote").data
  listpush(rio_peek("__block").data, rio_strtosymbol(elem))
end)

rio_addcore("___block_#idx_at", function(self)
  local idx = rio_pop("#idx").data + 1
  local block = rio_pop("__block").data
  if idx < 0 or idx > block.n then outofblockbounds(block.n, idx) end
  rio_eval(block[idx])
end)

rio_addcore("at-as-quote", function(self)
  local idx = rio_pop("#idx").data + 1
  local block = rio_pop("__block").data
  if idx < 0 or idx > block.n then outofblockbounds(block.n, idx) end
  rio_requiretype(block[idx], "__symbol")
  rio_push(rio_strtoquote(block[idx].data))
end)

rio_addcore("type-in-block", function(self)
  local idx = rio_pop("#idx").data + 1
  local block = rio_pop("__block").data
  if idx < 0 or idx > block.n then outofblockbounds(block.n, idx) end
  rio_push(rio_strtoquote(block[idx].ty))
end)

rio_addcore("___block_len", function(self)
  local block = rio_pop("__block").data
  rio_push({ ty="#idx", data=block.n, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("___block___block_++", function(self)
  local b = rio_pop("__block").data
  local a = rio_pop("__block").data
  rio_push(rio_listtoblock(tableconcat(a, b)))
end)

rio_addcore("defined?", function(self)
  local name = rio_pop("__quote").data
  rio_push({ ty="#bc", data=rio_nameinuse(name), aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("fqn-defined?", function(self)
  local name = rio_pop("__quote").data
  rio_push({ ty="#bc", data=broadfalse(bindingtable[name]), aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("stack-height", function(self)
  rio_push({ ty="#idx", data=stack.n, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("lift", function(self)
  local idx = rio_pop("#idx").data
  if idx >= stack.n or idx < 0 then outofstackbounds() end
  local elem = stack[stack.n - idx]
  for i=stack.n-idx,stack.n-1 do stack[i] = stack[i+1] end
  stack[stack.n] = elem
end)

rio_addcore("dup-at", function(self)
  local idx = rio_pop("#idx").data
  if idx >= stack.n or idx < 0 then outofstackbounds() end
  local elem = stack[stack.n - idx]
  rio_push(tablecopy(elem))
end)

rio_addcore("mangle-name", function(self)
  local ty = rio_pop("__quote").data
  local name = rio_sanitize(rio_pop("__quote").data)
  rio_eval(rio_getsymbol(ty .. "->repr"))
  local repr = rio_sanitize(rio_pop("__quote").data)
  rio_push(rio_strtoquote(binding_prefix .. name .. "__" .. repr))
end)

rio_addcore("binding-prefix", function(self)
  rio_push(rio_strtoquote(binding_prefix))
end)

rio_addcore("add-type", function(self)
  rio_addtype(rio_pop("__quote").data)
end)

rio_addcore("type-at", function(self)
  local idx = rio_pop("#idx").data
  if idx >= stack.n or idx < 0 then outofstackbounds() end
  rio_push({ ty="__quote", data=stack[stack.n - idx].ty, aliases={}, mut=true,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("pointer-size", function(self)
  rio_push({ ty="#B", data=8, aliases={}, mut=true,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("unsafe-set-type-at", function(self)
  local idx = rio_pop("#idx").data
  local ty = rio_pop("__quote").data
  if idx >= stack.n or idx < 0 then outofstackbounds() end
  local datum = tablecopy(stack[stack.n - idx])
  datum.ty = ty
  stack[stack.n - idx] = datum
end)

-- This function is, curiously, needed for bootstrapping
rio_addcore("unsafe-set-type", function(self)
  local ty = rio_pop("__quote").data
  local datum = tablecopy(rio_pop())
  datum.ty = ty
  rio_push(datum)
end)

-- Note, this could be emulated with type-of and compile-error, but this is
-- provided for consistency of error messages. It peeks rather than pops to
-- allow simpler inlining.
rio_addcore("require-type", function(self)
  local ty = rio_pop("__quote").data
  local datum = rio_peek()
  rio_requiretype(datum, ty)
end)

rio_addcore("type-mismatch", function(self)
  local actual = rio_pop("__quote").data
  local expected = rio_pop("__quote").data
  wrongtype(expected, actual)
end)

rio_addcore("is-type?", function(self)
  local ty = rio_pop("__quote").data
  rio_push({ ty="#bc", data=types[ty] ~= nil, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("print-aliases", function(self)
  local val = rio_pop()
  local output = {}
  for k in pairs(val.aliases) do table.insert(output, k) end
  print(table.concat(output, "; "))
end)

rio_addcore("print-stack", function(self)
  rio_printstack()
end)

rio_addcore("#print", function(self)
  local datum = rio_pop()
  if datum.ty == "__quote" then
    print(datum.data)
  elseif datum.ty == "__block" then
    print(rio_blocktostring(datum))
  else
    print(datum.ty .. ", " .. tostring(datum.data))
  end
end)

rio_addcore("set-backend-indent", function(self)
  indent_step = rio_pop("__quote").data
end)

rio_addcore("merge-aliases", function(self)
  local b = rio_pop()
  local a = rio_peek()
  for k in pairs(b.aliases) do a.aliases[k] = true end
end)

rio_addcore("add-alias", function(self)
  local name = rio_pop("__quote").data
  rio_peek().aliases[name] = true
end)

rio_addcore("remove-alias", function(self)
  local name = rio_pop("__quote").data
  rio_peek().aliases[name] = nil
end)

rio_addcore("alias-of?", function(self)
  local name = rio_pop("__quote").data
  local datum = rio_pop()
  rio_push({ ty="#bc", data=datum.aliases[name] ~= nil, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("mutable-alias-count", function(self)
  local datum = rio_pop()
  local res = 0
  for t in pairs(datum.aliases) do
    for i = 1, stack.n do
      if stack[i].mut and stack[i].aliases[t] then res = res + 1 end
    end
    for _,v in pairs(bindingtable) do
      if v.mut and v.aliases[t] then res = res + 1 end
    end
  end
  rio_push({ ty="#aliases", data=res, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("purge-aliases", function(self)
  local lastman = rio_peek()
  for t in pairs(lastman.aliases) do
    for i = 1, stack.n - 1 do
      if stack[i].aliases[t] then purgealiasonstack(t) end
    end
    for k,v in pairs(bindingtable) do
      if v.aliases[t] then rio_deletebinding(k, true) end
    end
  end
end)

rio_addcore("set-mutability", function(self)
  local val = rio_pop("#bc").data
  rio_peek().mut = val
end)

rio_addcore("mutable?", function(self)
  local datum = rio_pop()
  rio_push({ ty="#bc", data=datum.mut, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("get-anonymous-name", function(self)
  local ty = rio_sanitize(rio_pop("__quote").data)
  local i = 0
  while true do
    local name = "__anonymous" .. tostring(i) .. "_" .. ty
    if(not backendnames[name]) then
      backendnames[name] = true
      rio_push(rio_strtoquote(name))
      break
    end
    i = i + 1
  end
end)

rio_addcore("free-anonymous-name", function(self)
  local name = rio_pop("__quote").data
  backendnames[name] = nil
end)

rio_addcore("top-level?", function(self)
  rio_push({ ty="#bc", data=toplevel, aliases={}, mut=true,
    eval=function(self) rio_push(self) end })
end)

rio_addcore("require-top-level", function(self)
  if not toplevel then mustbetoplevel() end
end)

rio_addcore("require-not-top-level", function(self)
  if toplevel then mustnotbetoplevel() end
end)
