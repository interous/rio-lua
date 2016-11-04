PARSE_BLOCK = 0
PARSE_QUOTE = 1
PARSE_TOKEN = 2
PARSE_END = 3

function curchar()
  local f = filestack[filestack.n]
  return string.sub(f.data, f.pos, f.pos)
end

function nextchar()
  local f = filestack[filestack.n]
  if curchar() == "\n" then
    f.line = f.line + 1
    f.col = 1
  else
    f.col = f.col + 1
  end
  f.pos = f.pos + 1
  return curchar()
end

function nextatom()
  local f = filestack[filestack.n]
  local c = curchar()
  while c == " " or c == "\n" or c == "\t" do
    c = nextchar()
  end
  if c == "" then
    rio_close()
    if filestack.n == 0 then
      return { data=nil, ty=PARSE_END }
    else
      return nextatom()
    end
  end
  
  if c == "{" then
    local block = { n=0 }
    local startfile = f.name
    local startline = f.line
    local startcol = f.col
    nextchar()
    while curchar() ~= "}" do
      block.n = block.n + 1
      block[block.n] = nextatom()
      c = curchar()
      while c == " " or c == "\n" or c == "\t" do
        c = nextchar()
      end
      if c == "" then
        unterminatedblock(startfile, startline, startcol)
      end
    end
    nextchar()
    return { data=block, ty=PARSE_BLOCK }
  elseif c == "}" then
    orphanbrace()
  elseif c == "'" or c == "." or c == "-" or tonumber(c) then
    local quote = ""
    if c == "'" then c = nextchar() end
    while c ~= " " and c ~= "\n" and c ~= "\t" and c ~= "{" and c ~= "}" do
      quote = quote .. c
      c = nextchar()
    end
    return { data=quote, ty=PARSE_QUOTE }
  elseif c == "\"" then
    local quote = ""
    local startfile = f.name
    local startline = f.line
    local startcol = f.col
    c = nextchar()
    while c ~= "\"" do
      if c == "\\" then
        c = nextchar()
        if c == "\"" then quote = quote .. "\""
        elseif c == "n" then quote = quote .. "\n"
        elseif c == "t" then quote = quote .. "\t"
        elseif c == "\\" then quote = quote .. "\\"
        else invalidescape(c)
        end
        c = nextchar()
      elseif c == "" then
        unterminatedquote(startfile, startline, startcol)
      else
        quote = quote .. c
        c = nextchar()
      end
    end
    nextchar()
    return { data=quote, ty=PARSE_QUOTE }
  else
    local token = ""
    while c ~= " " and c ~= "\n" and c ~= "\t" and c ~= "{" and c ~= "}" do
      token = token .. c
      c = nextchar()
    end
    return { data=token, ty=PARSE_TOKEN }
  end
end
