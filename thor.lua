-- [Dependincies] --

local shadowcraft

if fs.exists("/lib/shadowcraft/shadowcraft.lua") then
    shadowcraft = require("/lib/shadowcraft/shadowcraft")
    shadowcraft.printManifest(require("/lib/shadowcraft/manifest"))
else
    printError("Shadowcraft v1.1.16+ is required to run THOR.")
    return nil
end

-- [Objects] --

local service = {}

service = {
    programTypes = {
        ["funnel"] = {
            set = "setFunnelComputer",
            update = "updateFunnelComputer",
        },
        ["monitor"] = {
            set = "setMonitorComputer",
            update = "updateMonitorComputer",
        },
        ["sensor"] = {
            set = "setSensorComputer",
            update = "updateSensorComputer",
        },
        ["exit"] = {},
    },

    ports = {
        commandPort = 1338,
        sensorPort = 1337,
    },
    
    runService = {
        programType = "generic",
        halt = false,
    
        systemFrequency = 1,

        portTimeout = 10,
    },
    
    debug = {
        general = true,
        sensor = false,
        
        terminalCount = 0,
        terminalLimit = 11
    },

    wirelessNetwork = {
        modem = nil,
    },

    sensorNetwork = {
        modem = nil,
        readers = {},
        sensors = {},
    },

    funnelNetwork = {
        modem = nil,
        integrators = {},
    },

    monitor = {
        monitor = nil,
        width = nil,
        height = nil,
    },

    updateMain = function()
        if service.runService.programType == "exit" then return nil end

        service[service.programTypes[service.runService.programType].update]()
    end,

    updateFunnelComputer = function()
        parallel.waitForAll(
            function()
                repeat
                    if #service.sensorNetwork.sensors > 0 then
                        for i, sensor in pairs(service.sensorNetwork.sensors) do
                            if service.getSensorType(sensor.name) == "heatVent" then
                                for k = 0, 8 do
                                    if sensor.reader == "blockReader_" .. k+1 then
                                        if sensor.data.heat <= 100 then
                                            service.funnelNetwork.modem.callRemote("redstoneIntegrator_"..k, "setOutput", "top", false)
                                        else
                                            service.funnelNetwork.modem.callRemote("redstoneIntegrator_"..k, "setOutput", "top", true)
                                        end
                                    end
                                end
                            end
                        end
                    end 

                    sleep(1/service.runService.systemFrequency)
                until service.runService.halt == true
            end,
            function()
                repeat
                    local event, side, channel, replyChannel, data, distance
                    local timeoutCounter = 0
                    parallel.waitForAny(
                        function()
                            repeat
                                event, side, channel, replyChannel, data, distance = os.pullEvent("modem_message")
                            until channel == service.ports.sensorPort
                        end,
                        function()
                            repeat
                                timeoutCounter = timeoutCounter + 1
                                sleep(1/service.runService.systemFrequency)
                            until timeoutCounter >= service.runService.portTimeout
                        end
                    )
                    
                    if channel == service.ports.sensorPort then
                        service.sensorNetwork.sensors = data
                        service.printDebug(string.format("\n%s | Received sensor data.", shadowcraft.getDate()))
                    elseif timeoutCounter >= service.runService.portTimeout then
                        error(string.format("\n%s | Sensor payload missed.", shadowcraft.getDate()),0)
                    end

                    sleep(1/service.runService.systemFrequency)
                until service.runService.halt == true
            end
        )   
    end,

    updateMonitorComputer = function()
        parallel.waitForAll(
            function()
                repeat
                    service.monitor.monitor.clear()
                    service.monitor.monitor.setCursorPos(1, 1)
                    
                    local Date = shadowcraft.getDate()
                    service.monitor.monitor.setCursorPos(service.monitor.width/2 - string.len(Date)/2+1, 1)
                    service.monitor.monitor.write(string.format("%s", shadowcraft.getDate()))
                    
                    if #service.sensorNetwork.sensors > 0 then
                        local CoreHeatText = "CORE HEAT"
                        service.monitor.monitor.setCursorPos(service.monitor.width/2 - string.len(CoreHeatText)/2+1, 3)
                        service.monitor.monitor.write(CoreHeatText)
                        local CoreHeatValue = service.sensorNetwork.sensors[1]["data"]["heat"]
                        service.monitor.monitor.setCursorPos(service.monitor.width/2-string.len(CoreHeatValue)/2+1,4)
                        service.monitor.monitor.write(string.format("%.2f",CoreHeatValue))
                        
                        local CoreFuelText = "CORE FUEL"
                        service.monitor.monitor.setCursorPos(service.monitor.width/2-string.len(CoreFuelText)/2+1,6)
                        service.monitor.monitor.write(CoreFuelText)
                        local CoreFuelValue = service.sensorNetwork.sensors[1]["data"]["heat"]
                        service.monitor.monitor.setCursorPos(service.monitor.width/2-string.len(CoreFuelValue)/2+1,7)
                        service.monitor.monitor.write(string.format("%.2f",CoreFuelValue))
                        
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
                            service.monitor.monitor.setCursorPos(service.monitor.width/QUAD-string.len(VentHeatText)/2+1,9+Y*4)
                            service.monitor.monitor.write(VentHeatText)
                            local VentHeatValue = service.sensorNetwork.sensors[i+1]["data"]["heat"]
                            local VentExtractValue = service.sensorNetwork.sensors[i+1]["data"]["extract"]
                            local VentValue = string.format("%.2f/%.2f",VentHeatValue,VentExtractValue)
                            service.monitor.monitor.setCursorPos(service.monitor.width/QUAD-string.len(VentValue)/2+1,10+Y*4)
                            service.monitor.monitor.write(VentValue)
                        end
                    end 

                    sleep(1/service.runService.systemFrequency)
                until service.runService.halt == true
            end,
            function()
                repeat
                    local event, side, channel, replyChannel, data, distance
                    local timeoutCounter = 0
                    parallel.waitForAny(
                        function()
                            repeat
                                event, side, channel, replyChannel, data, distance = os.pullEvent("modem_message")
                            until channel == service.ports.sensorPort
                        end,
                        function()
                            repeat
                                timeoutCounter = timeoutCounter + 1
                                sleep(1/service.runService.systemFrequency)
                            until timeoutCounter >= service.runService.portTimeout
                        end
                    )
                    
                    if channel == service.ports.sensorPort then
                        service.sensorNetwork.sensors = data
                        service.printDebug(string.format("\n%s | Received sensor data.", shadowcraft.getDate()))
                    elseif timeoutCounter >= service.runService.portTimeout then
                        error(string.format("\n%s | Sensor payload missed.", shadowcraft.getDate()),0)
                    end

                    sleep(1/service.runService.systemFrequency)
                until service.runService.halt == true
            end
        )   
    end,

    updateSensorComputer = function()
        repeat
            service.updateSensorData()
            service.wirelessNetwork.modem.transmit(service.ports.sensorPort, service.ports.commandPort, service.sensorNetwork.sensors)
    
            service.printDebug(string.format("\n%s | Transmitting Sensor Data\nPort:%s\nSensors:%s", shadowcraft.getDate(), service.ports.sensorPort, #service.sensorNetwork.sensors))
            sleep(1/service.runService.systemFrequency)
        until service.runService.halt == true
    end,

    updateSensorData = function()        
        for i, sensor in pairs(service.sensorNetwork.sensors) do
            sensor.data = service.sensorNetwork.modem.callRemote(sensor.reader, "getBlockData")
        end
    end,

    setMain = function()
        if service.runService.programType == "exit" then return nil end

        service[service.programTypes[service.runService.programType].set]()
    end,

    setFunnelComputer = function()
        service.setWirelessModem()
        service.setFunnelNetwork()

        service.wirelessNetwork.modem.open(service.ports.sensorPort)
    end,

    setMonitorComputer = function()
        service.setWirelessModem()
        service.setMonitor()

        service.wirelessNetwork.modem.open(service.ports.sensorPort)
    end,

    setSensorComputer = function()
        service.setWirelessModem()
        service.setSensorNetwork()

        service.wirelessNetwork.modem.open(service.ports.commandPort)
    end,

    setProgramType = function()
        service.getProgramType()
    end,

    setMonitor = function()
        service.monitor.monitor = shadowcraft.getMonitor()

        if service.monitor.monitor == nil then return nil end

        service.monitor.width, service.monitor.height = service.monitor.monitor.getSize()
        
        service.monitor.monitor.clear()
        service.monitor.monitor.setCursorPos(1,1)
    end,

    setWirelessModem = function()
        service.wirelessNetwork.modem = shadowcraft.getWirelessModem()
    end,

    setFunnelNetwork = function()
        service.funnelNetwork.modem = shadowcraft.getWiredModem()

        shadowcraft.printFancy("yellow", "\nScanning Funnel Network for Integrators...\n")
        service.funnelNetwork.integrators = service.funnelNetwork.modem.getNamesRemote()
        
        shadowcraft.printFancy("green","\nIntegrators are complete.")
        return true
    end,

    setSensorNetwork = function()
        service.sensorNetwork.modem = shadowcraft.getWiredModem()

        shadowcraft.printFancy("yellow", "\nScanning Sensor Network for Readers...\n")
        service.sensorNetwork.readers = service.sensorNetwork.modem.getNamesRemote()
        
        for i, name in pairs(service.sensorNetwork.readers) do
            local sensor = {}
            
            sensor = {
                name = service.sensorNetwork.modem.callRemote(name, "getBlockName"),
                reader = name,
                type = service.getSensorType(service.sensorNetwork.modem.callRemote(name, "getBlockName")),
                data = service.sensorNetwork.modem.callRemote(name, "getBlockData"),
            }
            
            service.sensorNetwork.sensors[#service.sensorNetwork.sensors+1] = sensor
            
            if service.debug.general == true then
                print(string.format("%s > %s : %s", sensor.reader, sensor.name, sensor.type))
            end
        end
        
        shadowcraft.printFancy("green","\nReaders are complete.\nSensors are set.")
        return true
    end,

    getSensorType = function(sensorName)
        if string.find(sensorName, "rod") then
            return "rod"
        elseif string.find(sensorName, "heat_vent") then
            return "heatVent"
        else
            return nil
        end
    end,
    
    getProgramType = function()
        print("Choose one of the Program Types:\n")
        shadowcraft.printData(service.programTypes)
        print("Type exit to exit the program.")
        local programType = read()

        if service.programTypes[programType] == nil then
            printError("Stated Program Type does not exits. Please enter a valid Program Type.")
            print("Choose one of the Program Types:\n")
            shadowcraft.printData(service.programTypes)
            print("Type exit to exit the program.")

            service.getProgramType()
        else
            service.runService.programType = programType
        end
    end,

    printDebug = function(debug)
        if service.debug.general == true then
            if service.debug.terminalCount == service.debug.terminalLimit then
                term.clear()
                service.debug.terminalCount = 0
            end
            service.debug.terminalCount = service.debug.terminalCount + 1
            print(debug)
        end
    end,
}

-- [Setup] --

service.setProgramType()
service.setMain()

-- [Update] --

service.updateMain()

return service