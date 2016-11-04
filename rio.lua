local os = require "os"
local io = require "io"
require "parse"
require "error"

backend = "cs"

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

filestack = { n=0 }
callstack = { n=0 }
rio_open(arg[1])
preamble = ""
body = ""

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

rio_addtype("__core")
rio_addtype("__token")
rio_addtype("__block")
rio_addtype("__procedure")
rio_addtype("__resource")

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

require "core_meta"
require "core_resource"
require "core_structure"

function eval(atom)
  if atom.ty == PARSE_END then
    local fd = assert(io.open(string.sub(arg[1], 1, -4) .. backend, "w"))
    fd:write(preamble)
    fd:write("\n")
    fd:write(body)
    fd:close()
  elseif atom.ty == PARSE_BLOCK then
    local val = { ty=types["__block"], data=atom.data,
      eval = function(self) rio_push(self) end }
    val:eval()
  elseif atom.ty == PARSE_QUOTE then
    local val = { ty=types["__token"], data=atom.data,
      eval = function(self) rio_push(self) end }
    val:eval()
  elseif atom.ty == PARSE_TOKEN then
    rio_getsymbol(atom.data):eval()
  end
end

while filestack.n > 0 do
  eval(nextatom())
end
