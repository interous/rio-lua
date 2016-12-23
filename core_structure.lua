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
      binding_prefix = "__" .. sanitized .. "__"
      rio_invokewithtrace(self.body)
      binding_prefixes[sanitized] = nil
      binding_prefix = old_prefix
    end })
end)

rio_addcore("if", function(self)
  local blocks = newlist()
  while stack.n > 0 and rio_peek().ty == types["__block"] do
    listpush(blocks, rio_pop(types["__block"]).data)
  end
  if blocks.n < 2 then iftooshort(blocks.n) end
  
  Y(function(f) return function(b)
    rio_flatten(listpop(b))
    if rio_peek().ty == types["#b"] then
      if rio_pop(types["#b"]).data then
        rio_flatten(listpop(b))
      else
        listpop(b)
        if b.n == 1 then
          rio_flatten(listpop(b))
        elseif b.n > 1 then
          f(b)
        end
      end
    elseif rio_peek().ty == types["^b"] then
      local conditionvar = rio_pop(types["^b"]).data
      local outerbody = curbody
      curbody = {}
      local startstack = rio_stackcopy()
      rio_flatten(listpop(b))
      local truebody = table.concat(curbody, "")
      local truestack = rio_stackcopy()
      curbody = {}
      stack = startstack
      local falsestack
      if b.n == 1 then
        rio_flatten(listpop(b))
        falsestack = rio_stackcopy()
      elseif b.n > 1 then
        f(b)
        falsestack = rio_stackcopy()
      else
        falsestack = startstack
      end
      rio_stackeq(truestack, falsestack)
      local falsebody = table.concat(curbody, "")
      curbody = outerbody
      table.insert(curbody, backend_if(conditionvar, truebody, falsebody))
    else
      wrongtypestr("#b or ^b", rio_peek().ty)
    end
  end end)(blocks)
end)

rio_addcore("finalize", function(self)
  local body = rio_pop(types["__block"]).data
  rio_flatten(body)
  finalize = table.concat(curbody, "")
  cur_body = {}
end)
