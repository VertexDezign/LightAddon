-- LAFix
--
-- @author  Grisu118 - VertexDezign.net
-- @history		v1.0 - 2014-11-11 - Initial implementation
--				v1.1 - Improvements from Xentro
--              v1.2 - isSelectable
--				v2.0 - FS17
-- @Descripion: Fix for Helptexts of LightAddon
-- @web: http://grisu118.ch or http://vertexdezign.net
-- Copyright (C) Grisu118, All Rights Reserved.

LAFix = {};
function LAFix.prerequisitesPresent(specializations)
    return true;
end;

function LAFix:load(xmlFile)
	local i = 0;
    while true do
        local key = string.format("vehicle.LightAddon.strobe(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		local n = getXMLString(xmlFile, key .. "#name");
		if n ~= nil then
			local x,_ = Utils.getModNameAndBaseDirectory(self.configFileName);
			g_i18n.globalI18N.texts[x..n] = g_i18n:getText(n);
		end;
		i = i + 1;
	end;
	--self.isSelectable = true;
    self.LAFixVersion = 2.0;
end;

function LAFix:delete()
end;

function LAFix:mouseEvent(posX, posY, isDown, isUp, button)
end;

function LAFix:keyEvent(unicode, sym, modifier, isDown)
end;

function LAFix:update(dt)
end;

function LAFix:updateTick(dt)
end;

function LAFix:draw()
end;