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

function usererror(message)
  print(message)
  stacktrace()
  os.exit(-1)
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

function orphanbracket()
  local f = filestack[filestack.n]
  print("ORPHAN_CLOSE_COMMENT at " .. f.name .. " " .. f.line .. ":" .. f.col)
  os.exit(-1)
end

function invalidescape(c)
  local f = filestack[filestack.n]
  print("INVALID_ESCAPE " .. c .. " at " .. f.name .. " " .. f.line .. ":" .. f.col)
  os.exit(-1)
end

function duplicatetype(name)
  print("DUPLICATE_TYPE " .. name)
  stacktrace()
  os.exit(-1)
end

function duplicatemakedecision(name)
  print("DUPLICATE_MAKE_DECISION_TYPE " .. name)
  stacktrace()
  os.exit(-1)
end

function invaliddecisionkind(kind)
  print("INVALID_DECISION_KIND " .. kind .. " (must be 'A or 'E)")
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

function notcommtiable(name)
  print("NOT_COMMITABLE " .. name)
  print("commitable requires _" .. name .. "_declare, _" .. name ..
    "_commit, and " .. name .. "->repr")
  stacktrace()
  os.exit(-1)
end

function wrongtype(expected, actual)
  print("WRONG_TYPE expected " .. expected .. " got " .. actual)
  stacktrace()
  os.exit(-1)
end

function expecteddecision(actual)
  print("EXPECTED_DECISION_TYPE got " .. actual)
  stacktrace()
  os.exit(-1)
end

function notatype(name)
  print("NOT_A_TYPE " .. name)
  stacktrace()
  os.exit(-1)
end

function badliteral(s, ty)
  print("BAD_LITERAL " .. s .. " couldn't be parsed as " .. ty)
  stacktrace()
  os.exit(-1)
end

function invalidprefix(name)
  print("INVALID_PREFIX " .. name .. " (must be exactly one character)")
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

function bindingmismatch(n, a, b)
  print("BINDING_MISMATCH " .. n)
  print("  " .. a.ty .. " " .. tostring(a.data))
  print("  " .. b.ty .. " " .. tostring(b.data))
  stacktrace()
  os.exit(-1)
end

function outofquotebounds(n, i)
  print("OUT_OF_QUOTE_BOUNDS " .. n .. " " .. tostring(i))
  stacktrace()
  os.exit(-1)
end

function quotewronglength(q)
  print("QUOTE_WRONG_LENGTH " .. q .. " (must be exactly one character)")
  stacktrace()
  os.exit(-1)
end

function charoutofbounds(c)
  print("CHAR_OUT_OF_BOUNDS " .. tostring(c) .. " (must be between 0 and 255)")
  stacktrace()
  os.exit(-1)
end
