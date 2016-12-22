local os = require "os"
local io = require "io"
require "parse"
require "error"

backend = "c"

if not arg[1] then
  print("error: no input file")
  os.exit(-1)
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

function rio_listtoblock(l)
  return { ty=types["__block"], data=l,
    eval = function(self) rio_push(self) end }
end

function rio_strtosymbol(s, f, l, c)
  return { ty=types["__symbol"], data=s, file=f, line=l, col=c,
    eval = function(self)
      rio_errorbase = { symbol=self.data, file=self.file, line=self.line, col=self.col }
      rio_getsymbol(self.data):eval()
    end }
end

function rio_strtoquote(s)
  return { ty=types["__quote"], data=s, line=l, col=c,
    eval = function(self) rio_push(self) end }
end

filestack = newlist()
callstack = newlist()
rio_open(arg[1])
preamble = {}
body = {}
finalize = nil
curbody = {}

stack = newlist()
symboltable = {}
backendtable = {}

function rio_addbackend(name, val)
  if backendtable[name] then
    print("duplicate backend symbol " .. name)
    os.exit(-1)
  end
  backendtable[name] = val
end

require ("backend_" .. backend)

types = newlist()
kinds = newlist()
literalparsers = {}

function rio_addtype(ty, kind)
  types.n = types.n + 1
  kinds.n = kinds.n + 1
  types[types.n] = ty
  types[ty] = types.n
  kinds[kinds.n] = types[kind] or 0
end

function rio_addcoretype(name, kind)
  kind = kind or 0
  rio_addtype(name, kind)
  rio_addsymbol(name, { name=name,
    eval = function(self) reservednoeval(self.name) end })
end

function rio_addvaltype(name, kind, parser)
  rio_addtype(name, kind)
  rio_addsymbol(name, { name=name,
    eval = function(self) reservednoeval(self.name) end })
  literalparsers[name] = parser
end

function rio_push(val)
  stack.n = stack.n + 1
  stack[stack.n] = val
end

function rio_pop(ty)
  if stack.n == 0 then invalidpop() end
  if ty then rio_requiretype(stack[stack.n], ty) end
  stack.n = stack.n - 1
  return stack[stack.n + 1]
end

function rio_peek()
  if stack.n == 0 then invalidpop() end
  return stack[stack.n]
end

function rio_addsymbol(name, val)
  if symboltable[name] then alreadybound(name) end
  if not val.file then val.file = rio_errorbase.file end
  if not val.line then val.line = rio_errorbase.line end
  if not val.col then val.col = rio_errorbase.col end
  symboltable[name] = val
end

function rio_addcore(name, f)
  rio_addsymbol(name, { ty=types["__core"], eval = f })
end

function rio_getsymbol(name)
  if not symboltable[name] then notbound(name) end
  return symboltable[name]
end

function rio_requiretype(val, ty)
  if val.ty ~= ty then wrongtype(ty, val.ty) end
end

function rio_requirekind(val, kind)
  if val ~= kind then wrongkind(kind, val) end
end

function rio_requiresamekind(a, b, c)
  if not types[a] then notatype(a) end
  if not types[b] then notatype(b) end
  if not types[c] then notatype(c) end
  if kinds[types[a]] ~= kinds[types[b]] then kindmismatch(kinds[types[a]], kinds[types[b]]) end
  if kinds[types[b]] ~= kinds[types[c]] then kindmismatch(kinds[types[b]], kinds[types[c]]) end
end

binding_prefix = ""
binding_prefixes = {}

require "core_meta"
require "core_resource"
require "core_structure"
require "core_type"

rio_addcoretype("__core")
rio_addcoretype("__type")
rio_addcoretype("__parse-end")
rio_addcoretype("__symbol")
rio_addcoretype("__quote")
rio_addcoretype("__block")
rio_addcoretype("__procedure")
rio_addcoretype("__derived")
rio_addcoretype("__constructor")
rio_addcoretype("__resource")
rio_addcoretype("__resource-write")
rio_addcoretype("__#val", "__type")
rio_addcoretype("__^val", "__type")

require "core_numerics"
require "core_bool"

require "prelude"

function rio_invokewithtrace(block)
  listpush(rio_errorstack, rio_errorbase)
  rio_flatten(block)
  listpop(rio_errorstack)
end

function rio_flatten(block)
  local i
  for i=1,block.n do
    block[i]:eval()
  end
end

function eval(atom)
  if atom.ty == types["__parse-end"] then
    local fd = assert(io.open(string.sub(arg[1], 1, -4) .. backend, "w"))
    fd:write(table.concat(preamble, ""))
    fd:write("\n")
    fd:write(table.concat(body, ""))
    fd:write("\n")
    fd:write(backend_finalize(finalize))
    fd:close()
  else
    atom:eval()
  end
end

while filestack.n > 0 do
  eval(nextatom())
end
