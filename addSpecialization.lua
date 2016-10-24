--
-- add specialization to all mods.
--
--
-- @author:    	Xentro (Marcus@Xentro.se)
-- @website:	www.Xentro.se
-- @history:	v1.53 - 2014-11-11 - Improvement
-- 				v1.52 - 2013-10-29 - 
--

addSpecialization = {};
addSpecialization.isLoaded = true;
addSpecialization.g_currentModDirectory = g_currentModDirectory;

if SpecializationUtil.specializations["LightAddon"] == nil then
	SpecializationUtil.registerSpecialization("LightAddon", "LightAddon", g_currentModDirectory .. "LightAddon.lua")
	addSpecialization.isLoaded = false;
end;

addModEventListener(addSpecialization);

function addSpecialization:loadMap(name)	
    if not g_currentMission.lightModLoaded then
		if not addSpecialization.isLoaded then
			addSpecialization:add();
			addSpecialization.isLoaded = true;
		end;
		
		g_currentMission.lightModLoaded = true;
	else
		print("LightAddon - Error: The LightAddon mod have been loaded already! remove one of the copy's");
	end;
end;

function addSpecialization:deleteMap()
	g_currentMission.lightModLoaded = nil;
end;

function addSpecialization:mouseEvent(posX, posY, isDown, isUp, button)
end;

function addSpecialization:keyEvent(unicode, sym, modifier, isDown)
end;

function addSpecialization:update(dt)
end;

function addSpecialization:draw()
end;

function addSpecialization:add()
	local searchWords = {"LightAddon"};
	local searchSpecializations = {{"LightAddon", false}}; -- only globally accessible scripts. (steerable, fillable etc.)
	
	for k, vehicle in pairs(VehicleTypeUtil.vehicleTypes) do
		local locationAllowed, specialization;
		
		for _, s in ipairs(searchSpecializations) do s[3] = false; end;
		
		for _, vs in ipairs(vehicle.specializations) do
			for _, s in ipairs(searchSpecializations) do
				if vs == SpecializationUtil.getSpecialization(s[1]) then
					if s[2] then
						locationAllowed = "allowed";
						s[3] = true;
					else
						locationAllowed = "has";
						specialization = s[1];
						break;
					end;
				end;
			end;
			
			if locationAllowed ~= nil and locationAllowed ~= "allowed" then
				break;
			end;
		end;
		
		if locationAllowed == nil then
			locationAllowed = "allowed";
		end;
		
		for _, s in ipairs(searchSpecializations) do
			if s[2] then
				if s[3] ~= true then
					locationAllowed = "missing";
					specialization = s[1];
					break;
				end;
			end;
		end;
		
		if locationAllowed == "allowed" then
			local addSpec;
			local modName = Utils.splitString(".", k);
			local spec = {};
			
			for name in pairs(SpecializationUtil.specializations) do
				if string.find(name, modName[1]) ~= nil then
					local parts = Utils.splitString(".", name);
					
					if table.getn(parts) > 1 then
						table.insert(spec, parts);
					end;
				end;
			end;
			
			for _, s in ipairs(spec) do
				for _, search in ipairs(searchWords) do
					if string.find(string.lower(s[2]), string.lower(search)) ~= nil then
						addSpec = s[2];
						break;
					end;
				end;
				
				if addSpec ~= nil then
					break;
				end;
			end;
			
			if addSpec == nil then
				table.insert(vehicle.specializations, SpecializationUtil.getSpecialization("LightAddon"));
				--print("LightAddon: Inserted on " .. k);
			else
				print("LightAddon: Failed inserting on " .. k .. " as it has the specialization (" .. addSpec .. ")");
			end;
		elseif locationAllowed == "has" then
			print("LightAddon: Failed inserting on " .. k .. " as it has the specialization (" .. specialization .. ")");
		else
			-- print("LightAddon: Failed inserting on " .. k .. " as its missing specialization " .. specialization);
		end;
	end;
end;