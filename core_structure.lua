rio_addcore("import", function(self)
  local f = rio_pop("__quote").data
  rio_open(f)
end)

rio_addcore("macro", function(self)
  local body = rio_pop("__block").data
  local name = rio_pop("__quote").data
  rio_addsymbol(name, { ty="__macro", body=body,
    name=name, eval = function(self)
      rio_invokeasmacro(self.name, self.body)
    end })
end)

rio_addcore("inline", function(self)
  local body = rio_pop("__block").data
  local name = rio_pop("__quote").data
  rio_addsymbol(name, { ty="__macro", body=body,
    name=name, eval = function(self)
      rio_invokewithtrace(self.body)
    end })
end)

rio_addcore("prefix", function(self)
  local body = rio_pop("__block").data
  local name = rio_pop("__quote").data
  if name:len() ~= 1 then invalidprefix(name) end
  rio_addprefix(name, { ty="__macro", body=body,
    name=name, eval = function(self)
      rio_invokewithtrace(self.body)
    end })
end)

rio_addcore("if", function(self)
  local blocks = newlist()
  while stack.n > 0 and rio_peek().ty == "__block" do
    listpush(blocks, rio_pop("__block").data)
  end
  if blocks.n < 2 then iftooshort(blocks.n) end
  
  local startbindings = rio_bindingtablecopy()
  local bindings = nil
  
  Y(function(f) return function(blocks)
    rio_invokewithtrace(listpop(blocks))
    local condition = rio_pop()
    if not decision_types[condition.ty] then
      expecteddecision(condition.ty)
    elseif decision_types[condition.ty] == "E" then
      if condition.data then
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
    elseif decision_types[condition.ty] == "A" then
      local outerbody = curbody
      curbody = {}
      local declbody = {}
      local cur_indent = indent_level
      indent_level = indent_level .. indent_step
      local startstack = rio_stackcopy()
      rio_collapsebindings(startbindings)
      rio_invokewithtrace(listpop(blocks))
      if not bindings then
        bindings = rio_makestackbindings()
      end
      rio_bindstack(bindings, stack)
      local truestack = rio_stackcopy()
      local truebody = table.concat(curbody, "")
      curbody = {}
      stack = tablecopy(startstack)
      rio_collapsebindings(startbindings)
      if blocks.n == 1 then
        rio_invokewithtrace(listpop(blocks))
        rio_bindstack(bindings, truestack)
      elseif blocks.n > 1 then
        local bound_elsewhere = f(blocks)
        if not bound_elsewhere then
          rio_bindstack(bindings, truestack)
        end
      else
        rio_bindstack(bindings)
      end
      rio_validatestack(truestack, stack)
      local falsebody = table.concat(curbody, "")
      curbody = outerbody
      indent_level = cur_indent
      rio_push(condition)
      rio_push(rio_strtoquote(truebody))
      rio_push(rio_strtoquote(falsebody))
      rio_eval(rio_getsymbol("backend-if"))
      return true
    end
  end end)(blocks)
end)

rio_addcore("while", function(self)
  local body = rio_pop("__block").data
  local head = rio_pop("__block").data
  local outerbody = curbody
  local startstack = rio_stackcopy()
  local startbindings = rio_bindingtablecopy()
  curbody = {}
  rio_invokewithtrace(head)
  local condition = rio_pop()
  if not decision_types[condition.ty] then
    expecteddecision(condition.ty)
  elseif decision_types[condition.ty] == "E" then
    table.insert(outerbody, table.concat(curbody, ""))
    curbody = outerbody
    if condition.data then
      rio_invokewithtrace(body)
      rio_push(rio_listtoblock(head))
      rio_push(rio_listtoblock(body))
      rio_deletenewbindings(startbindings)
      rio_getsymbol("while"):eval()
    end
  elseif decision_types[condition.ty] == "A" then
    local bindings = rio_makestackbindings()
    local headcode = table.concat(curbody, "")
    rio_bindstack(bindings)
    curbody = {}
    rio_collapsebindings(startbindings)
    stack = rio_stackcopy(startstack)
    local cur_indent = indent_level[1]
    indent_level[1] = backend_indent(indent_level[1])
    rio_invokewithtrace(body)
    indent_level[1] = cur_indent
    rio_bindstack(bindings)
    rio_collapsebindings(startbindings)
    local bodycode = table.concat(curbody, "")
    stack = rio_stackcopy(startstack)
    curbody = outerbody
    for i = 1, bindings.n do
      decl = backend_declare(binding_prefix, bindings[i].name, bindings[i].val)
      table.insert(curbody, cur_indent .. decl.code .. "\n")
    end
    table.insert(curbody, backend_while(headcode, condition.data, bodycode))
  end
end)

rio_addcore("finalize", function(self)
  local body = rio_pop("__block").data
  indent_level = indent_step
  local old_prefix = binding_prefix
  binding_prefix = "__finalize__"
  rio_invokewithtrace(body)
  binding_prefix = old_prefix
  finalize_decls = table.concat(curdecls, "")
  finalize_body = table.concat(curbody, "")
  curdecls = {}
  curbody = {}
  backend_purgescope()
end)
