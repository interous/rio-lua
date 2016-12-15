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

function reservednoeval(name)
  print("RESERVED_NO_EVAL " .. name)
  stacktrace()
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

function wrongtype(expected, actual)
  print("WRONG_TYPE expected " .. types[expected].ty .. " got " .. types[actual].ty)
  stacktrace()
  os.exit(-1)
end

function wrongkind(expected, actual)
  print("WRONG_KIND expected " .. types[expected].ty .. " got " .. types[actual].ty)
  stacktrace()
  os.exit(-1)
end

function notatype(name)
  print("NOT_A_TYPE " .. name)
  stacktrace()
  os.exit(-1)
end

function badliteral(s, outer, inner)
  print("BAD_LITERAL " .. s .. " couldn't be parsed as " .. outer .. " (i.e., " .. inner .. ")")
  stacktrace()
  os.exit(-1)
end

function iftooshort(n)
  print("IF_TOO_SHORT need at least 2 blocks, found " .. tostring(n))
  stacktrace()
  os.exit(-1)
end
