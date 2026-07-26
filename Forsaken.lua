--!strict
--!optimize 2

if game.GameId == 6331902150 then

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Map = workspace.Map
local Ingame = Map.Ingame
local Killers = workspace.Players.Killers
local ItemCache = {}
local bSurv = false
local bKill = false
local bInUI = false

local c = {
    danger = Color3.fromRGB(224,17,95),
    slightdanger = Color3.fromRGB(220,161,161),
    neutral = Color3.fromRGB(203,203,203),
    generator = Color3.fromRGB(234,162,33),
    cola = Color3.fromRGB(45,104,196),
    medkit = Color3.fromRGB(255,29,141),
    trap = Color3.fromRGB(179,27,27),
    azure = Color3.fromRGB(127,0,255),
    yellow = Color3.fromRGB(241,195,56),
}

local Names = {"shockwave", "Shockwave", "Swords", "SpikeCollision", "HumanoidRootProjectile", "Voidstar", "Bats", "Shadow", "VineModel", "GroundBulbModel", "BuildermanDispenser", "BuildermanSentry", "007n7", "Pizza", "GraffitiCL", "CrystalProjectile", "Medkit", "BloxyCola", "MisterBeast", "Noli"}
local SNames = {"BuildermanDispenser", "BuildermanSentry", "007n7", "Pizza", "GraffitiCL", "CrystalProjectile", "TaphTripwire", "SubspaceTripmine"}
local KNames = {"shockwave", "Shockwave", "Swords", "SpikeCollision", "HumanoidRootProjectile", "Voidstar", "Bats", "Shadow", "VineModel", "GroundBulbModel","Medkit", "BloxyCola", "MisterBeast", "Noli", "Puddle"}
local PNames = {"TaphTripwire", "SubspaceTripmine", "Puddle", "Shockwave"}

local NameColors = {
    shockwave = c.danger,
    Shockwave = c.danger,
    Swords = c.danger,
    SpikeCollision = c.neutral,
    HumanoidRootProjectile = c.danger,
    Voidstar = c.danger,
    Bats = c.danger,
    Shadow = c.trap,
    VineModel = c.trap,
    GroundBulbModel = c.trap,
    MisterBeast = c.azure,
    Azure = c.azure,
    Noli = c.neutral,
    ["1x1x1x1Zombie"] = c.yellow,
    JohnDoeTrail = c.slightdanger,
    Shadows = c.trap,
    Puddle = c.slightdanger,
    FakeGenerator = c.neutral,
    TaphTripwire = c.trap,
    SubspaceTripmine = c.danger,
    BuildermanDispenser = c.yellow,
    BuildermanSentry = c.trap,
    ["007n7"] = c.neutral,
    Pizza = c.yellow,
    GraffitiCL = c.yellow,
    CrystalProjectile = c.danger,
    Medkit = c.medkit,
    BloxyCola = c.cola,
}

local FullNames = {
    BuildermanDispenser = "Builder Dispenser",
    BuildermanSentry = "Builder Sentry",
    ["007n7"] = "007n7 Clone",
    Pizza = "Elliot Pizza",
    GraffitiCL = "Vee Graffiti",
    TaphTripwire = "Taph Tripwire",
    SubspaceTripmine = "Taph Mine",
    Shadow = "John Trap",
    VineModel = "Azure Vine",
    GroundBulbModel = "Azure Bulb",
    MisterBeast = "Azure Golem",
    ["1x1x1x1Zombie"] = "Zombie",
    FakeGenerator = "Fake Generator",
    Azure = "Azure",
    Noli = "Fake Noli",
    Medkit = "Medkit",
    BloxyCola = "Cola",
}

local BodyData = {"Head", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg"}

local h = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

local function GetGenPer(num)
    if num == 26 then return "25%" end
    if num == 52 then return "50%" end
    if num == 78 then return "75%" end
    return "0%"
end

local function GetPart(inst)
    local ClassName = inst.ClassName

    if ClassName == "Part" or ClassName == "UnionOperation" or ClassName == "MeshPart" then
        return inst
    end

    local Children = inst:GetChildren()

    if inst:FindFirstChild("Humanoid") then
        local ReturnTable = {}

        for _, part in BodyData do
            if inst:FindFirstChild(part) then
                table.insert(ReturnTable, inst[part])
            end
        end

        if #ReturnTable ~= 0 then return ReturnTable end
    end

    if inst.Name == "MisterBeast" then return inst:FindFirstChildOfClass("MeshPart") end
    if inst.Name == "VineModel" then return inst:FindFirstChild("Tentacle") end

    local s, p = pcall(function()
        return inst.PrimaryPart
    end)
    if s and p then return p end

    return inst:FindFirstChildOfClass("Part") or inst:FindFirstChildOfClass("MeshPart") or inst:FindFirstChildOfClass("UnionOperation")
end

local function Highlight(inst, color)
    local s, p = pcall(function()
        return inst.Position
    end)
    if s then
        h.Highlight(inst, color, .25, .7, .7)
    end
end

RunService.PreLocal:Connect(function()
    if LocalPlayer.Character then
        if LocalPlayer.Character.Parent then
            if LocalPlayer.Character.Parent.Name == "Survivors" then
                bSurv = true
                bKill = false
            elseif LocalPlayer.Character.Parent.Name == "Killers" then
                bSurv = false
                bKill = true
            else
                bSurv = false
                bKill = false
            end
        end
    end

    if LocalPlayer:FindFirstChild("PlayerGui") then
        if LocalPlayer.PlayerGui:FindFirstChild("PuzzleUI") then
            bInUI = true
        else
            bInUI = false
        end
    else
        bInUI = false
    end

    for _, inst in Ingame:GetChildren() do
        local id = InstId(inst)
        if not id then continue end
        if ItemCache[id] then continue end

        if table.find(Names, inst.Name) then
            ItemCache[id] = inst
            continue
        end

        for _, name in PNames do
            if string.find(inst.Name, name) then
                ItemCache[id] = inst
                continue
            end
        end

        if inst:FindFirstChild("Humanoid") then
            ItemCache[id] = inst
            continue
        end
    end

    for _, inst in Killers:GetChildren() do
        if inst.Name == "Noli" and not ItemCache[InstId(inst)] then
            if Players[inst:GetAttribute("Username")].Character ~= inst and InstId(inst) and #Killers:GetChildren() > 1 then
                ItemCache[InstId(inst)] = inst
                continue
            end
        end
    end

    if Map:FindFirstChild("Azure") then
        local id = InstId(Map.Azure)
        if id and not ItemCache[id] then
            ItemCache[id] = Map.Azure
        end
    end

    for _, inst in workspace:GetChildren() do
        local id = InstId(inst)
        if not id then continue end
        if ItemCache[id] then continue end

        if inst.Name == "BloxyCola" then
            ItemCache[id] = inst
        elseif inst.Name == "Medkit" then
            ItemCache[id] = inst
        end
    end

    for _, inst in Ingame:GetChildren() do
        if string.find(inst.Name, "JohnDoeTrail") or string.find(inst.Name, "Shadows") then
            for _, part in inst:GetChildren() do
                local id = InstId(part)
                if not id then continue end
                if ItemCache[id] then continue end

                ItemCache[id] = part
            end
        end
    end

    if not Ingame:FindFirstChild("Map") then return end

    for _, inst in Ingame.Map:GetChildren() do
        local id = InstId(inst)
        if not id then continue end
        if ItemCache[id] then continue end

        if inst.Name == "Generator" and inst:FindFirstChild("Progress") then
            if inst:FindFirstChild("Progress").Name == "Progress" then
                if inst:FindFirstChild("Progress").Value ~= 100 then
                    ItemCache[id] = inst
                end
            end
        elseif inst.Name == "FakeGenerator" then
            ItemCache[id] = inst
        elseif inst.Name == "BloxyCola" then
            ItemCache[id] = inst
        elseif inst.Name == "Medkit" then
            ItemCache[id] = inst
        end
    end
end)

RunService.Render:Connect(function()
    for id, inst in ItemCache do
        local Parent
        local Name
        if not inst or not inst.Parent then
            ItemCache[id] = nil
            continue
        elseif inst.Parent.Name == "Backpack" then
            ItemCache[id] = nil
            continue
        else
            Name = inst.Name
        end

        if type(Name) ~= "string" then
            ItemCache[id] = nil
            continue
        end

        if Name == "Generator" and bInUI then continue end

        if Name == "Generator" then
            if not inst:FindFirstChild("Main") or not inst:FindFirstChild("Progress") then
                ItemCache[id] = nil
                continue
            end

            local Main = inst.Main
            local Progress = inst.Progress

            if Progress.Value == 100 then
                ItemCache[id] = nil
                continue
            end

            Highlight(Main, c.generator)
            local p, v = Camera:WorldToScreenPoint(Main.Position)
			if v then
				local NewPos = Vector2.new(p.x, p.y - 6.5)
				DrawingImmediate.OutlinedText(NewPos, 13, c.generator, 1, GetGenPer(Progress.Value), true)
			end
            continue
        end

        local Parts = GetPart(inst)

        local color = NameColors[Name] or c.yellow
        local name = FullNames[Name]
        for _, v in PNames do
            if string.find(Name, v) then
                color = NameColors[v]
                name = FullNames[v]
            end
        end

        if bSurv and table.find(SNames, Name) then continue end
        if bKill and table.find(KNames, Name) then continue end
        if string.find(Name, "Spray") then continue end

        if type(Parts) == "table" then
            for _, part in Parts do
                if part.Name == "Torso" then
                    if not name then
                        name = "Minion"
                    end

                    local s, pos = pcall(function()
                        return part.Position
                    end)
                    if s then
                        local p, v = Camera:WorldToScreenPoint(pos)
                        if v then
                            local NewPos = Vector2.new(p.x, p.y - 6.5)
                            DrawingImmediate.OutlinedText(NewPos, 13, color, 1, name, true)
                        end
                    end
                end
                Highlight(part, color)
            end
        elseif Parts then
            if name then
                local s, pos = pcall(function()
                        return Parts.Position
                    end)
                if s then
                    local p, v = Camera:WorldToScreenPoint(pos)
                    if v then
                        local NewPos = Vector2.new(p.x, p.y - 6.5)
                        DrawingImmediate.OutlinedText(NewPos, 13, color, 1, name, true)
                    end
                end
            end
            Highlight(Parts, color)
        end
    end
end)

print("Loaded")

end
