--@name sfc2
--@author Sarah
--@server
--@include ./cl_init.lua
--@clientmain ./cl_init.lua

--@include ./sh_core.lua
dofile('./sh_core.lua')

sfc2.blacklist = {}
sfc2.color_client = Color(222, 169, 9)
sfc2.color_client_light = Color(232, 220, 117)
sfc2.color_server = Color(3, 169, 244)
sfc2.color_server_light = Color(152, 212, 255)
sfc2.color_menu = Color(76, 175, 80)
sfc2.color_execute = Color(191, 191, 191)
sfc2.color_feedback = sfc2.color_execute
local function print_target(target, ...)
	if target == owner() then
		print(...)
	else
		pcall(printHud, target, ...)
	end
end
local function print_all(...)
	for _, player in pairs(find.allPlayers()) do
		print_target(player, ...)
	end
end
local everyone = {}
local function print_execution(executor, server, targets, code)
	local message = {
		team.getColor(executor:getTeam()),
		executor:getName(),
		sfc2.color_execute,
		"@",
	}
	local first = true
	if server then
		table.insert(message, sfc2.color_server)
		table.insert(message, "server")
		first = false
	end
	if targets == everyone then
		if not first then
			table.insert(message, sfc2.color_execute)
			table.insert(message, ",")
		end
		table.insert(message, sfc2.color_client)
		table.insert(message, "everyone")
		first = false
	elseif targets then
		for _, target in ipairs(targets) do
			if not first then
				table.insert(message, sfc2.color_execute)
				table.insert(message, ",")
			end
			table.insert(message, team.getColor(target:getTeam()))
			table.insert(message, target == executor and "themselves" or target:getName())
			first = false
		end
	end
	local i = #message
	message[i+1] = sfc2.color_execute
	message[i+2] = ": "..code
	print_all(unpack(message))
end
sfc2.execution_response_due = {}
local function execute(code, server, targets, executor, print_result)
	if server then
		local success, return_value = sfc2.execute(code)
		if success then
			if print_result then
				print_target(executor, sfc2.color_server_light, "sfc2: serverside return: "..return_value)
			end
		else
			print_target(executor, sfc2.color_server_light, "sfc2: serverside script error: "..return_value)
		end
	end
	if targets == everyone then
		net.start(sfc2.NET_NAME)
			net.writeUInt(sfc2.CB_EXECUTE, sfc2.CB_WIDTH)
			net.writeUInt(#code, 32)
			net.writeData(code, #code)
		net.send()
		for _, player in pairs(find.allPlayers()) do
			if not player:isBot() and not sfc2.blacklist[player] then
				sfc2.execution_response_due[player] = {
					executor = executor,
					print_result = print_result,
				}
			end
		end
	elseif targets then
		for _, player in pairs(targets) do
			if not player:isBot() and not sfc2.blacklist[player] then
				net.start(sfc2.NET_NAME)
					net.writeUInt(sfc2.CB_EXECUTE, sfc2.CB_WIDTH)
					net.writeUInt(#code, 32)
					net.writeData(code, #code)
				net.send(player)
				sfc2.execution_response_due[player] = {
					executor = executor,
					print_result = print_result,
				}
			end
		end
	end
end

sfc2.commands = {}
sfc2.commands.blacklist = function(executor, target)
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	target = sfc2.get_target(target, true)
	if not target then
		print_target(speaker, sfc2.color_feedback, "sfc2: no such target")
		return
	end
	target = target:getSteamID()
	if sfc2.blacklist[target] then
		print_target(speaker, sfc2.color_feedback, "sfc2: target already blacklisted")
		return
	end
	sfc2.blacklist[target] = true
	print_target(speaker, sfc2.color_feedback, "sfc2: added to blacklist")
end
sfc2.commands.unblacklist = function(executor, target)
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	target = sfc2.get_target(target, true)
	if not target then
		print_target(speaker, sfc2.color_feedback, "sfc2: no such target")
		return
	end
	target = target:getSteamID()
	if sfc2.blacklist[target] then
		sfc2.blacklist[target] = nil
		print_target(speaker, sfc2.color_feedback, "sfc2: removed from blacklist")
		return
	end
	print_target(speaker, sfc2.color_feedback, "sfc2: target not blacklisted")
end
sfc2.commands.suicide = function(executor, target)
	target = sfc2.get_target(target, true)
	if not target then
		print_target(speaker, sfc2.color_feedback, "sfc2: no such target")
		return
	end
	if target ~= executor and executor ~= owner() then
		print_target(speaker, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	net.start(sfc2.NET_NAME)
		net.writeUInt(sfc2.CB_SUICIDE, sfc2.CB_WIDTH)
	net.send(target)
	print_target(speaker, sfc2.color_feedback, "sfc2: invoked suicide of target")
end

sfc2.commands.l = function(executor, code, print_result)
	-- Execute on server only
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	print_execution(executor, true, nil, code, print_result)
	execute(code, true, nil, executor, print_result)
end
sfc2.commands.ls = function(executor, code, print_result)
	-- Execute on server and all clients
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	print_execution(executor, true, everyone, code, print_result)
	execute(code, true, everyone, executor, print_result)
end
sfc2.commands.lc = function(executor, code, print_result)
	-- Execute on all clients
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	print_execution(executor, false, everyone, code, print_result)
	execute(code, false, everyone, executor, print_result)
end
sfc2.commands.lsc = function(executor, str, print_result)
	-- Execute on specified targets
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	local first_space = string.find(str, ' ')
	if not first_space then
		print_target(executor, sfc2.color_feedback, "sfc2: malformed command")
		return
	end
	local targets, code = string.explode(',', string.sub(str, 1, first_space-1)), string.sub(str, first_space+1)
	local targets2 = {}
	for k, v in pairs(targets) do
		local v2 = sfc2.get_target(v, true)
		if type(v2) == 'table' then
			for _, v3 in pairs(v2) do
				table.insert(targets2, v3)
			end
		elseif not v2 then
			print_target(executor, sfc2.color_feedback, "sfc2: no such target '"..v.."'")
			return
		else
			table.insert(targets2, v2)
		end
	end
	print_execution(executor, false, targets2, code, print_result)
	execute(code, false, targets2, executor, print_result)
end
sfc2.commands.lm = function(executor, code, print_result)
	-- Execute on local client only
	print_execution(executor, false, {executor}, code, print_result)
	execute(code, false, {executor}, executor, print_result)
end
sfc2.commands.lb = function(executor, code, print_result)
	-- Execute on server and local client
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	print_execution(executor, true, {executor}, code, print_result)
	execute(code, true, {executor}, executor, print_result)
end
sfc2.commands.p = function(executor, parameters) return sfc2.commands.l(executor, parameters, true) end
sfc2.commands.ps = function(executor, parameters) return sfc2.commands.ls(executor, parameters, true) end
sfc2.commands.pc = function(executor, parameters) return sfc2.commands.lc(executor, parameters, true) end
sfc2.commands.psc = function(executor, parameters) return sfc2.commands.lsc(executor, parameters, true) end
sfc2.commands.pm = function(executor, parameters) return sfc2.commands.lm(executor, parameters, true) end
sfc2.commands.pb = function(executor, parameters) return sfc2.commands.lb(executor, parameters, true) end

sfc2.seatDefaultPos = Vector(0, 0, -1337)
sfc2.seat = prop.createSeat(sfc2.seatDefaultPos, Angle(), 'models/hunter/blocks/cube1x1x1.mdl', true)
sfc2.seat:setNocollideAll(true)
sfc2.returnPos = setmetatable({}, {__mode='k'}) -- __mode doesn't work on Player, but let's use it anyway
local function tp(ply, dst)
	assert(ply == owner())
	sfc2.seat:setPos(dst)
	sfc2.seat:use()
	sfc2.seat:ejectDriver()
	sfc2.seat:setPos(sfc2.seatDefaultPos)
	pcall(ply.setEyeAngles, ply, (dst-ply:getEyePos()):getAngle())
end
sfc2.commands.goto = function(executor, parameters)
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	local target = sfc2.get_target(parameters, true)
	if not target then
		print_target(executor, sfc2.color_feedback, "sfc2: no such target")
		return
	end
	sfc2.returnPos[executor] = executor:getEyePos()
	tp(executor, type(target) == 'Vector' and target or target:getEyePos())
	local message = {team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " teleported to "}
	if type(target) == 'Player' then
		table.insert(message, team.getColor(target:getTeam()))
		table.insert(message, target:getName())
		table.insert(message, sfc2.color_feedback)
		table.insert(message, ".")
	else
		message[#message] = message[#message]..tostring(target).."."
	end
	print_all(unpack(message))
end
sfc2.commands['return'] = function(executor, parameters)
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	local returnPos = sfc2.returnPos[executor]
	if not returnPos then
		print_target(executor, sfc2.color_feedback, "sfc2: no return position")
		return
	end
	tp(executor, returnPos)
	print_all(team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " returned to their original position.")
end

sfc2.spectating = setmetatable({}, {__mode='k'}) -- __mode doesn't work on Player, but let's use it anyway
sfc2.commands.spectate = function(executor, parameters)
	if not parameters or parameters == '' then
		return sfc2.commands.unspectate(executor, parameters)
	end
	local target = sfc2.get_target(parameters, true)
	if type(target) ~= 'Player' then
		print_target(executor, sfc2.color_feedback, "sfc2: no such target")
		return
	end
	sfc2.spectating[executor] = target
	net.start(sfc2.NET_NAME)
		net.writeUInt(sfc2.CB_SETSPECTATEE, sfc2.CB_WIDTH)
		net.writeEntity(target)
	net.send(executor)
	print_all(team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " started spectating ", team.getColor(target:getTeam()), target:getName(), sfc2.color_feedback, ".")
end
sfc2.commands.unspectate = function(executor, parameters)
	net.start(sfc2.NET_NAME)
		net.writeUInt(sfc2.CB_SETSPECTATEE, sfc2.CB_WIDTH)
		net.writeEntity(entity(0))
	net.send(executor)
	if sfc2.spectating[executor] then
		print_all(team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " stopped spectating.")
	end
	sfc2.spectating[executor] = nil
end

--[[
sfc2.modules_response_due = {}
function sfc2.commands.setmodule(executor, parameters)
	local first_space = string.find(str, ' ')
	if not first_space then
		print_target(executor, "sfc2: malformed command")
		return
	end
	local target = sfc2.get_target(string.sub(str, 1, first_space-1), true)
	if not target then
		print_target(speaker, "sfc2: no such target")
		return
	end
	if target ~= executor and executor ~= owner() then
		print_target(speaker, "sfc2: not allowed")
		return
	end
	net.start(sfc2.NET_NAME)
		
	net.send(executor)
end
--]]

hook.add('PlayerSay', sfc2.HOOK_NAME, function(speaker, text, team_chat)
	if string.sub(text, 1, 1) ~= '$' then
		return
	end
	local first_space = string.find(text, ' ', 1, true)
	local command = string.sub(text, 2, first_space and first_space-1 or nil)
	local func = sfc2.commands[command]
	if func then
		func(speaker, first_space and string.sub(text, first_space+1) or '')
	else
		print_target(speaker, sfc2.color_feedback, "sfc2: no such command")
	end
	return ""
end)

net.receive(sfc2.NET_NAME, function(length, sender)
	if sfc2.blacklist[sender:getSteamID()] then
		return
	end
	local action = net.readUInt(sfc2.SB_WIDTH)
	if action == sfc2.SB_EXECUTE_SUCCESS then
		local data = sfc2.execution_response_due[sender]
		if not data then
			return
		elseif not data.print_result then
			sfc2.execution_response_due[sender] = nil
			return
		end
		local return_value_length = net.readUInt(32)
		local return_value = net.readData(return_value_length)
		print_target(data.executor, sfc2.color_client_light, "sfc2: clientside return from ", team.getColor(sender:getTeam()), sender:getName(), sfc2.color_client_light, ": "..return_value)
		sfc2.execution_response_due[sender] = nil
	elseif action == sfc2.SB_EXECUTE_ERROR then
		local data = sfc2.execution_response_due[sender]
		if not data then
			return
		end
		local return_value_length = net.readUInt(32)
		local return_value = net.readData(return_value_length)
		print_target(data.executor, sfc2.color_client_light, "sfc2: clientside script error from ", team.getColor(sender:getTeam()), sender:getName(), sfc2.color_client_light, ": "..return_value)
		sfc2.execution_response_due[sender] = nil
	end
end)
