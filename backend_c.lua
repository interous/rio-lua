backend_included = {}
backend_types = {}
backend_types["^int4"] = "int"

function backend_indent(s)
  return "  " .. s
end

function backend_finalize(code)
  return "int main(int __argv, char** __argc) {\n" .. code .. "  return 1;\n}\n"
end

function backend_include(file)
  if not backend_included[file] then
    table.insert(preamble, "#include <" .. file .. ">\n")
    backend_included[file] = true
  end
end

function backend_bind(n, v)
  local sanitized = rio_sanitize(n) .. "_" .. rio_sanitize(types[v.ty])
  local bt = backend_types[types[kinds[v.ty]]]
  return {name=sanitized, code=bt .. " " .. sanitized .. " = " .. v.data .. ";"}
end

function backend_if(c, t, f)
  local i = indent_level[1]
  return i .. "if(" .. c .. ") {\n" .. t .. i .. "} else {\n" .. f .. i .. "}\n"
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
