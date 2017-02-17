rio_addcore("backend-code", function(self)
  local code = rio_pop("__quote").data
  table.insert(curbody, indent_level .. code .. "\n")
end)

rio_addcore("backend-raw-code", function(self)
  table.insert(curbody, rio_pop("__quote").data)
end)

rio_addcore("backend-declare", function(self)
  local decl = rio_pop("__quote").data
  table.insert(curdecls, indent_level .. decl .. "\n")
end)

rio_addcore("backend-include", function(self)
  local file = rio_pop("__quote").data
  if not includes[file] then
    table.insert(preamble, file .. "\n")
    includes[file] = true
  end
end)

rio_addcore("eval", function(self)
  local quote = rio_pop("__quote").data
  rio_eval(rio_strtosymbol(quote, rio_errorbase.file, rio_errorbase.line, rio_errorbase.col))
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
  --print("concat")
  --print(a.data)
  --print(b.data)
  rio_push({ ty="__quote", data=a.data .. b.data, aliases={},
    eval = function(self) rio_push(self) end })
end)

rio_addcore("___quote___quote_=", function(self)
  local b = rio_pop("__quote").data
  local a = rio_pop("__quote").data
  rio_push({ ty="#bc", data=a == b, aliases={},
    eval = function(self) rio_push(self) end })
end)

rio_addcore("___quote___quote_/=", function(self)
  local b = rio_pop("__quote").data
  local a = rio_pop("__quote").data
  rio_push({ ty="#bc", data=a ~= b, aliases={},
    eval = function(self) rio_push(self) end })
end)

rio_addcore("___quote_#idx_at", function(self)
  local idx = rio_pop("#idx").data + 1
  local quote = rio_pop("__quote").data
  if idx < 0 or idx > quote:len() then outofquotebounds(quote, idx) end
  rio_push({ ty="#latin1-char", data=quote:byte(idx),
    eval = function(self) rio_push(self) end })
end)

rio_addcore("quote->char", function(self)
  local quote = rio_pop("__quote").data
  if quote:len() ~= 1 then quotewronglength(quote) end
  rio_push({ ty="#latin1-char", data=quote:byte(1),
    eval = function(self) rio_push(self) end })
end)

rio_addcore("char->quote", function(self)
  local char = rio_pop("#latin1-char").data
  if char < 0 or char > 255 then charoutofbounds(char) end
  rio_push(rio_strtoquote(string.char(char)))
end)

rio_addcore("___quote_len", function(self)
  local quote = rio_pop("__quote").data
  rio_push({ ty="#idx", data=quote:len(),
    eval=function(self) rio_push(self) end })
end)

rio_addcore("block-push", function(self)
  local elem = rio_pop()
  listpush(rio_peek("__block").data, elem)
end)

rio_addcore("___block___block_++", function(self)
  local b = rio_pop("__block").data
  local a = rio_pop("__block").data
  rio_push(rio_listtoblock(tableconcat(a, b)))
end)

rio_addcore("quote", function(self)
  local quote = tablecopy(rio_pop("__quote"))
  quote.data = "'" .. quote.data
  rio_push(quote)
end)

rio_addcore("symbol", function(self)
  rio_push(rio_strtosymbol(rio_pop("__quote").data))
end)

rio_addcore("defined?", function(self)
  local name = rio_pop("__quote").data
  rio_push({ ty="#bc", data=rio_nameinuse(name) ~= nil, aliases={},
    eval=function(self) rio_push(self) end })
end)

rio_addcore("lift", function(self)
  local idx = rio_pop("#idx").data
  if idx >= stack.n or idx < 0 then outofstackbounds() end
  local elem = stack[stack.n - idx]
  for i=stack.n-idx,stack.n-1 do stack[i] = stack[i+1] end
  stack[stack.n] = elem
end)

rio_addcore("dup", function(self)
  rio_push(rio_peek())
end)

rio_addcore("drop", function(self)
  rio_pop()
end)

rio_addcore("add-type", function(self)
  rio_addtype(rio_pop("__quote").data)
end)

rio_addcore("type-at", function(self)
  local idx = rio_pop("#idx").data
  if idx >= stack.n or idx < 0 then outofstackbounds() end
  rio_push({ ty="__quote", data=stack[stack.n - idx].ty, aliases={},
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

rio_addcore("print-aliases", function(self)
  local val = rio_pop()
  local output = {}
  for k in pairs(val.aliases) do table.insert(output, k) end
  print(table.concat(output, "; "))
end)

rio_addcore("print-stack", function(self)
  rio_printstack()
end)

rio_addcore("print-immediate", function(self)
  print(rio_pop("__quote").data)
end)

rio_addcore("set-backend-indent", function(self)
  indent_step = rio_pop("__quote").data
end)

rio_addcore("merge-aliases", function(self)
  local b = rio_pop()
  local a = rio_peek()
  for k in pairs(b.aliases) do a.aliases[k] = true end
end)
