local os = require "os"
local io = require "io"
require "parse"
require "error"

backend = "c"
indent_level = ""
indent_step = ""

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

function tableconcat(a, b)
  local c = { n=a.n + b.n }
  for k,v in pairs(a) do
    if k ~= "n" then table.insert(c, v) end
  end
  for k,v in pairs(b) do
    if k ~= "n" then table.insert(c, v) end
  end
  return c
end

function broadfalse(v)
  return v ~= false and v ~= nil
end

function rio_listtoblock(l)
  return { ty="__block", data=l, aliases={}, mut=true,
    eval=function(self) rio_push(rio_listtoblock(listcopy(self.data))) end }
end

function rio_strtosymbol(s, f, l, c)
  f = f or "core"
  l = l or 0
  c = c or 0
  return { ty="__symbol", data=s, file=f, line=l, col=c, aliases={}, mut=true,
    eval = function(self)
      rio_errorbase = { symbol=self.data, file=self.file, line=self.line, col=self.col }
      rio_getsymbol(self.data):eval()
    end }
end

function rio_strtoquote(s)
  return { ty="__quote", data=s, aliases={}, mut=true,
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
startable = {}
backendnames = {}
prefixtable = {}
prefixtable["'"] = { eval=function(self) end }
toplevel = true

--require ("backend_" .. backend)

types = {}
decision_types = {}

function rio_addtype(ty)
  if types[ty] then duplicatetype(ty) end
  types[ty] = ty
end

function rio_makedecisiontype(ty, kind)
  if not types[ty] then notatype(ty) end
  if decision_types[ty] then duplicatemakedecision(ty) end
  if kind ~= "A" and kind ~= "E" then invaliddecisionkind(kind) end
  decision_types[ty] = kind
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
    if not old[k] then rio_deletebinding(k, true) end
  end
end

function rio_collapsebindings(old)
  for k, v in pairs(bindingtable) do
    if not old[k] then rio_deletebinding(k, true)
    else
      if old[k].ty ~= v.ty or old[k].data ~= v.data then
        bindingmismatch(k, old[k], v)
      end
    end
  end
end

function rio_commitable(t)
  return (symboltable["_" .. t .. "_commit"] and
    symboltable["_" .. t .. "_declare"] and
    symboltable[t .. "->repr"]) ~= nil
end

function rio_stackeq(a, b)
  if a.n ~= b.n then stackmismatch(a, b) end
  local i
  for i = 1, a.n do
    if a[i].ty ~= b[i].ty or a[i].data ~= b[i].data then stackmismatch(a, b) end
  end
end

function rio_makestackbindings(startstack)
  local bindings = {}
  local mangles = {}
  for i = stack.n, 1, -1 do
    if rio_commitable(stack[i].ty) and (not startstack[i] or
        stack[i].ty ~= startstack[i].ty or
        stack[i].data ~= startstack[i].data) then
      rio_eval(rio_getsymbol(stack[i].ty .. "->repr"))
      local repr = rio_pop("__quote").data
      local mangle = 0
      local base_name = "__stack__" .. rio_sanitize(repr)
      local name = base_name .. mangle
      while rio_nameinuse(name) or mangles[name] do
        mangle = mangle + 1
        name = base_name .. mangle
      end
      mangles[name] = true
      bindings[i] = { name=name, val=stack[i] }
    end
  end
  return bindings
end

function rio_validatestack(startstack)
  if startstack.n ~= stack.n then stackmismatch(startstack, stack) end
  for i = 1, stack.n do
    if stack[i].ty ~= startstack[i].ty or stack[i].data ~= startstack[i].data then
      stackmismatch(startstack, stack)
    end
  end
end

function rio_commitstackentry(i)
  if not rio_commitable(stack[i].ty) then notcommtiable(stack[i].ty) end
  rio_eval(rio_getsymbol(stack[i].ty .. "->repr"))
  local repr = rio_pop("__quote").data
  local name = "__stack" .. tostring(i) .. "_" .. repr
  if not declarationtable[name] then
    rio_push(rio_strtoquote(name))
    rio_eval(rio_getsymbol("_" .. stack[i].ty .. "_declare"))
    declarationtable[name] = true
  end
  rio_push(rio_strtoquote(name))
  rio_push(stack[i])
  rio_eval(rio_getsymbol("_" .. stack[i].ty .. "_commit"))
  stack[i].data = name
end

function rio_commitstack()
  for i = 1, stack.n do
    if rio_commitable(stack[i].ty) then rio_commitstackentry(i) end
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
      table.insert(output, s[i].ty .. " " .. tostring(s[i].data))
    end
    print("  " .. table.concat(output, ", "))
  end
end

function rio_blocktostring(block)
  local res = {}
  for i = 1, block.data.n do
    if block.data[i].ty == "__block" then
      table.insert(res, rio_blocktostring(block.data[i]))
    else
      table.insert(res, block.data[i].ty .. ", " .. tostring(block.data[i].data))
    end
  end
  return "{" .. table.concat(res, "; ") .. "}"
end

function rio_nameinuse(name)
  return broadfalse(symboltable[name] or prefixtable[name] or
    bindingtable[binding_prefix .. name] or
    (name:sub(1, 1) == '*' and bindingtable[name]))
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

function rio_addbinding(name, val, noprefix)
  if rio_nameinuse(name) then alreadybound(name) end
  if name:sub(1, 1) == '*' then
    startable[name] = binding_prefix
  elseif not noprefix then
    name = binding_prefix .. name
  end
  bindingtable[name] = val
end

function rio_commit(name, val, raw, noprefix)
  if rio_commitable(val.ty) then
    rio_eval(rio_getsymbol(val.ty .. "->repr"))
    local repr = rio_pop("__quote").data
    local backend_name = ""
    if not noprefix and name:sub(1, 1) ~= '*' then
      backend_name = binding_prefix
    end
    if raw then
      backend_name = backend_name .. name .. "__" .. rio_sanitize(repr)
    else
      backend_name = backend_name .. rio_sanitize(name) .. "__" .. rio_sanitize(repr)
    end
    if not declarationtable[name] then
      rio_push(rio_strtoquote(backend_name))
      rio_eval(rio_getsymbol("_" .. val.ty .. "_declare"))
      declarationtable[name] = true
    end
    rio_push(rio_strtoquote(backend_name))
    rio_push(val)
    rio_eval(rio_getsymbol("_" .. val.ty .. "_commit"))
    local binding = { ty=val.ty, data=backend_name, mut=val.mut,
      aliases={}, eval=function(self) rio_push(self) end }
    if noprefix then
      binding.aliases[name] = true
    else
      binding.aliases[binding_prefix .. name] = true
    end
    rio_addbinding(name, binding, noprefix)
  else
    notcommtiable(val.ty)
  end
end

function rio_deletebinding(name, noprefix, nodestruct)
  if not noprefix and name:sub(1, 1) ~= '*' then
    name = binding_prefix .. name
  end
  if not bindingtable[name] then notbound(name) end
  if name:sub(1, 1) == '*' and startable[name] ~= binding_prefix then
    stardeleteoutofscope(name)
  end
  for i=1,stack.n do
    if stack[i].aliases[name] then rio_commitstackentry(i) end
  end
  for k,v in pairs(bindingtable) do
    if k ~= name and v.aliases and v.aliases[name] then
      bindingtable[k] = nil
      rio_commit(k, v, true, true)
    end
  end
  if not nodestruct then
    local handler = "_" .. bindingtable[name].ty .. "_delete"
    if symboltable[handler] then
      rio_push(rio_strtoquote(name))
      rio_push(bindingtable[name])
      rio_eval(rio_getsymbol(handler))
    end
  end
  bindingtable[name] = nil
end

function rio_addcore(name, f)
  rio_addsymbol(name, { ty="__core", eval=f })
end

function rio_getsymbol(name)
  if name:sub(1, 1) == '*' and bindingtable[name] then return bindingtable[name]
  elseif bindingtable[binding_prefix .. name] then return bindingtable[binding_prefix .. name]
  elseif symboltable[name] then return symboltable[name]
  else notbound(name) end
end

function rio_requiretype(val, ty)
  if val.ty ~= ty then wrongtype(ty, val.ty) end
end

binding_prefix = ""
binding_prefixes = {}

require "core_bind"
require "core_meta"
require "core_resource"
require "core_structure"
require "core_type"
require "core_numerics"
require "core_logic"

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
  rio_collapsebindings(old_bindingtable)
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
    local flatpreamble = {}
    local levels = {}
    for level in pairs(preamble) do table.insert(levels, level) end
    table.sort(levels)
    for _,level in ipairs(levels) do
      table.insert(flatpreamble, table.concat(preamble[level], ""))
    end
    fd:write(table.concat(flatpreamble, "\n"))
    fd:write("\n")
    fd:write(table.concat(body, ""))
    fd:write("\n")
    rio_push(rio_strtoquote(finalize_decls))
    rio_push(rio_strtoquote(finalize_body))
    rio_eval(rio_getsymbol("backend-finalize"))
    fd:write(rio_pop("__quote").data)
    fd:close()
  elseif blob.ty == "__symbol" and blob.data:len() > 1 and prefixtable[blob.data:sub(1, 1)] then
    rio_push(rio_strtoquote(blob.data:sub(2, -1)))
    prefixtable[blob.data:sub(1, 1)]:eval()
  else
    blob:eval()
  end
end

while filestack.n > 0 do
  rio_eval(nextatom())
end
