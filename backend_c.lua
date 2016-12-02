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
