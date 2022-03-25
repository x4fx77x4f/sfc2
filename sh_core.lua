sfc2 = sfc2 or {}

sfc2.HOOK_NAME = '_sfc2'
sfc2.RT_NAME = '_sfc2'
sfc2.NET_NAME = '_sfc2'
sfc2.CB_WIDTH = 8
sfc2.CB_EXECUTE = 0x01
sfc2.CB_SUICIDE = 0x02
sfc2.CB_SETMODULE = 0x03
sfc2.CB_SETSPECTATEE = 0x04
sfc2.SB_WIDTH = 8
sfc2.SB_EXECUTE_SUCCESS = 0x01
sfc2.SB_EXECUTE_ERROR = 0x02
sfc2.SB_READY = 0x03

sfc2.env = _G
sfc2.prefix = ''
function sfc2.execute(code, ...)
	local func = loadstring(sfc2.prefix..'return '..code)
	if type(func) ~= 'function' then
		func = loadstring(sfc2.prefix..code)
	end
	if type(func) ~= 'function' then
		return false, func
	end
	setfenv(func, sfc2.env)
	local return_values = {pcall(func, ...)}
	if return_values[1] then
		for k=2, #return_values do
			return_values[k-1] = tostring(return_values[k])
		end
		return_values[#return_values] = nil
		return true, table.concat(return_values, "\t")
	else
		local err = return_values[2]
		if type(err) == 'table' then
			err = rawget(err, 'message')
		end
		err = tostring(err)
		return false, err
	end
end
local potential_recursion = false
sfc2.get_target_handlers = {
	this = function()
		return player():getEyeTrace().Entity
	end,
	owner = owner,
	me = player,
	all = find.all,
	friends = function()
		return find.allPlayers(function(ply)
			return ply:getFriendStatus() == 'friend'
		end)
	end,
	humans = function()
		return find.allPlayers(function(ply)
			return not ply:isBot()
		end)
	end,
	bots = function()
		return find.allPlayers(function(ply)
			return ply:isBot()
		end)
	end,
	randply = function()
		return table.random(find.allPlayers())
	end,
	-- custom
	here = function()
		return player():getEyeTrace().HitPos
	end,
	chip = chip,
}
function sfc2.get_target(k, lenient)
	if not k then
		return
	elseif sfc2.get_target_handlers[k] then
		assert(not potential_recursion, "potential recursion detected")
		potential_recursion = true
		local retval = sfc2.get_target_handlers[k]()
		potential_recursion = false
		return retval
	-- custom
	elseif not k:find('[^%d]') then
		return entity(tonumber(k))
	elseif k:sub(1, 4) == 'pbn_' then
		return find.playersByName(k:sub(5), false, false)[1]
	elseif lenient then
		return find.playersByName(k, false, false)[1]
	end
end
setmetatable(sfc2.env, {
	__index = function(self, k)
		return sfc2.get_target(k)
	end
})

sfc2.TYPE_WIDTH = 8
sfc2.TYPE_NIL = 0x01
sfc2.TYPE_TRUE = 0x02
sfc2.TYPE_FALSE = 0x03
sfc2.TYPE_DOUBLE = 0x04
function sfc2.write_type(v)
	if v == nil then
		net.writeUInt(sfc2.TYPE_NIL, sfc2.TYPE_WIDTH)
	elseif v == true then
		net.writeUInt(sfc2.TYPE_TRUE, sfc2.TYPE_WIDTH)
	elseif v == false then
		net.writeUInt(sfc2.TYPE_FALSE, sfc2.TYPE_WIDTH)
	else
		local t = type(v)
		if t == 'number' then
			net.writeDouble(v)
		else
			error("cannot write type '"..t.."'")
		end
	end
end
function sfc2.read_type()
	local t = net.readUInt(sfc2.TYPE_WIDTH)
	if t == sfc2.TYPE_NIL then
		return nil, true
	elseif t == sfc2.TYPE_TRUE then
		return true, true
	elseif t == sfc2.TYPE_FALSE then
		return false, true
	elseif t == sfc2.TYPE_DOUBLE then
		return net.readDouble()
	end
end
