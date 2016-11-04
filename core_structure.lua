rio_addcore("procedure", function(self)
  local body = rio_pop()
  local name = rio_pop()
  rio_requiretype(body, types["__block"])
  rio_requiretype(name, types["__token"])
  rio_addsymbol(name.data, { ty=types["__procedure"], body=body.data,
    name=name.data, eval = function(self)
      local old_prefix = binding_prefix
      if binding_prefix == "" then binding_prefix = "_" end
      binding_prefix = binding_prefix .. self.name .. "_"
      local i
      for i=1,self.block.n do
        eval(self.block[i])
      end
      binding_prefix = old_prefix
    end })
end)
