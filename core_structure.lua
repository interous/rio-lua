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
  
  local startbindings = rio_bindingtablecopy()
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
      wrongtypestr("#b or ^b", rio_peek().ty)
    end
  end end)(blocks)
  
  if bindings then rio_unbindstack(bindings) end
end)

rio_addcore("while", function(self)
  local body = rio_pop(types["__block"])
  local head = rio_pop(types["__block"])
  local outerbody = curbody
  local startstack = rio_stackcopy()
  local startbindings = rio_bindingtablecopy()
  curbody = {}
  rio_invokewithtrace(head.data)
  local condition = rio_pop()
  if condition.ty == types["#b"] then
    table.insert(outerbody, table.concat(curbody, ""))
    curbody = outerbody
    if condition.data then
      rio_invokewithtrace(body.data)
      rio_push(head)
      rio_push(body)
      rio_getsymbol("while"):eval()
    end
  elseif condition.ty == types["^b"] then
    local bindings = rio_makestackbindings()
    local headcode = table.concat(curbody, "")
    rio_bindstack(bindings)
    curbody = {}
    rio_collapsebindings(startbindings)
    stack = rio_stackcopy(startstack)
    local cur_indent = indent_level[1]
    indent_level[1] = backend_indent(indent_level[1])
    rio_invokewithtrace(body.data)
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
    wrongtypestr("#b or ^b", condition.ty)
  end
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
