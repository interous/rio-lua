function stacktrace()
  print("stack trace goes here")
end

function unterminatedblock(file, line, col)
  print("UNTERMINATED_BLOCK beginning at " .. file .. " " .. line .. ":" .. col)
  os.exit(-1)
end

function unterminatedquote(file, line, col)
  print("UNTERMINATED_QUOTE beginning at " .. file .. " " .. line .. ":" .. col)
  os.exit(-1)
end

function orphanbrace()
  local f = filestack[filestack.n]
  print("ORPHAN_BRACE at " .. f.name .. " " .. f.line .. ":" .. f.col)
  os.exit(-1)
end

function invalidescape(c)
  local f = filestack[filestack.n]
  print("INVALID_ESCAPE " .. c .. " at " .. f.name .. " " .. f.line .. ":" .. f.col)
  os.exit(-1)
end

function invalidpop()
  print("POP_WITH_EMPTY_STACK")
  stacktrace()
  os.exit(-1)
end

function outofstackbounds()
  print("OUT_OF_STACK_BOUNDS")
  stacktrace()
  os.exit(-1)
end

function alreadybound(name)
  print("ALREADY_BOUND " .. name)
  stacktrace()
  os.exit(-1)
end

function notbound(name)
  print("NOT_BOUND " .. name)
  stacktrace()
  os.exit(-1)
end

function wrongtype(name, expected, actual)
  print("WRONG_TYPE " .. name .. " - expected " .. types[expected] .. " got " .. types[actual])
  stacktrace()
  os.exit(-1)
end

function notanumber(val)
  print("NOT_A_NUMBER " .. val)
  stacktrace()
  os.exit(-1)
end
