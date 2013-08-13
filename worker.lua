local tArgs = { ... }
if #tArgs ~= 1 then
  print("Usage: worker <name> <channel>")
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

print("worker "..name.." online")
while true do
  local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
  local pos = message:find("@")
  if pos then
    local worker = message:sub(1, pos - 1)
    if worker == name then
      local plan = message:sub(pos + 1)
      print(plan)
      act.act(plan, {worker=name, modem=modem, channel=channel, replyChannel=replyChannel})
      if replyChannel then
        modem.transmit(replyChannel, channel, name)
      end
    end
  end
end
