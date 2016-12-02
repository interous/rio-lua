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

filestack = { n=0 }
callstack = { n=0 }
rio_open(arg[1])
preamble = {}
body = {}
finalize = nil
curbody = {}

stack = { n=0 }
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

types = { n=0 }

function rio_addtype(ty)
  types.n = types.n + 1
  types[types.n] = ty
  types[ty] = types.n
end

rio_addtype("__parse-end")
rio_addtype("__core")
rio_addtype("__token")
rio_addtype("__block")
rio_addtype("__procedure")
rio_addtype("__resource")
rio_addtype("__resource-write")

function rio_push(val)
  stack.n = stack.n + 1
  stack[stack.n] = val
end

function rio_pop()
  if stack.n == 0 then invalidpop() end
  stack.n = stack.n - 1
  return stack[stack.n + 1]
end

function rio_addsymbol(name, val)
  if symboltable[name] then alreadybound(name) end
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

binding_prefix = ""
binding_prefixes = {}

require "core_meta"
require "core_resource"
require "core_structure"

function rio_flatten(block)
  local i
  for i=1,block.data.n do
    block.data[i]:eval()
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
