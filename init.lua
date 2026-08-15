local pdu = {}
local gsmalph = require("pdu.gsmalph")

--Auxillary FIFO-like buffer structure.
local Buf = {}
Buf.__index = Buf

function Buf.new(s)
	assert(s, "no buffer source specified")
	return setmetatable({ str = s, idx = 1 }, Buf)
end

function Buf:consume(n)
	if not n then
		local retval = self.str:sub(self.idx)
		self.idx = #self.str
		return retval
	end

	if #self.str - self.idx + 1 < n then
		return nil, "buffer doesn't have enough members"
	end

	local retval = self.str:sub(self.idx, self.idx + n-1)
	self.idx = self.idx + n

	return retval
end

--Converts a number string from PDU format to readable string.
local function get_num_str(pdu_num)
	local num_str = ""
	for i = 1, #pdu_num do
		local char = pdu_num:sub(i, i):byte()
		local dig1 = char % 16
		local dig2 = math.floor(char / 16)
		num_str = num_str .. dig1 .. (dig2 == 15 and "" or dig2)
	end
	return num_str
end

--Gets the idx-th septet from the string s.
local function get_septet(s, idx)
	local pos = idx * 7
	local lowfit = math.floor(pos / 8)
	local lowoff = pos % 8

	local lowbyte = s:sub(lowfit+1, lowfit+1):byte()
	local highbyte
	if lowoff <= 1 then highbyte = 0
	else highbyte = s:sub(lowfit+2, lowfit+2):byte()
	end

	local n = highbyte*256 + lowbyte
	n = math.floor(n / 2^lowoff)
	return n % 128
end

function pdu.parse(s)
	local buf = Buf.new(s)
	local smsc_len = assert(buf:consume(1)):byte()
	local smsc_type = assert(buf:consume(1)):byte()
	local smsc_num = assert(buf:consume(smsc_len-1))

	local smsc_num_str = get_num_str(smsc_num)

	local tpdu_status = assert(buf:consume(1)):byte()
	local tpdu_sender_len_digs = assert(buf:consume(1)):byte()
	local tpdu_sender_type = assert(buf:consume(1)):byte()

	local tpdu_sender_len = math.ceil(tpdu_sender_len_digs / 2)
	local tpdu_sender_num = assert(buf:consume(tpdu_sender_len))
	local tpdu_num_str = get_num_str(tpdu_sender_num)

	local tpdu_prot_id = assert(buf:consume(1)):byte()
	local tpdu_coding = assert(buf:consume(1)):byte() --TODO: warn for nonstandard coding

	local tpdu_tstamp = assert(buf:consume(7))
	local tstamp = get_num_str(tpdu_tstamp)

	--TODO: Handle timestamp
	local
		year, month, day,
		hour, minute, second,
		zone = tstamp:match("^" .. string.rep("(..)", 7) .. "$")

	local tpdu_sms_len = assert(buf:consume(1)):byte()
	local tpdu_sms = buf:consume()

	local text = ""
	for i = 0, tpdu_sms_len-1 do
		local sep = get_septet(tpdu_sms, i)
		local c = gsmalph[sep]
		text = text .. c
	end

	return {
		text = text,
		sender = (tpdu_sender_type == 0x91 and "+" or "(?) ") .. tpdu_num_str,
		time = {
			year = year,
			month = month,
			day = day,
			hour = hour,
			minute = minute,
			second = second
		}
	}
end

return pdu
