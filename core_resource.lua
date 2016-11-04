rio_addcore("resource", function(self)
  local name = rio_pop()
  rio_requiretype(name, types["__token"])
  rio_addsymbol(name.data, { ty=types["__resource"], name=name.data,
    eval = function(self) rio_push(self) end })
end)
