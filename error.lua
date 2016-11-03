function unterminatedblock(file, line, col)
  print("UNTERMINATED BLOCK beginning at " .. file .. " " .. line .. ":" .. col);
  os.exit(-1);
end

function orphanbrace()
  local f = filestack[filestack.n];
  print("ORPHAN BRACE at " .. f.name .. " " .. f.line .. ":" .. f.col);
  os.exit(-1);
end

function invalidescape(c)
  local f = filestack[filestack.n];
  print("INVALID ESCAPE " .. c .. " at " .. f.name .. " " .. f.line .. ":" .. f.col);
  os.exit(-1);
end
