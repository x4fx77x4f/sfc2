local print_target = sfc2.print_target
local print_all = sfc2.print_all

local bars = 'models/props_building_details/Storefront_Template001a_Bars.mdl'
sfc2.cell_prefabs = {
	ulx = {
		props = {
			{pos=Vector(0, 0, -46), ang=Angle(270, 0, 0), mdl=bars},
			{pos=Vector(0, 0, 46), ang=Angle(90, 0, 0), mdl=bars},
			{pos=Vector(21, 31, 0), ang=Angle(0, 270, 0), mdl=bars},
			{pos=Vector(21, -31, 0), ang=Angle(0, 90, 0), mdl=bars},
			{pos=Vector(-21, 31, 0), ang=Angle(0, 270, 0), mdl=bars},
			{pos=Vector(-21, -31, 0), ang=Angle(0, 90, 0), mdl=bars},
			{pos=Vector(-52, 0, 00), ang=Angle(0, 0, 0), mdl=bars},
			{pos=Vector(52, 0, 00), ang=Angle(0, 180, 0), mdl=bars},
		},
		min = Vector(-52, -31, -46),
		max = Vector(52, 31, 46),
	},
}
sfc2.cell_prefabs_default = 'ulx'
sfc2.cells = {}
sfc2.cells_lookup = {}

local function get_target(target)
	local ply, steamid
	if isstring(target) then
		steamid = target
		local plys = find.allPlayers()
		for k=1, #plys do
			local v = plys[k]
			if v:getSteamID() == steamid then
				ply = v
				break
			end
		end
	else
		ply = target
		steamid = ply:getSteamID()
	end
	return ply, steamid
end

local offset = Vector(0, 0, -1337)
sfc2.cell_offset = offset
function sfc2.cell_new(prefab, target)
	prefab = prefab or sfc2.cell_prefabs[sfc2.cell_prefabs_default]
	local cell = {
		prefab = prefab,
		props = {},
		ready = false,
		min = prefab.min,
		max = prefab.max,
	}
	if target then
		sfc2.cell_assign(cell, target)
	end
	table.insert(sfc2.cells, cell)
	local name = sfc2.HOOK_NAME..'_cellnew_'..table.address(cell)
	local dst, src, i = cell.props, prefab.props, 1
	local j = #src
	hook.add('think', name, function()
		while prop.canSpawn() do
			local info = src[i]
			local ent = prop.create(info.pos, info.ang, info.mdl, true)
			dst[i] = ent
			i = i+1
			if i > j then
				cell.ready = true
				hook.remove('think', name)
				return
			end
		end
	end)
end
function sfc2.cell_remove(cell)
	sfc2.cell_unassign(cell)
	for _, ent in pairs(cell.props) do
		ent:remove()
	end
end

function sfc2.cell_autoassign(target) 
	for _, cell in pairs(sfc2.cells) do
		if not cell.inmate then
			sfc2.cell_assign(cell, target)
			return
		end
	end
	sfc2.cell_new(nil, target)
end
function sfc2.cell_assign(cell, target)
	local ply, steamid = get_target(target)
	cell.inmate = ply
	cell.inmate_steamid = steamid
	sfc2.cells_lookup[steamid] = cell
end
function sfc2.cell_unassign(cell, target)
	local ply, steamid = cell.inmate, cell.inmate_steamid
	if not steamid then
		ply, steamid = get_target(target)
	end
	cell.inmate = nil
	cell.inmate_steamid = nil
	if steamid then
		sfc2.cells_lookup[steamid] = nil
	end
end
function sfc2.cell_reposition(cell, pos)
	if type(pos) == 'Player' then
		if not isValid(pos) then
			return
		end
		pos = pos:obbCenterW()
	end
	local src, dst = cell.prefab.props, cell.props
	for k=1, #dst do
		local v = dst[k]
		local v2 = src[k]
		v:setPos(v2.pos+pos)
		v:setAngles(v2.ang)
		v:setFrozen(true)
	end
	cell.min = cell.prefab.min+pos
	cell.max = cell.prefab.max+pos
end

hook.add('think', sfc2.HOOK_NAME..'_cellupdate', function()
	for _, cell in pairs(sfc2.cells_lookup) do
		local target = cell.inmate
		if cell.ready and isValid(target) then
			local pmin, pmax = target:worldSpaceAABB()
			local cmin, cmax = cell.min, cell.max
			if (
				pmin[1] < cmin[1] or
				pmin[2] < cmin[2] or
				pmin[3] < cmin[3] or
				pmax[1] > cmax[1] or
				pmax[2] > cmax[2] or
				pmax[3] > cmax[3]
			) then
				sfc2.cell_reposition(cell, target:obbCenterW())
			end
		end
	end
end)
hook.add('PlayerInitialSpawn', sfc2.HOOK_NAME..'_cellupdate', function(ply)
	local steamid = ply:getSteamID()
	for target, cell in pairs(sfc2.cells_lookup) do
		if target == steamid then
			cell.inmate = ply
			return
		end
	end
end)
hook.add('PlayerDisconnect', sfc2.HOOK_NAME..'_cellupdate', function(steamid, name, ply, reason, is_bot)
	for target, cell in pairs(sfc2.cells_lookup) do
		if target == steamid then
			cell.inmate = nil
		end
	end
end)

sfc2.commands.jail = function(executor, parameters)
	if not parameters or parameters == '' then
		return sfc2.commands.unjail(executor, parameters)
	end
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	local target = sfc2.get_target(parameters, true)
	if type(target) ~= 'Player' then
		print_target(executor, sfc2.color_feedback, "sfc2: no such target")
		return
	end
	if sfc2.cells_lookup[target:getSteamID()] then
		print_target(executor, sfc2.color_feedback, "sfc2: target already jailed")
		return
	end
	sfc2.cell_autoassign(target)
	if target then
		print_all(team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " jailed ", team.getColor(target:getTeam()), target:getName(), sfc2.color_feedback, ".")
	else
		print_all(team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " jailed ", sfc2.color_menu, string.format("%q", parameters), sfc2.color_feedback, ".")
	end
end
sfc2.commands.unjail = function(executor, parameters)
	if executor ~= owner() then
		print_target(executor, sfc2.color_feedback, "sfc2: not allowed")
		return
	end
	local target
	local cell = sfc2.cells_lookup[parameters]
	if not cell then
		target = sfc2.get_target(parameters, true)
		if type(target) ~= 'Player' then
			print_target(executor, sfc2.color_feedback, "sfc2: no such target")
			return
		end
		cell = sfc2.cells_lookup[target:getSteamID()]
	end
	if not cell then
		print_target(executor, sfc2.color_feedback, "sfc2: target not jailed")
		return
	end
	sfc2.cell_remove(cell)
	if target then
		print_all(team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " unjailed ", team.getColor(target:getTeam()), target:getName(), sfc2.color_feedback, ".")
	else
		print_all(team.getColor(executor:getTeam()), executor:getName(), sfc2.color_feedback, " unjailed ", sfc2.color_menu, string.format("%q", parameters), sfc2.color_feedback, ".")
	end
end
