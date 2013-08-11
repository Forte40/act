-- movement tracking -----------------------------------------------------------

local coord_change = {[0] = { 0,  1}, -- south / forward
                      [1] = {-1,  0}, -- west  / right
                      [2] = { 0, -1}, -- north / behind
                      [3] = { 1,  0}} -- east  / left
-- check if API already loaded
if turtle and not turtle.act then
  -- replace turtle functions
  turtle.act = true

  -- track relative direction and coordinates
  turtle.x = 0
  turtle.y = 0
  turtle.z = 0
  turtle.facing = 0
  turtle.selected = 0
  -- waypoints
  turtle.waypoint = {}
  -- how much to change x and z when moving in a direction                      

  -- helper functions
  turtle.setCoords = function (x, y, z, facing)
    turtle.x = x or 0
    turtle.y = y or 0
    turtle.z = z or 0
    turtle.facing = facing or 0
  end

  turtle.gps = function (getFacing)
    local x, y, z = gps.locate()
    if x ~= nil then
      turtle.x = x
      turtle.y = y
      turtle.z = z
      if getFacing then
          turtle.forward()
          local dx, dy, dz = gps.locate()
          if dx ~= nil then
            if x == dx then
              if z < dz then
                turtle.facing = 0
              else
                turtle.facing = 2
              end
            else
              if x < dx then
                turtle.facing = 3
              else
                turtle.facing = 1
              end
            end
          end
          turtle.back()
        end
      return true
    else
      return false
    end
  end

  turtle.face = function (facing)
    local new_facing = (facing - turtle.facing) % 4
    if new_facing == 1 then
        turtle.turnRight()
    elseif new_facing == 2 then
        turtle.turnRight()
        turtle.turnRight()
    elseif new_facing == 3 then
        turtle.turnLeft()
    end
  end

  -- replace movement functions
  turtle._turnLeft = turtle.turnLeft
  turtle.turnLeft = function ()
    if turtle._turnLeft() then
      turtle.facing = (turtle.facing - 1) % 4
      return true
    else
      return false
    end
  end

  turtle._turnRight = turtle.turnRight
  turtle.turnRight = function ()
    if turtle._turnRight() then
      turtle.facing = (turtle.facing + 1) % 4
      return true
    else
      return false
    end
  end

  turtle._forward = turtle.forward
  turtle.forward = function ()
    if turtle._forward() then
      turtle.x = turtle.x + coord_change[turtle.facing][1]
      turtle.z = turtle.z + coord_change[turtle.facing][2]
      return true
    else
      return false
    end
  end

  turtle._back = turtle.back
  turtle.back = function ()
    if turtle._back() then
      turtle.x = turtle.x - coord_change[turtle.facing][1]
      turtle.z = turtle.z - coord_change[turtle.facing][2]
      return true
    else
      return false
    end
  end

  turtle._up = turtle.up
  turtle.up = function ()
    if turtle._up() then
      turtle.y = turtle.y + 1
      return true
    else
      return false
    end
  end

  turtle._down = turtle.down
  turtle.down = function ()
    if turtle._down() then
      turtle.y = turtle.y - 1
      return true
    else
      return false
    end
  end

  turtle._select = turtle.select
  turtle.select = function (slot)
    if turtle._select(slot) then
      turtle.selected = slot
    end
  end
end

-- convenience functions for building a language -------------------------------

local function nopprocess(ast)
  return ast
end

local function L(rule, process) -- literial
  local r = {rule}
  r.type = "l"
  r.process = process or nopprocess
  return r
end

local function Z(rule, process) -- zero or more
  local r = {rule}
  r.type = "*"
  r.process = process or nopprocess
  return r
end

local function O(rule, process) -- one or more
  local r = {rule}
  r.type = "+"
  r.process = process or nopprocess
  return r
end

local function C(...) -- ordered choice
  if type(arg[#arg]) == "function" then
    arg.process = table.remove(arg)
  else
    arg.process = nopprocess
  end
  arg.type = "/"
  return arg
end

local function S(...) -- sequence
  if type(arg[#arg]) == "function" then
    arg.process = table.remove(arg)
  else
    arg.process = nopprocess
  end
  arg.type = " "
  return arg
end

local function M(rule, process) -- optional (maybe)
  local r = {rule}
  r.type = "?"
  r.process = process or nopprocess
  return r
end

local function N(rule, process) -- not predicate
  local r = {rule}
  r.type = "*"
  r.process = process or nopprocess
  return r
end

local function A(rule, process) -- not predicate
  local r = {rule}
  r.type = "*"
  r.process = process or nopprocess
  return r
end

local function P(process) -- process
  if type(process) == "table" then
    if #process == 0 then
      return function(ast)
        local rast = {}
        for k, v in pairs(process) do
          if type(v) == "number" then
            rast[k] = ast[v]
          else
            rast[k] = v
          end
        end
        return rast
      end
    elseif #process == 1 then
      return function(ast)
        return ast[process[1]]
      end
    elseif type(process) == "table" then
      return function(ast)
        local rast = {}
        for i, v in ipairs(process) do
          if type(v) == "number" then
            rast[i] = ast[v]
          else
            rast[i] = v
          end
        end
        return rast
      end
    end
  elseif type(process) == "function" then
    return function(ast)
      ast = process(ast)
      local rast = ""
      for i, v in ipairs(ast) do
        rast = rast .. tostring(v)
      end
      return rast
    end
  else
    return function(ast)
      local rast = ""
      for i, v in ipairs(ast) do
        rast = rast .. tostring(v)
      end
      return rast
    end
  end
end

local function I(rule, rules) -- help for circular reference
  for k, v in pairs(rules) do
    rule[k] = v
  end
end

-- recursive decent parser -----------------------------------------------------

local function match(rules, src, pos)
  local ast, rast, newpos, start, stop
  if type(rules) == "table" then
    if rules.type == "l" then -- literal
      start, stop = src:find("^"..rules[1], pos)
      if stop then
        return stop + 1, rules.process(src:sub(start, stop)), stop + 1
      else
        return nil, nil, pos
      end
    elseif rules.type == " " then -- sequence
      rast = {}
      newpos = pos
      for i, rule in ipairs(rules) do
        newpos, ast = match(rule, src, newpos)
        if newpos == nil then
          return nil, nil, pos
        end
        rast[i] = ast
      end
      return newpos, rules.process(rast), newpos
    elseif rules.type == "/" then -- ordered choice
      for i, rule in ipairs(rules) do
        newpos, ast = match(rule, src, pos)
        if newpos then
          return newpos, rules.process(ast), newpos
        end
      end
      return nil, nil, pos
    elseif rules.type == "*" then -- zero or more
      rast = {}
      newpos, ast = match(rules[1], src, pos)
      while newpos do
        pos = newpos
        table.insert(rast, ast)
        newpos, ast = match(rules[1], src, pos)
      end
      return pos, rules.process(rast), pos
    elseif rules.type == "+" then -- one or more
      rast = {}
      newpos, ast = match(rules[1], src, pos)
      if newpos == nil then
        return nil, nil, pos
      end
      while newpos do
        pos = newpos
        table.insert(rast, ast)
        newpos, ast = match(rules[1], src, pos)
      end
      return pos, rules.process(rast), pos
    elseif rules.type == "?" then -- optional
      newpos, ast = match(rules[1], src, pos)
      if newpos then
        return newpos, rules.process(ast), newpos
      else
        return pos, nil, pos
      end
    elseif rules.type == "&" then -- and predicate
      if match(rules[1], src, pos) then
        return pos, nil, pos
      else
        return nil, nil, pos
      end
    elseif rules.type == "!" then -- not predicate
      if match(rules[1], src, pos) then
        return nil, nil, pos
      else
        return pos, nil, pos
      end
    end
  else -- literal, no processing
    start, stop = src:find("^"..rules, pos)
    if stop then
      return stop + 1, src:sub(start, stop), stop + 1
    else
      return nil, nil, pos
    end
  end
end

-- language for striping spaces and comments, the pre-processor ----------------

local pre = {}
pre.comment = S("%-%-[^\r\n]*[\r\n]*")
pre.space = C("[ \r\n]+", pre.comment)
pre.line = S(Z(pre.space), "[^ \r\n]+", Z(pre.space), P({2}))
pre.source = O(pre.line, P())

-- act language ----------------------------------------------------------------

local lang = {}
lang.float = L("%-?%d+%.%d+", function (ast)    return tonumber(ast) end)
lang.int = L("%-?%d+", function (ast)   return tonumber(ast) end)
lang.token = L("[%u%l%d_]+")
lang.numvar = S("#", "[%u%l]", P({vartype="num", name=2}))
lang.boolvar = S("%$", "[%u%l]", P({vartype="bool", name=2}))
lang.worker = S(lang.token, ":", P({1}))
lang.number = C("%*", lang.float, lang.int, lang.numvar)
lang.variable = S("=", C(lang.numvar, lang.boolvar), P({2}))
lang.predicate = L("[%?~]")
lang.locationaction = C(
  S("G<", lang.int, ",", lang.int, ",", lang.int, M(S(",", lang.int, P({2}))), ">", P({waypointtype="G", x=2, y=4, z=6, facing=7})),
  S("[Gw]", "<", lang.token, ">", P({waypointtype=1, waypoint=3}))
)
lang.param2action = S("t", lang.int, ",", lang.int, P({action=1, param1=2, param2=4})) 
lang.paramaction = S(C("[cegostz]", "[E][fud]"), lang.number, P({action=1, param=2}))
lang.simpleaction = C("[fblrudq]", "[ABCDGHMPS][fud]", "Gb", "I[csf]")
lang.extension = S("%%", lang.token, Z(S(",", lang.token, P({2}))), "%%", P({extension=2, params=3}))
lang.action = {}
lang.joiner = S("/", O(lang.action))
lang.plan = S(M(lang.worker), O(lang.action), M(lang.joiner),
  function (ast)
    local rast = {actions=ast[2], plantype="seq"}
    if ast[1] then rast.worker = ast[1] end
    if ast[3] then rast.join = ast[3][2] end
    return rast
  end
)
lang.seqplan = S("%(", lang.plan, "%)", P({2}))
lang.parplan = S("{", lang.plan, "}",
  function (ast)
    local rast = ast[2]
    rast.plantype = "par"
    return rast
  end
)
I(lang.action, S(M(lang.predicate), C(
                   lang.extension,
                   lang.param2action,
                   lang.paramaction,
                   lang.locationaction,
                   lang.simpleaction,
                   lang.seqplan,
                   lang.parplan
                 ), M(lang.number), M(lang.variable),
  function (ast)
    local rast = {action=ast[2]}
    if ast[1] then rast.predicate = ast[1] end
    if ast[3] then rast.count = ast[3] end
    if ast[4] then rast.variable = ast[4] end
    return rast
  end
))
lang.start = O(C(lang.parplan, lang.seqplan, lang.plan), P({1}))

-- macro mode ------------------------------------------------------------------

lang.repeater = S(M(lang.int), M(lang.joiner), "%)", M(lang.number), P({repeatlines=1, join=2, count=4}))

-- compiler --------------------------------------------------------------------

local planContainer = {seq = {"(", ")"},
                 par = {"{", "}"}}
local varType = {num="#", bool="$"}
function compile(ast)
  if ast.action then
    local src = ""
    if type(ast.action) == "string" then
      src = ast.action
    else
      src = compile(ast.action)
    end
    if ast.predicate then
      src = ast.predicate .. src
    end
    if ast.count then
      if type(ast.count) == "table" then
        src = src .. varType[ast.count.vartype] .. ast.count.name
      else
        src = src .. tostring(ast.count)
      end
    end
    if ast.param then
      src = src .. tostring(ast.param)
    end
    if ast.param1 then
      src = src .. tostring(ast.param1) .. "," .. tostring(ast.param2)
    end
    if ast.variable then
      src = src .. "=" .. varType[ast.variable.vartype] .. ast.variable.name
    end
    return src
  elseif ast.actions then
    local src = planContainer[ast.plantype][1]
    if ast.worker then
      src = src .. ast.worker .. ":"
    end
    for i, v in ipairs(ast.actions) do
      src = src .. compile(v)
    end
    if ast.join then
      src = src .. "/"
      for i, v in ipairs(ast.join) do
        src = src .. compile(v)
      end
    end
    return src .. planContainer[ast.plantype][2]
  elseif ast.waypointtype then
    if ast.waypoint then
      return ast.waypointtype .. "<" .. ast.waypoint .. ">"
    else
      local src = ast.waypointtype .. "<" .. tostring(ast.x) .. "," .. tostring(ast.y) .. "," .. tostring(ast.z)
      if ast.facing then
        src = src .. "," .. ast.facing
      end
      src = src .. ">"
      return src
    end
  elseif ast.extension then
    local src = "%" .. ast.extension
    for i, v in ipairs(ast.params) do
      src = src .. "," .. v
    end
    src = src .. "%"
    return src
  end
end

-- interpreter, the helper functions -------------------------------------------

local turtle = turtle or {}
local forward = 0
local up = 1
local down = 2
local back = 3
local tMove = {[forward] = turtle.forward,
               [up] = turtle.up,
               [down] = turtle.down,
               [back] = turtle.back}
local tDetect = {[forward] = turtle.detect,
                 [up] = turtle.detectUp,
                 [down] = turtle.detectDown}
local tAttack = {[forward] = turtle.attack,
                 [up] = turtle.attackUp,
                 [down] = turtle.attackDown}
local tDig = {[forward] = turtle.dig,
              [up] = turtle.digUp,
              [down] = turtle.digDown}
local tPlace = {[forward] = turtle.place,
                [up] = turtle.placeUp,
                [down] = turtle.placeDown}

-- Go, move or wait to be cleared
local function goDir(dir)
  while not tMove[dir]() do
    sleep(1)
  end
  return true, 1
end
function goForward()
  return goDir(forward)
end
function goUp()
  return goDir(up)
end
function goDown()
  return goDir(down)
end
function goBack()
  return goDir(back)
end

-- Move, move or dig or attack until moved
local function moveDir(dir)
  while not tMove[dir]() do
    if tDetect[dir]() then
      tDig[dir]()
    else
      tAttack[dir]()
    end
  end
  return true, 1
end
function move()
  return moveDir(forward)
end
function moveUp()
  return moveDir(up)
end
function moveDown()
  return moveDir(down)
end

local function findSimilar()
  for s = 1, 16 do
    if s ~= turtle.selected then
      if turtle.compareTo(s) then
        return s
      end
    end
  end
  return nil
end

-- Build, place block with automatic resupply if needed
local function buildDir(dir)
  if turtle.getItemCount(turtle.selected) == 1 then
    local resupplySlot = findSimilar()
    if resupplySlot then
      if tPlace[dir]() then
        local currentSlot = turtle.selected
        turtle.select(resupplySlot)
        turtle.transferTo(currentSlot, turtle.getItemCount(resupplySlot))
        turtle.select(currentSlot)
        return true
      else
        return false
      end
    else
      return tPlace[dir]()
    end
  else
    return tPlace[dir]()
  end
end
function build()
  return buildDir(forward)
end
function buildUp()
  return buildDir(up)
end
function buildDown()
  return buildDir(down)
end

-- Sleep
local function zzz(n)
  sleep(n)
  return true
end

-- command handlers

local tHandlers = {
    -- move
  ["f"] = turtle.forward,
  ["b"] = turtle.back,
  ["u"] = turtle.up,
  ["d"] = turtle.down,
  ["l"] = turtle.turnLeft,
  ["r"] = turtle.turnRight,
  -- others
  ["s"] = turtle.select,
  ["t"] = turtle.transferTo,
  ["R"] = turtle.refuel,
  -- dig
  ["Df"] = turtle.dig,
  ["Du"] = turtle.digUp,
  ["Dd"] = turtle.digDown,
  -- attack
  ["Af"] = turtle.attack,
  ["Au"] = turtle.attackUp,
  ["Ad"] = turtle.attackDown,
  -- place
  ["Pf"] = turtle.place,
  ["Pu"] = turtle.placeUp,
  ["Pd"] = turtle.placeDown,
  -- build
  ["Bf"] = build,
  ["Bu"] = buildUp,
  ["Bd"] = buildDown,
  -- suck
  ["Sf"] = turtle.suck,
  ["Su"] = turtle.suckUp,
  ["Sd"] = turtle.suckDown,
  -- drop (E for eject)
  ["Ef"] = turtle.drop,
  ["Eu"] = turtle.dropUp,
  ["Ed"] = turtle.dropDown,
  -- move, dig routine with anti-gravel/sand and anti-mob logic
  ["Mf"] = move,
  ["Mu"] = moveUp,
  ["Md"] = moveDown,
  -- go, move or wait to be cleared
  ["Gf"] = goForward,
  ["Gu"] = goUp,
  ["Gd"] = goDown,
  ["Gb"] = goBack,
  -- hit, detect
  ["Hf"] = turtle.detect,
  ["Hu"] = turtle.detectUp,
  ["Hd"] = turtle.detectDown,
  -- compare
  ["Cf"] = turtle.compare,
  ["Cu"] = turtle.compareUp,
  ["Cd"] = turtle.compareDown,
  ["c"] = turtle.compareTo,
  -- inspect
  ["Ic"] = turtle.getItemCount,
  ["Is"] = turtle.getItemSpace,
  ["If"] = turtle.getFuelLevel,

  ["z"] = zzz --sleep
}

-- extensions ------------------------------------------------------------------

local tExtensions = {
  ["gps"] = function (getFacing)
    return 1, turtle.gps(getFacing)
  end
}

function registerExtension(name, func)
  tExtensions[name] = func
end

-- interpreter -----------------------------------------------------------------

function getWorkers(ast)
  local workers = {}
  if ast.actions then
    if ast.worker then
      workers[ast.worker] = true
    end
    for i, v in ipairs(ast.actions) do
      subWorkers = getWorkers(v, env)
      for worker, _ in pairs(subWorkers) do
        workers[worker] = true
      end
    end
  end
  return workers
end

function interpret(ast, env)
  env = env or {}
  env.num = env.num or {}
  env.bool = env.bool or {}
  if ast.actions then
    local succ = true
    local count = 0
    if ast.worker and env.worker ~= ast.worker then
      if env.executing then
        -- send via modem
        if env.modem and env.channel and env.replyChannel then
          env.modem.transmit(env.channel, env.replyChannel, compile(ast))
          if ast.plantype == "par" then
            -- wait for response
            while true do
              local event, modemSide, senderChannel, replyChannel, returnMessage, senderDistance = os.pullEvent("modem_message")
              if event == "modem_message" then
                break
              end
            end
          end
        else
          print("cannot send modem message to "..ast.worker)
        end
      end
    else
      env.executing = true
      for i, v in ipairs(ast.actions) do
        rep, succ = interpret(v, env)
        if not succ then
          break
        end
        count = count + 1
      end
      if ast.join and env.iter < env.count then
        for i, v in ipairs(ast.join) do
          rep, succ = interpret(v, env)
          if not succ then
            break
          end
          count = count + 1
        end
      end
    end
    return count, succ
  elseif ast.action then
    local predicate = ast.predicate
    local count = ast.count or 1
    if ast.count and type(ast.count) == "table" then
      count = env[ast.count.vartype][ast.count.name] or 0
    elseif ast.count == "*" then
      count = math.huge
    end
    local i = 0
    local succ = true
    local rep = 0
    if type(ast.action) == "string" then
      local func = tHandlers[ast.action]
      if ast.param then
        succ = func(ast.param)
      elseif ast.param1 then
        succ = func(ast.param1, ast.param2)
      else
        while i < count do
          succ = func()
          if not succ then break end
          i = i + 1
        end
      end
    else
      env.count = count
      while i < count do
        env.iter = i + 1
        rep, succ = interpret(ast.action, env)
        if not succ then break end
        i = i + 1
      end
    end
    if ast.variable then
      if ast.variable.vartype == "num" then
        env["num"][ast.variable.name] = i
      elseif ast.variable.vartype == "bool" then
        env["bool"][ast.variable.name] = succ
      end
    end
    if ast.predicate then
      if ast.predicate == "?" then
        return i, succ
      elseif ast.predicate == "~" then
        return i, not succ
      end
    else
      return i, true
    end
  elseif ast.waypointtype then
    if ast.waypointtype == "w" then
      -- set waypoint
      turtle.waypoint[ast.waypoint] = {x=turtle.x, y=turtle.y, z=turtle.z, facing=turtle.facing}
    elseif ast.waypointtype == "G" then
      -- goto waypoint
      local waypoint = {}
      if ast.waypoint then
        waypoint = turtle.waypoint[ast.waypoint]
        if not waypoint then
          print("unknown waypoint: " .. ast.waypoint)
          return 0, false
        end
      else
        waypoint.x = ast.x
        waypoint.y = ast.y
        waypoint.z = ast.z
        waypoint.facing = ast.facing or turtle.facing
      end
      -- move up or down
      local dy = waypoint.y - turtle.y
      if dy > 0 then
        for i = 1, dy do
          goUp()
        end
      elseif dy < 0 then
        for i = 1, -dy do
          goDown()
        end
      end
      -- move east or west
      local dx = waypoint.x - turtle.x
      if dx > 0 then -- east
        turtle.face(3)
        for i = 1, dx do
          goForward()
        end
      elseif dx < 0 then -- west
        turtle.face(1)
        for i = 1, -dx do
          goForward()
        end
      end
      -- move north or south
      local dz = waypoint.z - turtle.z
      if dz > 0 then -- south
        turtle.face(0)
        for i = 1, dz do
          goForward()
        end
      elseif dz < 0 then -- north
        turtle.face(2)
        for i = 1, -dz do
          goForward()
        end
      end
      turtle.face(waypoint.facing)
      return 1, true
    end
  elseif ast.extension then
    if tExtensions[ast.extension] then
      return tExtensions[ast.extension](unpack(ast.params))
    end
  end
end

function parse(plan, rule)
  -- remove whitespace and comments
  pos, ast, highpos = match(pre.source, plan, 1)
  plan = ast
  -- parse source
  rule = rule and lang[rule] or lang.start
  pos, ast, highpos = match(rule, plan, 1)
  if pos and pos > plan:len() then
    return ast
  else
    --print(plan)
    --print(string.rep("-", highpos-1).."^")
    --print("failure at "..tostring(highpos))
    return nil, plan .. "\n" .. string.rep("-", highpos-1) .. "^"
  end
end

function act(plan, env)
  -- interpret abstract syntax tree
  local ast = parse(plan)
  if ast then
    return interpret(ast, env)
  else
    return false
  end
end

-- debugging -------------------------------------------------------------------

function tprint (tbl, indent, max)
  if not max then max = 5 end
  if not indent then indent = 0 end
  if indent >= max then return end
  if tbl == nil then
    print("nil")
  elseif type(tbl) == "string" then
    print(tbl)
  else
    for k, v in pairs(tbl) do
      formatting = string.rep("  ", indent) .. k .. ": "
      if type(v) == "table" then
        print(formatting)
        tprint(v, indent+1, max)
      elseif type(v) == "boolean" then
        print(formatting .. tostring(v))
      else
        print(formatting .. v)
      end
    end
  end
end

tArgs = { ... }
if tArgs[1] then
  local ast = parse(tArgs[1])
  tprint(ast)
  if ast then
    print(compile(ast))
  end
end