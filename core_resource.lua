rio_addcore("resource", function(self)
  local name = rio_pop()
  rio_requiretype(name, types["__token"])
  rio_addsymbol(name.data, { ty=types["__resource"], name=name.data,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("write", function(self)
  local body = rio_pop()
  local resource = rio_pop()
  local name = rio_pop()
  rio_requiretype(body, types["__block"])
  rio_requiretype(resource, types["__token"])
  rio_requiretype(name, types["__token"])
  rio_addsymbol(name.data, { ty=types["__resource-write"],
    resource=resource.data, name=name.data, body=body,
    eval = function(self)
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
      rio_flatten(self.body)
      binding_prefixes[sanitized] = nil
      binding_prefix = old_prefix
    end })
end)
