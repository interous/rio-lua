rio_addcore("singleton", function(self)
  local name = rio_pop(types["__quote"])
  rio_addsymbol(name.data, { ty=types["__resource"], name=name.data,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("write", function(self)
  local body = rio_pop(types["__block"])
  local resource = rio_pop(types["__quote"])
  local name = rio_pop(types["__quote"])
  rio_addsymbol(name.data, { ty=types["__resource-write"],
    resource=resource.data, name=name.data, body=body.data,
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
      binding_prefix = "__" .. sanitized .. binding_prefix
      local old_bindingtable = rio_bindingtablecopy()
      rio_invokewithtrace(self.body)
      local merged_bindingtable = {}
      for k, v in pairs(old_bindingtable) do
        if bindingtable[k] then merged_bindingtable[k] = bindingtable[k] end
      end
      bindingtable = merged_bindingtable
      binding_prefixes[sanitized] = nil
      binding_prefix = old_prefix
    end })
end)
