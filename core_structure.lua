rio_addcore("procedure", function(self)
  local body = rio_pop()
  local name = rio_pop()
  rio_requiretype(body, types["__block"])
  rio_requiretype(name, types["__token"])
  rio_addsymbol(name.data, { ty=types["__procedure"], body=body.data,
    name=name.data, eval = function(self)
      local base_sanitized = rio_sanitize(self.name)
      local sanitized = base_sanitized
      local mangle = 0
      while binding_prefixes[sanitized] do
        sanitized = base_sanitized .. mangle
        mangle = mangle + 1
      end
      binding_prefixes[sanitized] = 0
      local old_prefix = binding_prefix
      binding_prefix = "__" .. sanitized .. "__"
      local i
      for i=1,self.block.n do
        eval(self.block[i])
      end
      binding_prefixes[sanitized] = nil
      binding_prefix = old_prefix
    end })
end)

rio_addcore("finalize", function(self)
  local body = rio_pop()
  rio_requiretype(body, types["__block"])
  rio_flatten(body)
  finalize = table.concat(curbody, "")
  cur_body = {}
end)
