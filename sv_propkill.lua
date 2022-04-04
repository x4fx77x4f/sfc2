local sfc2 = sfc2
local print_target = sfc2.print_target
local print_all = sfc2.print_all

local default_pos = Vector(0, 0, -1337)
sfc2.propkill_default_pos = default_pos
local default_ang = Angle()
sfc2.propkill_default_ang = default_ang
local ent = prop.create(default_pos, default_ang, 'models/props_junk/PopCan01a.mdl', true)
sfc2.propkill_ent = ent
ent:setColor(Color(0, 0, 0, 0))
ent:setNoDraw(true)
ent:setMass(math.huge)

local queue = {}
sfc2.propkill_queue = queue

local at_home = false
local function home()
	ent:setPos(default_pos)
	ent:setAngles(default_ang)
	ent:setFrozen(true)
	at_home = true
end
sfc2.propkill_home = home

local zo = -math.min(
	ent:obbMins().z,
	ent:obbMaxs().z
)
local vel = Vector(0, 0, -1000)
sfc2.propkill_vel = vel
local function kill(target)
	at_home = false
	local pos = target:getPos()
	pos.z = math.max(
		(pos+target:obbMins()).z,
		(pos+target:obbMaxs()).z
	)+zo+1
	ent:setFrozen(false)
	ent:setPos(pos)
	ent:addVelocity(vel)
end
sfc2.propkill_kill = kill

timer.create(sfc2.TIMER_NAME..'_propkill_queue', 1/30, 0, function()
	local target = table.remove(queue, 1)
	if not isValid(target) then
		if not at_home then
			home()
		end
		return
	else
		kill(target)
	end
end)

sfc2.commands.propkill = function(executor, parameters)
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	local target = sfc2.get_target(parameters, true)
	if type(target) ~= 'Player' then
		print_target(executor, sfc2.color_feedback, "sfc2: no such target")
		return
	end
	table.insert(queue, target)
	print_all(team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " propkilled ", team.getColor(target:getTeam()), target:getName(), sfc2.color_feedback, ".")
end
