--[[
	Capture The Flag System
	Author: Maxwell Denisson(MaXwEllDeN)
	Version: 2.0 [REMAKE] 22/04/2013
	Contact: maxwellmda@gmail.com
]]

local CTF = CTF_LIB

local function sendEffect()
	if (getGlobalStorageValue(16505) > 0) then
		doSendAnimatedText(CTF.tppos, "CTF ON", math.random(180))
		addEvent(sendEffect, 750)
	end
end

function onThink(interval, lastExecution)
	local time = os.date("*t")

	if (isInArray(CTF.days, time.wday)) then
		doBroadcastMessage("[CTF] Est� aberto no depot de Thais para novos participantes, em ".. CTF.timeclose .." minuto(s) n�o ser� mais poss�vel entrar!")
		setGlobalStorageValue(16705, 1)

		addEvent(CTF.start, CTF.timeclose * 60 * 1000)

		local teelz = doCreateItem(1387, 1, CTF.tppos)
		doItemSetAttribute(teelz, "aid", 47521)
		sendEffect()
	end

	return true
end
