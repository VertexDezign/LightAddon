-- GrisuDebug
--
-- @author  Grisu118 - VertexDezign.net
-- @history		v1.0 	- 2016-10-26 - Initial implementation
-- @Descripion: Providing debug utils
-- @web: http://grisu118.ch or http://vertexdezign.net
-- Copyright (C) Grisu118, All Rights Reserved.
GrisuDebug = {}
GrisuDebug.__index = GrisuDebug

GrisuDebug.TRACE = 1;
GrisuDebug.DEBUG = 2;
GrisuDebug.INFO = 3;
GrisuDebug.WARNING = 4;
GrisuDebug.ERROR = 5;

function GrisuDebug:create(name, id)
    local d = {}-- our new object
    setmetatable(d, GrisuDebug)-- make Account handle lookup
    d.name = name -- initialize our object
    d.id = id
    d.lvl = GrisuDebug.DEBUG
    return d
end

function GrisuDebug:setLogLvl(lvl)
    self.lvl = lvl
end

function GrisuDebug:print(lvl, txt)
    if lvl < self.lvl then
        return
    end
    local level = "TRACE"
    if lvl == GrisuDebug.ERROR then
        level = "ERROR"
    elseif lvl == GrisuDebug.WARNING then
        level = "WARN"
    elseif lvl == GrisuDebug.INFO then
        level = "INFO"
    elseif lvl == GrisuDebug.DEBUG then
        level = "DEBUG"
    end
    
    if (self.id == nil) then
        print(self.name .. " - " .. level .. ": " .. txt)
    else
        print(self.name .. " - " .. level .. ": (" .. id .. " - " .. getName(id) .. ") " .. txt)
    end
end
