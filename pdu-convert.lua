#!/usr/bin/luajit
local pdu = require("pdu")
local s
if arg[1] then
	s = arg[1]:gsub("..", function (a) return string.char(tonumber(a, 16)) end)
else
	local proto = io.read("*a")
	s = proto:match("^response: .-\n(%x+)"):gsub("..", function (a) return string.char(tonumber(a, 16)) end)
end

local suc, sms = pcall(pdu.parse, s)

if not suc then io.write("ERROR: ", sms, "\n") return end

io.write("Sender: ", sms.sender, "\n")
io.write((string.format(
	"Date: %s/%s/%s %s:%s.%s (dd/mm/yy hh:mm.ss)\n",
	sms.time.day, sms.time.month, sms.time.year,
	sms.time.hour, sms.time.minute, sms.time.second
)))

io.write("Text:\n", sms.text, "\n")
