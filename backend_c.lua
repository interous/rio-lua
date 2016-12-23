backend_included = {}

function backend_finalize(code)
  return "int main(int __argv, char** __argc) {\n" .. code .. "  return 1;\n}\n"
end

function backend_include(file)
  if not backend_included[file] then
    table.insert(preamble, "#include <" .. file .. ">\n")
    backend_included[file] = true
  end
end

function backend_if(c, t, f)
  return "  if(" .. c .. ") {\n" .. t .. "  } else {\n" .. f .. "  }\n"
end

function backend_int4(s)
  return tostring(s)
end

function backend_int4_plus(a, b)
  return "(" .. a .. " + " .. b .. ")"
end

function backend_int4_times(a, b)
  return "(" .. a .. " * " .. b .. ")"
end

function backend_int4_equal(a, b)
  return "(" .. a .. " == " .. b .. ")"
end

function backend_binary(s)
  if s then return "1" else return "0" end
end
