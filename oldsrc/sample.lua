-- Author: Topraksu
-- Date: d/m/y
-- Purpose:
-- Notes:

local Service = {}

-- [Dependincies] --

if fs.exists("/shadowork/") then else printError("Shadowork 1.0.0+ is required.") return nil end

local PrintService = require("/shadowork/services/print")

-- [Objects] --

local Peripheral = peripheral.find("name", function(name, modem) return not modem.isWireless() end)

-- [Variables] --

local CommandPort = 1338

local SystemFrequency = 1
local Debug = true

local Halt = false

-- [Functions] --

Service = {
}

-- [Setup] --

print("Launching Reactor Control")

-- [Update] --

repeat
    sleep(1/SystemFrequency)
until Halt == true

