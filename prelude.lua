rio_push({ ty=types["__quote"], data="#idx" })
rio_push({ ty=types["__quote"], data="#float8" })
rio_getsymbol("unit"):eval()

rio_push({ ty=types["__quote"], data="#arity" })
rio_push({ ty=types["__quote"], data="#float8" })
rio_getsymbol("unit"):eval()

function prelude_addpoly(s, a)
  rio_push({ ty=types["__quote"], data=s })
  rio_push({ ty=types["#arity"], data=a })
  rio_getsymbol("poly"):eval()
end

prelude_addpoly("++", 2)
prelude_addpoly("=", 2)
prelude_addpoly("+", 2)
prelude_addpoly("*", 2)
