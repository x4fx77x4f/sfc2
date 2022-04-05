function sfc2.spectate_calcview(pos, ang, fov, znear, zfar)
	local spectatee = sfc2.spectatee
	local valid = isValid(spectatee)
	if valid then
		pcall(spectatee.setNoDraw, spectatee, true)
		local wpn = spectatee:getActiveWeapon()
		if isValid(wpn) then
			pcall(wpn.setNoDraw, wpn, true)
		end
	end
	return {
		origin = valid and spectatee:getEyePos() or pos,
		angles = valid and spectatee:getEyeAngles() or ang,
		fov = (valid and spectatee.getFOV) and spectatee:getFOV() or fov,
		znear = znear,
		zfar = zfar,
		drawviewer = true,
	}
end
function sfc2.spectate_drawhud()
	local spectatee = sfc2.spectatee
	if not isValid(spectatee) then
		return
	end
	local str = string.format(
		"You are spectating %s.\n"..
		"Team: %q (%d)\n"..
		"Health: %d / %d\n"..
		"Armor: %d / %d",
		spectatee:getName(),
		team.getName(spectatee:getTeam()), spectatee:getTeam(),
		spectatee:getHealth(), spectatee:getMaxHealth(),
		spectatee:getArmor(), spectatee:getMaxArmor()
	)
	local x, y = 8, 256
	render.setFont('DermaLarge')
	render.setRGBA(0, 0, 0, 255)
	render.drawText(x+2, y+2, str)
	render.setRGBA(255, 255, 255, 255)
	render.drawText(x, y, str)
end
local blacklist = {
	CHudAmmo = true,
	CHudBattery = true,
	CHudGMod = true,
	CHudHealth = true,
	CHudPoisonDamageIndicator = true,
	CHudSecondaryAmmo = true,
	CHudSquadStatus = true,
	CHudZoom = true,
	CHUDQuickInfo = true,
	CHudSuitPower = true,
}
sfc2.spectate_hud_blacklist = blacklist
function sfc2.spectate_hudshoulddraw(name)
	if blacklist[name] then
		return false
	end
end

function sfc2.spectate(target)
	if target == nil then
		hook.remove('calcview', sfc2.HOOK_NAME)
		hook.remove('postdrawhud', sfc2.HOOK_NAME)
		hook.remove('hudshoulddraw', sfc2.HOOK_NAME)
		local spectatee = sfc2.spectatee
		if isValid(spectatee) then
			pcall(spectatee.setNoDraw, spectatee, false)
			for _, wpn in pairs(spectatee:getWeapons()) do
				pcall(wpn.setNoDraw, wpn, false)
			end
		end
	else
		hook.add('calcview', sfc2.HOOK_NAME, sfc2.spectate_calcview)
		hook.add('postdrawhud', sfc2.HOOK_NAME, sfc2.spectate_drawhud)
		hook.add('hudshoulddraw', sfc2.HOOK_NAME, sfc2.spectate_hudshoulddraw)
	end
	sfc2.spectatee = target
end
