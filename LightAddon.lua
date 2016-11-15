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
--              v2.0.1    - 2016-11-14 - Fix Patch 1.3, Fix turnlight reset for steering wheels
-- @Descripion: Extends the standart FS Lights with additional Functions
-- @web: http://grisu118.ch or http://vertexdezign.net
-- Copyright (C) Grisu118, All Rights Reserved.
--[[ XML Structure
<LightAddon drlAllwaysOn="false">
<drl decoration="" realLight=""/>
<strobe decoration="" realLight="" isBeacon="false" name="" sequence="" invert="" minOn="" maxOn="" minOff="" maxOff="" />
</LightAddon>

]]
LightAddon = {}
function LightAddon:prerequisitesPresent(specializations)
    return true
end

function LightAddon:load(savegame)
    self.setState = SpecializationUtil.callSpecializationsFunction("setState")
    self.setBeaconLightsVisibility   = Utils.appendedFunction(self.setBeaconLightsVisibility, LightAddon.setBeaconLightsVisibility)
    self.startMotor = Utils.appendedFunction(self.startMotor, LightAddon.startMotor)
    self.stopMotor = Utils.appendedFunction(self.stopMotor, LightAddon.stopMotor)
    self.setLightsTypesMask = Utils.appendedFunction(self.setLightsTypesMask, LightAddon.setLightsTypesMask)

    self.LA = {}
    
    local x, y = Utils.getModNameAndBaseDirectory(self.configFileName)
    self.LA.modName = x
    
    self.LA.debugger = GrisuDebug:create("LightAddon (" .. tostring(self.configFileName) .. ")")
	self.LA.debugger:setLogLvl(GrisuDebug.INFO)
    self.LA.debugger:print(GrisuDebug.TRACE, "load(xml)")

    --Turn Signals
	self.LA.steerTresh = 0.3
    
    --BeaconLights
    self.LA.beaconActive = false
    self.LA.hasBeacons = #self.beaconLights > 0
    
    
    --DayDriveLight drl
    self.LA.drl = {}
    self.LA.drlIsActive = false
    self.LA.hasDRL = false

    self.LA.drlAllwaysOn = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.LightAddon#drlAllwaysOn"), false)

    local i = 0
    while true do
        local key = string.format("vehicle.LightAddon.drl(%d)", i)
        if not hasXMLProperty(self.xmlFile, key) then
            break
        end
        local drl = {}
        drl.decoration = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#decoration"))
        drl.realLight = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#realLight"))
        if drl.decoration ~= nil then
            table.insert(self.LA.drl, drl)
            self.LA.hasDRL = true
            setVisibility(drl.decoration, false)
            if drl.realLight ~= nil then
                setVisibility(drl.realLight, false)
            end
        end
        i = i + 1
    end
    
    --Strobes
    self.LA.str = {}
    self.LA.helptexts = {}
    local i = 0
    local lafixwarning = false
    while true do
        local key = string.format("vehicle.LightAddon.strobe(%d)", i)
        if not hasXMLProperty(self.xmlFile, key) then
            break
        end
        local str = {}
        local error = false
        str.decoration = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#decoration"))
        str.realLight = Utils.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#realLight"))
        if str.decoration ~= nil then
            str.isBeacon = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#isBeacon"), true)
            str.isAcitve = false
            str.time = 1 --actual timer
            str.seqLen = 0 --how long sequence is
            str.seqActive = false
            if not str.isBeacon then
                local name = getXMLString(self.xmlFile, key .. "#name")
                
                if name ~= nil and self.configFileName ~= nil and g_i18n:hasText(self.configFileName .. name) then
                    str.name = self.configFileName .. name
                    str.input = name
                    self.LA.helptexts[name] = g_i18n:getText(str.name)
                    self.LA.debugger:print(GrisuDebug.DEBUG, "HelpText: " .. tostring(self.LA.helptexts[name]))
                    if InputBinding[str.input] == nil then
                        self.LA.debugger:print(GrisuDebug.ERROR, "no input defined for " .. name)
                        error = true
                    end
                    if not lafixwarning and (self.LAFixVersion == nil or self.LAFixVersion < 2.0) then
                        self.LA.debugger:print(GrisuDebug.WARNING, "Newer LAFix.lua available!")
                        lafixwarning = true
                    end
                end
            end
            local sequence = getXMLString(self.xmlFile, key .. "#sequence")
            if sequence ~= nil then
                str.sequence = {Utils.getVectorFromString(sequence)}
                str.invert = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#invert"), false)
                str.seqActive = str.invert
                str.random = false
                str.seqNum = 0
            else
                str.minOn = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#minOn"), 100)
                str.maxOn = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#maxOn"), 100)
                str.minOff = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#minOff"), 100)
                str.maxOff = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#maxOff"), 400)
                str.random = true
            end
            
            if not error then
                table.insert(self.LA.str, str)
            end
            setVisibility(str.decoration, false)
            if str.realLight ~= nil then
                setVisibility(str.realLight, false)
            end
        end
        i = i + 1
    end
    
    math.randomseed(getDate("%d%m%y%H%M%S"))
end

function LightAddon:delete()
end

function LightAddon:mouseEvent(posX, posY, isDown, isUp, button)
end

function LightAddon:keyEvent(unicode, sym, modifier, isDown)
end

function LightAddon:update(dt)
    -- Run Strobes
    local realBeaconLights = g_gameSettings:getValue("realBeaconLights")
    for _, str in ipairs(self.LA.str) do
        if str.isAcitve then
            if str.time > str.seqLen then
                str.seqActive = not str.seqActive
                setVisibility(str.decoration, str.seqActive)
                if  realBeaconLights and str.realLight ~= nil then
                    setVisibility(str.realLight, str.seqActive)
                end
                str.time = 0
                if str.random then
                    if str.seqActive then
                        str.seqLen = math.random(str.minOn, str.maxOn)
                    else
                        str.seqLen = math.random(str.minOff, str.maxOff)
                    end
                else
                    str.seqNum = str.seqNum + 1
                    if str.seqNum > table.getn(str.sequence) then
                        str.seqNum = 1
                    end
                    str.seqLen = str.sequence[str.seqNum]
                end
            end
            str.time = str.time + dt
        else
            setVisibility(str.decoration, str.isAcitve)
            if  realBeaconLights and str.realLight ~= nil then
                setVisibility(str.realLight, str.isAcitve)
            end
        end
    end
    
    --Strobe Input
    if self:getIsActiveForLights() then --and not self:hasInputConflictWithSelection() then
        for i = 1, table.getn(self.LA.str) do
            local str = self.LA.str[i]
            if InputBinding.hasEvent(InputBinding[str.input]) then
                self:setState("strobe-" .. i, not str.isAcitve)
            end
        end
    end

    if self:getIsActive() and self.turnLights ~= nil and self.steering then
        if self.turnLightState ~= Lights.TURNLIGHT_HAZARD and self.turnLightState ~= Lights.TURNLIGHT_OFF then --Reset turnlights after driving a curve
            local _,y,_ = getRotation(self.steering)           
            if self.LA.steerTreshReached then
                if math.abs(y) <= 0.001 then
                    self.LA.steerTreshReached = false
                    self:setTurnLightState(Lights.TURNLIGHT_OFF, false)
                    self.LA.debugger:print(GrisuDebug.TRACE, "steerTreshReached")
                end
            elseif self.turnLightState == Lights.TURNLIGHT_LEFT then
                self.LA.steerTreshReached =  y > self.LA.steerTresh
            elseif self.turnLightState == Lights.TURNLIGHT_RIGHT then
                self.LA.steerTreshReached =  y < -self.LA.steerTresh
            end
        end
    end
end

function LightAddon:updateTick(dt)

end

function LightAddon:draw()
    if self.isClient and self:getIsActiveForLights() then
        for k, str in pairs(self.LA.helptexts) do
            g_currentMission:addHelpButtonText(str, InputBinding[k])
        end
    end
end

function LightAddon:setBeaconLightsVisibility(visibility, force, noEventSend)
    self.LA.debugger:print(GrisuDebug.TRACE, "setBeaconLightsVisibility(" .. tostring(visibility) .. ", " .. tostring(force) .. ", ".. tostring(noEventSend) .. ")")
    self:setState("beacon", visibility)
end

function LightAddon:startMotor(noEventSend)
    self.LA.debugger:print(GrisuDebug.TRACE, "startMotor(" .. tostring(noEventSend) .. ")")
    local state = self.LA.drlAllwaysOn or ( not self.LA.drlAllwaysOn and self.lightsTypesMask == 0)
    self:setState("drl", state, true)
end

function LightAddon:stopMotor(noEventSend)
    self.LA.debugger:print(GrisuDebug.TRACE, "stopMotor(" .. tostring(noEventSend) .. ")")
    self:setState("drl", false, true)
end

function LightAddon:setLightsTypesMask(lightsTypesMask, force, noEventSend)
    self.LA.debugger:print(GrisuDebug.TRACE, "setLightsTypesMask(" .. tostring(lightsTypesMask) .. ", " .. tostring(force) .. ", ".. tostring(noEventSend) .. ")")
    if not self.LA.drlAllwaysOn and self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
        if self.lightsTypesMask == 0 then
            self:setState("drl", true, true)
        else
            self:setState("drl", false, true)
        end

    end
end

function LightAddon:setState(obj, state, noEventSend)
    self.LA.debugger:print(GrisuDebug.TRACE, "setState(" .. tostring(obj) .. ", " .. tostring(state) .. ", " .. tostring(noEventSend) .. " ) called with " .. tostring(self.configFileName))
    if obj == "beacon" then
        for _, str in ipairs(self.LA.str) do
            if str.isBeacon then
                str.isAcitve = state
            end
        end
        return --Needed to avoid that strobes which are beacons syncs two times.
    elseif obj == "drl" then

        self.LA.drlIsActive = state
        for _, v in ipairs(self.LA.drl) do
            setVisibility(v.decoration, self.LA.drlIsActive)
            if v.realLight ~= nil then
                setVisibility(v.realLight, self.LA.drlIsActive and self:getUseHighProfile())
            end
        end
    elseif string.match(obj, "strobe.*") ~= nil then
        local _, ind = unpack(Utils.splitString("-", obj))
        local index = tonumber(ind)
        self.LA.str[index].isAcitve = state
    end
    if noEventSend == nil or noEventSend == false then
        LightAddonEvent.sendEvent(self, obj, state, noEventSend)
    end
end

function LightAddon:readStream(streamId, connection)
    if self.LA.hasDRL then
        self:setState("drl", streamReadBool(streamId), true)
    end
    for i = 1, table.getn(self.LA.str) do
        if not self.LA.str[i].isBeacon then
            self:setState("strobe-" .. i, streamReadBool(streamId), true)
        else
            self:setState("beacon", streamReadBool(streamId), true)
        end
    end
end

function LightAddon:writeStream(streamId, connection)
    if self.LA.hasDRL then
        streamWriteBool(streamId, self.LA.drlIsActive)
    end
    for _, v in pairs(self.LA.str) do
        streamWriteBool(streamId, v.isAcitve)
    end
end

LightAddonEvent = {}
LightAddonEvent_mt = Class(LightAddonEvent, Event)

InitEventClass(LightAddonEvent, "LightAddonEvent")

function LightAddonEvent:emptyNew()
    local self = Event:new(LightAddonEvent_mt)
    self.className = "LightAddonEvent"
    return self
end

function LightAddonEvent:new(object, light, state)
    local self = LightAddonEvent:emptyNew()
    self.object = object
    self.light = light
    self.state = state
    return self
end

function LightAddonEvent:readStream(streamId, connection)
    self.object = networkGetObject(streamReadInt32(streamId))
    self.light = streamReadString(streamId)
    self.state = streamReadBool(streamId)
    self:run(connection)
end

function LightAddonEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.object))
    streamWriteString(streamId, self.light)
    streamWriteBool(streamId, self.state)
end

function LightAddonEvent:run(connection)
    if self.object == nil then
        print("LightAddon: Sync Error on " .. tostring(self.light) .. " with state " .. tostring(self.state))
    end
    if self.object.LA ~= nil then
        self.object:setState(self.light, self.state, true)
        if not connection:getIsServer() then
            g_server:broadcastEvent(LightAddonEvent:new(self.object, self.light, self.state), nil, connection, self.object)
        end
    end
end

function LightAddonEvent.sendEvent(vehicle, light, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(LightAddonEvent:new(vehicle, light, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(LightAddonEvent:new(vehicle, light, state))
        end
    end
end
