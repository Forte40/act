local tArgs = { ... }
if #tArgs ~= 1 then
  print("Usage: actor <name> <channel>")
  return
end

local name = tArgs[1]

local modem
for _, side in ipairs(rs.getSides) do
  if peripheral.getType(side) == "modem" then
    modem = peripheral.wrap(side)
  end
end
if not modem then
  print("Not a wireless modem or computer")
  return
end

local channel = 284
if tArgs[2] then
  channel = tonumber(tArgs[2]) or channel
end
if not modem.isOpen(channel) then
  modem.open(channel)
end

function split(s, sep)
  ret = {}
  for v in string.gmatch(s, "[^"..sep.."]+") do
    table.insert(ret, v)
  end
  return ret
end

--local actChannel

os.loadAPI("apis/act")

function remotePlan()
  local event, modemSide, senderChannel, replyChannel, plan, senderDistance = os.pullEvent("modem_message")
  act.act(plan, {worker=name, modem=modem, channel=channel, replyChannel=replyChannel})
  modem.transmit(replyChannel, channel, name)
end

local stop = false
function localPlan()
  local plan = read()
  if plan ~= nil then
    if plan == "]]" then
      stop = true
    else
      act.act(plan)
    end
  end
end

while not stop do
  parallel.waitForAny(rednetPlan, localPlan)
end

modem.closeAll()
