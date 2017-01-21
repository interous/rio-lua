rio_addcore("singleton", function(self)
  local name = rio_pop("__quote").data
  rio_addsymbol(name, { ty="__resource", name=name,
    eval = function(self) rio_push(self) end })
end)

rio_addcore("write", function(self)
  local body = rio_pop("__block").data
  local resource = rio_pop("__quote").data
  local name = rio_pop("__quote").data
  rio_addsymbol(name, { ty="__resource-write",
    resource=resource, name=name, body=body,
    eval = function(self)
      rio_invokeasmacro(self.name, self.body)
    end })
end)
