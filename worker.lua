local tArgs = { ... }
if #tArgs ~= 1 then
  print("Usage: actor <name> <channel>")
  return
end

local name = tArgs[1]

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

local channel = 284
if tArgs[2] then
  channel = tonumber(tArgs[2]) or channel
end
if not modem.isOpen(channel) then
  modem.open(channel)
end

os.loadAPI("apis/act")

local plans = {}

function remotePlan()
  local event, modemSide, senderChannel, replyChannel, plan, senderDistance = os.pullEvent("modem_message")
  table.insert(plans, {plan, replyChannel})
end

local stop = false
function localPlan()
  local plan = read()
  if plan ~= nil then
    if plan == "]]" then
      stop = true
    else
      table.insert(plans, {plan, nil})
    end
  end
end

function doPlan()
  local plan = table.remove(plans, 1)
  if plan ~= nil then
    local replyChannel = plan[2]
    plan = plan[1]
    act.act(plan, {worker=name, modem=modem, channel=channel, replyChannel=replyChannel})
    if replyChannel then
      modem.transmit(replyChannel, channel, name)
    end
  end
end

while not stop do
  parallel.waitForAll(
    function ()
      parallel.waitForAny(remotePlan, localPlan)
    end,
    doPlan
  )
end

modem.closeAll()
