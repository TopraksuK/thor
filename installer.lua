url = "https://github.com/TopraksuK/shadowcraft/releases/latest/download/"

local manifestContentRequest = http.get(url .. "manifest.lua")
local manifestContent = manifestContentRequest.readAll()
manifestContentRequest.close()

if not manifestContent then
    printError("Could not connect to the URL website and fetch manifest.")
    return false
end

fs.makeDir("/tempInstall/")

local tempManifestFile = fs.open("/tempInstall/manifest.lua", "w")
tempManifestFile.write(manifestContent)
tempManifestFile.close()

local tempManifest = require("/tempInstall/manifest")

local installationDirectory = tempManifest.directory

if fs.exists(installationDirectory) then
    local installedManifest = require(installationDirectory .. "manifest")

    if tempManifest.version == installedManifest.version then
        print(string.format("\n%s is installed and up to date.", installedManifest.name))
        fs.delete("/tempInstall/")
        return true
    else
        print(string.format("\nA new release for %s is found.\nVersion: %s > %s\nWould you like to install it? (y/n)", installedManifest.name, installedManifest.version, tempManifest.version))
        local answer = service.getAnswer()

        if not answer then
            fs.delete("/tempInstall/")
            return true
        end

        fs.delete(tempManifest.directory)
    end
else
    print(string.format("\n%s is going to be installed.\nVersion: %s\nWould you like to install it? (y/n)", tempManifest.name, tempManifest.version))
    local answer = service.getAnswer()

    if not answer then
        fs.delete("/tempInstall/")
        return false
    end
end
    
fs.delete(installationDirectory)

for i, content in pairs(tempManifest.files) do
    local download = http.get(url .. content[1]).readAll()
    local installation = fs.open(tempManifest.directory .. content[2] .. content[1], "w")
    installation.write(download)
    installation.close()
end

fs.delete("/tempInstall/")

service.printFancy("green",string.format("\n%s %s successfully installed.", tempManifest.name, tempManifest.version))