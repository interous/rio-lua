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
  while blocks.n > 0 do
    rio_flatten(listpop(blocks))
    if rio_peek().ty == types["#b"] then
      if rio_pop(types["#b"]).data then
        rio_flatten(listpop(blocks))
        break
      else
        listpop(blocks)
        if blocks.n == 0 then break
        elseif blocks.n == 1 then
          rio_flatten(listpop(blocks))
          break
        end
      end
    else if rio_peek().ty == types["^b"] then
      -- hmmmmmmmmmmmmmmmmmmmmmmmmmmmm
    else
      wrongtypestr("#b or ^b", rio_peek().ty)
    end
  end
  curbody = outerbody
  if codestack.n <= 1 then
    table.insert(curbody, table.concat(codestack, ""))
  end
end)

rio_addcore("finalize", function(self)
  local body = rio_pop(types["__block"]).data
  rio_flatten(body)
  finalize = table.concat(curbody, "")
  cur_body = {}
end)
