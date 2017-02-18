rio_addcore("commit", function(self)
  local name = rio_pop("__quote").data
  local datum = rio_pop()
  rio_commit(name, datum)
end)

rio_addcore("bind", function(self)
  local name = rio_pop("__quote").data
  local datum = rio_pop()
  rio_addbinding(name, datum)
end)

rio_addcore("delete", function(self)
  rio_deletebinding(rio_pop("__quote").data)
end)

rio_addcore("raw-delete", function(self)
  rio_deletebinding(rio_pop("__quote").data, false, true)
end)
