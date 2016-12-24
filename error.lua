rio_errorbase = { symbol="(init)", file="core", line=0, col=0 }
rio_errorstack = { n=0 }

function stacktrace()
  print("stack trace:")
  print("  " .. rio_errorbase.symbol .. " at " .. rio_errorbase.file ..
    " " .. rio_errorbase.line .. ":" .. rio_errorbase.col)
  local i
  for i=rio_errorstack.n,1,-1 do
    print("  " .. rio_errorstack[i].symbol .. " at " ..
      rio_errorstack[i].file .. " " .. rio_errorstack[i].line .. ":" ..
      rio_errorstack[i].col)
  end
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
  print("WRONG_TYPE expected " .. types[expected] .. " got " .. types[actual])
  stacktrace()
  os.exit(-1)
end

function wrongtypestr(expected, actual)
  rio_printstack(stack)
  print("WRONG_TYPE expected " .. expected .. " got " .. types[actual])
  stacktrace()
  os.exit(-1)
end

function wrongkind(expected, actual)
  print("WRONG_KIND expected " .. types[expected] .. " got " .. types[actual])
  stacktrace()
  os.exit(-1)
end

function kindmismatch(a, b)
  print("KIND_MISMATCH " .. types[a] .. " " .. types[b])
  stacktrace()
  os.exit(-1)
end

function notatype(name)
  print("NOT_A_TYPE " .. name)
  stacktrace()
  os.exit(-1)
end

function nonnumerickind(name)
  print("NON_NUMERIC_KIND " .. types[name])
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

function stackmismatch(a, b)
  print("STACK_MISMATCH")
  print("first stack:")
  rio_printstack(a)
  print("second stack:")
  rio_printstack(b)
  print("")
  stacktrace()
  os.exit(-1)
end
