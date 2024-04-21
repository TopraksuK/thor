-- Author: Topraksu
-- Date: 20/04/2024
-- Purpose: The main monitor computer for printing reactor values.
-- Notes: Uses port 1338 to command other computers

local Service = {}

-- [Dependincies] --

if fs.exists("/shadowork/") then else printError("Shadowork 1.0.0+ is required.") return nil end

local PrintService = require("/shadowork/services/print")

-- [Objects] --

local Monitor = peripheral.find("monitor")
local Modem = peripheral.find("modem",function(name,modem) return modem.isWireless() end)

local MonitorWidth, MonitorHeight

local SensorData = {}

-- [Variables] --

local CommandPort = 1338
local SensorPort = 1337

local PortTimeout = 10

local SystemFrequency = 1
local Debug = false

local Halt = false

-- [Functions] --

Service = {
    RenderSensorData = function()
        Monitor.clear()
        Monitor.setCursorPos(1,1)
        
        local Date = PrintService.Date()
        Monitor.setCursorPos(MonitorWidth/2-string.len(Date)/2+1,1)
        Monitor.write(string.format("%s",PrintService.Date()))
        
        if #SensorData <= 0 then return nil end
        
        local CoreHeatText = "CORE HEAT"
        Monitor.setCursorPos(MonitorWidth/2-string.len(CoreHeatText)/2+1,3)
        Monitor.write(CoreHeatText)
        local CoreHeatValue = SensorData[1]["Data"]["heat"]
        Monitor.setCursorPos(MonitorWidth/2-string.len(CoreHeatValue)/2+1,4)
        Monitor.write(CoreHeatValue)
        
        local CoreFuelText = "CORE FUEL"
        Monitor.setCursorPos(MonitorWidth/2-string.len(CoreFuelText)/2+1,6)
        Monitor.write(CoreFuelText)
        local CoreFuelValue = SensorData[1]["Data"]["heat"]
        Monitor.setCursorPos(MonitorWidth/2-string.len(CoreFuelValue)/2+1,7)
        Monitor.write(CoreFuelValue)
        
        for i = 1, 9 do
            local X = i%3
            local Y = math.floor((i-1)/3)
            
            local QUAD
            if X == 1 then
                QUAD = 6
            elseif X == 2 then
                QUAD = 2
            elseif X == 0 then
                QUAD = 6/5
            end
        
            local VentHeatText = string.format("VENT-%s H/O",i)
            Monitor.setCursorPos(MonitorWidth/QUAD-string.len(VentHeatText)/2+1,9+Y*4)
            Monitor.write(VentHeatText)
            local VentHeatValue = SensorData[i+1]["Data"]["heat"]
            local VentExtractValue = SensorData[i+1]["Data"]["extract"]
            local VentValue = string.format("%s/%s",VentHeatValue,VentExtractValue)
            Monitor.setCursorPos(MonitorWidth/QUAD-string.len(VentValue)/2+1,10+Y*4)
            Monitor.write(VentValue)
        end
    end,   
    
    ReceiveData = function()
        if Modem == nil then
            error(string.format("\n%s | Program terminated: Wireless Modem lost.",PrintService.Date()),0)
            Halt = true
            return nil
        end
        
        if not Modem.isOpen(SensorPort) then printError(string.format("Defined port for sensor (%s) is not opened.",SensorPort)) return nil end
        
        local Event, Side, Channel, ReplyChannel, Data, Distance
        local TimeoutCounter = 0
        repeat
            Event, Side, Channel, ReplyChannel, Data, Distance = os.pullEvent("modem_message")
            TimeoutCounter = TimeoutCounter + 1
        until Channel == SensorPort or TimeoutCounter == PortTimeout
        
        if Channel == SensorPort then
            SensorData = Data
            if Debug == true then
                print(string.format("\n%s | Received sensor data.",PrintService.Date()))
            end    
        elseif TimeoutCounter >= PortTimeout then
            error(string.format("\n%s | Sensor payload missed.",PrintService.Date()),0)
        end
    end,

    SetMonitor = function()
        PrintService.printFancy("yellow","\nLooking for a Monitor...")
        Monitor = peripheral.find("monitor")
        
        if Monitor == nil then 
            printError("\nMonitor not found. Monitoring the reactor values is crucial for survival.") 
            return nil 
        else
            PrintService.printFancy("green", string.format("\nMonitor found.", Monitor.getSize()))
        end
        
        MonitorWidth, MonitorHeight = Monitor.getSize()
        
        print(string.format("Monitor Size: %sx%s",MonitorWidth,MonitorHeight))
        
        Monitor.clear()
        Monitor.setCursorPos(1,1)
    end,
    
    SetModem = function()
        PrintService.printFancy("yellow","\nLooking for a Wireless Modem...")
        Modem = peripheral.find("modem",function(name,modem) return modem.isWireless() end)
        
        if Modem == nil then
            printError("\nWireless Modem not found.")
            Halt = true
            return nil            
        end
        
        Modem.open(SensorPort)
        print(string.format("\nPort:%s is open for sensor reading.",SensorPort))
        PrintService.printFancy("green","\nWireless Modem is all set.")
    end,
}

-- [Setup] --

print("Launching Reactor Monitoring")

Service.SetMonitor()
Service.SetModem()

-- [Update] --

if Halt == true then
    error("\nProgram terminated due to halt command. Press any key to continue.",0)
    return nil
end

parallel.waitForAll(
    function()
        repeat
            Service.ReceiveData()
            sleep(1/SystemFrequency)
        until Halt == true
    end,
    function()
        repeat
            Service.RenderSensorData()
            sleep(1/SystemFrequency)
        until Halt == true
    end
)


