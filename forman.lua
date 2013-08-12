local tArgs = { ... }
if #tArgs ~= 1 then
  print("Usage: forman <plan>|<filename> ...")
  print("              [<sendChannel> ...")
  print("                [<recieveChannel>]]")
  return
end

os.loadAPI("apis/act")

local modem
for _, side in ipairs(rs.getSides()) do
  if peripheral.getType(side) == "modem" then
    modem = peripheral.wrap(side)
  end
end
if not modem then
  print("Not a wireless modem or computer")
  return
end

local plan = tArgs[1]
if fs.exists(plan) then
  print("using file "..plan)
  local file = fs.open(plan, "r")
  plan = file.readAll()
  file.close()
end

local sendChannel = 284
if tArgs[2] then
  sendChannel = tonumber(tArgs[2]) or sendChannel
end
local recieveChannel = 220
if tArgs[2] then
  recieveChannel = tonumber(tArgs[2]) or recieveChannel
end
if not modem.isOpen(recieveChannel) then
  modem.open(recieveChannel)
end

local ast = act.parse(plan)
if not ast then
  print("act script cannot be parsed")
  return
end

function ping(worker, nTimeout)
  local message = worker.."@"..worker..":If"
  nTimeout = nTimeout or 1
  modem.transmit(sendChannel, recieveChannel, message)
  local timer = os.startTimer(nTimeout)
  while true do
    local event, modemSide, senderChannel, replyChannel, returnMessage, senderDistance = os.pullEvent()
    if event == "modem_message" then
      return message
    elseif event == "timer" and modemSide == timer then
      return nil
    end
  end
end

local workers = act.getWorkers(ast)
for worker, _ in pairs(workers) do
  if ping(worker) then
    print(worker.." online")
  else
    print(worker.." offline")
    return
  end
end

act.interpret(ast, {executing=true, modem=modem, channel=sendChannel, replyChannel=recieveChannel})

modem.closeAll()