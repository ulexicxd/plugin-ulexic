# Plugin

A lightweight, sandboxed plugin system for Roblox that allows for modular code execution, dynamic API injection, and inter-plugin communication via imports/exports.

## Features

- **Sandboxed Execution**: Runs plugin code within a custom environment using `loadstring`.
- **Inter-Plugin Communication**: Built-in `import()` and `export()` functions to share functionality between loaded plugins.
- **Lifecycle Events**: Signals for `Init`, `Start`, and `Stop` phases.
- **Dynamic API**: Automatically loads and injects modules from an API folder into the plugin's global environment.
- **Dependency Management**: Uses a namespace system (`Author/Name`) for indexing and retrieving loaded plugins.

## Prerequisites

To use this system, you must enable the following in your Game Settings:
1. **Allow HTTP Requests** (Required for GUID generation).
2. **Enable LoadStringEnabled** in `ServerScriptService`.

## Installation

1. Place the main script in your project.
2. Create an `API` folder containing the ModuleScripts you want to expose to your plugins.
3. Create a `Packages` folder containing a `Signal` module (e.g., FastSignal or GoodSignal).

## Usage

### 1. Initializing the System
```lua
local PluginSystem = require(path.to.Plugin)

-- Load the API modules
PluginSystem.ReloadAPI()

-- Create a new plugin instance
local myPlugin = PluginSystem.new({
    Name = "MyCoolPlugin",
    Author = "DevName",
    PluginCode = [[
        print("Plugin initialized!")
        
        -- Exporting functions for other plugins
        export({
            SayHello = function() print("Hello from MyCoolPlugin!") end
        })
        
        -- Listening to lifecycle events
        plugin.Start:Connect(function()
            print("Plugin started!")
        end)
    ]]
})

myPlugin:Init()
myPlugin:Start()