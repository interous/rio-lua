rio_push(rio_strtoquote("#idx"))
rio_push(rio_strtoquote"#float8"))
rio_getsymbol("unit"):eval()

rio_push(rio_strtoquote("#arity"))
rio_push(rio_strtoquote("#float8"))
rio_getsymbol("unit"):eval()

rio_push(rio_strtoquote("#b"))
rio_push(rio_strtoquote("#binary"))
rio_getsymbol("unit"):eval()

function prelude_addpoly(s, a)
  rio_push(rio_strtoquote(s))
  rio_push({ ty=types["#arity"], data=a })
  rio_getsymbol("poly"):eval()
end

prelude_addpoly("++", 2)
prelude_addpoly("=", 2)
prelude_addpoly("<", 2)
prelude_addpoly("+", 2)
prelude_addpoly("-", 2)
prelude_addpoly("*", 2)
