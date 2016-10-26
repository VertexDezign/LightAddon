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
<LightAddon drlAllwaysOn="false">
	<drl decoration="" realLight=""/>
	<strobe decoration="" realLight="" isBeacon="false" name="" sequence="" invert="" minOn="" maxOn="" minOff="" maxOff="" />
</LightAddon>

]]

LightAddon = {}
function LightAddon:prerequisitesPresent(specializations)
	return true
end

function LightAddon:load(xmlFile)
    self.LA = {}

    local x,y = Utils.getModNameAndBaseDirectory(self.configFileName)
	self.LA.modName = x

    self.LA.debugger = GrisuDebug:create("LightAddon (" .. self.LA.modName .. ")")
    self.LA.debugger:printLog(GrisuDebug.TRACE, "load(xml)")

    --BeaconLights
	self.LA.beaconActive = false
	self.LA.hasBeacons = #self.beaconLights > 0

    --DayDriveLight drl
	self.LA.drl = {}
	self.LA.drlIsActive = false
	self.LA.hasDRL = false
	local i = 0
	while true do
		local key = string.format("vehicle.LightAddon.drl(%d)", i)
		if not hasXMLProperty(xmlFile, key) then
			break
		end
        local drl = {}
		drl.decoration = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#decoration"))
        drl.realLight = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#realLight"))
		if drl.decoration ~= nil then
			table.insert(self.LA.drl, drl)
			self.LA.hasDRL = true
			setVisibility(drl.decoration, false)
            setVisibility(drl.realLight, false)
		end
		i = i + 1
	end
end

function LightAddon:delete()
end

function LightAddon:mouseEvent(posX, posY, isDown, isUp, button)
end

function LightAddon:keyEvent(unicode, sym, modifier, isDown)
end

function LightAddon:update(dt)

end

function LightAddon:updateTick(dt)

end

function LightAddon:draw()

end


