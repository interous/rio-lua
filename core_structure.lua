rio_addcore("import", function(self)
  local f = rio_pop("__quote").data
  rio_open(f)
end)

rio_addcore("macro", function(self)
  local body = rio_pop("__block").data
  local name = rio_pop("__quote").data
  rio_addsymbol(name, { ty="__macro", body=body, mut=true,
    name=name, eval = function(self)
      rio_invokeasmacro(self.name, self.body)
    end })
end)

rio_addcore("inline", function(self)
  local body = rio_pop("__block").data
  local name = rio_pop("__quote").data
  rio_addsymbol(name, { ty="__macro", body=body, mut=true,
    name=name, eval = function(self)
      rio_invokewithtrace(self.body)
    end })
end)

rio_addcore("prefix", function(self)
  local body = rio_pop("__block").data
  local name = rio_pop("__quote").data
  if name:len() ~= 1 then invalidprefix(name) end
  if name == '*' then reservedprefix(name) end
  rio_addprefix(name, { ty="__macro", body=body, mut=true,
    name=name, eval = function(self)
      rio_invokewithtrace(self.body)
    end })
end)

rio_addcore("if", function(self)
  local blocks = newlist()
  while stack.n > 0 and rio_peek().ty == "__block" do
    listpush(blocks, rio_pop("__block").data)
  end
  if stack.n > 0 and rio_peek().ty == "__quote" and rio_peek().data == "__fi" then
    rio_pop()
  end
  if blocks.n < 2 then iftooshort(blocks.n) end

  --[[
    This may seem a bit obtuse, but the idea is that we should only
    snapshot the program state at the start of the first A-kind branch.
  ]]--
  local startbindings = nil
  local bindings = nil
  local startstack = nil

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
      if not startstack then startstack = rio_stackcopy() end
      if not startbindings then startbindings = rio_bindingtablecopy() end
      rio_invokewithtrace(listpop(blocks))
      rio_commitstack()
      rio_collapsebindings(startbindings)
      local truestack = rio_stackcopy()
      stack = tablecopy(startstack)
      local truebody = table.concat(curbody, "")
      curbody = {}
      if blocks.n == 1 then
        rio_invokewithtrace(listpop(blocks))
        rio_commitstack()
        rio_validatestack(truestack)
      elseif blocks.n > 1 then
        local bound_elsewhere = f(blocks)
        if not bound_elsewhere then
          rio_commitstack()
          rio_validatestack(truestack)
        end
      else
        rio_commitstack()
        rio_validatestack(truestack)
      end
      rio_collapsebindings(startbindings)
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
    local headcode = table.concat(curbody, "")
    rio_commitstack()
    rio_validatestack(startstack)
    curbody = {}
    rio_collapsebindings(startbindings)
    stack = rio_stackcopy(startstack)
    local cur_indent = indent_level
    indent_level = indent_level .. indent_step
    rio_invokewithtrace(body)
    indent_level = cur_indent
    rio_commitstack()
    rio_validatestack(startstack)
    rio_collapsebindings(startbindings)
    local bodycode = table.concat(curbody, "")
    curbody = outerbody
    rio_push(rio_strtoquote(headcode))
    rio_push(condition)
    rio_push(rio_strtoquote(bodycode))
    rio_eval(rio_getsymbol("backend-while"))
  end
end)

rio_addcore("finalize", function(self)
  local body = rio_pop("__block").data
  indent_level = indent_step
  local old_prefix = binding_prefix
  binding_prefix = "__finalize__"
  if not toplevel then mustbetoplevel() end
  toplevel = false
  rio_invokewithtrace(body)
  toplevel = true
  binding_prefix = old_prefix
  finalize_decls = table.concat(curdecls, "")
  finalize_body = table.concat(curbody, "")
  curdecls = {}
  curbody = {}
end)
