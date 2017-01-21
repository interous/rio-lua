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
    if not reprs[rio_peek().ty] then
      wrongkind("#val or ^val", rio_peek().ty)
    elseif reprs[rio_peek().ty] == "#binary" then
      if rio_pop().data then
        rio_invokewithtrace(listpop(blocks))
      else
        listpop(blocks)
        if blocks.n == 1 then
          rio_invokewithtrace(listpop(blocks))
        elseif blocks.n > 1 then
          f(blocks)
        end
      end
      return false
    elseif reprs[rio_peek().ty] == "^binary" then
      local conditionvar = rio_pop().data
      local outerbody = curbody
      curbody = {}
      local declbody = {}
      local cur_indent = indent_level[1]
      indent_level[1] = backend_indent(indent_level[1])
      local startstack = rio_stackcopy()
      rio_collapsebindings(startbindings)
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
      rio_collapsebindings(startbindings)
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
      local falsebody = table.concat(curbody, "")
      curbody = outerbody
      indent_level[1] = cur_indent
      table.insert(curbody, table.concat(declbody, ""))
      table.insert(curbody, backend_if(conditionvar, truebody, falsebody))
      return true
    else
      wrongrepr("#binary or ^binary", reprs[rio_peek().ty])
    end
  end end)(blocks)
  
  if bindings then rio_unbindstack(bindings) end
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
  if not reprs[condition.ty] then
    wrongkind("#val or ^val", condition.ty)
  elseif reprs[condition.ty] == "#binary" then
    table.insert(outerbody, table.concat(curbody, ""))
    curbody = outerbody
    if condition.data then
      rio_invokewithtrace(body)
      rio_push(rio_listtoblock(head))
      rio_push(rio_listtoblock(body))
      rio_deletenewbindings(startbindings)
      rio_getsymbol("while"):eval()
    end
  elseif reprs[condition.ty] == "^binary" then
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
  else
    wrongtype("#binary or ^binary", condition.ty)
  end
end)

rio_addcore("finalize", function(self)
  local body = rio_pop("__block").data
  indent_level[1] = "  "
  local old_prefix = binding_prefix
  binding_prefix = "__finalize__"
  rio_invokewithtrace(body)
  binding_prefix = old_prefix
  finalize = table.concat(curbody, "")
  cur_body = {}
  backend_purgescope()
end)
