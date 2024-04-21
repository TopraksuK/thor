-- [Dependincies] --

local shadowcraft

if fs.find("shadowcraft") then
    shadowcraft = require("shadowcraft")
else
    error("Shadowcraft v1.0.1+ is required to run THOR.")
end

-- [Objects] --

local service = {}

service = {
    manifest = {
        name = "THOR",
        version = "v1.0.0",
        directory = "/thor/",
    },

    programTypes = {
        ["sensor"] = {
            set = "setSensorComputer",
            update = "updateSensorComputer",
        }
    },

    ports = {
        commandPort = 1338,
        sensorPort = 1337,
    },
    
    runService = {
        programType = "generic",
        halt = false,
    
        systemFrequency = 1
    },
    
    debug = {
        general = true,
        sensor = false,
    
        terminal = 11
    },

    wirelessNetwork = {
        modem = nil,
    },

    sensorNetwork = {
        modem = nil,
        readers = {},
        sensors = {},
    },

    updateSensorComputer = function()

    end,

    setSensorComputer = function()
        service.setWirelessModem()
        service.setSensorNetwork()
    end,

    setWirelessModem = function()
        service.wirelessNetwork.modem = shadowcraft.getWirelessModem()
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
                type = service.GetSensorType(service.sensorNetwork.modem.callRemote(name, "getBlockName")),
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
        if string.find(name, "rod") then
            return "rod"
        elseif string.find(name, "heat_vent") then
            return "heatVent"
        else
            return nil
        end
    end,
    
    getRunService = function()
        local programType = read()

        if service.programTypes[programType] == nil then
            error("Stated Program Type does not exits. Please enter a valid Program Type.")
            print("Choose one of the run services:\n")
            shadowcraft.printData(service.programTypes)
            
            service.getRunService()
        else
            service.runService.programType = programType
        end
    end,
}

-- [Setup] --

shadowcraft.printManifest(service.manifest)
shadowcraft.getRunService()

-- [Update] --

