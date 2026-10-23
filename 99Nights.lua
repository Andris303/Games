--!optimize 2
--!strict

if game.GameId == 7326934954 then

local RobloxVersion = _G.RobloxVersion or game:GetClientVersion()
local offsetsOk, offsetsData = pcall(crypt.json.decode, game:HttpGet("https://offsets.imtheo.lol/" .. RobloxVersion .. "/offsets.json"))
local O = offsetsOk and type(offsetsData) == "table" and offsetsData.Offsets or {}
local childrenOffset = O.Instance and O.Instance.ChildrenStart
local childrenEndOffset = O.Instance and O.Instance.ChildrenEnd

local UI = loadstring(game:HttpGet("https://gitlab.com/okdude42/severe-scripts/-/raw/main/uilib2/SevereUI.luau?ref_type=heads"))()

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local bItemESP = false
local bMobESP = false
local maxDistance = 1000
local newPerScan = 15

local window
local preLocalConnect
local renderConnect
local FlagSetters = {}
local AppliedFlags = {}

local Enabled = {}
local Categories = {}
local ItemCache = {}
local MobCache = {}
local Retry = {}
local DrawList = {}
local Timers = {Scan = 0, DrawList = 0}
local lastTick = 0
local lastData = 0

local ESPColors = {
    Tool = Color3.fromRGB(138, 0, 196),
    Food = Color3.fromRGB(46, 111, 64),
    Chest = Color3.fromRGB(239, 191, 4),
    Scrap = Color3.fromRGB(109, 129, 150),
    Fuel = Color3.fromRGB(162, 87, 79),
    ItemMisc = Color3.fromRGB(45, 104, 196),
    Mob = Color3.fromRGB(198, 131, 70),
    Cultist = Color3.fromRGB(255, 92, 0),
    MobMisc = Color3.fromRGB(205, 28, 24),
}

local function InstId(inst)
    return tostring(tonumber(inst.Data))
end

local function ReadU64(address, offset)
    local ok, value = pcall(memory.readu64, address, offset)
    return ok and value or nil
end

local function MemoryChildren(folder)
    if not childrenOffset or not childrenEndOffset then return folder:GetChildren() end

    local address = tonumber(folder.Data)
    local list = address and ReadU64(address, childrenOffset)
    local first = list and ReadU64(list, 0)
    local last = list and ReadU64(list, childrenEndOffset)
    if not first or not last or last < first or last - first > 0x10 * 5000 then
        return folder:GetChildren()
    end

    local children = {}
    for pointer = first, last - 0x10, 0x10 do
        local child = ReadU64(pointer, 0)
        if child and child ~= 0 then
            local ok, inst = pcall(pointer_to_userdata, child)
            if ok and inst then children[#children + 1] = inst end
        end
    end
    return children
end

local function Categorize(inst, isMob)
    if isMob then
        if inst:GetAttribute("CanBeTamed") then return "Mob" end
        if string.find(inst.Name, "Cultist") then return "Cultist" end
        return "MobMisc"
    end

    if inst:GetAttribute("ToolName") then return "Tool" end
    if inst:GetAttribute("RestoreHunger") then return "Food" end
    if string.find(inst.Name, "Chest") then return "Chest" end
    if inst:GetAttribute("Scrappable") then return "Scrap" end
    if inst:GetAttribute("BurnFuel") then return "Fuel" end
    return "ItemMisc"
end

local function MakeEntry(inst, isMob, now)
    if not inst:IsA("Model") then
        Retry[InstId(inst)] = math.huge
        return nil
    end

    local primary = inst.PrimaryPart
    if not primary or not (primary:IsA("Part") or primary:IsA("MeshPart")) then
        Retry[InstId(inst)] = now + 2
        return nil
    end

    if not isMob and inst:GetAttribute("InBag") == "true" then
        Retry[InstId(inst)] = now + 2
        return nil
    end

    local name = inst.Name
    local key = (isMob and "Mob:" or "Item:") .. name
    local category = Categories[key]
    if not category then
        category = Categorize(inst, isMob)
        Categories[key] = category
    end

    return {Part = primary, Name = name, Category = category}
end

local function ScanFolder(folder, cache, isMob, now, budget)
    local fresh = {}
    for _, inst in MemoryChildren(folder) do
        local id = InstId(inst)
        local entry = cache[id]
        if not entry and budget > 0 and now >= (Retry[id] or 0) then
            budget -= 1
            Retry[id] = nil
            entry = MakeEntry(inst, isMob, now)
        end
        if entry then fresh[id] = entry end
    end
    return fresh, budget
end

local function Scan(now)
    local budget = newPerScan
    local items = workspace:FindFirstChild("Items")
    local characters = workspace:FindFirstChild("Characters")

    if items and bItemESP then
        ItemCache, budget = ScanFolder(items, ItemCache, false, now, budget)
    else
        ItemCache = {}
    end

    if characters and bMobESP then
        MobCache = ScanFolder(characters, MobCache, true, now, budget)
    else
        MobCache = {}
    end
end

local function BuildDrawList()
    local list = {}
    local cameraPos = Camera.Position

    for _, cache in {ItemCache, MobCache} do
        for _, entry in cache do
            if Enabled[entry.Category] and vector.magnitude(entry.Part.Position - cameraPos) <= maxDistance then
                list[#list + 1] = entry
            end
        end
    end
    DrawList = list
end

local function SyncFlags()
    for flag, apply in FlagSetters do
        local value = window:get(flag)
        if value ~= AppliedFlags[flag] then
            AppliedFlags[flag] = value
            apply(value)
        end
    end
end

local function Due(name, interval, now)
    if now < Timers[name] then return false end
    Timers[name] = now + interval
    return true
end

local function PreLocal()
    SyncFlags()

    local now = os.clock()
    if now - lastTick > 1 then
        ItemCache = {}
        MobCache = {}
        DrawList = {}
        Retry = {}
        for name in Timers do Timers[name] = 0 end
    end
    lastTick = now

    if Due("Scan", .25, now) then Scan(now) end
    if Due("DrawList", .25, now) then BuildDrawList() end

    lastData = os.clock()
end

local function Render()
    if os.clock() - lastData > .5 then return end

    for i = 1, #DrawList do
        local entry = DrawList[i]
        local position, visible = Camera:WorldToScreenPoint(entry.Part.Position)
        if visible then
            DrawingImmediate.OutlinedText(position, 13, ESPColors[entry.Category], 1, entry.Name, true)
        end
    end
end

window = UI.new({
    Title = "Andris: 99 Nights",
    Subtitle = "ESP",
    Version = "2.0.0",
    Folder = "99nightsAndris",
    Footer = "Item and NPC ESP",
    UpdateNotice = {"V2.0.0", "This script now uses ok0f's V2 UI library."},
    OnUnload = function()
        preLocalConnect:Disconnect()
        renderConnect:Disconnect()
    end,
    OnReload = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Games/refs/heads/main/99Nights.lua"))()
    end,
})

do
    local main = window:tab("Main")
    local items = main:section("ITEMS")
    local npcs = main:section("NPCS")
    local other = main:section("OTHER")
    local colors = window:tab("Colors")
    local itemColors = colors:section("ITEMS")
    local npcColors = colors:section("NPCS")

    items:toggle({Name = "Item ESP", Flag = "ItemESP", Default = false})
    FlagSetters.ItemESP = function(val)
        bItemESP = val
    end

    npcs:toggle({Name = "NPC ESP", Flag = "MobESP", Default = false})
    FlagSetters.MobESP = function(val)
        bMobESP = val
    end

    for _, entry in {
        {items, itemColors, "Tools", "Tool"},
        {items, itemColors, "Foods", "Food"},
        {items, itemColors, "Chests", "Chest"},
        {items, itemColors, "Scrap", "Scrap"},
        {items, itemColors, "Fuel", "Fuel"},
        {items, itemColors, "Misc items", "ItemMisc"},
        {npcs, npcColors, "Mobs", "Mob"},
        {npcs, npcColors, "Cultists", "Cultist"},
        {npcs, npcColors, "Misc NPCs", "MobMisc"},
    } do
        local section, colorSection, label, category = entry[1], entry[2], entry[3], entry[4]

        section:toggle({Name = "Show " .. label, Flag = "Show" .. category, Default = false})
        FlagSetters["Show" .. category] = function(val)
            Enabled[category] = val
        end

        colorSection:color({Name = label .. " color", Flag = "Color" .. category, Default = ESPColors[category]})
        FlagSetters["Color" .. category] = function(val)
            ESPColors[category] = val
        end
    end

    other:slider({Name = "Max distance", Flag = "MaxDistance", Min = 50, Max = 3000, Default = 1000, Step = 50})
    FlagSetters.MaxDistance = function(val)
        maxDistance = val
    end
end

window:start()

preLocalConnect = RunService.PreLocal:Connect(PreLocal)
renderConnect = RunService.Render:Connect(Render)

print("Loaded")

end
