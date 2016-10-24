-- LightAddon
--
-- @author  Grisu118 - VertexDezign.net
-- @history		v1.0 	- 2014-10-31 - Initial implementation
--				v1.1	- 2014-11-14 - Implemented improvements of Xentro
--				v1.1.1	- 2014-11-23 - Bugfix: If leaving vehicle with turned on implement, lightsTypesMask was wrong
--				v1.2 	- 2015-01-01 - Courseplay LightFix, Drl Fix, removed use of self.lightsState
--              v1.2.1  - 2015-01-04 - Fixed problem with onEnter
--              v1.2.2  - 2015-01-13 - Use getIsActiveForLights instead of isActiveForInput
--              v1.2.3  - 2015-01-19 - Only Sync drl if vehicle has drl
--              v1.2.4  - 2015-03-24 - Fix for attachedVehicle with Belv3
--				v1.3	- 2016-02-06 - Fix for Beacon, LA nil, reset turnlights, fix for beaconlights on trailer with dolly.
--              v1.4    - 2016-02-07 - Fix for strobelights, LAFix Version >=1.2 needed
--              v1.4.1  - 2016-03-11 - Fix for BelV3.1 getn from nil
--				v2.0 	- 2016-10-24 - FS17, only DRL and Strobes
-- @Descripion: Extends the standart FS Lights with additional Functions
-- @web: http://grisu118.ch or http://vertexdezign.net
-- Copyright (C) Grisu118, All Rights Reserved.

--[[ XML Structure
<LightAddon>
	<drl index="" />
	<strobe index="" isBeacon="false" name="" sequence="" invert="" minOn="" maxOn="" minOff="" maxOff="" />
	<!--			optional(true)		|		optional	|		--       optinal 			--
						only needed if isBeacon=false		|
													Only needed if sequence -->
</LightAddon>

]]

LightAddon = {};
function LightAddon.prerequisitesPresent(specializations)
	return true;
end;

function LightAddon:load(xmlFile)
	self.deactivate = SpecializationUtil.callSpecializationsFunction("deactivate");
	self.activate = SpecializationUtil.callSpecializationsFunction("activate");
	self.setState = SpecializationUtil.callSpecializationsFunction("setState");
	self.setDRL = SpecializationUtil.callSpecializationsFunction("setDRL");

	self.LA = {};
	self.LA.debug = false; --Sets debug, if true additional prints are written to the log.
    self.LA.debugLevel = 2;

	local x,y = Utils.getModNameAndBaseDirectory(self.configFileName);
	self.LA.modName = x;
	--Turn Signals
	self.LA.turnState = 0;
	self.LA.steerTresh = 0.7;

	--BeaconLights
	self.LA.beaconActive = false;
	self.LA.hasBeacons = table.getn(self.beaconLights) > 0;

	--DayDriveLight drl
	self.LA.drl = {};
	self.LA.drlIsActive = false;
	self.LA.hasDRL = false;
	local i = 0;
	while true do
		local key = string.format("vehicle.LightAddon.drl(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		local drlIndex = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"));

		if drlIndex ~= nil then
			table.insert(self.LA.drl, drlIndex);
			self.LA.hasDRL = true;
			setVisibility(drlIndex, false);
		end;
		i = i + 1;
	end;

	--Helptexts
	self.LA.helptexts = {};

	--Strobe
	self.LA.str = {};
	local i = 0;
    local lafixwarning = false;
	while true do
		local key = string.format("vehicle.LightAddon.strobe(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		local str = {};
		str.index = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index"));
		if str.index ~= nil then
			str.isBeacon = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isBeacon"), true);
			str.isAcitve = false;
			str.time = 1; --actual timer
			str.seqLen = 0; --how long sequence is
			str.seqActive = false;
			if not str.isBeacon then
				local name = getXMLString(xmlFile, key .. "#name");

				if name ~= nil and self.LA.modName ~= nil and g_i18n:hasText(self.LA.modName..name) then
					str.name = self.LA.modName..name;
					str.input = name;
					self.LA.helptexts[name] = g_i18n:getText(str.name);
					if InputBinding[str.input] == nil then
						print("LightAddon: Error in " .. self.LA.modName .. ", no input defined for " .. name);
					end;
                    if not lafixwarning and (self.LAFixVersion == nil or self.LAFixVersion < 2.0) then
                        print("LightAddon: Warning for " .. self.LA.modName .. ", Newer LAFix.lua available!")
                        lafixwarning = true
                    end
				end;
			end;
			local sequence = getXMLString(xmlFile, key .. "#sequence");
			if sequence ~= nil then
				str.sequence = {Utils.getVectorFromString(sequence)};
				str.invert = Utils.getNoNil(getXMLBool(xmlFile, key .."#invert"),false);
				str.seqActive = str.invert;
				str.random = false;
				str.seqNum = 0;
			else
				str.minOn = Utils.getNoNil(getXMLInt(xmlFile, key.."#minOn"),100);
				str.maxOn = Utils.getNoNil(getXMLInt(xmlFile, key.."#maxOn"),100);
				str.minOff = Utils.getNoNil(getXMLInt(xmlFile, key.."#minOff"),100);
				str.maxOff = Utils.getNoNil(getXMLInt(xmlFile, key.."#maxOff"),400);
				str.random = true;
			end;

			math.randomseed(getDate("%d%m%y%H%M%S"));
			table.insert(self.LA.str, str);

			if str.index ~= nil then
				setVisibility(str.index, false);
			end;
		end;
		i = i + 1;
	end;
	self.LA.isParent = SpecializationUtil.hasSpecialization(Steerable, self.specializations);
	self.LA.isMotorStarted = false;
	self.LA.firstRun = true;
	self.LA.tmp = {};
	self.LA.isEntered = false;
end;

function LightAddon:delete()
end;

function LightAddon:mouseEvent(posX, posY, isDown, isUp, button)
end;

function LightAddon:keyEvent(unicode, sym, modifier, isDown)
end;

function LightAddon:update(dt)
	-- Run Strobes
	for _,str in ipairs(self.LA.str) do
		if str.isAcitve then
			if str.time > str.seqLen then
				str.seqActive = not str.seqActive;
				setVisibility(str.index, str.seqActive);
				str.time = 0;
				if str.random then
					if str.seqActive then
						str.seqLen = math.random(str.minOn, str.maxOn);
					else
						str.seqLen = math.random(str.minOff, str.maxOff);
					end;
				else
					str.seqNum = str.seqNum + 1;
					if str.seqNum > table.getn(str.sequence) then
						str.seqNum = 1;
					end;
					str.seqLen = str.sequence[str.seqNum];
				end;
			end;
			str.time = str.time + dt;
		else
			setVisibility(str.index, str.isAcitve);
		end;
	end;

	--Strobe Input
	if self:getIsActiveForInput(true) and not self:hasInputConflictWithSelection() then
		for i=1, table.getn(self.LA.str) do
			local str = self.LA.str[i];
			if  InputBinding.hasEvent(InputBinding[str.input]) then
				self:setState("strobe-"..i, not str.isAcitve);
			end;
		end;
	end;
end;

function LightAddon:updateTick(dt)
	if self.LA.isParent then -- only 1 mod needs to control everything
        if self:getIsActive() then
            if self.LA.beaconActive ~= self.beaconLightsActive then
                self:setState("beacon", self.beaconLightsActive);
            end;
        end;
--[[
        if self.turnSignals ~= nil then
            if self:getIsActive() then
                self.LA.turnState = self.turnSignalState;
                if self.LA.turnState ~= 3 and self.LA.turnState ~= 0 then --Reset turnlights after driving a curve
                    if math.abs(self.rotatedTime/self.maxRotTime) > self.LA.steerTresh then
                        self.LA.steerTreshReached = true;
                        if self.LA.debug and self.LA.debugLevel == 1 then
                            print("SteerTreshReached");
                        end;
                    end;

                    if self.LA.steerTreshReached and math.abs(self.rotatedTime) <= 0.1 then
                        if self.rotatedTime > 0 and self.LA.turnState == 1 then
                            self:setTurnSignalState(0, false);
                        elseif self.rotatedTime < 0 and self.LA.turnState == 2 then
                            self:setTurnSignalState(0, false);
                        end;
                        self.LA.steerTreshReached = false;
                    end;
                end;
            else
                if self.LA.turnState ~= self.turnSignalState then
                    self:setTurnSignalState(self.LA.turnState, true);
                end;
            end;
        end;
]]
        --Lights and drl
		-- TODO
	end;
end;

function LightAddon:draw()
    if g_currentMission.showHelpText and self.isClient and self:getIsActiveForInput(true) then
        for k, str in pairs(self.LA.helptexts) do
            g_currentMission:addHelpButtonText(str, InputBinding[k]);
        end
    end
end

function LightAddon:onAttach(attachedTo)
	self.LA.attachedVehicle = self:getRootAttacherVehicle();

	self.LA.turnState = self.LA.attachedVehicle.turnSignalState;
	self.LA.beaconActive = self.LA.attachedVehicle.beaconLightsActive;
    if self.setState ~= nil then
        self:setState("beacon", self.LA.beaconActive);
    end;
	self.LA.lightsTypesMask = self.LA.attachedVehicle.lightsTypesMask;
	if self.LA.attachedVehicle.LA ~= nil then
		self.LA.drlIsActive = self.LA.attachedVehicle.LA.drlIsActive;
	else
		self:setDRL();
	end;
	self:activate();
end;

function LightAddon:onDetach(detachedFrom)
	self.LA.attachedVehicle = nil;
	self:deactivate();



end;

function LightAddon:onDeactivate()
	
end;

function LightAddon:fixOnDeactivate()
	
end;

function LightAddon:onLeave()
	self.LA.isMotorStarted = self.isMotorStarted;
	self.LA.isEntered = false;
	self:setDRL();
end;

function LightAddon:deactivate()
	self.LA.turnState = 0;
	self.LA.beaconActive = false;
    self:setState("beacon", self.LA.beaconActive);
	self.LA.drlIsActive = false;
	for _,k in ipairs(self.LA.str) do
		k.isAcitve = false;
	end;

    if self.attachedImplements ~= nil then
        for _, k in ipairs(self.attachedImplements) do
            if k.object.deactivate ~= nil then
                k.object:deactivate();
            end;
        end;
    end;
end;

function LightAddon:onEnter()
	self.LA.isEntered = true;
	self:activate();
end;

function LightAddon:onActivate()
	--self:activate();
end;

function LightAddon:activate()
	
	--self:setDRL();
end;

function LightAddon:readStream(streamId, connection)
	if self.LA.hasDRL then
		self:setState("drl", streamReadBool(streamId), true);
	end;
	for i = 1,table.getn(self.LA.str) do
		if not self.LA.str[i].isBeacon then
			self:setState("strobe-" .. i, streamReadBool(streamId),true);
		else
			self:setState("beacon", streamReadBool(streamId),true);
		end;
	end;
end;

function LightAddon:writeStream(streamId, connection)
	if self.LA.hasDRL then
		streamWriteBool(streamId, self.LA.drlIsActive);
	end;
	for _,v in pairs(self.LA.str) do
		streamWriteBool(streamId, v.isAcitve);
	end;
end;

function LightAddon:setState(obj, state, noEventSend)
    if self.LA.debug then
        print("Set State called with "..tostring(self.configFileName));
    end;
	if obj == "beacon" then
		if self.LA.debug then
			print("Set State called on "..tostring(obj));
		end;
		self.LA.beaconActive = state;
		for _, str in ipairs(self.LA.str) do
			if str.isBeacon then
				str.isAcitve = state;
			end;
		end;
        if self.attachedImplements ~= nil then
            for _, k in ipairs(self.attachedImplements) do
                if k.object.setState ~= nil and k.object.LA ~= nil then
                    if self.LA.debug and self.LA.debugLevel == 2 then
                        print("SetState for "..tostring(k.object.configFileName));
                    end;
                    	k.object:setState("beacon", self.LA.beaconActive);
				end;
            end;
        end;
		return; --Needed to avoid that strobes which are beacons syncs two times.
	elseif obj == "turnLights" then
		if self.LA.debug then
			print("Set State called on "..tostring(obj));
		end;
		self.LA.turnState = state;
	elseif obj == "drl" then
		if self.LA.debug then
			print("Set State called on "..tostring(obj).. " State: " .. tostring(state));
		end;
		self.LA.drlIsActive = state;
		for _, v in ipairs(self.LA.drl) do
			setVisibility(v, self.LA.drlIsActive);
		end;
	elseif string.match(obj, "strobe.*") ~= nil then
		if self.LA.debug then
			print("Set State called on "..tostring(obj));
		end;
		local _,ind = unpack(Utils.splitString("-",obj));
		local index = tonumber(ind);
		self.LA.str[index].isAcitve = state;
	end;

	LightAddonEvent.sendEvent(self,obj,state,noEventSend);
end;

function LightAddon:testflag(set, flag)
	return set % (2*flag) >= flag;
end;

function LightAddon:setDRL(noEventSend)
	if self.LA.hasDRL then
		local b = self.LA.isMotorStarted and not LightAddon:testflag(self.LA.lightsTypesMask, 1);
		self:setState("drl", b, noEventSend);
	end;
end;


Vehicle.onDeactivate   = Utils.appendedFunction(Vehicle.onDeactivate, LightAddon.fixOnDeactivate);

LightAddonEvent = {};
LightAddonEvent_mt = Class(LightAddonEvent, Event);

InitEventClass(LightAddonEvent, "LightAddonEvent");

function LightAddonEvent:emptyNew()
	local self = Event:new(LightAddonEvent_mt);
	self.className="LightAddonEvent";
	return self;
end;

function LightAddonEvent:new(object, light, state)
	local self = LightAddonEvent:emptyNew()
	self.object = object;
	self.light = light;
	self.state = state;
	return self;
end;

function LightAddonEvent:readStream(streamId, connection)
	self.object = networkGetObject(streamReadInt32(streamId));
	self.light  = streamReadString(streamId);
	self.state = streamReadBool(streamId);
	self:run(connection);
end;

function LightAddonEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, networkGetObjectId(self.object));
	streamWriteString(streamId, self.light);
	streamWriteBool(streamId, self.state);
end;

function LightAddonEvent:run(connection)
	if self.object == nil then
		print("LightAddon: Sync Error on " .. tostring(self.light) .. " with state " .. tostring(self.state));
	end;
	if self.object.LA ~= nil then
		self.object:setState(self.light,self.state, true);
		if not connection:getIsServer() then
			g_server:broadcastEvent(LightAddonEvent:new(self.object, self.light, self.state), nil, connection, self.object);
		end;
	end;
end;

function LightAddonEvent.sendEvent(vehicle, light, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(LightAddonEvent:new(vehicle, light, state), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(LightAddonEvent:new(vehicle, light, state));
		end;
	end;
end;
