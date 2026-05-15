# Plugins
Lightweight, easy-to-use custom plugin manager.

# Examples

* API<br>
In the example shown, the plugin maker will be able to access the service by simply typing ```Services.Players```
```
--Services.luau

local Players = game:GetService("Players")

return {
    ["Players"] = {
        GetPlayer = function(searchProperty, propertyValue)
            local playersFound = {}
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player[searchProperty] == propertyValue then table.insert(playersFound, player) end
            end

            return if #playersFound == 1 then playersFound[1] else playersFound
        end
    }
}
```

* Plugin Loading<br>
Author and Name are generally suggested if you plan on debugging or using ```import()```
```
--PluginHandler.luau

PluginExecutor.ReloadAPI()

local newPlugin = PluginExecutor.new({
    Name = "TestPlugin",
    Author = "User" -- if nil, uses "Unknown Publisher",
    PluginCode = ""
})

newPlugin:Init()
newPlugin:Start()
```

* Plugin
```
--Plugin.init.luau

plugin.Start:Wait()

if plugin.ImportsAllowed and plugin.ExportsAllowed then
    plugin.Stop:Fire()
end

import("User/TestPlugin")

export({
    Division = function(a, b)
        return a / b
    end
})
```
