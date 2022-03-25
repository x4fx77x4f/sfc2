--@name sfc2
--@author Sarah
--@client

--@include ./sh_core.lua
dofile('./sh_core.lua')

--@include ./cl_spectate.lua
dofile('./cl_spectate.lua')

local test_blending_bug
function test_blending_bug()
	local RT_NAME = sfc2.RT_NAME
	render.createRenderTarget(RT_NAME)
	render.selectRenderTarget(RT_NAME)
	render.setRGBA(255, 0, 0, 255)
	render.drawRect(0, 0, 1024, 1024)
	render.setRGBA(0, 255, 0, 127)
	render.drawRect(0, 0, 1024, 1024)
	function test_blending_bug()
		render.selectRenderTarget(RT_NAME)
		render.capturePixels()
		local c = render.readPixel(0, 0)
		sfc2.blending_result = c
		sfc2.blending_bug = c[4] ~= 255
		render.destroyRenderTarget(RT_NAME)
		function test_blending_bug()
			error("test_blending_bug expired")
		end
		return true
	end
end
hook.add('renderoffscreen', sfc2.HOOK_NAME, function()
	if test_blending_bug() then
		hook.remove('renderoffscreen', sfc2.HOOK_NAME)
	end
end)

sfc2.modules = {}
net.receive(sfc2.NET_NAME, function()
	local action = net.readUInt(sfc2.CB_WIDTH)
	if action == sfc2.CB_EXECUTE then
		local length = net.readUInt(32)
		local code = net.readData(length)
		local success, return_value = sfc2.execute(code)
		if success then
			net.start(sfc2.NET_NAME)
				net.writeUInt(sfc2.SB_EXECUTE_SUCCESS, sfc2.SB_WIDTH)
				assert(#return_value <= 2^32, "return value too long")
				net.writeUInt(#return_value, 32)
				net.writeData(return_value, #return_value)
			net.send()
		else
			net.start(sfc2.NET_NAME)
				net.writeUInt(sfc2.SB_EXECUTE_ERROR, sfc2.SB_WIDTH)
				assert(#return_value <= 2^32, "error message too long")
				net.writeUInt(#return_value, 32)
				net.writeData(return_value, #return_value)
			net.send()
		end
	elseif action == sfc2.CB_SUICIDE then
		net.receive(sfc2.NET_NAME)
		sfc2 = nil
	elseif action == sfc2.CB_SETMODULE then
		local module_name = net.readString()
		local k = net.readString()
		local v = sfc2.read_type()
		local module = sfc2.modules[module_name]
		if not module then
			return
		end
		module[k] = v
	elseif action == sfc2.CB_SETSPECTATEE then
		local spectatee = net.readEntity()
		if not isValid(spectatee) then
			spectatee = nil
		end
		sfc2.spectate(spectatee)
		sfc2.spectatee = spectatee
	end
end)

net.start(sfc2.NET_NAME)
	net.writeUInt(sfc2.SB_READY, sfc2.SB_WIDTH)
net.send()
pcall(enableHud, player(), true)
