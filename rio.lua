local os = require "os"
local io = require "io"
require "parse"
require "error"

backend = "c"
indent_level = {""}

if not arg[1] then
  print("error: no input file")
  os.exit(-1)
end

--[[
  The legendary Y-combinator, which does anonymous recursion.
  
  The argument to Y is a unary function f, which should return a nullary
  or unary function. The inner function then does the work, and f is an
  anonymous function that allows recursive calls on the inner function.
  
  For example, you could do something like,
  factorial = Y(function(f) return function(n)
    if n == 0 then return 1 else return n * f(n - 1) end
  end end)
  factorial(5) -- returns 120
  
  You can handle functions of higher arity by embedding more and more
  anonymous functions. For example,
  print_nums = Y(function(f) return function(a) return function(b)
    print(a .. " " .. b)
    if a > 0 then f(a-1)(b-1) end
  end end end)
  print_nums(3)(6) -- prints 3 6; 2 5; 1 4; 0 3
  
  You can also do higher arity by having a single unary inner function
  that takes a table argument:
  print_nums = Y(function(f) return function(args)
    print(args[1] .. " " .. args[2])
    if args[1] > 0 then f{args[1]-1, args[2]-1} end
  end end)
  print_nums{3, 6} -- prints 3 6; 2 5; 1 4; 0 3
  
  Finally, embedding multiple anonymous functions can be used for
  argument closures:
  divmod = Y(function(f)
    return function(c) return function(a) return function(b)
      if a < b then return {c, a} else return f(c + 1)(a - b)(b) end
  end end end end)(0)
  divmod(10)(3) -- returns {3, 1}
--]]
function Y(f)
  return function(a)
    return (function(x) return x(x) end)(function(x) return f(function(y) return x(x)(y) end) end)(a)
  end
end

function rio_open(name)
  filestack.n = filestack.n + 1
  local fd = assert(io.open(name, "r"))
  filestack[filestack.n] = {
    name = name,
    data = fd:read("*a"),
    line = 1,
    col = 1,
    pos = 1
  }
  io.close(fd)
end

function rio_close()
  filestack[filestack.n] = nil
  filestack.n = filestack.n - 1
end

function rio_tohex(n)
  local res = {}
  while n > 0 do
    local d = n % 16
    if d < 10 then table.insert(res, tostring(d))
    elseif d == 10 then table.insert(res, "A")
    elseif d == 11 then table.insert(res, "B")
    elseif d == 12 then table.insert(res, "C")
    elseif d == 13 then table.insert(res, "D")
    elseif d == 14 then table.insert(res, "E")
    else table.insert(res, "F")
    end
    n = math.floor(n / 16)
  end
  return string.reverse(table.concat(res, ""))
end

function rio_sanitize(str)
  local res = {}
  for i=1,string.len(str) do
    local c = string.byte(str, i)
    if (c >= 48 and c < 58) or (c >= 65 and c < 91) or
        (c >= 97 and c < 123) then
      table.insert(res, string.char(c))
    else
      table.insert(res, "_")
      table.insert(res, rio_tohex(c))
    end
  end
  return table.concat(res, "")
end

function newlist() return { n=0 } end

function listpush(l, e)
  l.n = l.n + 1
  l[l.n] = e
end

function listpop(l)
  if l.n == 0 then return nil end
  local e = l[l.n]
  l[l.n] = nil
  l.n = l.n - 1
  return e
end

function listcopy(l)
  local c = newlist()
  c.n = l.n
  for i=1,l.n do
    c[i] = l[i]
  end
  return c
end

function tablecopy(t)
  local c = {}
  for k,v in pairs(t) do
    c[k] = v
  end
  return c
end

function rio_listtoblock(l)
  return { ty="__block", data=l,
    eval=function(self) rio_push(rio_listtoblock(listcopy(self.data))) end }
end

function rio_strtosymbol(s, f, l, c)
  f = f or "core"
  l = l or 0
  c = c or 0
  return { ty="__symbol", data=s, file=f, line=l, col=c,
    eval = function(self)
      rio_errorbase = { symbol=self.data, file=self.file, line=self.line, col=self.col }
      rio_getsymbol(self.data):eval()
    end }
end

function rio_strtoquote(s)
  return { ty="__quote", data=s,
    eval=function(self) rio_push(self) end }
end

filestack = newlist()
callstack = newlist()
rio_open(arg[1])
includes = {}
preamble = {}
body = {}
finalize_decls = nil
finalize_body = nil
curbody = {}
curdecls = {}

stack = newlist()
declarationtable = {}
symboltable = {}
bindingtable = {}
prefixtable = {}
prefixtable["'"] = { eval=function(self) end }

require ("backend_" .. backend)

kinds = {}
reprs = {}

function rio_addrepr(repr, kind)
  if kinds[repr] then duplicaterepr(repr) end
  kinds[repr] = kind
end

function rio_addtype(ty, repr)
  if reprs[ty] then duplicatetype(ty) end
  reprs[ty] = repr
end

function rio_push(val)
  stack.n = stack.n + 1
  stack[stack.n] = val
end

function rio_pop(ty)
  if stack.n == 0 then invalidpop() end
  if ty then rio_requiretype(stack[stack.n], ty) end
  local res = stack[stack.n]
  stack[stack.n] = nil
  stack.n = stack.n - 1
  return res
end

function rio_peek(ty)
  if stack.n == 0 then invalidpop() end
  if ty then rio_requiretype(stack[stack.n], ty) end
  return stack[stack.n]
end

function rio_stackcopy()
  local s = { n=stack.n }
  for i = 1, stack.n do
    s[i] = stack[i]
  end
  return s
end

function rio_bindingtablecopy(t)
  if not t then t = bindingtable end
  local s = {}
  for symbol, value in pairs(t) do
    s[symbol] = value
  end
  return s
end

function rio_deletenewbindings(old)
  for k,v in pairs(bindingtable) do
    if not old[k] then bindingtable[k] = nil end
  end
end

function rio_collapsebindings(old)
  for k, v in pairs(bindingtable) do
    if not old[k] then bindingtable[k] = nil
    else
      if old[k].ty ~= v.ty or old[k].data ~= v.data then
        bindingmismatch(k, old[k], v)
      end
    end
  end
end

function rio_isAtype(t)
  return reprs[t] and kinds[reprs[t]] and (kinds[reprs[t]] == "^val" or kinds[reprs[t]] == "^ref")
end

function rio_stackeq(a, b)
  if a.n ~= b.n then stackmismatch(a, b) end
  local i
  for i = 1, a.n do
    if a[i].ty ~= b[i].ty or a[i].data ~= b[i].data then stackmismatch(a, b) end
  end
end

function rio_makestackbindings()
  bindings = newlist()
  mangles = {}
  for i = stack.n, 1, -1 do
    local mangle = 0
    local base_name = "__stack_" .. stack[i].ty
    local name = base_name .. mangle
    while rio_nameinuse(name) or mangles[name] do
      mangle = mangle + 1
      name = base_name .. mangle
    end
    mangles[name] = true
    listpush(bindings, { name=name, val=stack[i] })
  end
  return bindings
end

function rio_validatestackbindings(bindings)
  local bindings_stack = newlist()
  for i = 1, bindings.n do
    listpush(bindings_stack, bindings[i].val)
  end
  if bindings.n ~= stack.n then stackmismatch(bindings_stack, stack) end
  for i = 1, stack.n do
    if stack[i].ty ~= bindings_stack[i].ty then stackmismatch(bindings_stack, stack) end
    if not rio_isAtype(stack[i].ty) then
      if stack[i].data ~= bindings_stack[i].data then
        stackmismatch(bindings_stack, stack)
      end
    end
  end
end

function rio_bindstack(bindings)
  rio_validatestackbindings(bindings)
  for i = 1, bindings.n do
    rio_push(rio_strtoquote(bindings[i].name))
    rio_getsymbol("bind"):eval()
  end
end

function rio_unbindstack(bindings)
  for i = bindings.n, 1, -1 do
    rio_getsymbol(bindings[i].name):eval()
  end
end

function rio_printstack(s)
  if not s then s = stack end
  if s.n == 0 then
    print ("  (empty)")
  else
    local output = {}
    local i
    for i = 1, s.n do
      if rio_isAtype(s[i].ty) then
        table.insert(output, s[i].ty)
      else
        table.insert(output, s[i].ty .. " " .. tostring(s[i].data))
      end
    end
    print("  " .. table.concat(output, ", "))
  end
end

function rio_nameinuse(name)
  return symboltable[name] or prefixtable[name] or bindingtable[binding_prefix .. name]
end

function rio_addsymbol(name, val)
  if rio_nameinuse(name) then alreadybound(name) end
  if not val.file then val.file = rio_errorbase.file end
  if not val.line then val.line = rio_errorbase.line end
  if not val.col then val.col = rio_errorbase.col end
  symboltable[name] = val
end

function rio_addprefix(name, val)
  if rio_nameinuse(name) then alreadybound(name) end
  prefixtable[name] = val
end

function rio_addbinding(name, val)
  if rio_nameinuse(name) then alreadybound(name) end
  bindingtable[binding_prefix .. name] = val
end

function rio_deletebinding(name)
  if not bindingtable[binding_prefix .. name] then notbound(name) end
  bindingtable[binding_prefix .. name] = nil
end

function rio_addcore(name, f)
  rio_addsymbol(name, { ty="__core", eval=f })
end

function rio_getsymbol(name)
  if bindingtable[binding_prefix .. name] then return bindingtable[binding_prefix .. name]
  elseif symboltable[name] then return symboltable[name]
  else notbound(name) end
end

function rio_requiretype(val, ty)
  if val.ty ~= ty then wrongtype(ty, val.ty) end
end

function rio_requirekind(val, kind)
  if val ~= kind then wrongkind(kind, val) end
end

function rio_requiresamerepr(a, b, c)
  if not reprs[a] then notatype(a) end
  if not reprs[b] then notatype(b) end
  if not reprs[c] then notatype(c) end
  if reprs[a] ~= reprs[b] then kindmismatch(reprs[a], reprs[b]) end
  if reprs[b] ~= reprs[c] then kindmismatch(reprs[b], reprs[c]) end
end

binding_prefix = ""
binding_prefixes = {}

require "core_bind"
require "core_meta"
require "core_resource"
require "core_structure"
require "core_type"
require "core_numerics"
require "core_binary"

function rio_invokewithtrace(block)
  listpush(rio_errorstack, rio_errorbase)
  rio_flatten(block)
  listpop(rio_errorstack)
end

function rio_invokeasmacro(name, body)
  local base_sanitized = rio_sanitize(name)
  local sanitized = base_sanitized
  local mangle = 0
  while binding_prefixes[sanitized] do
    sanitized = base_sanitized .. mangle
    mangle = mangle + 1
  end
  binding_prefixes[sanitized] = 0
  local old_prefix = binding_prefix
  binding_prefix = "__" .. sanitized .. binding_prefix
  local old_bindingtable = rio_bindingtablecopy()
  rio_invokewithtrace(body)
  local merged_bindingtable = {}
  for k, v in pairs(old_bindingtable) do
    if bindingtable[k] then merged_bindingtable[k] = bindingtable[k] end
  end
  bindingtable = merged_bindingtable
  binding_prefixes[sanitized] = nil
  binding_prefix = old_prefix
end

function rio_flatten(block)
  for i=1,block.n do
    rio_eval(block[i])
  end
end

function rio_eval(blob)
  if not blob then
    local fd = assert(io.open(string.sub(arg[1], 1, -4) .. backend, "w"))
    fd:write(table.concat(preamble, ""))
    fd:write("\n")
    fd:write(table.concat(body, ""))
    fd:write("\n")
    rio_push(rio_strtoquote(finalize_decls))
    rio_push(rio_strtoquote(finalize_body))
    rio_eval(rio_getsymbol("backend-finalize"))
    fd:write(rio_pop("__quote").data)
    fd:close()
  elseif blob.ty == "__symbol" and prefixtable[blob.data:sub(1, 1)] then
    rio_push(rio_strtoquote(blob.data:sub(2, -1)))
    prefixtable[blob.data:sub(1, 1)]:eval()
  else
    blob:eval()
  end
end

while filestack.n > 0 do
  rio_eval(nextatom())
end
