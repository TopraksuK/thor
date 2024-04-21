-- Author: Topraksu
-- Date: 20/04/2024
-- Purpose: Reading and transmitting heat and fuel readings of the 3x3x3 Thorium reactor.
-- Notes: Uses the 1337 and 1338 ports for transmitting reading data and receiving remote directories.

local Service = {}

-- [Dependincies] --

if fs.exists("/shadowork/") then else printError("Shadowork 1.0.0+ is required.") return nil end

local PrintService = require("/shadowork/services/print")

-- [Objects] --

local SensorNetwork = peripheral.find("modem", function(name, modem) return not modem.isWireless() end)
local Modem = peripheral.find("modem", function(name, modem) return modem.isWireless() end)

local Sensors = {}

-- [Variables] --

local SensorPort = 1337
local CommandPort = 1338

local SystemFrequency = 1
local Debug = true
local DebugSensor = false

local TerminalCount = 0
local TerminalMaximum = 11

local Halt = false

-- [Functions] --

Service = {
    TransmitData = function()
        if Modem == nil then
            error(string.format("\n%s | Program terminated: Wireless Modem lost.",PrintService.Date()),0)
            Halt = true
            return nil
        end
    
        Service.UpdateSensors()
        Modem.transmit(SensorPort,CommandPort,Sensors)
        
        if Debug == true then
            if TerminalCount == TerminalMaximum then
                term.clear()
                TerminalCount = 0
            end
            TerminalCount = TerminalCount + 1
            print(string.format("\n%s | Transmitting Sensor Data\nPort:%s\nSensors:%s",PrintService.Date(),SensorPort,#Sensors))
        end
    end,
    
    UpdateSensors = function()
        if SensorNetwork == nil then
            error(string.format("\n%s | Program terminated: Reader Network lost.",PrintService.Date()),0)
            Halt = true
            return nil
        end
        
        for i, sensor in pairs(Sensors) do
            sensor.Data = SensorNetwork.callRemote(sensor.Reader,"getBlcokData")
        end
        
        if DebugSensor == true then
            Service.PrintSensors()
        end
    end,

    SetModem = function()
        PrintService.printFancy("yellow","\nLooking for a Wireless Modem...")
        Modem = peripheral.find("modem", function(name, modem) return modem.isWireless() end)
        
        if Modem == nil then  
            Halt = true
            return nil
        end
    
        Modem.open(SensorPort)
        PrintService.printFancy("green", "\nWireless Modem is set.")
    end,

    SetSensorNetwork = function()
        PrintService.printFancy("yellow","\nChecking Sensor Network...\n")
        
        if Network == nil then 
            printError("Sensor network not found.") 
            Halt = true
            return nil 
        else
            PrintService.printFancy("green","\nSensor Network found.")
        end
    
        local ReaderNames = Network.getNamesRemote()
        
        for i, name in pairs(ReaderNames) do
            local Sensor = {}
            
            Sensor = {
                Name = Network.callRemote(name,"getBlockName"),
                Reader = name,
                Type = Service.GetSensorType(Network.callRemote(name,"getBlockName")),
                Data = Network.callRemote(name, "getBlockData"),
            }
            
            Sensors[#Sensors+1] = Sensor
            
            if Debug == true then
                print(string.format("%s > %s : %s", Sensor.Reader,Sensor.Name,Sensor.Type))
            end
        end
        
        PrintService.printFancy("green","\nReading complete\nSensors are set")
        
        return true
    end,
    
    GetSensorType = function(name)
        if string.find(name, "rod") then
            return "rod"
        elseif string.find(name, "heat_vent") then
            return "heatVent"
        else
            return nil
        end
    end,
    
    PrintSensors = function(speed)
        speed = speed or 0
        for i, sensor in pairs(Sensors) do
            print("\n"..i,":")
            PrintService.printData(sensor)
            if speed <= 0 then ::continue:: end
            sleep(speed)
        end
    end,
}

-- [Setup] --

print("Launching Reactor Sensors")

Service.SetSensorNetwork()
Service.SetModem()
--Service.PrintSensors()

-- [Update] --

if Halt == true then
    error("\nProgram terminated due to halt command. Press any key to continue.",0)
    return nil
end

repeat
    Service.TransmitdData()
    sleep(1/SystemFrequency)
until Halt == true

