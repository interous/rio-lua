local os = require "os"
local io = require "io"
require "parse"

if not arg[1] then
  print("error: no input file");
  os.exit(-1);
end

function rio_open(name)
  filestack.n = filestack.n + 1;
  local fd = assert(io.open(name, "r"));
  filestack[filestack.n] = {
    name = name,
    data = fd:read("*a"),
    line = 1,
    col = 1,
    pos = 1
  }
  io.close(fd);
end

function rio_close()
  filestack[filestack.n] = nil;
  filestack.n = filestack.n - 1;
end

filestack = { n=0 };
rio_open(arg[1]);

local indent = "";

function print_atom(atom, indent)
  if atom.ty == PARSE_TOKEN then
    print(indent .. atom.data);
  elseif atom.ty == PARSE_QUOTE then
    print(indent .. "QUOTE: " .. atom.data);
  elseif atom.ty == PARSE_BLOCK then
    local i = 1;
    while atom.data[i] do
      print_atom(atom.data[i], indent .. "  ");
      i = i + 1;
    end
  else
    print("end of file");
  end
end

local atom = nextatom();
while atom.data do
  print_atom(atom, "");
  atom = nextatom();
end
