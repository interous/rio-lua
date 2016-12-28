rio_addcore("import", function(self)
  local f = rio_pop(types["__quote"]).data
  rio_open(f)
end)

rio_addcore("procedure", function(self)
  local body = rio_pop(types["__block"])
  local name = rio_pop(types["__quote"])
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

rio_addcore("prefix", function(self)
  local body = rio_pop(types["__block"]).data
  local name = rio_pop(types["__quote"]).data
  if name:len() ~= 1 then invalidprefix(name) end
  rio_addprefix(name, { ty=types["__procedure"], body=body,
    name=name, eval = function(self)
      rio_invokewithtrace(self.body)
    end })
end)

rio_addcore("if", function(self)
  local blocks = newlist()
  while stack.n > 0 and rio_peek().ty == types["__block"] do
    listpush(blocks, rio_pop(types["__block"]).data)
  end
  if blocks.n < 2 then iftooshort(blocks.n) end
  
  local old_bindingtable = rio_bindingtablecopy()
  local bindings = nil
  
  Y(function(f) return function(blocks)
    rio_invokewithtrace(listpop(blocks))
    if rio_peek().ty == types["#b"] then
      if rio_pop(types["#b"]).data then
        rio_invokewithtrace(listpop(blocks))
      else
        listpop(blocks)
        if blocks.n == 1 then
          rio_invokewithtrace(listpop(blocks))
        elseif blocks.n > 1 then
          return f(blocks)
        end
      end
      return false
    elseif rio_peek().ty == types["^b"] then
      local conditionvar = rio_pop(types["^b"]).data
      local outerbody = curbody
      curbody = {}
      local declbody = {}
      local cur_indent = indent_level[1]
      indent_level[1] = backend_indent(indent_level[1])
      local startstack = rio_stackcopy()
      bindingtable = rio_bindingtablecopy(old_bindingtable)
      rio_invokewithtrace(listpop(blocks))
      local truestack = rio_stackcopy()
      if not bindings then
        bindings = rio_makestackbindings()
        for i = 1, bindings.n do
          decl = backend_declare(binding_prefix, bindings[i].name, bindings[i].val)
          table.insert(declbody, cur_indent .. decl.code .. "\n")
        end
      end
      rio_bindstack(bindings)
      local truebody = table.concat(curbody, "")
      curbody = {}
      stack = startstack
      bindingtable = rio_bindingtablecopy(old_bindingtable)
      local falsestack
      if blocks.n == 1 then
        rio_invokewithtrace(listpop(blocks))
        falsestack = rio_stackcopy()
        rio_bindstack(bindings)
      elseif blocks.n > 1 then
        local bound_elsewhere = f(blocks)
        falsestack = rio_stackcopy()
        if not bound_elsewhere then rio_bindstack(bindings) end
      else
        falsestack = startstack
        stack = startstack
        rio_bindstack(bindings)
      end
      --rio_stackeq(truestack, falsestack)
      local falsebody = table.concat(curbody, "")
      curbody = outerbody
      indent_level[1] = cur_indent
      table.insert(curbody, table.concat(declbody, ""))
      table.insert(curbody, backend_if(conditionvar, truebody, falsebody))
      return true
    else
      wrongtypestr("#b or ^b", rio_peek().ty)
    end
  end end)(blocks)
  
  if bindings then rio_unbindstack(bindings) end
end)

rio_addcore("finalize", function(self)
  local body = rio_pop(types["__block"]).data
  indent_level[1] = "  "
  local old_prefix = binding_prefix
  binding_prefix = "__finalize__"
  rio_invokewithtrace(body)
  binding_prefix = old_prefix
  finalize = table.concat(curbody, "")
  cur_body = {}
  backend_purgescope()
end)
