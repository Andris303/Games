--!optimize 2
--!strict

if game.GameId == 7326934954 then

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/okdude42/ui-lib/refs/heads/main/SevereLib.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local FilterNames = {}
local FilterTags = {}
local ItemCache = {}
local MobCache = {}
local BItemEsp = false
local BItemTool = false
local BItemFood = false
local BItemChest = false
local BItemScrap = false
local BItemFuel = false
local BItemMisc = false
local BMobEsp = false
local BMobMob = false
local BMobCultist = false
local BMobMisc = false

local ESPColors = {
    Tool = _G.ToolColor or Color3.fromRGB(138,0,196),
    Food = _G.FoodColor or Color3.fromRGB(46,111,64),
    Chest = _G.ChestColor or Color3.fromRGB(239,191,4),
    Scrap = _G.ScrapColor or Color3.fromRGB(109,129,150),
    Fuel = _G.FuelColor or Color3.fromRGB(162,87,79),
    ItemMisc = _G.MiscItemColor or Color3.fromRGB(45,104,196),
    Mob = _G.MobColor or Color3.fromRGB(198,131,70),
    Cultist = _G.CultistColor or Color3.fromRGB(255,92,0),
    MobMisc = _G.MiscNPCColor or Color3.fromRGB(205,28,24),
}

local function CheckFilter(inst, b)
    if not b then
        if inst:GetAttribute("ToolName") then
            return "Tool"
        elseif inst:GetAttribute("RestoreHunger") then
            return "Food"
        elseif string.find(inst.Name, "Chest") then
            return "Chest"
        elseif inst:GetAttribute("Scrappable") then
            return "Scrap"
        elseif inst:GetAttribute("BurnFuel") then
            return "Fuel"
        else
            return "ItemMisc"
        end
    else
        if inst:GetAttribute("CanBeTamed") then
            return "Mob"
        elseif string.find(inst.Name, "Cultist") then
            return "Cultist"
        else
            return "MobMisc"
        end
    end
end

local window = UI:createwindow({
    Title = "99 Nights in the forest | Andris",
    Version = "VX",
    Keybind = "RightShift",
    ConfigFolder = "99nightsAndris", -- this is what the folder in workspace will be named, this is where your configs save
    CustomResolution = Vector2.new(580, 360), -- adjust ui resolution
    DPIScale = 1.0, -- only use if you have a custom scale set or 4k res
    CompactSettings = false,
    DefaultTab = "Main", 
    TabAlignment = "Center", -- options: "Left", "Center", "Right"
    DefaultColor = Color3.fromRGB(28, 27, 31),
    DefaultAccent = Color3.fromRGB(208, 188, 255),
    DefaultSnowfall = true,
    DefaultScale = 1.0,
    DefaultFont = 5 -- all fonts are at the bottom of the script
})

local tabMain = window:createtab("Main")

window:createtoggle(tabMain, {
    Name = "Toggle Item ESP",
    Col = 1,
    Default = false,
    Callback = function(val)
        BItemEsp = val
    end
})

window:createlabel(tabMain, "Item ESP Settings:", 1)

window:createtoggle(tabMain, {
    Name = "Show Tools",
    Col = 1,
    Default = false,
    Callback = function(val)
        BItemTool = val
        if val then
            table.insert(FilterTags, "Tool")
        else
            table.remove(FilterTags, table.find(FilterTags, "Tool"))
        end
    end
})

window:createtoggle(tabMain, {
    Name = "Show Foods",
    Col = 1,
    Default = false,
    Callback = function(val)
        BItemFood = val
        if val then
            table.insert(FilterTags, "Food")
        else
            table.remove(FilterTags, table.find(FilterTags, "Food"))
        end
    end
})

window:createtoggle(tabMain, {
    Name = "Show Chest",
    Col = 1,
    Default = false,
    Callback = function(val)
        BItemChest = val
        if val then
            table.insert(FilterTags, "Chest")
        else
            table.remove(FilterTags, table.find(FilterTags, "Chest"))
        end
    end
})

window:createtoggle(tabMain, {
    Name = "Show Scrap",
    Col = 1,
    Default = false,
    Callback = function(val)
        BItemScrap = val
        if val then
            table.insert(FilterTags, "Scrap")
        else
            table.remove(FilterTags, table.find(FilterTags, "Scrap"))
        end
    end
})

window:createtoggle(tabMain, {
    Name = "Show Fuel",
    Col = 1,
    Default = false,
    Callback = function(val)
        BItemFuel = val
        if val then
            table.insert(FilterTags, "Fuel")
        else
            table.remove(FilterTags, table.find(FilterTags, "Fuel"))
        end
    end
})

window:createtoggle(tabMain, {
    Name = "Show Misc Items",
    Col = 1,
    Default = false,
    Callback = function(val)
        BItemMisc = val
        if val then
            table.insert(FilterTags, "ItemMisc")
        else
            table.remove(FilterTags, table.find(FilterTags, "ItemMisc"))
        end
    end
})

window:createtoggle(tabMain, {
    Name = "Toggle NPC ESP",
    Col = 2,
    Default = false,
    Callback = function(val)
        BMobEsp = val
    end
})

window:createlabel(tabMain, "NPC ESP Settings:", 2)

window:createtoggle(tabMain, {
    Name = "Show Mobs",
    Col = 2,
    Default = false,
    Callback = function(val)
        BMobMob = val
        if val then
            table.insert(FilterTags, "Mob")
        else
            table.remove(FilterTags, table.find(FilterTags, "Mob"))
        end
    end
})

window:createtoggle(tabMain, {
    Name = "Show Cultists",
    Col = 2,
    Default = false,
    Callback = function(val)
        BMobCultist = val
        if val then
            table.insert(FilterTags, "Cultist")
        else
            table.remove(FilterTags, table.find(FilterTags, "Cultist"))
        end
    end
})

window:createtoggle(tabMain, {
    Name = "Show Misc NPCs",
    Col = 2,
    Default = false,
    Callback = function(val)
        BMobMisc = val
        if val then
            table.insert(FilterTags, "MobMisc")
        else
            table.remove(FilterTags, table.find(FilterTags, "MobMisc"))
        end
    end
})

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

RunService.Render:Connect(function()
    if BItemEsp then
        for id, inst in ItemCache do
            if not table.find(FilterTags, FilterNames[inst.Name]) then continue end
            local Color = ESPColors[FilterNames[inst.Name]]

            local s2, Position, Visible = pcall(function()
                return Camera:WorldToScreenPoint(inst.PrimaryPart.Position)
            end)

            if s2 and Visible then
                DrawingImmediate.OutlinedText(Position, 13, Color, 1, inst.Name, true)
            end
        end
    end

    if BMobEsp then
        for id, inst in MobCache do
            if not table.find(FilterTags, FilterNames[inst.Name]) then continue end
            local Color = ESPColors[FilterNames[inst.Name]]

            local s2, Position, Visible = pcall(function()
                return Camera:WorldToScreenPoint(inst.PrimaryPart.Position)
            end)

            if s2 and Visible then
                DrawingImmediate.OutlinedText(Position, 13, Color, 1, inst.Name, true)
            end
        end
    end
end)

local counter = 0

task.spawn(function()
    while true do
        task.wait(.01)
        counter += 1

        for _, inst in workspace.Items:GetChildren() do
            task.wait(.01)
            if ItemCache[InstId(inst)] then continue end
            if inst:IsA("Model") and inst.PrimaryPart then
                if inst.PrimaryPart:IsA("Part") or inst.PrimaryPart:IsA("MeshPart") and not inst:GetAttribute("InBag") then
                    if InstId(inst) then
                        FilterNames[inst.Name] = CheckFilter(inst, false)
                        ItemCache[InstId(inst)] = inst
                    end
                end
            end
        end

        for _, inst in workspace.Characters:GetChildren() do
            task.wait(.01)
            if MobCache[InstId(inst)] then continue end
            if inst:IsA("Model") and inst.PrimaryPart then
                if inst.PrimaryPart:IsA("Part") or inst.PrimaryPart:IsA("MeshPart") then
                    if InstId(inst) then
                        FilterNames[inst.Name] = CheckFilter(inst, true)
                        MobCache[InstId(inst)] = inst
                    end
                end
            end
        end

        for id, inst in ItemCache do
            if not inst or not inst.Parent then
                ItemCache[id] = nil
                continue
            end

            local Primary = inst.PrimaryPart
            if not Primary or (inst:IsA("Part") or inst:IsA("MeshPart")) then
                ItemCache[id] = nil
                continue
            end
        end

        for id, inst in MobCache do
            if not inst or not inst.Parent then
                MobCache[id] = nil
                continue
            end

            local Primary = inst.PrimaryPart
            if not Primary or (inst:IsA("Part") or inst:IsA("MeshPart")) then
                MobCache[id] = nil
                continue
            end
        end
    end
end)

print("Loaded")

end
