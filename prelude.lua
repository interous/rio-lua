rio_push({ ty=types["__quote"], data="#idx" })
rio_push({ ty=types["__quote"], data="#float8" })
rio_getsymbol("type"):eval()

rio_push({ ty=types["__quote"], data="++" })
rio_push({ ty=types["#idx"], data=2 })
rio_getsymbol("poly"):eval()

rio_push({ ty=types["__quote"], data="=" })
rio_push({ ty=types["#idx"], data=2 })
rio_getsymbol("poly"):eval()
