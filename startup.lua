if not turtle then return end

-- install
if not fs.exists("act-install") then
  shell.run("pastebin", "get", "5CuUMxqr", "act-install")
end
shell.run("act-install")
os.loadAPI("apis/act")

-- get act script
local plan
local actFile
local formanName
for i, filename in ipairs(fs.list("disk")) do
  if filename:find("%.act$") then
    print("initializing "..filename)
    local f = fs.open(fs.combine("disk",filename), "r")
    plan = f.readAll()
    f.close()
    actFile = filename
    formanName = filename:sub(1, #filename - 4)
    break
  end
end
local ast = act.parse(plan)

-- get next offline worker
local workers = act.getWorkers(ast)
local modem
for _, side in ipairs(rs.getSides()) do
  if peripheral.getType(side) == "modem" then
    modem = peripheral.wrap(side)
  end
end
if not modem then
  print("Not a wireless turtle")
  return
end
if not modem.isOpen(220) then
  modem.open(220)
end
local nextWorker
for worker, _ in pairs(workers) do
  modem.transmit(284, 220, worker.."@"..worker..":If")
  local timer = os.startTimer(1)
  while true do
    local event, modemSide, senderChannel, replyChannel, returnMessage, senderDistance = os.pullEvent()
    if event == "modem_message" then
      print("  worker '"..worker.."' online")
      break
    elseif event == "timer" and modemSide == timer then
      print("  worker '"..worker.."' offline")
      nextWorker = worker
      break
    end
  end
  if nextWorker then
    break
  end
end

-- fuel and orient turtle
while true do
  local pType = peripheral.getType("front")
  if pType and pType:find("chest") then
    if turtle.getFuelLevel() == 0 then
      for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
          turtle.select(i)
          turtle.suck()
          turtle.refuel()
          print("getting fuel: "..turtle.getFuelLevel())
          break
        end
      end
    end
    break
  end
  turtle.turnRight()
end
turtle.turnLeft()
turtle.facing = 0
if turtle.gps(true) then
  print("gps synced")
end

-- send to startup position
function sendToStartup(theWorker)
  function getStartup(ast)
    if ast.actions then
      for i, v in ipairs(ast.actions) do
        local startup = getStartup(v)
        if startup then
          return startup
        end
      end
    elseif ast.action and type(ast.action) == "table" then
      return getStartup(ast.action)
    elseif ast.extension and ast.extension == "startup" then
      return ast.params
    end
  end
  local params = getStartup(ast)
  tFacing = {south=0, west=1, north=2, east=3}
  for i = 1, #params, 5 do
    local worker, x, y, z, facing = params[i], params[i+1], params[i+2], params[i+3], params[i+4]
    facing = tFacing[facing] or facing
    if worker and worker == theWorker and x and y and z and facing then
      local plan = "G<"..x..","..y..","..z..","..facing..">"
      print(plan)
      act.act(plan)
      break
    end
  end
end

if nextWorker then
  os.setComputerLabel(nextWorker)
  print("label set to "..nextWorker)

  -- create startup
  f = fs.open("startup", "w")
  f.write("shell.run('worker','"..nextWorker.."')")
  f.close()
  print("startup file created")

  sendToStartup(nextWorker)

  -- start worker program
  shell.run("worker", nextWorker)
else
  -- setup forman
  os.setComputerLabel("forman"..formanName)
  fs.copy(fs.combine("disk",actFile), actFile)
  f = fs.open("start", "w")
  f.write("shell.run('forman', '"..actFile.."')")
  f.close()

  sendToStartup("forman")

  print("forman ready, run 'start'")
end